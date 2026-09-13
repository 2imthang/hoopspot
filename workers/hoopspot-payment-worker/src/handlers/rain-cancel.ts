import type { ServiceAccount } from '../lib/google-auth';
import { getFirestoreAccessToken } from '../lib/google-auth';
import { getDocument } from '../lib/firestore';
import { executeRefund, findConfirmedPayment, parseBookingEndTime } from '../refundExecution';

interface Env {
	VNP_TMN_CODE: string;
	VNP_HASH_SECRET: string;
	FIREBASE_SERVICE_ACCOUNT_JSON: string;
}

interface RainCancelBody {
	ownerId: string;
	bookingId: string;
}

function isValidBody(body: unknown): body is RainCancelBody {
	if (typeof body !== 'object' || body === null) return false;
	const b = body as Record<string, unknown>;
	return typeof b.ownerId === 'string' && b.ownerId.length > 0 && typeof b.bookingId === 'string' && b.bookingId.length > 0;
}

// TASK-026 — Owner đánh dấu "hủy do mưa": không có rule 6 tiếng (hoàn 100%
// bất kể thời điểm), nhưng chỉ áp dụng cho sân `isOutdoor` và chỉ khi buổi
// chơi CHƯA KẾT THÚC (functional-spec 4.5.B).
export async function handleRainCancel(request: Request, env: Env): Promise<Response> {
	let body: unknown;
	try {
		body = await request.json();
	} catch {
		return Response.json({ error: 'Body không phải JSON hợp lệ' }, { status: 400 });
	}
	if (!isValidBody(body)) {
		return Response.json({ error: 'Thiếu hoặc sai kiểu ownerId/bookingId' }, { status: 400 });
	}

	const serviceAccount = JSON.parse(env.FIREBASE_SERVICE_ACCOUNT_JSON) as ServiceAccount;
	const accessToken = await getFirestoreAccessToken(serviceAccount);
	const projectId = serviceAccount.project_id;

	const booking = await getDocument(projectId, accessToken, `bookings/${body.bookingId}`);
	if (!booking) {
		return Response.json({ error: 'Không tìm thấy booking' }, { status: 404 });
	}
	// Chỉ Owner đúng chủ sân của booking này mới được đánh dấu — không cho
	// Owner khác hủy hộ, tránh lạm dụng (functional-spec 4.5.B).
	if (booking.ownerId !== body.ownerId) {
		return Response.json({ error: 'Booking không thuộc sân của owner này' }, { status: 403 });
	}
	if (booking.status !== 'confirmed') {
		return Response.json({ error: 'Chỉ hủy được booking đã xác nhận thanh toán (confirmed)' }, { status: 409 });
	}

	const court = await getDocument(projectId, accessToken, `courts/${booking.courtId}`);
	if (!court || court.isOutdoor !== true) {
		return Response.json({ error: 'Hủy do mưa chỉ áp dụng cho sân ngoài trời' }, { status: 409 });
	}

	const playEnd = parseBookingEndTime(booking.date as string, booking.timeSlot as string);
	if (playEnd.getTime() <= Date.now()) {
		return Response.json({ error: 'Buổi chơi đã kết thúc, không thể đánh dấu hủy do mưa' }, { status: 409 });
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
		cancelReason: 'rain',
		ipAddr: request.headers.get('CF-Connecting-IP') ?? '127.0.0.1',
	});
}
