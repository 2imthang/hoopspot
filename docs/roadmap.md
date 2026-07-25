# HoopSpot — Kế Hoạch Triển Khai 6 Tuần (1.5 tháng)

### Chiến lược: Vibe code để tăng tốc, nhưng có "điểm dừng bắt buộc" để hiểu sâu phục vụ phỏng vấn

---

## 0. Nguyên tắc xuyên suốt

- **Vibe code (để AI sinh code nhanh, review qua)**: CRUD cơ bản, UI widget, form, styling, boilerplate NestJS module
- **Không vibe, phải tự hiểu từng dòng** (đánh dấu 🔴 trong task): JWT flow, race condition trong Booking, VNPay callback/signature verify, ownership authorization check — đây chính xác là những phần nhà tuyển dụng hay hỏi sâu
- Cuối mỗi tuần có mục **"Đọc hiểu lại"** — dành 1-2 tiếng đọc lại code tuần đó, tự hỏi "nếu bị hỏi vì sao làm thế này thì trả lời sao"
- Task đánh số `TASK-XXX`, mỗi task ước lượng 2-6 giờ như chuẩn đã thống nhất

---

## Tuần 1: Nền tảng — Setup + Authentication

**Mục tiêu**: Chạy được backend + Flutter kết nối nhau, đăng ký/đăng nhập hoạt động đầy đủ cho cả 2 loại tài khoản.

| Task | Nội dung | Ghi chú |
|---|---|---|
| TASK-001 | Khởi tạo NestJS project, cấu hình PostgreSQL + Prisma/TypeORM, kết nối thử | Vibe code |
| TASK-002 | Khởi tạo Flutter project, cấu hình Clean Architecture folder structure (feature-first), cài Bloc, Dio | Vibe code |
| TASK-003 | Thiết kế bảng `User` (role, status: active/pending/rejected/locked) | 🔴 Tự thiết kế, đây là nền cho toàn bộ authorization sau này |
| TASK-004 | API Đăng ký (User + Owner), hash password bcrypt, validation | Vibe code phần CRUD, 🔴 tự hiểu bcrypt + validation pipe |
| TASK-005 | API Đăng nhập, sinh JWT access + refresh token | 🔴 Bắt buộc hiểu — đây là câu hỏi phỏng vấn kinh điển |
| TASK-006 | Middleware/Guard kiểm tra JWT + kiểm tra `status` (chặn pending/locked) | 🔴 Bắt buộc hiểu |
| TASK-007 | Google OAuth Login qua backend (verify id_token, cấp JWT riêng) | Vibe code, đọc hiểu luồng 1 lần |
| TASK-008 | Flutter: màn Splash, Login, Register (chọn role), Forgot Password | Vibe code |
| TASK-009 | Dio Interceptor: tự động đính JWT, tự động refresh khi hết hạn | 🔴 Bắt buộc hiểu |

**Đọc hiểu lại cuối tuần**: Vẽ tay (giấy hoặc note) toàn bộ luồng JWT từ lúc login tới lúc access token hết hạn — nếu vẽ được không cần xem code là đạt.

---

## Tuần 2: Sân & Đặt sân (Core Logic)

**Mục tiêu**: CRUD sân hoàn chỉnh, luồng đặt sân + giữ slot hoạt động đúng, chống được race condition.

| Task | Nội dung | Ghi chú |
|---|---|---|
| TASK-010 | Bảng `Court`, `CourtImage`, `Facility`, `CourtSchedule` (giờ hoạt động) | Vibe code |
| TASK-011 | API CRUD sân cho Owner + check ownership (chỉ sửa/xóa sân của mình) | 🔴 Bắt buộc hiểu authorization check |
| TASK-012 | Upload ảnh lên Firebase Storage từ Flutter | Vibe code |
| TASK-013 | API danh sách sân (pagination) + tìm kiếm + lọc | Vibe code |
| TASK-014 | Bảng `Booking` (status, expires_at, court_id, date, time_slot) | 🔴 Tự thiết kế kỹ, đây là bảng lõi |
| TASK-015 | API tạo booking + **DB transaction + unique constraint chống race condition** | 🔴 Bắt buộc hiểu sâu — test bằng cách bắn 2 request cùng lúc để tự kiểm chứng |
| TASK-016 | Cơ chế giữ slot 10 phút (`expires_at`) + job/logic nhả slot khi hết hạn | 🔴 Bắt buộc hiểu |
| TASK-017 | Flutter: Home, Court Detail, Google Maps hiển thị vị trí + chỉ đường | Vibe code |
| TASK-018 | Flutter: màn chọn ngày/giờ theo ca, gọi API giữ slot | Vibe code phần UI, 🔴 hiểu luồng state (holding/error) |

**Đọc hiểu lại cuối tuần**: Tự giải thích được vì sao dùng unique constraint thay vì chỉ check bằng code trước khi insert (đây là bẫy phỏng vấn hay gặp — nhiều người chỉ check-rồi-insert, không atomic).

---

## Tuần 3: Thanh toán VNPay + Hủy/Hoàn tiền

**Mục tiêu**: Luồng thanh toán thật chạy được trên sandbox, có refund.

| Task | Nội dung | Ghi chú |
|---|---|---|
| TASK-019 | Đăng ký tài khoản VNPay Sandbox, đọc kỹ docs (redirect, IPN, refund API) | 🔴 Bắt buộc — không vibe được, phải đọc docs thật |
| TASK-020 | API tạo URL thanh toán VNPay | Vibe code theo docs |
| TASK-021 | API xử lý IPN callback: verify signature, cập nhật payment + booking status | 🔴 Bắt buộc hiểu sâu nhất trong toàn dự án |
| TASK-022 | Xử lý idempotency (IPN gọi trùng lặp) | 🔴 Bắt buộc hiểu |
| TASK-023 | Flutter: WebView thanh toán, polling trạng thái booking sau khi quay lại app | Vibe code |
| TASK-024 | Màn "Xác nhận điều khoản" — checkbox bắt buộc trước khi thanh toán | Vibe code |
| TASK-025 | Logic hủy booking (rule 6 tiếng) + gọi VNPay Refund API | 🔴 Bắt buộc hiểu |
| TASK-026 | Cờ `is_outdoor` trên Court + màn Owner đánh dấu "hủy do mưa" → trigger refund | Vibe code, hiểu luồng gọi lại |
| TASK-027 | Flutter: Booking History, hủy lịch, xem trạng thái thanh toán | Vibe code |

**Đọc hiểu lại cuối tuần**: Tự trả lời — "Vì sao không tin kết quả redirect từ client mà phải chờ IPN?" Đây gần như chắc chắn sẽ bị hỏi nếu CV ghi thanh toán VNPay.

---

## Tuần 4: Yêu thích, Đánh giá, Owner Dashboard, Admin

**Mục tiêu**: Hoàn thiện các tính năng còn lại, Owner và Admin dùng được đầy đủ.

| Task | Nội dung | Ghi chú |
|---|---|---|
| TASK-028 | API + Flutter: Yêu thích (toggle, optimistic update) | Vibe code |
| TASK-029 | API + Flutter: Đánh giá (chỉ cho booking đã confirmed & qua giờ chơi) | Vibe code |
| TASK-030 | Local Notification nhắc lịch trước giờ chơi | Vibe code |
| TASK-031 | Flutter: My Courts, Court Schedule Config (Owner) | Vibe code |
| TASK-032 | Flutter: Owner Bookings — xem danh sách đặt tại sân mình | Vibe code |
| TASK-033 | API + Flutter: Admin duyệt/từ chối Owner (bắt buộc lý do khi từ chối) | Vibe code |
| TASK-034 | API + Flutter: Admin khóa/mở User, ẩn/hiện sân | Vibe code |
| TASK-035 | API + Flutter: Admin xem danh sách giao dịch | Vibe code |
| TASK-036 | Empty state, Error state, Loading skeleton cho toàn bộ màn hình | Vibe code |

**Đọc hiểu lại cuối tuần**: Không có phần 🔴 mới tuần này — dùng thời gian ôn lại 3 tuần trước, đặc biệt là Auth + Booking + Payment.

---

## Tuần 5: Testing, Polish UI, Coding Standard

**Mục tiêu**: Ứng dụng ổn định, code sạch, sẵn sàng demo.

| Task | Nội dung | Ghi chú |
|---|---|---|
| TASK-037 | Viết 5-8 Unit Test cho business logic quan trọng (race condition, JWT, refund) | 🔴 Tự viết, không vibe hoàn toàn — hiểu test case mới viết được test đúng |
| TASK-038 | Viết 3-5 Widget Test cho Flutter (form validation, booking flow) | Vibe code, review lại logic assert |
| TASK-039 | Rà lại toàn bộ coding convention: không hard-code string/color/URL, đặt tên nhất quán | Vibe code (dùng AI để review + refactor) |
| TASK-040 | Dark Mode, Responsive check trên vài kích thước màn hình | Vibe code |
| TASK-041 | Error handling toàn cục: network error, retry, thông báo rõ ràng | Vibe code |
| TASK-042 | Setup GitHub Actions cơ bản: lint + build check | Vibe code |
| TASK-043 | Deploy backend lên Render/Railway, test end-to-end trên môi trường thật | 🔴 Tự làm, dễ phát sinh lỗi môi trường (env variable, CORS...) |

**Đọc hiểu lại cuối tuần**: Tự chạy full flow trên bản deploy thật (không phải localhost) từ đăng ký → đặt sân → thanh toán → hủy → hoàn tiền, ghi lại mọi lỗi phát sinh và tự sửa (đừng để AI sửa hộ hoàn toàn — đây là lúc hiểu sâu nhất).

---

## Tuần 6: README, Demo Video, Ôn phỏng vấn

**Mục tiêu**: Đóng gói portfolio, sẵn sàng trả lời phỏng vấn.

| Task | Nội dung | Ghi chú |
|---|---|---|
| TASK-044 | Viết README.md: giới thiệu, tech stack, hướng dẫn cài đặt, ảnh chụp màn hình | Vibe code phần viết, tự chọn nội dung nhấn mạnh |
| TASK-045 | Viết API.md: liệt kê toàn bộ endpoint | Vibe code (tự động sinh từ code) |
| TASK-046 | Quay video demo ngắn (2-3 phút) toàn bộ luồng chính | Tự làm |
| TASK-047 | Chuẩn bị câu trả lời cho 6-8 câu hỏi phỏng vấn dự kiến (xem mục 2 bên dưới) | 🔴 Bắt buộc tự chuẩn bị |
| TASK-048 | Buffer — dự phòng cho task trễ hoặc bug phát sinh | — |

---

## 2. Câu hỏi phỏng vấn dự kiến — chuẩn bị trước

Dựa theo đúng những gì dự án có, khả năng cao sẽ bị hỏi:

1. "Bạn xử lý race condition khi 2 người đặt cùng slot như thế nào?" → trả lời bằng DB transaction + unique constraint, có thể vẽ lại luồng
2. "Vì sao không dùng Firebase mà tự viết backend?" → trả lời: muốn thể hiện khả năng thiết kế API, xử lý auth, business logic thật
3. "JWT access token và refresh token khác nhau thế nào, vì sao cần cả 2?" 
4. "Thanh toán online bạn xác nhận kết quả thế nào, có tin vào redirect từ client không?" → nhấn mạnh IPN + verify signature
5. "Clean Architecture bạn áp dụng cụ thể ra sao trong dự án?" → chỉ ra folder structure thật, giải thích Data/Domain/Presentation
6. "Nếu có thêm thời gian, bạn sẽ làm gì tiếp theo?" → có thể nhắc lại ý tưởng Subscription đã cân nhắc nhưng quyết định bỏ vì ưu tiên chất lượng MVP — đây là câu trả lời tốt, thể hiện tư duy đánh đổi phạm vi (trade-off), không phải thiếu ý tưởng

---

## 3. Rủi ro cần theo dõi trong quá trình làm

| Rủi ro | Cách phòng tránh |
|---|---|
| VNPay Sandbox docs khó hiểu, tốn thời gian hơn dự kiến | Làm việc này SỚM (tuần 3, không để cuối), có buffer tuần 6 |
| Vibe code quá tay, không hiểu code AI sinh ra | Bắt buộc dừng đọc hiểu cuối mỗi tuần như đã thiết kế ở trên |
| Deploy backend gặp lỗi môi trường vào phút chót | Deploy thử từ tuần 3 (sau khi có API cơ bản), không để dồn tuần 5 |
| Hết 6 tuần chưa xong hết | Task tuần 4 (Favorites, Review, Notification) là nhóm ưu tiên thấp nhất, có thể cắt nếu trễ tiến độ, không ảnh hưởng phần lõi (Auth, Booking, Payment) |
