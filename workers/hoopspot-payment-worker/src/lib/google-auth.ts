/**
 * Lấy OAuth2 access token cho Firebase Admin REST API bằng service account.
 *
 * Cloudflare Workers không chạy được `firebase-admin` (SDK Node.js), nên phải
 * tự ký 1 JWT bằng private key của service account rồi đổi lấy access token
 * qua Google OAuth2 — đúng cơ chế mà `firebase-admin` làm bên dưới, chỉ là
 * viết tay bằng Web Crypto API thay vì dùng thư viện Node.
 */

export interface ServiceAccount {
	project_id: string;
	client_email: string;
	private_key: string;
}

const TOKEN_URL = 'https://oauth2.googleapis.com/token';
const FIRESTORE_SCOPE = 'https://www.googleapis.com/auth/datastore';

function base64UrlEncodeBytes(bytes: ArrayBuffer | Uint8Array): string {
	const arr = bytes instanceof Uint8Array ? bytes : new Uint8Array(bytes);
	let binary = '';
	for (const b of arr) binary += String.fromCharCode(b);
	return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function base64UrlEncodeString(s: string): string {
	return base64UrlEncodeBytes(new TextEncoder().encode(s));
}

// PEM (PKCS8, "-----BEGIN PRIVATE KEY-----...") -> raw DER bytes mà crypto.subtle cần.
function pemToArrayBuffer(pem: string): ArrayBuffer {
	const base64 = pem.replace('-----BEGIN PRIVATE KEY-----', '').replace('-----END PRIVATE KEY-----', '').replace(/\s+/g, '');
	const binary = atob(base64);
	const bytes = new Uint8Array(binary.length);
	for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
	return bytes.buffer;
}

async function signJwt(serviceAccount: ServiceAccount): Promise<string> {
	const header = { alg: 'RS256', typ: 'JWT' };
	const now = Math.floor(Date.now() / 1000);
	const claimSet = {
		iss: serviceAccount.client_email,
		scope: FIRESTORE_SCOPE,
		aud: TOKEN_URL,
		iat: now,
		exp: now + 3600,
	};

	const unsignedToken = `${base64UrlEncodeString(JSON.stringify(header))}.${base64UrlEncodeString(JSON.stringify(claimSet))}`;

	const cryptoKey = await crypto.subtle.importKey(
		'pkcs8',
		pemToArrayBuffer(serviceAccount.private_key),
		{ name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
		false,
		['sign'],
	);
	const signature = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', cryptoKey, new TextEncoder().encode(unsignedToken));

	return `${unsignedToken}.${base64UrlEncodeBytes(signature)}`;
}

export async function getFirestoreAccessToken(serviceAccount: ServiceAccount): Promise<string> {
	const jwt = await signJwt(serviceAccount);

	const response = await fetch(TOKEN_URL, {
		method: 'POST',
		headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
		body: new URLSearchParams({
			grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
			assertion: jwt,
		}),
	});

	if (!response.ok) {
		throw new Error(`Lấy access token thất bại: ${response.status} ${await response.text()}`);
	}

	const data = (await response.json()) as { access_token: string };
	return data.access_token;
}
