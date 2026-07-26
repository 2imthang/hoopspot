# HoopSpot — Đặc Tả Chức Năng, UI & Yêu Cầu Hệ Thống
### (Functional & UI Specification — dựa trên Design Brief đã chốt)

> ⚠️ **Đã pivot sang Firebase** — toàn bộ user flow, business logic, validation, edge case, và đặc tả 23 màn hình UI trong tài liệu này **vẫn đúng và áp dụng bình thường**. Chỉ riêng các chỗ ghi cụ thể "API" dạng `GET /courts`, `POST /bookings`... nên hiểu là **thao tác Firestore SDK tương ứng** (đọc/ghi collection), không phải endpoint REST tự viết. Chi tiết kỹ thuật Firebase xem trong `CLAUDE.md`.

---

## 1. Tổng quan hệ thống

| | |
|---|---|
| Tên dự án | HoopSpot — Ứng dụng đặt sân bóng rổ |
| Nền tảng | Flutter (Android) + Firebase (Auth, Firestore, Storage, Cloud Functions) |
| Loại tài khoản | User, Court Owner (tách riêng), Admin |
| Truy cập | Bắt buộc đăng nhập/đăng ký, không có chế độ Guest |

---

## 2. Yêu cầu phi chức năng (Non-Functional Requirements)

| Nhóm | Yêu cầu |
|---|---|
| Hiệu năng | Danh sách sân load < 2s với pagination; ảnh nén trước khi hiển thị |
| Bảo mật | JWT access token (15 phút) + refresh token (7 ngày); HTTPS bắt buộc; mật khẩu hash bằng bcrypt |
| Khả dụng | Xử lý mất mạng: cache dữ liệu đọc gần nhất, hàng chờ retry cho request ghi |
| Khả mở rộng | Kiến trúc module hóa (NestJS Module theo domain), Flutter Feature-first — dễ thêm role/tính năng mới |
| Đồng thời | Chống race condition khi 2 user đặt cùng slot (transaction + unique constraint ở DB) |
| Khả bảo trì | Coding convention thống nhất, không hard-code string/color/URL |

---

## 3. Ma trận phân quyền (Permission Matrix)

| Chức năng | User | Owner | Admin |
|---|:---:|:---:|:---:|
| Đăng ký / Đăng nhập | ✅ | ✅ | — (được Admin tạo sẵn) |
| Xem danh sách/chi tiết sân | ✅ | ✅ | ✅ |
| Đặt sân + thanh toán | ✅ | ❌ | ❌ |
| Hủy lịch, xem lịch sử đặt | ✅ | ❌ | ❌ |
| Yêu thích, đánh giá | ✅ | ❌ | ❌ |
| CRUD sân của mình | ❌ | ✅ (sau khi được duyệt) | ❌ |
| Quản lý lịch hoạt động sân | ❌ | ✅ | ❌ |
| Xem booking của sân mình | ❌ | ✅ | ❌ |
| Duyệt tài khoản Owner mới | ❌ | ❌ | ✅ |
| Khóa/mở tài khoản User/Owner | ❌ | ❌ | ✅ |
| Ẩn/hiện sân vi phạm | ❌ | ❌ | ✅ |
| Xem giao dịch thanh toán (đối soát) | ❌ | ❌ | ✅ |

---

## 4. Đặc tả chi tiết từng chức năng

### 4.1 Authentication

**Mục đích**: Quản lý định danh người dùng, phân biệt rõ 2 luồng đăng ký User/Owner.

**User Flow — Đăng ký**
1. Mở app → màn hình Login → chọn "Đăng ký"
2. Chọn loại tài khoản: **Người chơi** hoặc **Chủ sân**
3. Nhập email, mật khẩu, họ tên, số điện thoại
4. Nếu chọn "Chủ sân" → hiển thị thêm thông báo: *"Tài khoản cần được Admin duyệt trước khi sử dụng"*
5. Submit → backend tạo tài khoản:
   - User → `status: active`, đăng nhập được ngay
   - Owner → `status: pending`, hiển thị màn hình chờ duyệt, không cho vào app chính
6. Gửi email xác nhận (tối giản, không bắt buộc verify mới dùng được)

**User Flow — Đăng nhập**
1. Nhập email/mật khẩu hoặc chọn Google Login
2. Backend kiểm tra `status`:
   - `active` → cấp JWT, vào Home
   - `pending` (Owner) → chặn, hiển thị màn hình "Đang chờ duyệt"
   - `rejected` → hiển thị lý do từ chối (nếu có) + cho phép đăng ký lại
   - `locked` → chặn, hiển thị "Tài khoản đã bị khóa, liên hệ hỗ trợ"

**Business Logic**
- Google Login qua OAuth backend, không dùng Firebase Auth SDK trực tiếp trong Flutter — Flutter chỉ lấy Google id_token rồi gửi lên NestJS để verify và cấp JWT riêng của hệ thống
- Refresh token lưu trong secure storage, tự động refresh khi access token hết hạn (qua Dio Interceptor)

**Validation**
- Email: đúng định dạng, unique trong hệ thống (unique riêng theo từng loại tài khoản hay unique toàn hệ thống — **cần quyết định**: đề xuất unique toàn hệ thống, một email không thể vừa là User vừa là Owner, để tránh nhầm lẫn đăng nhập)
- Mật khẩu: tối thiểu 8 ký tự, có chữ và số
- Số điện thoại: đúng định dạng VN (10 số, đầu 0)

**Edge Cases**
- Đăng ký trùng email → trả lỗi rõ ràng "Email đã tồn tại"
- Owner bị từ chối duyệt → cho phép sửa thông tin và nộp lại, không cần tạo tài khoản mới
- Refresh token hết hạn khi đang dùng app → tự động logout, điều hướng về Login kèm thông báo
- Mất mạng khi đăng ký → giữ form data, cho phép thử lại không cần nhập lại

---

### 4.2 Hồ sơ cá nhân

**Mục đích**: Cho phép User/Owner quản lý thông tin cá nhân.

**User Flow**: Vào tab Profile → xem thông tin → bấm "Chỉnh sửa" → cập nhật tên/ảnh đại diện/số điện thoại → Lưu. Đổi mật khẩu ở màn hình riêng, yêu cầu nhập mật khẩu cũ.

**Validation**: Tương tự đăng ký. Ảnh đại diện giới hạn 5MB, tự resize trước khi upload lên Firebase Storage.

**Edge Cases**: Đổi mật khẩu sai mật khẩu cũ → báo lỗi, không cho submit. Upload ảnh thất bại do mất mạng → giữ nguyên ảnh cũ, thông báo lỗi, cho thử lại.

---

### 4.3 Trang chủ & Tìm kiếm

**Mục đích**: Điểm vào chính, giúp User khám phá sân nhanh.

**User Flow**: Home hiển thị Banner + danh sách sân (phân trang) → gõ từ khóa tìm kiếm (tên sân/khu vực) hoặc bấm Lọc (giá, khoảng cách, tiện ích) → danh sách cập nhật realtime theo bộ lọc.

**Business Logic**: Tìm kiếm debounce 300ms tránh gọi API liên tục. Danh sách dùng pagination (limit/offset hoặc cursor), không load hết 1 lần.

**Edge Cases**: Không có sân phù hợp bộ lọc → hiển thị Empty State với gợi ý nới lỏng bộ lọc. Mất mạng khi đang load thêm trang → hiển thị nút "Thử lại" ở cuối danh sách thay vì lỗi toàn màn hình.

---

### 4.4 Chi tiết sân

**Mục đích**: Cung cấp đầy đủ thông tin để User quyết định đặt sân.

**User Flow**: Từ Home/Search bấm vào 1 sân → xem ảnh (carousel), giá, tiện ích, vị trí trên Google Maps, danh sách đánh giá → bấm "Chỉ đường" mở Google Maps app → bấm "Đặt sân" chuyển sang màn Booking.

**Edge Cases**: Sân bị Admin ẩn trong lúc User đang xem (hiếm nhưng cần xử lý) → khi bấm Đặt sân, backend trả lỗi 404/410, hiển thị thông báo "Sân hiện không khả dụng".

---

### 4.5 Đặt sân, Giữ slot & Hủy/Hoàn tiền

**Mục đích**: Chức năng lõi — logic phức tạp nhất trong toàn bộ hệ thống.

> **Đã loại bỏ**: chế độ Đặt theo tháng (Subscription/recurring booking) — cân nhắc lại vì độ phức tạp (sinh nhiều booking, conflict resolution trên nhiều ngày, chính sách hủy/mưa riêng, cơ chế bù buổi) không tương xứng với giá trị thể hiện thêm, trong khi Hourly Booking đã đủ thể hiện race condition, giữ slot, thanh toán, và hoàn tiền — đúng những gì cần cho portfolio. Có thể bổ sung lại sau nếu còn thời gian sau khi hoàn thành MVP.

**User Flow**
1. Chọn ngày → hệ thống load các khung giờ trống của ngày đó (dựa theo lịch hoạt động Owner đã cấu hình, trừ các slot đã bị đặt). 1 "ca" cố định = 2 tiếng
2. Chọn 1 hoặc nhiều ca trong ngày (không bắt buộc liên tiếp, không giới hạn tổng số giờ/ngày — miễn còn trống & trong giờ hoạt động sân)
3. Bấm "Đặt sân" → backend tạo booking trạng thái `pending_payment` cho từng ca đã chọn, **khóa các slot đó trong 10 phút**
4. Hiển thị màn **Xác nhận điều khoản** (chính sách hủy/hoàn tiền, thời gian giữ slot) → user phải tích "Tôi đồng ý" mới bấm được "Tiếp tục thanh toán"
5. Chuyển sang màn Thanh toán, thanh toán 1 lần cho tổng số ca đã chọn
6. Thanh toán thành công trong 10 phút → toàn bộ booking chuyển `confirmed`
7. Quá 10 phút chưa thanh toán → hệ thống tự hủy toàn bộ booking đang giữ, nhả slot lại

**Business Logic**
- Chống race condition: **DB transaction + unique constraint** trên cặp (court_id, date, time_slot) ở trạng thái pending/confirmed — 2 request cùng lúc, chỉ 1 insert thành công, request còn lại nhận lỗi 409 Conflict
- Giữ slot có timeout: field `expires_at` trên booking, mỗi lần query slot trống phải loại cả những booking `pending_payment` còn hạn, coi booking hết hạn như đã hủy

**Validation**
- Không cho đặt slot trong quá khứ
- Không cho đặt slot ngoài giờ hoạt động sân

**Edge Cases**
- 2 user bấm đặt cùng slot cùng lúc → 1 thành công, 1 nhận lỗi "Khung giờ vừa được đặt, vui lòng chọn khung giờ khác", tự động refresh danh sách slot
- User thoát app giữa lúc đang giữ slot chưa thanh toán → booking tự hết hạn sau 10 phút như bình thường, không cần xử lý đặc biệt

---

#### 4.5.B Chính sách hủy & hoàn tiền

| Trường hợp | Kết quả |
|---|---|
| Hủy trước giờ chơi ≥ 6 tiếng | Hoàn tiền 100% qua VNPay Refund API |
| Hủy trong vòng < 6 tiếng | Không hoàn tiền |
| Sân ngoài trời (`court.is_outdoor = true`) bị mưa | Hoàn tiền 100%, bất kể thời điểm hủy |

**Business Logic**
- "Hủy do mưa": chỉ Owner của sân đó được đánh dấu, áp dụng cho 1 booking cụ thể (không áp dụng hàng loạt để tránh lạm dụng), tự động trigger refund, không cần Admin duyệt lại (tối giản cho MVP)
- Refund thực hiện qua **VNPay Refund API** (server-to-server), cập nhật `payment.status = refunded`

**Edge Cases**
- Owner đánh dấu hủy do mưa cho buổi đã qua giờ chơi → chặn, chỉ cho đánh dấu với buổi chưa diễn ra hoặc đang diễn ra
- Gọi Refund API thất bại (lỗi mạng/VNPay) → lưu trạng thái `refund_pending`, có cơ chế retry, không để booking "treo" không rõ trạng thái

---

### 4.6 Thanh toán (VNPay Sandbox)

**Mục đích**: Xác nhận booking bằng thanh toán thật qua sandbox.

**User Flow**
1. Từ màn Đặt sân, bấm Thanh toán → backend tạo payment record `pending`, sinh URL thanh toán VNPay
2. Flutter mở WebView load URL VNPay → user nhập thông tin thẻ test → xác nhận
3. VNPay redirect về `return_url` của backend kèm tham số kết quả → backend verify **checksum/signature**
4. Backend gọi thêm **IPN (Instant Payment Notification)** từ VNPay để xác nhận server-to-server (không chỉ tin vào redirect từ client) → cập nhật `payment.status` + `booking.status`
5. Flutter nhận kết quả qua deep link hoặc polling trạng thái → hiển thị màn Kết quả thanh toán

**Business Logic**
- **Không tin tưởng kết quả redirect từ client** — vì user có thể tự sửa URL redirect để giả mạo thành công. Trạng thái thật chỉ được xác nhận qua IPN callback verify bằng secret key
- Xử lý **idempotency**: nếu VNPay gọi IPN 2 lần cho cùng 1 giao dịch (có thể xảy ra), backend phải kiểm tra `transaction_id` đã xử lý chưa trước khi cập nhật lại, tránh confirm booking 2 lần hoặc lỗi logic

**Validation**: Verify signature bằng secret key VNPay cấp, sai signature → từ chối, log lại nghi vấn giả mạo.

**Edge Cases**
- Thanh toán thất bại (user hủy giữa chừng) → booking quay lại trạng thái chờ hoặc hủy luôn, nhả slot
- Mạng gián đoạn giữa lúc thanh toán xong và app nhận kết quả → dùng cơ chế polling trạng thái booking khi quay lại app, không phụ thuộc hoàn toàn vào deep link
- IPN đến trước khi user quay lại app → khi app active lại, poll API để lấy trạng thái mới nhất, không hiển thị sai

**Luồng hoàn tiền (Refund)**
- Kích hoạt khi: user tự hủy đủ điều kiện (≥ 6 tiếng), hoặc Owner đánh dấu "hủy do mưa" (sân ngoài trời)
- Backend gọi **VNPay Refund API**, cập nhật `payment.status = refunded`, hiển thị trong lịch sử giao dịch của User
- Refund thất bại (lỗi tạm thời từ VNPay) → lưu `refund_pending`, retry theo cơ chế nền, không để trạng thái mập mờ với user

---

### 4.7 Yêu thích

**User Flow**: Bấm icon trái tim ở Card sân hoặc màn Chi tiết → toggle thêm/xóa → đồng bộ ngay xuống backend (optimistic update ở UI, rollback nếu API lỗi).

**Edge Cases**: Bấm yêu thích khi mất mạng → hiển thị trạng thái tạm thời, retry ngầm, nếu thất bại hẳn thì rollback UI + thông báo nhỏ (snackbar).

---

### 4.8 Đánh giá

**User Flow**: Chỉ hiện nút "Viết đánh giá" nếu User có booking `confirmed` đã qua giờ chơi tại sân đó → chọn rating 1-5 sao + viết bình luận → submit.

**Validation**: Mỗi booking chỉ được đánh giá 1 lần. Bình luận giới hạn độ dài (ví dụ 500 ký tự), lọc từ ngữ không phù hợp cơ bản (tối giản: blacklist từ khóa, không cần AI).

**Edge Cases**: User cố đánh giá sân chưa từng đặt → chặn ở cả UI (ẩn nút) lẫn backend (kiểm tra lại, không tin UI).

---

### 4.9 Thông báo (Local Notification)

**User Flow**: Khi booking `confirmed`, hệ thống lên lịch local notification trước giờ chơi (ví dụ 1 tiếng và 15 phút).

**Business Logic**: Lên lịch bằng `flutter_local_notifications`, hủy lịch thông báo tương ứng nếu user hủy booking.

**Edge Cases**: User tắt quyền thông báo hệ thống → app vẫn hoạt động bình thường, chỉ không hiển thị thông báo, không chặn luồng chính.

---

### 4.10 Chủ sân — CRUD sân & lịch hoạt động

**User Flow**
1. Owner (đã `approved`) vào tab "Sân của tôi" → "Thêm sân mới" → nhập thông tin, upload ảnh, chọn vị trí trên bản đồ, thêm tiện ích
2. Cấu hình lịch hoạt động: chọn khung giờ mở/đóng theo từng ngày trong tuần
3. Sửa/xóa sân đã tạo

**Business Logic**: Owner chỉ thao tác được trên sân do chính mình tạo — backend check `court.owner_id === currentUser.id` ở mọi API sửa/xóa.

**Edge Cases**: Owner xóa sân đang có booking `confirmed` trong tương lai → chặn xóa, yêu cầu xử lý các booking đó trước (hủy hoặc chờ hoàn thành), tránh mất dữ liệu lịch sử.

---

### 4.11 Chủ sân — Quản lý lịch đặt

**User Flow**: Xem danh sách booking tại các sân của mình, lọc theo trạng thái (pending_payment/confirmed/cancelled/completed).

**Edge Cases**: Không cho Owner chỉnh sửa trực tiếp trạng thái booking (tránh gian lận xác nhận thanh toán giả) — trạng thái chỉ đổi qua hệ thống thanh toán hoặc hành động hủy của chính User.

---

### 4.12 Admin — Duyệt tài khoản Owner

**User Flow**: Xem danh sách tài khoản Owner đang `pending` → xem thông tin đăng ký → Duyệt (approved) hoặc Từ chối (rejected, **bắt buộc nhập lý do**, hiển thị lại cho Owner ở màn hình chờ duyệt của họ).

**Validation**: Trường lý do từ chối bắt buộc nhập, không cho submit rỗng.

**Edge Cases**: Owner đã duyệt nhưng sau đó vi phạm → Admin dùng chức năng khóa tài khoản (đổi status sang `locked`), không cần chức năng "hủy duyệt" riêng.

**Ghi chú phạm vi**: Duyệt miễn phí ở giai đoạn MVP, chưa thiết kế thu phí đăng ký Owner (để ngỏ cho mở rộng sau).

---

### 4.13 Admin — Quản lý User & Sân

**User Flow**: Xem danh sách User/Owner → khóa/mở tài khoản. Xem danh sách Sân → ẩn/hiện sân vi phạm.

**Edge Cases**: Khóa tài khoản Owner đang có booking active tại sân của họ → các booking đã `confirmed` vẫn giữ nguyên (User đã thanh toán, không thể tự ý hủy), chỉ chặn Owner tạo thêm sân/booking mới.

---

### 4.14 Admin — Xem giao dịch thanh toán

**User Flow**: Xem danh sách giao dịch (chỉ đọc), tìm theo mã booking/user để hỗ trợ khi có khiếu nại.

**Ghi chú phạm vi**: Không có filter/thống kê nâng cao, không biểu đồ — đúng tinh thần "tối giản" đã thống nhất.

---

## 5. Đặc tả màn hình (UI Screens)

### Nhóm User (15 màn hình)

| # | Màn hình | Mục đích | API chính | State chính |
|---|---|---|---|---|
| 1 | Splash | Kiểm tra token, điều hướng | `GET /auth/me` | Loading |
| 2 | Login | Đăng nhập | `POST /auth/login` | idle/loading/error |
| 3 | Register | Đăng ký, chọn role | `POST /auth/register` | idle/loading/error |
| 4 | Forgot Password | Quên mật khẩu | `POST /auth/forgot-password` | idle/loading/success |
| 5 | Home | Danh sách sân, banner | `GET /courts` | loading/loaded/empty/error |
| 6 | Search & Filter | Tìm kiếm, lọc | `GET /courts?query=...` | loading/loaded |
| 7 | Court Detail | Chi tiết sân | `GET /courts/:id` | loading/loaded |
| 8 | Booking (chọn slot theo ca) | Chọn ngày/giờ | `GET /courts/:id/slots`, `POST /bookings` | loading/holding/error |
| 9 | Terms & Conditions Confirmation | Hiển thị chính sách hủy/hoàn tiền/mưa, bắt buộc tích đồng ý trước khi thanh toán | — | idle/agreed |
| 10 | Payment (WebView) | Thanh toán VNPay | `POST /payments/create`, poll `GET /bookings/:id` | pending/success/failed |
| 11 | Booking History | Lịch sử đặt sân, hủy lịch | `GET /bookings/me`, `POST /bookings/:id/cancel` | loading/loaded/empty |
| 12 | Favorites | Danh sách yêu thích | `GET /favorites` | loading/loaded/empty |
| 13 | Write Review | Viết đánh giá sau khi chơi | `POST /reviews` | idle/submitting |
| 14 | Profile | Hồ sơ + đổi mật khẩu | `GET/PUT /users/me` | idle/loading |
| 15 | Notifications | Danh sách thông báo local | (local, không cần API) | — |

### Nhóm Owner (5 màn hình)

| # | Màn hình | Mục đích | API chính |
|---|---|---|---|
| 16 | Owner Pending Screen | Màn chờ duyệt (pending/rejected + lý do từ chối) | `GET /auth/me` |
| 17 | My Courts | Danh sách sân của tôi, thêm/sửa/xóa, đánh dấu `is_outdoor` | `GET/POST/PUT/DELETE /courts/mine` |
| 18 | Court Schedule Config | Cấu hình khung giờ hoạt động | `PUT /courts/:id/schedule` |
| 19 | Owner Bookings | Danh sách booking tại sân mình | `GET /courts/mine/bookings` |
| 20 | Mark Rain Cancellation | Đánh dấu hủy do mưa cho 1 buổi cụ thể (chỉ sân outdoor), tự động hoàn tiền | `POST /bookings/:id/rain-cancel` |

### Nhóm Admin (3 màn hình)

| # | Màn hình | Mục đích | API chính |
|---|---|---|---|
| 21 | Owner Approval List | Duyệt/từ chối tài khoản Owner (từ chối bắt buộc lý do) | `GET /admin/owners/pending`, `PUT /admin/owners/:id/approve`, `PUT /admin/owners/:id/reject` |
| 22 | User & Court Management | Khóa/mở User, ẩn/hiện sân | `PUT /admin/users/:id/lock`, `PUT /admin/courts/:id/hide` |
| 23 | Transactions List | Xem giao dịch, gồm cả trạng thái refund (chỉ đọc) | `GET /admin/transactions` |

**Tổng: 23 màn hình** — quay về đúng khoảng hợp lý so với ước lượng ban đầu (15-20), chỉ nhỉnh hơn chút do thêm Terms Confirmation, Mark Rain Cancellation, và tách riêng role User/Owner. Không còn phần nào thuộc diện "rủi ro cao, để làm sau" — toàn bộ 23 màn hình đều là phạm vi lõi, khả thi trong 2-3 tháng.

---

## 6. Trạng thái quyết định

Tất cả câu hỏi mở ở vòng thiết kế trước đã được chốt:

| Quyết định | Giá trị đã chốt |
|---|---|
| Chính sách hủy | ≥ 6 tiếng: hoàn tiền 100% / < 6 tiếng: không hoàn |
| Hoàn tiền do mưa | Áp dụng cho sân outdoor, Owner tự đánh dấu, không cần Admin duyệt lại |
| Thời gian giữ slot | 10 phút |
| Chế độ đặt sân | Chỉ Hourly (2h/ca) — **đã loại bỏ Subscription/đặt theo tháng** do cân nhắc lại độ phức tạp |
| Phí duyệt Owner | Miễn phí ở MVP |
| Từ chối Owner | Bắt buộc nhập lý do |

Tài liệu đã sẵn sàng để chuyển sang bước **Database Schema + ER Diagram** — phạm vi giờ đã gọn và rõ ràng, không còn phần logic dạng "state machine nhiều lớp" như Subscription, nên bước thiết kế Database sẽ đơn giản và chắc chắn hơn nhiều.
