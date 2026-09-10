import type { ServiceAccount } from '../lib/google-auth';
import { getFirestoreAccessToken } from '../lib/google-auth';
import { buildWrite, commitWrites, getDocument } from '../lib/firestore';
import { buildSignedPaymentUrl } from '../vnpay';

interface Env {
	VNP_TMN_CODE: string;
	VNP_HASH_SECRET: string;
	FIREBASE_SERVICE_ACCOUNT_JSON: string;
}

interface CreatePaymentUrlBody {
	userId: string;
	bookingIds: string[];
	returnUrl: string;
}

function isValidBody(body: unknown): body is CreatePaymentUrlBody {
	if (typeof body !== 'object' || body === null) return false;
	const b = body as Record<string, unknown>;
	return (
		typeof b.userId === 'string' &&
		b.userId.length > 0 &&
		Array.isArray(b.bookingIds) &&
		b.bookingIds.length > 0 &&
		b.bookingIds.every((id) => typeof id === 'string') &&
		typeof b.returnUrl === 'string' &&
		b.returnUrl.length > 0
	);
}

// Không tin số tiền từ app gửi lên — tự đọc từng booking trong Firestore rồi
// cộng dồn `pricePerSlot`, để tránh 1 app đã bị sửa đổi yêu cầu thanh toán
// thiếu tiền. Đồng thời chặn luôn việc trả tiền hộ booking của người khác.
async function loadAndValidateBookings(
	projectId: string,
	accessToken: string,
	bookingIds: string[],
	userId: string,
): Promise<{ amount: number } | { error: string; status: number }> {
	let amount = 0;
	for (const bookingId of bookingIds) {
		const doc = await getDocument(projectId, accessToken, `bookings/${bookingId}`);
		if (!doc) return { error: `Không tìm thấy booking ${bookingId}`, status: 404 };
		if (doc.userId !== userId) return { error: `Booking ${bookingId} không thuộc về user này`, status: 403 };
		if (doc.status !== 'pendingPayment') return { error: `Booking ${bookingId} không ở trạng thái chờ thanh toán`, status: 409 };
		amount += doc.pricePerSlot as number;
	}
	return { amount };
}

function randomTxnRef(): string {
	return crypto.randomUUID().replace(/-/g, '').slice(0, 20).toUpperCase();
}

export async function handleCreatePaymentUrl(request: Request, env: Env): Promise<Response> {
	let body: unknown;
	try {
		body = await request.json();
	} catch {
		return Response.json({ error: 'Body không phải JSON hợp lệ' }, { status: 400 });
	}

	if (!isValidBody(body)) {
		return Response.json({ error: 'Thiếu hoặc sai kiểu userId/bookingIds/returnUrl' }, { status: 400 });
	}

	const serviceAccount = JSON.parse(env.FIREBASE_SERVICE_ACCOUNT_JSON) as ServiceAccount;
	const accessToken = await getFirestoreAccessToken(serviceAccount);
	const projectId = serviceAccount.project_id;

	const validation = await loadAndValidateBookings(projectId, accessToken, body.bookingIds, body.userId);
	if ('error' in validation) {
		return Response.json({ error: validation.error }, { status: validation.status });
	}

	const txnRef = randomTxnRef();
	await commitWrites(projectId, accessToken, [
		buildWrite(projectId, `payments/${txnRef}`, {
			userId: body.userId,
			bookingIds: body.bookingIds,
			amount: validation.amount,
			status: 'pending',
			createdAt: new Date(),
		}),
	]);

	const paymentUrl = await buildSignedPaymentUrl({
		amount: validation.amount,
		orderInfo: `Thanh toan ${body.bookingIds.length} ca san HoopSpot`,
		txnRef,
		returnUrl: body.returnUrl,
		tmnCode: env.VNP_TMN_CODE,
		hashSecret: env.VNP_HASH_SECRET,
		ipAddr: request.headers.get('CF-Connecting-IP') ?? '127.0.0.1',
	});

	return Response.json({ paymentUrl, txnRef });
}
