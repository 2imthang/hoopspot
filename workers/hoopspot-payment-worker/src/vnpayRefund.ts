import { formatVnpDate, hmacSha512Hex } from './vnpay';

/**
 * TASK-025 — gọi VNPay Refund API. Đây là API RIÊNG (khác hẳn tạo URL thanh
 * toán / IPN ở TASK-020/021): gửi JSON qua POST, và chữ ký ký trên chuỗi nối
 * bằng dấu "|" theo ĐÚNG THỨ TỰ cố định (không sort alphabet, không
 * form-encode) — đối chiếu từ mã nguồn thật của thư viện vnpay (Node.js) vì
 * docs VNPay không nêu rõ chi tiết encode.
 */

const VNPAY_REFUND_URL = 'https://sandbox.vnpayment.vn/merchant_webapi/api/transaction';

// 02 = hoàn toàn phần, 03 = hoàn 1 phần. Luôn dùng 03 với đúng số tiền của
// booking bị hủy — đơn giản hơn vì xử lý giống nhau dù payment gốc có 1 hay
// nhiều booking (không cần biết đây có phải toàn bộ payment hay không).
const VNP_TRANSACTION_TYPE_PARTIAL = '03';

export interface RefundInput {
	tmnCode: string;
	hashSecret: string;
	txnRef: string;
	amount: number;
	transactionNo: string;
	/** `vnp_PayDate` gốc, đã ở định dạng yyyyMMddHHmmss — lấy từ payment doc. */
	transactionDate: string;
	orderInfo: string;
	ipAddr: string;
}

export interface RefundResult {
	success: boolean;
	responseCode: string;
	message: string;
	vnpTransactionNo?: string;
}

export async function callVnpayRefund(input: RefundInput): Promise<RefundResult> {
	const requestId = crypto.randomUUID().replace(/-/g, '').slice(0, 20).toUpperCase();
	const now = new Date();
	const createDate = formatVnpDate(now);
	const amountX100 = String(Math.round(input.amount * 100));

	const body: Record<string, string> = {
		vnp_RequestId: requestId,
		vnp_Version: '2.1.0',
		vnp_Command: 'refund',
		vnp_TmnCode: input.tmnCode,
		vnp_TransactionType: VNP_TRANSACTION_TYPE_PARTIAL,
		vnp_TxnRef: input.txnRef,
		vnp_Amount: amountX100,
		vnp_TransactionNo: input.transactionNo,
		vnp_TransactionDate: input.transactionDate,
		vnp_CreateBy: 'system',
		vnp_CreateDate: createDate,
		vnp_IpAddr: input.ipAddr,
		vnp_OrderInfo: input.orderInfo,
	};

	// Thứ tự nối chuỗi PHẢI đúng như dưới đây — không tự ý sắp xếp lại.
	const signData = [
		body.vnp_RequestId,
		body.vnp_Version,
		body.vnp_Command,
		body.vnp_TmnCode,
		body.vnp_TransactionType,
		body.vnp_TxnRef,
		body.vnp_Amount,
		body.vnp_TransactionNo,
		body.vnp_TransactionDate,
		body.vnp_CreateBy,
		body.vnp_CreateDate,
		body.vnp_IpAddr,
		body.vnp_OrderInfo,
	].join('|');

	const secureHash = await hmacSha512Hex(input.hashSecret, signData);

	const response = await fetch(VNPAY_REFUND_URL, {
		method: 'POST',
		headers: {
			'Content-Type': 'application/json',
			'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36',
		},
		body: JSON.stringify({ ...body, vnp_SecureHash: secureHash }),
	});

	if (!response.ok) {
		const text = await response.text();
		return { success: false, responseCode: 'http_error', message: `VNPay HTTP ${response.status}: ${text.slice(0, 300)}` };
	}

	const data = (await response.json()) as Record<string, string>;
	const isSuccess = data.vnp_ResponseCode === '00' && data.vnp_TransactionStatus === '00';

	return {
		success: isSuccess,
		responseCode: data.vnp_ResponseCode ?? 'unknown',
		message: data.vnp_Message ?? '',
		vnpTransactionNo: data.vnp_TransactionNo,
	};
}
