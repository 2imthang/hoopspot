import type { ServiceAccount } from '../lib/google-auth';
import { getFirestoreAccessToken } from '../lib/google-auth';
import { getDocument } from '../lib/firestore';
import { cancelWithoutRefund, executeRefund, findConfirmedPayment, parseBookingStartTime } from '../refundExecution';

interface Env {
	VNP_TMN_CODE: string;
	VNP_HASH_SECRET: string;
	FIREBASE_SERVICE_ACCOUNT_JSON: string;
}

// functional-spec 4.5.B: hủy ≥ 6 tiếng trước giờ chơi mới được hoàn 100%.
const MIN_HOURS_BEFORE_PLAY_FOR_REFUND = 6;

interface RefundRequestBody {
	userId: string;
	bookingId: string;
}

function isValidBody(body: unknown): body is RefundRequestBody {
	if (typeof body !== 'object' || body === null) return false;
	const b = body as Record<string, unknown>;
	return typeof b.userId === 'string' && b.userId.length > 0 && typeof b.bookingId === 'string' && b.bookingId.length > 0;
}

export async function handleRefund(request: Request, env: Env): Promise<Response> {
	let body: unknown;
	try {
		body = await request.json();
	} catch {
		return Response.json({ error: 'Body không phải JSON hợp lệ' }, { status: 400 });
	}
	if (!isValidBody(body)) {
		return Response.json({ error: 'Thiếu hoặc sai kiểu userId/bookingId' }, { status: 400 });
	}

	const serviceAccount = JSON.parse(env.FIREBASE_SERVICE_ACCOUNT_JSON) as ServiceAccount;
	const accessToken = await getFirestoreAccessToken(serviceAccount);
	const projectId = serviceAccount.project_id;

	const booking = await getDocument(projectId, accessToken, `bookings/${body.bookingId}`);
	if (!booking) {
		return Response.json({ error: 'Không tìm thấy booking' }, { status: 404 });
	}
	if (booking.userId !== body.userId) {
		return Response.json({ error: 'Booking không thuộc về user này' }, { status: 403 });
	}
	if (booking.status !== 'confirmed') {
		return Response.json({ error: 'Chỉ hủy được booking đã xác nhận thanh toán (confirmed)' }, { status: 409 });
	}

	const playStart = parseBookingStartTime(booking.date as string, booking.timeSlot as string);
	const hoursUntilPlay = (playStart.getTime() - Date.now()) / (1000 * 60 * 60);
	if (hoursUntilPlay < MIN_HOURS_BEFORE_PLAY_FOR_REFUND) {
		return cancelWithoutRefund(projectId, accessToken, body.bookingId);
	}

	const found = await findConfirmedPayment(projectId, accessToken, booking);
	if (!found) {
		return Response.json({ error: 'Không tìm thấy giao dịch thanh toán gốc đã thành công cho booking này' }, { status: 409 });
	}

	return executeRefund({
		projectId,
		accessToken,
		tmnCode: env.VNP_TMN_CODE,
		hashSecret: env.VNP_HASH_SECRET,
		bookingId: body.bookingId,
		pricePerSlot: booking.pricePerSlot as number,
		txnRef: found.txnRef,
		payment: found.payment,
		cancelReason: 'user_cancel',
		ipAddr: request.headers.get('CF-Connecting-IP') ?? '127.0.0.1',
	});
}
