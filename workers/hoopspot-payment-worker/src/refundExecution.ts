import { buildWrite, commitWrites, getDocument } from './lib/firestore';
import { callVnpayRefund } from './vnpayRefund';

/**
 * Phần dùng chung giữa TASK-025 (`POST /refund`, user tự hủy) và TASK-026
 * (`POST /rain-cancel`, Owner đánh dấu hủy do mưa) — 2 route khác nhau ở
 * ĐIỀU KIỆN được phép hủy (6 tiếng vs sân ngoài trời), nhưng phần "gọi
 * VNPay Refund thật + ghi kết quả vào Firestore" thì giống hệt nhau.
 */

// `date`/`timeSlot` là giờ VN (GMT+7) dạng chuỗi thuần, vd "2026-09-20" +
// "18:00-20:00" — dựng lại đúng thời điểm UTC thật để so với "bây giờ".
function parseSlotBoundary(date: string, timeSlot: string, part: 'start' | 'end'): Date {
	const [year, month, day] = date.split('-').map(Number);
	const [startStr, endStr] = timeSlot.split('-');
	const hour = Number((part === 'start' ? startStr : endStr).split(':')[0]);
	const naiveUtcMs = Date.UTC(year, month - 1, day, hour, 0, 0);
	return new Date(naiveUtcMs - 7 * 60 * 60 * 1000);
}

export function parseBookingStartTime(date: string, timeSlot: string): Date {
	return parseSlotBoundary(date, timeSlot, 'start');
}

export function parseBookingEndTime(date: string, timeSlot: string): Date {
	return parseSlotBoundary(date, timeSlot, 'end');
}

// Tìm giao dịch VNPay gốc đã thanh toán thành công của 1 booking, qua
// `booking.txnRef` (IPN — TASK-021 — ghi lại field này lúc confirm).
export async function findConfirmedPayment(
	projectId: string,
	accessToken: string,
	booking: Record<string, unknown>,
): Promise<{ txnRef: string; payment: Record<string, unknown> } | null> {
	const txnRef = booking.txnRef as string | undefined;
	if (!txnRef) return null;
	const payment = await getDocument(projectId, accessToken, `payments/${txnRef}`);
	if (!payment || payment.status !== 'success') return null;
	return { txnRef, payment };
}

export type CancelReason = 'user_cancel' | 'rain';

export interface ExecuteRefundParams {
	projectId: string;
	accessToken: string;
	tmnCode: string;
	hashSecret: string;
	bookingId: string;
	pricePerSlot: number;
	txnRef: string;
	payment: Record<string, unknown>;
	cancelReason: CancelReason;
	ipAddr: string;
}

// Gọi VNPay Refund API thật, rồi ghi kết quả vào Firestore. Luôn hoàn 1
// phần (`vnp_TransactionType: 03`) đúng bằng giá của booking bị hủy — không
// cần biết payment gốc có 1 hay nhiều booking, xử lý giống nhau.
export async function executeRefund(params: ExecuteRefundParams): Promise<Response> {
	const refund = await callVnpayRefund({
		tmnCode: params.tmnCode,
		hashSecret: params.hashSecret,
		txnRef: params.txnRef,
		amount: params.pricePerSlot,
		transactionNo: (params.payment.vnp_TransactionNo as string) || '0',
		transactionDate: (params.payment.vnp_PayDate as string) || '',
		orderInfo: `Hoan tien huy booking ${params.bookingId} (${params.cancelReason})`,
		ipAddr: params.ipAddr,
	});

	if (!refund.success) {
		// functional-spec 4.5.B: gọi Refund API thất bại -> đánh dấu
		// `refund_pending` thay vì để booking "treo" không rõ trạng thái, KHÔNG
		// đổi `status` (vẫn `confirmed`) vì tiền chưa chắc chắn được hoàn.
		await commitWrites(params.projectId, params.accessToken, [
			buildWrite(params.projectId, `bookings/${params.bookingId}`, { refundStatus: 'refund_pending' }, ['refundStatus']),
		]);
		return Response.json(
			{ error: `VNPay từ chối hoàn tiền: ${refund.message} (${refund.responseCode})`, refundStatus: 'refund_pending' },
			{ status: 502 },
		);
	}

	await commitWrites(params.projectId, params.accessToken, [
		buildWrite(
			params.projectId,
			`bookings/${params.bookingId}`,
			{
				status: 'cancelled',
				refundStatus: 'refunded',
				cancelReason: params.cancelReason,
				vnp_RefundTransactionNo: refund.vnpTransactionNo ?? '',
			},
			['status', 'refundStatus', 'cancelReason', 'vnp_RefundTransactionNo'],
		),
	]);

	return Response.json({ refunded: true });
}
