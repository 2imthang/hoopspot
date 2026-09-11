import type { ServiceAccount } from '../lib/google-auth';
import { getFirestoreAccessToken } from '../lib/google-auth';
import { buildWrite, commitWrites, getDocument } from '../lib/firestore';
import { callVnpayRefund } from '../vnpayRefund';

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

// `date`/`timeSlot` là giờ VN (GMT+7) dạng chuỗi thuần, vd "2026-09-20" +
// "18:00-20:00" — dựng lại đúng thời điểm UTC thật để so với "bây giờ".
function parseBookingStartTime(date: string, timeSlot: string): Date {
	const [year, month, day] = date.split('-').map(Number);
	const startHour = Number(timeSlot.split('-')[0].split(':')[0]);
	const naiveUtcMs = Date.UTC(year, month - 1, day, startHour, 0, 0);
	return new Date(naiveUtcMs - 7 * 60 * 60 * 1000);
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
		return Response.json(
			{ error: 'Hủy trong vòng 6 tiếng trước giờ chơi không được hoàn tiền', hoursUntilPlay },
			{ status: 409 },
		);
	}

	const txnRef = booking.txnRef as string | undefined;
	const payment = txnRef ? await getDocument(projectId, accessToken, `payments/${txnRef}`) : null;
	if (!txnRef || !payment || payment.status !== 'success') {
		return Response.json({ error: 'Không tìm thấy giao dịch thanh toán gốc đã thành công cho booking này' }, { status: 409 });
	}

	const refund = await callVnpayRefund({
		tmnCode: env.VNP_TMN_CODE,
		hashSecret: env.VNP_HASH_SECRET,
		txnRef,
		amount: booking.pricePerSlot as number,
		transactionNo: (payment.vnp_TransactionNo as string) || '0',
		transactionDate: (payment.vnp_PayDate as string) || '',
		orderInfo: `Hoan tien huy booking ${body.bookingId}`,
		ipAddr: request.headers.get('CF-Connecting-IP') ?? '127.0.0.1',
	});

	if (!refund.success) {
		// functional-spec 4.5.B: gọi Refund API thất bại -> đánh dấu
		// `refund_pending` thay vì để booking "treo" không rõ trạng thái, KHÔNG
		// đổi `status` (vẫn `confirmed`) vì tiền chưa chắc chắn được hoàn.
		await commitWrites(projectId, accessToken, [
			buildWrite(projectId, `bookings/${body.bookingId}`, { refundStatus: 'refund_pending' }, ['refundStatus']),
		]);
		return Response.json(
			{ error: `VNPay từ chối hoàn tiền: ${refund.message} (${refund.responseCode})`, refundStatus: 'refund_pending' },
			{ status: 502 },
		);
	}

	await commitWrites(projectId, accessToken, [
		buildWrite(
			projectId,
			`bookings/${body.bookingId}`,
			{ status: 'cancelled', refundStatus: 'refunded', vnp_RefundTransactionNo: refund.vnpTransactionNo ?? '' },
			['status', 'refundStatus', 'vnp_RefundTransactionNo'],
		),
	]);

	return Response.json({ refunded: true });
}
