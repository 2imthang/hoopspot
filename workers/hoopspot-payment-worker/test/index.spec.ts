import { env, createExecutionContext, waitOnExecutionContext } from 'cloudflare:test';
import { describe, it, expect } from 'vitest';
import worker from '../src/index';

const IncomingRequest = Request<unknown, IncomingRequestCfProperties>;

// Các test ở đây chỉ kiểm tra phần logic thuần (validation, verify chữ ký)
// không cần gọi Firestore/Google thật. Phần xác minh "có thật sự tạo được
// payment + URL hợp lệ, IPN có thật sự cập nhật đúng booking không" được
// verify trực tiếp qua `wrangler dev` + curl với dữ liệu Firestore thật (xem
// ghi chú trong hoopspot_progress_tracker.md) — đáng tin hơn nhiều so với
// giả lập, vì đây đụng tới 2 API bên thứ 3 thật (VNPay, Google OAuth2).

describe('unknown routes', () => {
	it('404s on anything other than the known routes', async () => {
		const request = new IncomingRequest('http://example.com/');
		const ctx = createExecutionContext();
		const response = await worker.fetch(request, env, ctx);
		await waitOnExecutionContext(ctx);
		expect(response.status).toBe(404);
	});
});

describe('POST /create-payment-url', () => {
	it('400s when required fields are missing', async () => {
		const request = new IncomingRequest('http://example.com/create-payment-url', {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ userId: 'u1' }),
		});
		const ctx = createExecutionContext();
		const response = await worker.fetch(request, env, ctx);
		await waitOnExecutionContext(ctx);
		expect(response.status).toBe(400);
	});
});

describe('GET /vnpay-ipn', () => {
	it('rejects a call with a wrong/missing vnp_SecureHash before touching Firestore', async () => {
		const request = new IncomingRequest(
			'http://example.com/vnpay-ipn?vnp_TxnRef=FAKE&vnp_Amount=20000000&vnp_ResponseCode=00&vnp_TransactionStatus=00&vnp_SecureHash=deadbeef',
		);
		const ctx = createExecutionContext();
		const response = await worker.fetch(request, env, ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(200);
		const body = (await response.json()) as { RspCode: string; Message: string };
		expect(body.RspCode).toBe('97');
		expect(body.Message).toBe('Fail checksum');
	});
});

describe('POST /refund', () => {
	it('400s when required fields are missing', async () => {
		const request = new IncomingRequest('http://example.com/refund', {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ userId: 'u1' }),
		});
		const ctx = createExecutionContext();
		const response = await worker.fetch(request, env, ctx);
		await waitOnExecutionContext(ctx);
		expect(response.status).toBe(400);
	});

	it('404s when the booking does not exist', async () => {
		const request = new IncomingRequest('http://example.com/refund', {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ userId: 'u1', bookingId: 'does-not-exist-' + Date.now() }),
		});
		const ctx = createExecutionContext();
		const response = await worker.fetch(request, env, ctx);
		await waitOnExecutionContext(ctx);
		expect(response.status).toBe(404);
	});
});

describe('POST /rain-cancel', () => {
	it('400s when required fields are missing', async () => {
		const request = new IncomingRequest('http://example.com/rain-cancel', {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ ownerId: 'o1' }),
		});
		const ctx = createExecutionContext();
		const response = await worker.fetch(request, env, ctx);
		await waitOnExecutionContext(ctx);
		expect(response.status).toBe(400);
	});

	it('404s when the booking does not exist', async () => {
		const request = new IncomingRequest('http://example.com/rain-cancel', {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ ownerId: 'o1', bookingId: 'does-not-exist-' + Date.now() }),
		});
		const ctx = createExecutionContext();
		const response = await worker.fetch(request, env, ctx);
		await waitOnExecutionContext(ctx);
		expect(response.status).toBe(404);
	});
});
