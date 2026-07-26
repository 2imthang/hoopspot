# HoopSpot — Kế Hoạch Triển Khai 6 Tuần (1.5 tháng) — Bản Firebase (đã đơn giản hóa)

### Chiến lược: Vibe code là chính, chỉ dừng lại hiểu sâu ở vài điểm thực sự cần

> **Đã đổi hướng**: Bỏ backend tự viết (NestJS/Prisma), chuyển sang Firebase (Auth + Firestore + Storage) + Cloud Functions tối thiểu cho thanh toán. Roadmap này thay thế hoàn toàn bản cũ.

---

## 0. Nguyên tắc xuyên suốt

- **Vibe code (để AI sinh code nhanh, review qua)**: phần lớn công việc — CRUD qua Firestore SDK, UI widget, form, styling
- **Không vibe, phải tự hiểu** (đánh dấu 🔴): chỉ còn 4 điểm thực sự cần — Firestore Transaction chống trùng slot, VNPay IPN, Firestore Security Rules phân quyền, và luồng thanh toán tổng thể. Số lượng 🔴 giảm mạnh so với bản NestJS vì Firebase Auth/Database không cần bạn tự lo cơ chế bên dưới
- Cuối mỗi tuần có mục **"Đọc hiểu lại"** — 1 câu hỏi để tự kiểm tra
- Task đánh số `TASK-XXX`, mỗi task ước lượng 2-6 giờ

---

## Tuần 1: Setup Firebase + Authentication

**Mục tiêu**: App kết nối được Firebase, đăng ký/đăng nhập hoạt động cho cả 2 loại tài khoản.

| Task | Nội dung | Ghi chú |
|---|---|---|
| TASK-001 | Tạo project trên Firebase Console, bật Authentication (Email/Password + Google), bật Firestore, bật Storage | Tự làm theo hướng dẫn, không cần hiểu sâu |
| TASK-002 | Kết nối Flutter với Firebase (FlutterFire CLI, thêm file cấu hình) | Vibe code |
| TASK-003 | Thiết kế cấu trúc document `users` trong Firestore (role, status) | Vibe code — Firestore không cần schema cứng như SQL, chỉ cần thống nhất cấu trúc field |
| TASK-004 | Màn Đăng ký (chọn role User/Owner) dùng Firebase Auth | Vibe code |
| TASK-005 | Màn Đăng nhập (email/password + Google Sign-In) | Vibe code |
| TASK-006 | Chặn truy cập nếu `status` = pending/rejected/locked (check ngay sau khi login) | Vibe code, đọc hiểu 1 lần cách check |
| TASK-007 | Firestore Security Rules cơ bản: user chỉ sửa được document của chính mình | 🔴 Bắt buộc hiểu — đây là "lớp bảo vệ" thay thế cho JWT middleware, khác cách nghĩ SQL nhưng đơn giản hơn |
| TASK-008 | Flutter: màn Splash, Forgot Password | Vibe code |

**Đọc hiểu lại cuối tuần**: Tự giải thích được — "Vì sao Firestore Security Rules lại thay được cho việc tự viết middleware kiểm tra quyền?"

---

## Tuần 2: Sân & Đặt sân (Core Logic)

**Mục tiêu**: CRUD sân hoàn chỉnh, luồng đặt sân + giữ slot hoạt động đúng, không bị đặt trùng.

| Task | Nội dung | Ghi chú |
|---|---|---|
| TASK-009 | Cấu trúc document `courts` (ảnh, giá, tiện ích, vị trí, is_outdoor) | Vibe code |
| TASK-010 | CRUD sân cho Owner qua Firestore SDK trực tiếp (không qua REST API trung gian) | Vibe code |
| TASK-011 | Security Rules: chỉ Owner đúng chủ sân mới sửa/xóa được | 🔴 Bắt buộc hiểu (nối tiếp TASK-007) |
| TASK-012 | Upload ảnh sân lên Firebase Storage | Vibe code |
| TASK-013 | Flutter: Home (danh sách sân), Search & Filter | Vibe code |
| TASK-014 | Cấu trúc document `bookings` (status, expiresAt, courtId, date, timeSlot) | Vibe code |
| TASK-015 | Tạo booking dùng **Firestore Transaction** để chống đặt trùng slot | 🔴 Bắt buộc hiểu sâu nhất tuần này — test bằng cách bấm đặt 2 lần liên tiếp thật nhanh để tự kiểm chứng |
| TASK-016 | Cơ chế giữ slot 10 phút — kiểm tra `expiresAt` mỗi khi query danh sách slot | Vibe code, hiểu ý tưởng 1 lần |
| TASK-017 | Flutter: Court Detail, Google Maps hiển thị vị trí + chỉ đường | Vibe code |
| TASK-018 | Flutter: màn chọn ngày/giờ theo ca | Vibe code |

**Đọc hiểu lại cuối tuần**: Tự trả lời — "Vì sao dùng Transaction mà không phải chỉ kiểm tra-rồi-tạo bình thường?" (câu trả lời: 2 người bấm cùng lúc, nếu không dùng Transaction cả 2 đều đọc thấy "còn trống" trước khi ai kịp ghi, dẫn tới đặt trùng).

---

## Tuần 3: Thanh toán VNPay + Hủy/Hoàn tiền

**Mục tiêu**: Thanh toán thật chạy trên sandbox — đây là phần DUY NHẤT cần "viết backend" (Cloud Function), phần còn lại của app không cần.

| Task | Nội dung | Ghi chú |
|---|---|---|
| TASK-019 | Đăng ký VNPay Sandbox, đọc docs cơ bản (redirect, IPN, refund) | 🔴 Bắt buộc đọc, không vibe được phần hiểu docs |
| TASK-020 | Viết Cloud Function tạo URL thanh toán VNPay | Vibe code theo docs, đây là function nhỏ (~30-50 dòng), không phải cả hệ thống backend |
| TASK-021 | Viết Cloud Function xử lý IPN callback: verify signature, cập nhật Firestore | 🔴 Bắt buộc hiểu — đây là điểm quan trọng nhất trong toàn dự án, nhưng chỉ là 1 function duy nhất, không phải nhiều lớp như NestJS |
| TASK-022 | Xử lý idempotency (IPN gọi lặp) trong Cloud Function | 🔴 Bắt buộc hiểu, gộp chung buổi học với TASK-021 |
| TASK-023 | Flutter: WebView thanh toán, polling trạng thái booking | Vibe code |
| TASK-024 | Màn "Xác nhận điều khoản" — checkbox bắt buộc trước thanh toán | Vibe code |
| TASK-025 | Cloud Function hoàn tiền (rule 6 tiếng) gọi VNPay Refund API | Vibe code, đọc hiểu logic 1 lần |
| TASK-026 | Owner đánh dấu "hủy do mưa" → trigger Cloud Function hoàn tiền | Vibe code |
| TASK-027 | Flutter: Booking History, hủy lịch, xem trạng thái thanh toán | Vibe code |

**Đọc hiểu lại cuối tuần**: Tự trả lời — "Vì sao không tin kết quả redirect từ client mà phải chờ IPN?" Đây gần như chắc chắn sẽ bị hỏi nếu CV ghi thanh toán VNPay.

---

## Tuần 4: Yêu thích, Đánh giá, Owner Dashboard, Admin

**Mục tiêu**: Hoàn thiện các tính năng còn lại.

| Task | Nội dung | Ghi chú |
|---|---|---|
| TASK-028 | Flutter: Yêu thích (toggle qua Firestore, optimistic update) | Vibe code |
| TASK-029 | Flutter: Đánh giá (chỉ cho booking đã confirmed & qua giờ chơi) | Vibe code |
| TASK-030 | Local Notification nhắc lịch trước giờ chơi | Vibe code |
| TASK-031 | Flutter: My Courts, Court Schedule Config (Owner) | Vibe code |
| TASK-032 | Flutter: Owner Bookings — xem danh sách đặt tại sân mình | Vibe code |
| TASK-033 | Flutter: Admin duyệt/từ chối Owner (bắt buộc lý do khi từ chối) | Vibe code |
| TASK-034 | Flutter: Admin khóa/mở User, ẩn/hiện sân | Vibe code |
| TASK-035 | Flutter: Admin xem danh sách giao dịch (đọc Firestore) | Vibe code |
| TASK-036 | Empty state, Error state, Loading skeleton cho toàn bộ màn hình | Vibe code |

**Đọc hiểu lại cuối tuần**: Không có phần 🔴 mới — ôn lại 3 tuần trước, đặc biệt Transaction (TASK-015) và VNPay IPN (TASK-021/022).

---

## Tuần 5: Testing, Polish UI, Coding Standard

**Mục tiêu**: Ứng dụng ổn định, code sạch, sẵn sàng demo.

| Task | Nội dung | Ghi chú |
|---|---|---|
| TASK-037 | Viết 4-6 Unit Test cho logic quan trọng (transaction, refund calculation) | Vibe code, review kỹ test case |
| TASK-038 | Viết 3-5 Widget Test cho Flutter (form validation, booking flow) | Vibe code |
| TASK-039 | Rà coding convention: không hard-code string/color/URL | Vibe code (AI tự review + refactor) |
| TASK-040 | Dark Mode, Responsive check | Vibe code |
| TASK-041 | Error handling toàn cục: network error, retry | Vibe code |
| TASK-042 | Deploy Cloud Functions lên Firebase (`firebase deploy`), test end-to-end | Tự làm, đơn giản hơn nhiều so với deploy NestJS server — chỉ 1 lệnh |

**Đọc hiểu lại cuối tuần**: Chạy full flow trên bản thật (không phải giả lập) từ đăng ký → đặt sân → thanh toán → hủy → hoàn tiền, ghi lại lỗi phát sinh và tự sửa.

---

## Tuần 6: README, Demo Video, Ôn phỏng vấn

**Mục tiêu**: Đóng gói portfolio, sẵn sàng trả lời phỏng vấn.

| Task | Nội dung | Ghi chú |
|---|---|---|
| TASK-043 | Viết README.md: giới thiệu, tech stack, hướng dẫn cài đặt, ảnh chụp màn hình | Vibe code phần viết |
| TASK-044 | Quay video demo ngắn (2-3 phút) toàn bộ luồng chính | Tự làm |
| TASK-045 | Chuẩn bị câu trả lời cho câu hỏi phỏng vấn dự kiến (mục 2 bên dưới) | 🔴 Bắt buộc tự chuẩn bị |
| TASK-046 | Buffer — dự phòng cho task trễ hoặc bug phát sinh | — |

---

## 2. Câu hỏi phỏng vấn dự kiến — chuẩn bị trước

1. "Bạn chống đặt trùng slot sân như thế nào?" → Firestore Transaction, giải thích ngắn gọn cơ chế đọc-kiểm tra-ghi atomic
2. "Vì sao chọn Firebase thay vì tự viết backend?" → trả lời thật: ưu tiên tốc độ phát triển và độ ổn định cho MVP, tập trung thời gian vào chất lượng UI/UX và business logic ở tầng ứng dụng, thay vì dành phần lớn thời gian cho hạ tầng backend — đây là quyết định kỹ thuật có cân nhắc đánh đổi, không phải né tránh
3. "Thanh toán online bạn xác nhận kết quả thế nào, có tin vào redirect từ client không?" → nhấn mạnh Cloud Function xử lý IPN + verify signature
4. "Firestore Security Rules hoạt động thế nào, khác gì với việc tự viết authorization?" → giải thích ngắn gọn qua ví dụ ownership check
5. "Clean Architecture bạn áp dụng thế nào dù dùng Firebase?" → chỉ ra vẫn tách Data/Domain/Presentation, lớp Data gọi Firestore SDK thay vì REST API, nhưng domain/presentation không đổi
6. "Nếu có thêm thời gian, bạn sẽ làm gì tiếp theo?" → có thể nhắc: tự viết 1 backend REST API riêng để so sánh, hoặc thêm Subscription (đã cân nhắc, quyết định bỏ ở bản đầu để ưu tiên chất lượng MVP)

---

## 3. Rủi ro cần theo dõi trong quá trình làm

| Rủi ro | Cách phòng tránh |
|---|---|
| VNPay Sandbox docs khó hiểu | Làm SỚM (tuần 3), có buffer tuần 6 |
| Firestore Security Rules viết sai, dữ liệu bị lộ/sửa nhầm | Test kỹ bằng Firebase Emulator trước khi tin tưởng hoàn toàn |
| Cloud Function lỗi khi deploy (thường do thiếu quyền/config) | Deploy thử sớm ở cuối tuần 3, không để dồn tuần 5 |
| Hết 6 tuần chưa xong hết | Tuần 4 (Favorites, Review, Notification) là nhóm ưu tiên thấp nhất, có thể cắt nếu trễ, không ảnh hưởng phần lõi (Auth, Booking, Payment) |
