import { env, createExecutionContext, waitOnExecutionContext, SELF } from 'cloudflare:test';
import { describe, it, expect } from 'vitest';
import worker from '../src/index';

const IncomingRequest = Request<unknown, IncomingRequestCfProperties>;

function postCreatePaymentUrl(body: unknown) {
	return new IncomingRequest('http://example.com/create-payment-url', {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify(body),
	});
}

describe('unknown routes', () => {
	it('404s on anything other than POST /create-payment-url', async () => {
		const request = new IncomingRequest('http://example.com/');
		const ctx = createExecutionContext();
		const response = await worker.fetch(request, env, ctx);
		await waitOnExecutionContext(ctx);
		expect(response.status).toBe(404);
	});
});

describe('POST /create-payment-url', () => {
	it('400s when required fields are missing', async () => {
		const request = postCreatePaymentUrl({ amount: 200000 });
		const ctx = createExecutionContext();
		const response = await worker.fetch(request, env, ctx);
		await waitOnExecutionContext(ctx);
		expect(response.status).toBe(400);
	});

	it('returns a signed VNPay sandbox URL for a valid request (unit style)', async () => {
		const request = postCreatePaymentUrl({
			amount: 200000,
			orderInfo: 'Thanh toan booking test',
			txnRef: 'TEST-TXN-001',
			returnUrl: 'https://example.com/vnpay-return',
		});
		const ctx = createExecutionContext();
		const response = await worker.fetch(request, env, ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(200);
		const { paymentUrl } = (await response.json()) as { paymentUrl: string };
		expect(paymentUrl).toMatch(/^https:\/\/sandbox\.vnpayment\.vn\/paymentv2\/vpcpay\.html\?/);
		expect(paymentUrl).toContain('vnp_SecureHash=');
		expect(paymentUrl).toContain('vnp_Amount=20000000');
	});

	it('returns a signed VNPay sandbox URL for a valid request (integration style)', async () => {
		const response = await SELF.fetch('https://example.com/create-payment-url', {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({
				amount: 200000,
				orderInfo: 'Thanh toan booking test',
				txnRef: 'TEST-TXN-002',
				returnUrl: 'https://example.com/vnpay-return',
			}),
		});

		expect(response.status).toBe(200);
		const { paymentUrl } = (await response.json()) as { paymentUrl: string };
		expect(paymentUrl).toContain('vnp_SecureHash=');
	});
});
