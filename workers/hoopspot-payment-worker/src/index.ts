/**
 * HoopSpot payment worker.
 *
 * - POST /create-payment-url — TASK-020: sinh URL thanh toán VNPay đã ký,
 *   tạo kèm `payments/{txnRef}` để IPN có chỗ tra cứu ngược lại.
 * - GET  /vnpay-ipn — TASK-021/022: VNPay tự gọi vào đây (server-to-server)
 *   để báo kết quả thanh toán thật. Đây là nguồn DUY NHẤT được tin để xác
 *   nhận `booking.status = confirmed` — không tin kết quả redirect từ app.
 *
 * Secrets (vnp_TmnCode/vnp_HashSecret, Firebase service account) đến từ
 * `.dev.vars` khi chạy local, và từ `wrangler secret put` khi deploy thật —
 * không commit lên git.
 */

interface Env {
	VNP_TMN_CODE: string;
	VNP_HASH_SECRET: string;
	FIREBASE_SERVICE_ACCOUNT_JSON: string;
}

import { handleCreatePaymentUrl } from './handlers/create-payment-url';
import { handleVnpayIpn } from './handlers/vnpay-ipn';

export default {
	async fetch(request, env): Promise<Response> {
		const url = new URL(request.url);

		if (request.method === 'POST' && url.pathname === '/create-payment-url') {
			return handleCreatePaymentUrl(request, env);
		}

		if (request.method === 'GET' && url.pathname === '/vnpay-ipn') {
			return handleVnpayIpn(url, env);
		}

		return new Response('Not found', { status: 404 });
	},
} satisfies ExportedHandler<Env>;
