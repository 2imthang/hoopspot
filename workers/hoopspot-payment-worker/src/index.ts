/**
 * HoopSpot payment worker.
 *
 * TASK-020: POST /create-payment-url — builds a signed VNPay Sandbox
 * payment URL. The Flutter app opens this URL in a WebView (TASK-023).
 *
 * vnp_TmnCode/vnp_HashSecret come from `.dev.vars` locally, and from
 * `wrangler secret put` in production — never committed to git.
 */

interface Env {
	VNP_TMN_CODE: string;
	VNP_HASH_SECRET: string;
}

const VNP_VERSION = '2.1.0';
const VNP_COMMAND = 'pay';
const VNP_CURR_CODE = 'VND';
const VNP_LOCALE = 'vn';
const VNP_ORDER_TYPE = 'other';
const VNPAY_PAYMENT_URL = 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';

// Matches the 10-minute slot hold from TASK-015 (`bookings.expiresAt`) —
// the VNPay payment window shouldn't outlive the held slot.
const PAYMENT_EXPIRE_MINUTES = 10;

interface CreatePaymentUrlBody {
	amount: number;
	orderInfo: string;
	txnRef: string;
	returnUrl: string;
}

function isValidBody(body: unknown): body is CreatePaymentUrlBody {
	if (typeof body !== 'object' || body === null) return false;
	const b = body as Record<string, unknown>;
	return (
		typeof b.amount === 'number' &&
		b.amount > 0 &&
		typeof b.orderInfo === 'string' &&
		b.orderInfo.length > 0 &&
		typeof b.txnRef === 'string' &&
		b.txnRef.length > 0 &&
		typeof b.returnUrl === 'string' &&
		b.returnUrl.length > 0
	);
}

// yyyyMMddHHmmss theo giờ VN (GMT+7) — định dạng bắt buộc của VNPay.
function formatVnpDate(date: Date): string {
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

async function hmacSha512Hex(key: string, data: string): Promise<string> {
	const enc = new TextEncoder();
	const cryptoKey = await crypto.subtle.importKey('raw', enc.encode(key), { name: 'HMAC', hash: 'SHA-512' }, false, ['sign']);
	const signature = await crypto.subtle.sign('HMAC', cryptoKey, enc.encode(data));
	return Array.from(new Uint8Array(signature))
		.map((b) => b.toString(16).padStart(2, '0'))
		.join('');
}

// VNPay yêu cầu: sắp xếp tham số theo alphabet, rồi mới ký HMAC-SHA512 lên
// đúng chuỗi query-string đã encode đó (không phải encode sau khi ký).
async function buildSignedPaymentUrl(body: CreatePaymentUrlBody, env: Env, ipAddr: string): Promise<string> {
	const now = new Date();
	const expireDate = new Date(now.getTime() + PAYMENT_EXPIRE_MINUTES * 60 * 1000);

	const params: Record<string, string> = {
		vnp_Version: VNP_VERSION,
		vnp_Command: VNP_COMMAND,
		vnp_TmnCode: env.VNP_TMN_CODE,
		vnp_Amount: String(Math.round(body.amount * 100)),
		vnp_CurrCode: VNP_CURR_CODE,
		vnp_TxnRef: body.txnRef,
		vnp_OrderInfo: body.orderInfo,
		vnp_OrderType: VNP_ORDER_TYPE,
		vnp_Locale: VNP_LOCALE,
		vnp_ReturnUrl: body.returnUrl,
		vnp_IpAddr: ipAddr,
		vnp_CreateDate: formatVnpDate(now),
		vnp_ExpireDate: formatVnpDate(expireDate),
	};

	const sortedKeys = Object.keys(params).sort();
	const searchParams = new URLSearchParams();
	for (const key of sortedKeys) {
		searchParams.append(key, params[key]);
	}

	const signData = searchParams.toString();
	const secureHash = await hmacSha512Hex(env.VNP_HASH_SECRET, signData);

	return `${VNPAY_PAYMENT_URL}?${signData}&vnp_SecureHash=${secureHash}`;
}

export default {
	async fetch(request, env): Promise<Response> {
		const url = new URL(request.url);

		if (request.method !== 'POST' || url.pathname !== '/create-payment-url') {
			return new Response('Not found', { status: 404 });
		}

		let body: unknown;
		try {
			body = await request.json();
		} catch {
			return Response.json({ error: 'Body không phải JSON hợp lệ' }, { status: 400 });
		}

		if (!isValidBody(body)) {
			return Response.json({ error: 'Thiếu hoặc sai kiểu amount/orderInfo/txnRef/returnUrl' }, { status: 400 });
		}

		const ipAddr = request.headers.get('CF-Connecting-IP') ?? '127.0.0.1';
		const paymentUrl = await buildSignedPaymentUrl(body, env, ipAddr);

		return Response.json({ paymentUrl });
	},
} satisfies ExportedHandler<Env>;
