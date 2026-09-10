/**
 * Client REST tối giản cho Firestore — chỉ đủ dùng cho worker này (get 1 doc,
 * commit nhiều write cùng lúc). Không phải SDK đầy đủ, cố tình giữ nhỏ.
 *
 * Firestore REST API bọc mỗi giá trị field trong 1 "Value" object mô tả kiểu
 * dữ liệu (vd `{stringValue: "abc"}`, `{integerValue: "123"}`) thay vì JSON
 * thường — encode/decodeFields ở dưới lo phần chuyển đổi qua lại đó.
 */

const FIRESTORE_BASE = 'https://firestore.googleapis.com/v1';

type FirestoreValue =
	| { stringValue: string }
	| { integerValue: string }
	| { booleanValue: boolean }
	| { timestampValue: string }
	| { arrayValue: { values: FirestoreValue[] } }
	| { nullValue: null };

export function docName(projectId: string, path: string): string {
	return `projects/${projectId}/databases/(default)/documents/${path}`;
}

function encodeValue(value: unknown): FirestoreValue {
	if (value === null || value === undefined) return { nullValue: null };
	if (typeof value === 'string') return { stringValue: value };
	if (typeof value === 'number') return { integerValue: String(Math.trunc(value)) };
	if (typeof value === 'boolean') return { booleanValue: value };
	if (value instanceof Date) return { timestampValue: value.toISOString() };
	if (Array.isArray(value)) return { arrayValue: { values: value.map(encodeValue) } };
	throw new Error(`Không hỗ trợ encode kiểu dữ liệu: ${typeof value}`);
}

export function encodeFields(obj: Record<string, unknown>): Record<string, FirestoreValue> {
	const fields: Record<string, FirestoreValue> = {};
	for (const [key, value] of Object.entries(obj)) {
		fields[key] = encodeValue(value);
	}
	return fields;
}

function decodeValue(value: Record<string, unknown>): unknown {
	if ('stringValue' in value) return value.stringValue;
	if ('integerValue' in value) return Number(value.integerValue);
	if ('doubleValue' in value) return value.doubleValue;
	if ('booleanValue' in value) return value.booleanValue;
	if ('timestampValue' in value) return value.timestampValue;
	if ('arrayValue' in value) {
		const arr = value.arrayValue as { values?: Record<string, unknown>[] };
		return (arr.values ?? []).map(decodeValue);
	}
	if ('nullValue' in value) return null;
	return undefined;
}

function decodeFields(fields: Record<string, Record<string, unknown>> | undefined): Record<string, unknown> {
	if (!fields) return {};
	const result: Record<string, unknown> = {};
	for (const [key, value] of Object.entries(fields)) {
		result[key] = decodeValue(value);
	}
	return result;
}

export async function getDocument(projectId: string, accessToken: string, path: string): Promise<Record<string, unknown> | null> {
	const res = await fetch(`${FIRESTORE_BASE}/${docName(projectId, path)}`, {
		headers: { Authorization: `Bearer ${accessToken}` },
	});
	if (res.status === 404) return null;
	if (!res.ok) throw new Error(`Firestore get thất bại: ${res.status} ${await res.text()}`);

	const doc = (await res.json()) as { fields?: Record<string, Record<string, unknown>> };
	return decodeFields(doc.fields);
}

interface FirestoreWrite {
	update: { name: string; fields: Record<string, FirestoreValue> };
	updateMask?: { fieldPaths: string[] };
}

export function buildWrite(projectId: string, path: string, data: Record<string, unknown>, onlyFields?: string[]): FirestoreWrite {
	const write: FirestoreWrite = {
		update: { name: docName(projectId, path), fields: encodeFields(data) },
	};
	if (onlyFields) write.updateMask = { fieldPaths: onlyFields };
	return write;
}

export async function commitWrites(projectId: string, accessToken: string, writes: FirestoreWrite[]): Promise<void> {
	const res = await fetch(`${FIRESTORE_BASE}/projects/${projectId}/databases/(default)/documents:commit`, {
		method: 'POST',
		headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
		body: JSON.stringify({ writes }),
	});
	if (!res.ok) throw new Error(`Firestore commit thất bại: ${res.status} ${await res.text()}`);
}
