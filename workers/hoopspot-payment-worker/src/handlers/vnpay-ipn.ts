import type { ServiceAccount } from '../lib/google-auth';
import { getFirestoreAccessToken } from '../lib/google-auth';
import { buildWrite, commitWrites, getDocument } from '../lib/firestore';
import { verifyVnpaySignature } from '../vnpay';

interface Env {
	VNP_HASH_SECRET: string;
	FIREBASE_SERVICE_ACCOUNT_JSON: string;
}

// Format bắt buộc VNPay yêu cầu ở mọi phản hồi IPN — không phải body thường,
// VNPay đọc đúng field RspCode để biết có cần gọi lại IPN nữa không.
function ipnResponse(rspCode: string, message: string): Response {
	return Response.json({ RspCode: rspCode, Message: message });
}

export async function handleVnpayIpn(url: URL, env: Env): Promise<Response> {
	const params = Object.fromEntries(url.searchParams.entries());

	// 1. Verify chữ ký TRƯỚC TIÊN — không tin bất kỳ field nào khác cho tới
	// khi biết chắc lời gọi này thật sự đến từ VNPay (có khóa bí mật mới ký
	// đúng được), tránh ai đó tự gọi vào route này để giả mạo xác nhận thanh toán.
	const isValidSignature = await verifyVnpaySignature(params, env.VNP_HASH_SECRET);
	if (!isValidSignature) {
		return ipnResponse('97', 'Fail checksum');
	}

	const serviceAccount = JSON.parse(env.FIREBASE_SERVICE_ACCOUNT_JSON) as ServiceAccount;
	const accessToken = await getFirestoreAccessToken(serviceAccount);
	const projectId = serviceAccount.project_id;

	const txnRef = params['vnp_TxnRef'];
	const payment = await getDocument(projectId, accessToken, `payments/${txnRef}`);
	if (!payment) {
		return ipnResponse('01', 'Order not found');
	}

	// 2. Idempotency (TASK-022): VNPay có thể gọi IPN lặp lại cho cùng 1 giao
	// dịch (mất mạng, timeout...). Nếu đơn đã xử lý rồi (khác 'pending') thì
	// báo lại thành công luôn, KHÔNG ghi đè/confirm lần 2.
	if (payment.status !== 'pending') {
		return ipnResponse('02', 'Order already confirmed');
	}

	const receivedAmount = Number(params['vnp_Amount']) / 100;
	if (receivedAmount !== payment.amount) {
		return ipnResponse('04', 'Invalid amount');
	}

	const isSuccess = params['vnp_ResponseCode'] === '00' && params['vnp_TransactionStatus'] === '00';
	const bookingIds = (payment.bookingIds as string[]) ?? [];

	await commitWrites(projectId, accessToken, [
		buildWrite(
			projectId,
			`payments/${txnRef}`,
			{ status: isSuccess ? 'success' : 'failed', vnp_TransactionNo: params['vnp_TransactionNo'] ?? '' },
			['status', 'vnp_TransactionNo'],
		),
		...bookingIds.map((bookingId) =>
			buildWrite(projectId, `bookings/${bookingId}`, { status: isSuccess ? 'confirmed' : 'cancelled' }, ['status']),
		),
	]);

	return ipnResponse('00', 'Confirm Success');
}
