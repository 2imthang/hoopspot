# HoopSpot — Tài Liệu Thiết Kế Dự Án
### App Đặt Sân Bóng Rổ | Portfolio Flutter Internship

> ⚠️ **LƯU Ý QUAN TRỌNG**: Tài liệu này ban đầu được viết cho kiến trúc NestJS + PostgreSQL + JWT tự viết. Dự án đã **pivot sang Firebase** (xem mục 2 — Tech Stack) để đơn giản hóa cho mục tiêu vibe code. **Mục 2 và các quyết định về tài khoản/role vẫn đúng và mới nhất.** Tuy nhiên các mục phía sau nói về ER Diagram dạng bảng SQL, REST API endpoint chi tiết, JWT flow, Backend Architecture kiểu NestJS — những phần đó **không còn áp dụng**, chỉ giữ lại làm tài liệu tham khảo lịch sử. Khi cần chi tiết database/API mới, dùng cấu trúc Firestore collection mô tả trong `CLAUDE.md` và `hoopspot-roadmap.md` (bản Firebase) thay thế.

---

## 0. Mục tiêu & Nguyên tắc

- **Mục tiêu**: MVP chất lượng cao, đủ gọn để hoàn thành trong 1.5 tháng bằng vibe code (Claude Code), không cần hiểu sâu backend phức tạp.
- **Nguyên tắc**: Không over-engineering. Ưu tiên đơn giản, dễ hiểu hơn là thể hiện chiều sâu kỹ thuật backend — đổi lại tập trung chiều sâu vào Flutter/UI và đúng 1 phần thanh toán (Cloud Function).
- **Vai trò khi thực hiện**: Technical Lead + Senior Flutter Developer, giải thích rõ lý do mỗi quyết định kỹ thuật, ưu tiên phương án đơn giản nhất đáp ứng đúng yêu cầu.

---

## 1. Thông tin dự án

| | |
|---|---|
| Tên dự án | HoopSpot — Ứng dụng Đặt Sân Bóng Rổ |
| Nền tảng | Flutter (Android) |
| Đối tượng | Người chơi (User), Chủ sân (Court Owner), Admin — không có chế độ Guest, bắt buộc đăng nhập/đăng ký mới vào được màn chính |
| Phạm vi | MVP có thể mở rộng, không phải sản phẩm hoàn chỉnh |

---

## 2. Tech Stack (đã chốt — bản Firebase, đã pivot từ NestJS/Prisma vì quá nặng kiến thức so với mục tiêu vibe code)

> **Lịch sử quyết định**: Bản đầu tiên chọn tự viết backend (NestJS + Prisma) để thể hiện kỹ năng API. Sau khi triển khai thực tế, nhận thấy khối lượng kiến thức cần hiểu (JWT, migration, deploy server...) vượt quá mục tiêu ban đầu là "vibe code" nhanh. Quyết định pivot sang Firebase để đơn giản hóa, giữ lại đúng 1 phần cần "viết backend" là Cloud Function xử lý thanh toán VNPay.

| Thành phần | Lựa chọn | Lý do ngắn gọn |
|---|---|---|
| Mobile | Flutter + Dart | Yêu cầu bắt buộc |
| State Management | **Bloc (flutter_bloc)** | Đã chốt — quản lý state tường minh qua Event/State, phổ biến ở nhiều công ty outsource/product tại VN, dễ giải thích luồng dữ liệu khi phỏng vấn |
| Architecture | Clean Architecture (Feature-first) | Chuẩn doanh nghiệp, dễ test, dễ mở rộng — lớp Data giờ gọi Firestore SDK thay vì REST API tự viết, nhưng Domain/Presentation không đổi |
| Networking | Dio | Vẫn dùng để gọi API bên thứ 3 (Google Maps, VNPay) — phần lớn dữ liệu app (Users, Courts, Bookings) đọc/ghi thẳng qua Firestore SDK |
| **Backend/Database** | **Firebase (Firestore + Cloud Functions)** | Không tự viết REST API/JWT/migration — Firestore lo database, Cloud Functions chỉ dùng cho phần bắt buộc phải có backend: xác nhận thanh toán VNPay an toàn |
| **Authentication** | **Firebase Authentication** (Email/Password + Google Sign-In) | Không tự viết JWT — Firebase SDK tự lo toàn bộ vòng đời token |
| File Storage | Firebase Storage | Upload ảnh sân, avatar |
| Notification | flutter_local_notifications | Không cần FCM/Push |
| Maps | Google Maps Flutter Plugin | Tìm sân gần, chỉ đường |
| **Payment Gateway** | **VNPay Sandbox** | Vẫn tích hợp thật (redirect, IPN callback, verify signature) qua Cloud Function — không mock, vì đây là phần thể hiện kỹ năng duy nhất còn giữ lại |
| Deploy | `firebase deploy` (Cloud Functions + Hosting nếu cần) | Không cần tự thuê/cấu hình server riêng như Render/Railway |

**Lưu ý quan trọng**: Business data (Users, Courts, Bookings, Reviews...) đọc/ghi trực tiếp qua Firestore SDK từ Flutter, có Security Rules kiểm soát quyền truy cập ở tầng database — thay thế cho việc tự viết middleware/guard kiểm tra JWT như hướng cũ.

**Quyết định mô hình tài khoản**: User và Court Owner là 2 loại tài khoản tách biệt hoàn toàn (không phải 1 tài khoản mang nhiều role). Role chỉ có 3 giá trị cố định: `USER`, `OWNER`, `ADMIN`. Owner đăng ký xong ở trạng thái `pending`, cần Admin duyệt (`approved`) mới tạo được sân. Việc tách riêng giúp authorization đơn giản (check role trực tiếp qua Security Rules, không cần check ownership phức tạp), UI/navigation tách biệt theo role, và loại bỏ rủi ro tự đặt/tự review sân của chính mình.

---

## 3. Chức năng (giữ nguyên từ bản gốc, đã rà soát không mâu thuẫn)

### Authentication
- Đăng ký, Đăng nhập, Google Login (qua backend OAuth, không qua Firebase Auth), Quên mật khẩu, Đăng xuất
- **User và Court Owner là 2 loại tài khoản riêng biệt** — khi đăng ký, chọn "Người chơi" hoặc "Chủ sân"
- Tài khoản **Court Owner phải qua Admin duyệt** trước khi được phép tạo sân — sau khi đăng ký, tài khoản Owner ở trạng thái `pending`, chỉ dùng được sau khi Admin chuyển sang `approved`
- Tài khoản User kích hoạt ngay sau khi đăng ký, không cần duyệt

### Người dùng
Hồ sơ cá nhân, Chỉnh sửa thông tin, Đổi mật khẩu

### Trang chủ
Danh sách sân, Banner, Tìm kiếm, Lọc, Danh mục

### Chi tiết sân
Thông tin sân, Hình ảnh, Giá, Tiện ích, Google Maps, Chỉ đường, Đánh giá

### Đặt sân
Đặt theo giờ (Hourly): 1 ca = 2 tiếng, chọn ngày + 1 hoặc nhiều ca trong ngày (không giới hạn số giờ/ngày, miễn còn trống & trong giờ hoạt động)

Xác nhận điều khoản (chính sách hủy/hoàn tiền) trước khi thanh toán, Giữ slot chờ thanh toán (10 phút), Hủy lịch (theo chính sách hoàn tiền), Lịch sử đặt sân
> Đây là phần logic quan trọng nhất — cần xử lý chống đặt trùng slot (race condition) ở tầng backend. Booking chỉ được xác nhận "confirmed" sau khi thanh toán thành công; nếu quá 10 phút giữ slot mà chưa thanh toán, slot tự động nhả lại.

> **Đã loại bỏ khỏi phạm vi**: Đặt theo tháng (Subscription/recurring booking) — cân nhắc lại vì độ phức tạp (sinh nhiều booking, conflict resolution trên nhiều ngày, chính sách hủy/mưa riêng) không tương xứng với giá trị thể hiện thêm cho portfolio, trong khi Hourly Booking đã đủ thể hiện toàn bộ kỹ năng cốt lõi. Có thể cân nhắc bổ sung sau khi hoàn thành MVP nếu còn thời gian.

**Chính sách hủy & hoàn tiền**
- Hủy trước giờ chơi ≥ 6 tiếng → hoàn tiền 100%
- Hủy trong vòng < 6 tiếng → không hoàn tiền
- Sân ngoài trời (`is_outdoor = true`) + trời mưa → hoàn tiền 100% bất kể thời điểm hủy, do Owner đánh dấu "hủy do mưa" cho buổi cụ thể, tự động kích hoạt hoàn tiền

### Thanh toán
- Thanh toán booking qua **VNPay Sandbox** (redirect sang cổng thanh toán, xử lý callback, verify signature qua IPN, không tin kết quả redirect từ client)
- Trạng thái thanh toán: pending → success / failed
- Hỗ trợ **hoàn tiền qua VNPay Refund API** theo chính sách hủy ở trên
- Lịch sử giao dịch của User
- Xử lý các trường hợp: thanh toán thất bại, timeout, callback trùng lặp (idempotency)

### Yêu thích
Thêm / Xóa / Danh sách yêu thích

### Đánh giá
Rating, Bình luận

### Thông báo
Local Notification (nhắc lịch đặt sân)

### Chủ sân
CRUD sân, CRUD lịch hoạt động, Quản lý lịch đặt, Xem lịch sử booking đã thanh toán của sân mình (chỉ danh sách giao dịch, không phải báo cáo doanh thu/biểu đồ)

### Admin (tối giản — theo yêu cầu)
- Không có dashboard/web riêng — dùng chung app Flutter, hiện thêm 2-3 màn hình khi role = admin
- **Duyệt/từ chối tài khoản Court Owner đăng ký mới** (pending → approved/rejected). Từ chối bắt buộc nhập lý do, hiển thị lại cho Owner. Duyệt miễn phí ở giai đoạn MVP (có thể bổ sung phí đăng ký sau — không thiết kế trong phạm vi này)
- Xem danh sách User, khóa/mở tài khoản
- Xem danh sách Sân, ẩn/hiện sân vi phạm
- Xem danh sách giao dịch thanh toán (chỉ để đối soát/hỗ trợ khi có khiếu nại, không phải báo cáo tài chính)
- **Không làm**: thống kê, biểu đồ, báo cáo doanh thu, phân quyền nhiều cấp

---

## 4. Không triển khai (giữ nguyên bản gốc)

Chat, AI, Voucher, Promotion, Membership, Tournament, Thuê HLV, Thuê dụng cụ, Livestream, Camera AI, OCR, Recommendation Engine, Cloud Functions, Firebase Analytics, Dashboard BI, Báo cáo tài chính, Thanh toán MoMo/Stripe.

> **Đã thay đổi**: Thanh toán VNPay Sandbox được đưa VÀO phạm vi MVP (xem mục Tech Stack và Chức năng > Thanh toán). MoMo/Stripe vẫn loại trừ — chỉ tích hợp 1 cổng thanh toán duy nhất để tránh dàn trải.

**Bổ sung không triển khai** (do đã chốt kiến trúc):
- Firestore, Firebase Authentication
- Figma (UI sẽ thiết kế trực tiếp cùng Claude khi tới giai đoạn dựng giao diện, không qua bước Figma trung gian)
- Sprint Planning kiểu team nhiều người (chỉ cần Task Breakdown cá nhân)
- Backend Middleware/Logging/API Versioning ở mức phức tạp — giữ ở mức vừa đủ cho một service nhỏ

---

## 5. Yêu cầu đầu ra (đã rút gọn từ 22 phần xuống còn các phần thật sự cần thiết)

1. **Phân tích sản phẩm** — vấn đề, người dùng, giá trị, USP, đối thủ, điểm mạnh/yếu
2. **Chi tiết từng chức năng** — mục đích, user flow, business logic, validation, edge case
3. **Phân quyền** — User / Court Owner / Admin (không có Guest — bắt buộc đăng nhập/đăng ký ngay từ màn hình mở app mới vào được Trang chủ và các màn hình khác)
4. **User Flow** (Mermaid)
5. **Database Design** — PostgreSQL, ~12-15 bảng, kèm Field/Type/PK/FK/Relationship/Validation
6. **ER Diagram** (Mermaid)
7. **REST API Design** — URL, Method, Auth, Request, Response, Error, Status Code cho từng endpoint
8. **Flutter Architecture** — so sánh MVC/MVVM/Clean/Feature-first → chọn 1, sinh Folder Structure đầy đủ + giải thích
9. **Backend Architecture** — Module/Controller/Service/Repository/DTO, ở mức vừa đủ cho service quy mô nhỏ
10. **Packages đề xuất** — công dụng, lý do chọn, alternative
11. **Design System** — color palette, typography, spacing, component chính, dark mode (không cần Figma, chỉ cần định nghĩa trong Flutter)
12. **Danh sách màn hình** (~15-20) — mục đích, widget chính, API dùng, state, business logic
13. **Business Logic quan trọng** — chống đặt trùng sân, giữ slot chờ thanh toán (có timeout tự nhả), xử lý callback thanh toán idempotent, hủy lịch, hoàn slot khi thanh toán thất bại, xử lý mất mạng
14. **Bảo mật** — JWT flow, HTTPS, OWASP Mobile cơ bản
15. **Tối ưu hiệu năng** — cache, pagination, lazy loading, nén ảnh
16. **Error Handling** — network/validation/API error, retry
17. **Testing** — Unit test + Widget test cơ bản, vài test case mẫu
18. **Git Workflow** — Git Flow, branch, commit convention
19. **Coding Standard** — SOLID, DRY, KISS, naming convention, giới hạn dòng file/hàm, không hard-code string/color/URL
20. **Roadmap & Milestone** — kèm thời gian ước lượng
21. **Task Breakdown** — TASK-001, TASK-002..., mỗi task 2-6 giờ, có Definition of Done
22. **Đánh giá giá trị Portfolio** — kỹ năng thể hiện được, điểm mạnh, gợi ý bổ sung sau này

---

## 6. Quy tắc thực hiện

- Không viết code ở giai đoạn thiết kế.
- Luôn giải thích lý do khi có lựa chọn kỹ thuật (đã chốt sẵn ở mục 2 thì không cần so sánh lại từ đầu, chỉ giải thích ngắn gọn khi áp dụng).
- Làm theo từng phần, xong 1 phần thì dừng lại để review trước khi sang phần tiếp theo — **không dồn toàn bộ 22 phần vào một lần trả lời** (tránh loãng nội dung, dễ theo dõi và góp ý).
- Tài liệu output: chỉ cần README.md (tổng hợp) + API.md (danh sách endpoint) — không cần INSTALL/CONTRIBUTING/CHANGELOG/DATABASE.md riêng lẻ.

---

## 7. Thứ tự đề xuất khi triển khai thiết kế

1. Phân tích sản phẩm + User Flow
2. Database Schema + ER Diagram
3. REST API Design
4. Flutter Architecture + Backend Architecture + Folder Structure
5. Danh sách màn hình + Design System
6. Business Logic quan trọng + Bảo mật + Error Handling
7. Testing + Git Workflow + Coding Standard
8. Roadmap + Task Breakdown + Đánh giá Portfolio
