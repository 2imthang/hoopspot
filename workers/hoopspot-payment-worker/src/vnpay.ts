/**
 * Ký và xác thực chữ ký VNPay (HMAC-SHA512). Thuật toán đối chiếu từ mã
 * nguồn thật của thư viện vnpay (Node.js) vì docs chính thức của VNPay
 * không mô tả đủ chi tiết phần encode — xem giải thích đầy đủ ở TASK-020.
 */

export const VNP_VERSION = '2.1.0';
export const VNP_COMMAND = 'pay';
export const VNP_CURR_CODE = 'VND';
export const VNP_LOCALE = 'vn';
export const VNP_ORDER_TYPE = 'other';
export const VNPAY_PAYMENT_URL = 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';

// Khớp với 10 phút giữ slot ở TASK-015 (`bookings.expiresAt`).
export const PAYMENT_EXPIRE_MINUTES = 10;

// yyyyMMddHHmmss theo giờ VN (GMT+7) — định dạng bắt buộc của VNPay.
export function formatVnpDate(date: Date): string {
	const gmt7 = new Date(date.getTime() + 7 * 60 * 60 * 1000);
	const pad = (n: number) => n.toString().padStart(2, '0');
	return (
		gmt7.getUTCFullYear().toString() +
		pad(gmt7.getUTCMonth() + 1) +
		pad(gmt7.getUTCDate()) +
		pad(gmt7.getUTCHours()) +
		pad(gmt7.getUTCMinutes()) +
		pad(gmt7.getUTCSeconds())
	);
}

export async function hmacSha512Hex(key: string, data: string): Promise<string> {
	const enc = new TextEncoder();
	const cryptoKey = await crypto.subtle.importKey('raw', enc.encode(key), { name: 'HMAC', hash: 'SHA-512' }, false, ['sign']);
	const signature = await crypto.subtle.sign('HMAC', cryptoKey, enc.encode(data));
	return Array.from(new Uint8Array(signature))
		.map((b) => b.toString(16).padStart(2, '0'))
		.join('');
}

// Sắp xếp key theo alphabet rồi encode kiểu form (dấu cách -> '+'), đúng
// chuẩn VNPay yêu cầu. Trả về cả chuỗi đã ký lẫn map các key đã sort, để chỗ
// gọi tái sử dụng (build URL) hoặc chỉ lấy signData (verify IPN).
function sortedFormEncode(params: Record<string, string>): string {
	const sortedKeys = Object.keys(params).sort();
	const searchParams = new URLSearchParams();
	for (const key of sortedKeys) searchParams.append(key, params[key]);
	return searchParams.toString();
}

export interface BuildPaymentUrlInput {
	amount: number;
	orderInfo: string;
	txnRef: string;
	returnUrl: string;
	tmnCode: string;
	hashSecret: string;
	ipAddr: string;
}

export async function buildSignedPaymentUrl(input: BuildPaymentUrlInput): Promise<string> {
	const now = new Date();
	const expireDate = new Date(now.getTime() + PAYMENT_EXPIRE_MINUTES * 60 * 1000);

	const params: Record<string, string> = {
		vnp_Version: VNP_VERSION,
		vnp_Command: VNP_COMMAND,
		vnp_TmnCode: input.tmnCode,
		vnp_Amount: String(Math.round(input.amount * 100)),
		vnp_CurrCode: VNP_CURR_CODE,
		vnp_TxnRef: input.txnRef,
		vnp_OrderInfo: input.orderInfo,
		vnp_OrderType: VNP_ORDER_TYPE,
		vnp_Locale: VNP_LOCALE,
		vnp_ReturnUrl: input.returnUrl,
		vnp_IpAddr: input.ipAddr,
		vnp_CreateDate: formatVnpDate(now),
		vnp_ExpireDate: formatVnpDate(expireDate),
	};

	const signData = sortedFormEncode(params);
	const secureHash = await hmacSha512Hex(input.hashSecret, signData);

	return `${VNPAY_PAYMENT_URL}?${signData}&vnp_SecureHash=${secureHash}`;
}

// Dùng cho cả return URL (TASK-023) lẫn IPN (TASK-021): loại vnp_SecureHash
// (và vnp_SecureHashType nếu có) ra khỏi tập tham số trước khi tính lại chữ
// ký trên phần còn lại, rồi so với chữ ký VNPay gửi kèm.
export async function verifyVnpaySignature(params: Record<string, string>, hashSecret: string): Promise<boolean> {
	const receivedHash = params['vnp_SecureHash'];
	if (!receivedHash) return false;

	const { vnp_SecureHash: _hash, vnp_SecureHashType: _hashType, ...toVerify } = params;
	const signData = sortedFormEncode(toVerify);
	const expectedHash = await hmacSha512Hex(hashSecret, signData);

	return expectedHash.toLowerCase() === receivedHash.toLowerCase();
}
