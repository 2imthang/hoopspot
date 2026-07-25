# CLAUDE.md — HoopSpot Project Context

Đây là file ngữ cảnh chính cho Claude Code. Đọc file này trước khi thực hiện bất kỳ task nào. Các file chi tiết đầy đủ nằm trong `/docs`: `design-brief.md`, `functional-spec.md`, `roadmap.md` — tham chiếu khi cần chi tiết sâu hơn phần tóm tắt dưới đây.

## Tổng quan dự án

- **Tên**: HoopSpot — App đặt sân bóng rổ, Flutter (Android)
- **Mục tiêu**: Portfolio xin thực tập Flutter, hoàn thành trong 6 tuần
- **Chiến lược code**: dùng Claude Code sinh code nhanh (vibe code) cho phần CRUD/UI thông thường, nhưng ở các phần đánh dấu 🔴 trong roadmap, giải thích rõ logic từng bước để người dùng hiểu sâu (phục vụ phỏng vấn), không chỉ sinh code cho chạy.

## Tech Stack (đã chốt — không đổi, không đề xuất thay thế)

| Layer | Công nghệ |
|---|---|
| Mobile | Flutter + Dart, Bloc (flutter_bloc) — KHÔNG dùng Riverpod |
| Architecture | Clean Architecture, Feature-first folder structure |
| Networking | Dio + Interceptor (tự động đính JWT, tự động refresh token) |
| Backend | NestJS + PostgreSQL + Prisma hoặc TypeORM |
| Auth | Tự viết JWT (access + refresh) — KHÔNG dùng Firebase Auth |
| File Storage | Firebase Storage (chỉ dùng cho ảnh, không dùng cho gì khác) |
| Notification | flutter_local_notifications — KHÔNG dùng FCM/Push |
| Maps | Google Maps Flutter Plugin |
| Payment | VNPay Sandbox (tích hợp thật: redirect + IPN callback + verify signature + refund API) |
| Backend Hosting | Render hoặc Railway (free tier) |

## Mô hình tài khoản & phân quyền

- 3 role tách biệt hoàn toàn: `USER`, `OWNER`, `ADMIN` (không gộp chung 1 tài khoản nhiều role)
- Không có Guest — bắt buộc đăng nhập/đăng ký ngay khi mở app
- Đăng ký chọn rõ "Người chơi" hoặc "Chủ sân"
- Tài khoản Owner đăng ký xong ở trạng thái `pending`, phải chờ Admin duyệt (`approved`/`rejected`) mới dùng được. Từ chối bắt buộc nhập lý do. Duyệt miễn phí (MVP).
- User field `status`: `active | pending | rejected | locked`

## Business Logic bắt buộc hiểu đúng (không được đơn giản hóa)

### Đặt sân (Hourly only — KHÔNG có chế độ theo tháng, đã cân nhắc và loại bỏ)
- 1 ca = 2 tiếng cố định, chọn được nhiều ca/ngày, không giới hạn
- Đặt → tạo booking `pending_payment`, giữ slot **10 phút** (`expires_at`)
- Chống race condition: **DB transaction + unique constraint** trên (court_id, date, time_slot) — KHÔNG được chỉ check-rồi-insert (không atomic)
- Quá 10 phút chưa thanh toán → tự hủy, nhả slot
- Trước khi thanh toán: bắt buộc màn hình xác nhận điều khoản, checkbox tích mới cho qua

### Hủy & hoàn tiền
- Hủy ≥ 6 tiếng trước giờ chơi → hoàn 100% qua VNPay Refund API
- Hủy < 6 tiếng → không hoàn
- Sân `is_outdoor = true` + mưa → hoàn 100% ngay bất kể thời điểm, do Owner tự đánh dấu (không cần Admin duyệt lại)

### Thanh toán VNPay
- **Không tin kết quả redirect từ client** — chỉ xác nhận trạng thái thật qua **IPN callback** (server-to-server), verify signature bằng secret key
- Xử lý idempotency: IPN có thể gọi lặp, phải check transaction_id đã xử lý chưa trước khi cập nhật lại

## Danh sách tính năng theo role

**User**: Auth, Profile, Home/Search/Filter, Court Detail, Booking (hourly), Terms Confirmation, Payment, Booking History, Favorites, Review, Local Notification

**Owner**: tất cả quyền User + CRUD sân + cấu hình lịch hoạt động + quản lý booking tại sân mình + đánh dấu hủy do mưa

**Admin**: duyệt/từ chối Owner, khóa/mở tài khoản, ẩn/hiện sân, xem giao dịch (chỉ đọc) — không dashboard riêng, dùng chung app Flutter

## Coding Standard

- SOLID, DRY, KISS, Repository Pattern, Dependency Injection
- Không hard-code string/color/API URL — quản lý tập trung (constants, theme)
- Naming: Class PascalCase, file snake_case, biến camelCase
- File không quá 300 dòng, hàm không quá 40 dòng (khi hợp lý)
- Git Flow: nhánh feature/, commit convention rõ ràng

## UI

- 23 màn hình đã được thiết kế sẵn trong Claude Design (đã handoff qua `/design-sync` hoặc export) — ưu tiên dùng đúng component/token đã thiết kế, không tự bịa lại style
- Material 3, Dark Mode, Skeleton Loading, Empty/Error State, Pull to Refresh

## Cách làm việc mong muốn

1. Luôn thực hiện theo đúng thứ tự `TASK-XXX` trong `docs/roadmap.md`, không nhảy cóc
2. Task đánh dấu 🔴 trong roadmap (JWT, race condition, VNPay IPN, ownership check): giải thích ngắn gọn logic đang làm và vì sao làm vậy, không chỉ trả code
3. Sau mỗi task, dừng lại để người dùng review trước khi sang task tiếp theo
4. Nếu phát hiện mâu thuẫn với tài liệu trong `/docs`, hỏi lại trước khi tự quyết định
