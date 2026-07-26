# CLAUDE.md — HoopSpot Project Context

Đây là file ngữ cảnh chính cho Claude Code. Đọc file này trước khi thực hiện bất kỳ task nào. Các file chi tiết đầy đủ nằm trong `/docs`: `design-brief.md`, `functional-spec.md`, `roadmap.md` — tham chiếu khi cần chi tiết sâu hơn phần tóm tắt dưới đây.

## Tổng quan dự án

- **Tên**: HoopSpot — App đặt sân bóng rổ, Flutter (Android)
- **Mục tiêu**: Portfolio xin thực tập Flutter, hoàn thành trong 6 tuần
- **Chiến lược code**: dùng Claude Code sinh code nhanh (vibe code) — ưu tiên đơn giản, dễ hiểu, tránh khái niệm phức tạp không cần thiết. Người dùng KHÔNG rành backend sâu — giải thích ngắn gọn, dễ hiểu khi cần, không dùng thuật ngữ nặng nếu không bắt buộc.

## ⚠️ THAY ĐỔI KIẾN TRÚC QUAN TRỌNG (đã pivot từ NestJS/Prisma sang Firebase)

Dự án BAN ĐẦU dự định tự viết backend bằng NestJS + Prisma + PostgreSQL (Neon) — đã có 1 project NestJS được khởi tạo trong thư mục `/backend`. **QUYẾT ĐỊNH MỚI: bỏ hướng này, chuyển sang Firebase để đơn giản hóa.**

**Việc cần làm ngay**: Xóa thư mục `/backend` (project NestJS cũ) — không dùng nữa. Không cần Neon database nữa (có thể xóa project trên neon.tech sau, không bắt buộc ngay).

## ⚠️ THAY ĐỔI TIẾP THEO: bỏ Firebase Storage + Cloud Functions (tránh bắt buộc gói Blaze/thẻ tín dụng)

Firebase Storage và Cloud Functions từ cuối 2024 **bắt buộc nâng cấp gói Blaze (phải nhập thẻ tín dụng)**, dù nằm trong free quota vẫn phải nhập thẻ. Người dùng muốn dự án **không cần thẻ, không rủi ro phí ở bất kỳ đâu**. **QUYẾT ĐỊNH: thay 2 phần đó bằng dịch vụ free-tier không cần thẻ**, giữ nguyên Firebase Auth + Firestore (gói Spark, free, không cần thẻ).

| Phần cũ (cần Blaze) | Thay bằng |
|---|---|
| Firebase Storage | **Cloudinary** (free tier 25GB storage/bandwidth, không cần thẻ) |
| Firebase Cloud Functions (VNPay IPN) | **Cloudflare Workers** (free tier rộng rãi, không cần thẻ, không bị sleep như 1 số free host khác) |

## Tech Stack (đã chốt — không đổi, không đề xuất thay thế)

| Layer | Công nghệ |
|---|---|
| Mobile | Flutter + Dart, Bloc (flutter_bloc) — KHÔNG dùng Riverpod |
| Architecture | Clean Architecture, Feature-first folder structure (giữ nguyên cấu trúc đã tạo ở TASK-002, chỉ đổi lớp Data để gọi Firebase SDK thay vì Dio → REST API tự viết) |
| Auth | **Firebase Authentication** (email/password + Google Sign-In) — KHÔNG tự viết JWT |
| Database | **Cloud Firestore** (NoSQL, không cần schema/migration — định nghĩa cấu trúc document trong functional-spec) |
| File Storage | **Cloudinary** (ảnh sân, avatar) — KHÔNG dùng Firebase Storage (tránh bắt buộc gói Blaze) |
| Payment Backend | **Cloudflare Workers** (1-2 function nhỏ: tạo URL thanh toán VNPay, xử lý IPN callback, gọi Refund API) — KHÔNG dùng Firebase Cloud Functions (tránh bắt buộc gói Blaze), KHÔNG dựng backend riêng |
| Payment Gateway | VNPay Sandbox (vẫn tích hợp thật qua Cloudflare Worker, không mock) |
| Notification | flutter_local_notifications — KHÔNG dùng FCM/Push |
| Maps | Google Maps Flutter Plugin |
| Networking | Dio — dùng để gọi Cloudinary upload API, Google Maps API, và Cloudflare Worker (VNPay) trực tiếp từ app khi cần, nhưng phần lớn dữ liệu (Users, Courts, Bookings...) đọc/ghi thẳng qua **Firestore SDK**, không qua REST API trung gian tự viết |

**Lý do đổi (Firebase)**: Loại bỏ hoàn toàn nhu cầu tự viết REST API, tự quản lý JWT, tự deploy server, tự lo migration database — những phần này là nguồn gây quá tải kiến thức cho người mới. Firebase lo sẵn Auth + Database; Cloudflare Workers chỉ cần cho đúng 1 việc bắt buộc phải có backend: xác nhận thanh toán VNPay an toàn (không thể làm việc này chỉ từ app di động).

**Lý do đổi (Cloudinary/Cloudflare thay vì Firebase Storage/Functions)**: Toàn bộ project ưu tiên **0đ chi phí, 0 rủi ro phí, không cần nhập thẻ ở bất kỳ đâu** — đây là yêu cầu cứng của người dùng, không phải tối ưu kỹ thuật.

## Mô hình tài khoản & phân quyền

- 3 role tách biệt hoàn toàn: `USER`, `OWNER`, `ADMIN` (không gộp chung 1 tài khoản nhiều role) — lưu trong Firestore collection `users`, field `role`
- Không có Guest — bắt buộc đăng nhập/đăng ký ngay khi mở app
- Đăng ký chọn rõ "Người chơi" hoặc "Chủ sân"
- Tài khoản Owner đăng ký xong ở trạng thái `pending`, phải chờ Admin duyệt (`approved`/`rejected`) mới dùng được. Từ chối bắt buộc nhập lý do. Duyệt miễn phí (MVP).
- User field `status`: `active | pending | rejected | locked`
- Phân quyền dữ liệu dùng **Firestore Security Rules** (không phải middleware tự viết như backend truyền thống) — VD chỉ Owner đúng chủ sân mới sửa được document sân đó
- Ảnh (court, avatar) upload thẳng lên **Cloudinary** từ app (unsigned upload preset hoặc ký chữ ký đơn giản), lưu URL trả về vào field tương ứng trong Firestore document

## Business Logic bắt buộc hiểu đúng (không được đơn giản hóa)

### Đặt sân (Hourly only — KHÔNG có chế độ theo tháng, đã cân nhắc và loại bỏ)
- 1 ca = 2 tiếng cố định, chọn được nhiều ca/ngày, không giới hạn
- Đặt → tạo booking document trạng thái `pending_payment`, giữ slot **10 phút** (field `expiresAt`)
- Chống đặt trùng: dùng **Firestore Transaction** khi tạo booking (đọc + kiểm tra slot trống + ghi trong cùng 1 transaction) — Firestore tự đảm bảo tính atomic, không cần tự lo unique constraint như SQL
- Quá 10 phút chưa thanh toán → tự hủy, nhả slot (có thể dùng Cloud Function chạy theo lịch, hoặc kiểm tra `expiresAt` mỗi lần query — ưu tiên cách đơn giản: kiểm tra khi query)
- Trước khi thanh toán: bắt buộc màn hình xác nhận điều khoản, checkbox tích mới cho qua

### Hủy & hoàn tiền
- Hủy ≥ 6 tiếng trước giờ chơi → hoàn 100% qua VNPay Refund API (gọi qua Cloud Function)
- Hủy < 6 tiếng → không hoàn
- Sân `isOutdoor = true` + mưa → hoàn 100% ngay bất kể thời điểm, do Owner tự đánh dấu (không cần Admin duyệt lại)

### Thanh toán VNPay (phần duy nhất bắt buộc cần backend riêng, giải thích kỹ khi tới)
- Cloudflare Worker 1: tạo URL thanh toán VNPay
- Cloudflare Worker 2 (route riêng, đóng vai trò webhook): nhận IPN callback từ VNPay, verify signature, cập nhật Firestore (dùng Firebase Admin REST API hoặc firebase-admin qua Cloudflare Workers-compatible client) — **không tin kết quả redirect từ client**
- Xử lý idempotency: IPN có thể gọi lặp, check đã xử lý transaction đó chưa trước khi cập nhật lại

## Danh sách tính năng theo role

**User**: Auth, Profile, Home/Search/Filter, Court Detail, Booking (hourly), Terms Confirmation, Payment, Booking History, Favorites, Review, Local Notification

**Owner**: tất cả quyền User + CRUD sân + cấu hình lịch hoạt động + quản lý booking tại sân mình + đánh dấu hủy do mưa

**Admin**: duyệt/từ chối Owner, khóa/mở tài khoản, ẩn/hiện sân, xem giao dịch (chỉ đọc) — không dashboard riêng, dùng chung app Flutter

## Coding Standard

- SOLID, DRY, KISS, Repository Pattern, Dependency Injection
- Không hard-code string/color/URL — quản lý tập trung (constants, theme)
- Naming: Class PascalCase, file snake_case, biến camelCase
- File không quá 300 dòng, hàm không quá 40 dòng (khi hợp lý)
- Git Flow: nhánh feature/, commit convention rõ ràng

## UI

- 23 màn hình đã được thiết kế sẵn trong Claude Design, ảnh lưu tại `docs/screens/` (đặt tên mô tả theo chức năng, đối chiếu với danh sách 23 màn trong `docs/functional-spec.md`)
- Material 3, Dark Mode, Skeleton Loading, Empty/Error State, Pull to Refresh

## Cách làm việc mong muốn

1. Luôn thực hiện theo đúng thứ tự `TASK-XXX` trong `docs/roadmap.md` (đã cập nhật lại theo Firebase — bỏ các task liên quan NestJS/Prisma/Neon cũ), không nhảy cóc
2. Ở các phần cần hiểu sâu (Firestore Transaction chống trùng slot, VNPay IPN, Security Rules phân quyền): giải thích ngắn gọn, dễ hiểu, không dùng thuật ngữ nặng, không giả định người dùng đã biết backend
3. Sau mỗi task, dừng lại để người dùng review trước khi sang task tiếp theo
4. Nếu phát hiện mâu thuẫn với tài liệu trong `/docs`, hỏi lại trước khi tự quyết định
5. Ưu tiên đơn giản — nếu có cách làm đơn giản hơn mà vẫn đúng yêu cầu, chọn cách đơn giản hơn
