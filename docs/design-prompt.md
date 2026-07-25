# Prompt cho Claude Design — Thiết kế giao diện HoopSpot

Copy toàn bộ nội dung bên dưới và gửi cho Claude Design.

---

## VAI TRÒ

Bạn là UI/UX Designer chuyên thiết kế mobile app cho Flutter, phong cách hiện đại, tối giản, chuẩn Material 3. Hãy thiết kế giao diện cho ứng dụng dưới đây.

## THÔNG TIN DỰ ÁN

**Tên app**: HoopSpot — Ứng dụng đặt sân bóng rổ
**Nền tảng**: Flutter (Android)
**Đối tượng**: 3 loại tài khoản riêng biệt — Người chơi (User), Chủ sân (Court Owner), Admin. Không có chế độ khách (Guest) — mở app phải đăng nhập/đăng ký ngay.

## PHONG CÁCH THIẾT KẾ

- Material 3, hiện đại, bo góc, màu sắc tối giản (gợi ý tông cam/đen lấy cảm hứng bóng rổ, nhưng không bắt buộc — có thể đề xuất bảng màu khác nếu hợp lý hơn)
- Có Dark Mode
- Có Skeleton Loading / Shimmer Loading khi tải dữ liệu
- Có Empty State (khi danh sách rỗng) và Error State (khi lỗi mạng/API) rõ ràng, thân thiện
- Hỗ trợ Pull to Refresh và Infinite Scroll ở các danh sách dài (danh sách sân, lịch sử đặt sân)
- Typography rõ ràng, phân cấp tốt (tiêu đề/nội dung/chú thích)
- Component tái sử dụng: Button, Card sân, Bottom Navigation, Badge trạng thái (pending/confirmed/cancelled)

## BƯỚC BẮT BUỘC ĐẦU TIÊN: DESIGN TOKEN SYSTEM

**Trước khi thiết kế bất kỳ màn hình nào**, hãy định nghĩa 1 bộ Design Token chung, dùng xuyên suốt toàn bộ 23 màn hình (không tự phối màu/font riêng lẻ theo từng màn):

- **Color Palette**: primary, secondary, background, surface, error, success, warning + các biến thể cho Light Mode và Dark Mode (kèm mã hex cụ thể)
- **Typography Scale**: tên font, các cấp độ (Heading 1/2/3, Body Large/Medium/Small, Caption) kèm font-size/weight/line-height
- **Spacing Scale**: đơn vị khoảng cách chuẩn (VD 4/8/12/16/24/32px) dùng nhất quán cho padding/margin
- **Component Style chuẩn**: bo góc (border-radius) cho Card/Button/Input, độ đổ bóng (elevation), trạng thái Badge theo màu (pending = vàng, confirmed = xanh lá, cancelled = đỏ, refunded = xanh dương...)

Sau khi có bộ token này, áp dụng đúng y hệt cho tất cả các màn hình bên dưới — không đổi màu/font/spacing giữa các màn để đảm bảo tính nhất quán khi đưa vào code Flutter thật (ThemeData dùng chung).

## DANH SÁCH MÀN HÌNH CẦN THIẾT KẾ (đầy đủ 23 màn hình, chia theo nhóm)

### Nhóm User (15 màn hình)
1. **Splash** — logo app, kiểm tra đăng nhập
2. **Login** — email/password + nút Google Login
3. **Register** — có bước chọn loại tài khoản "Người chơi" hoặc "Chủ sân"
4. **Forgot Password** — nhập email nhận link/mã khôi phục
5. **Home** — danh sách sân dạng card (ảnh, tên, giá, khoảng cách, rating), banner khuyến mãi trên cùng, thanh tìm kiếm + nút lọc
6. **Search & Filter** — kết quả tìm kiếm + bộ lọc (giá, khoảng cách, tiện ích)
7. **Court Detail** — ảnh carousel, tên sân, giá, tiện ích (icon), vị trí trên bản đồ, nút "Chỉ đường", danh sách đánh giá, nút CTA "Đặt sân" nổi bật
8. **Booking (chọn slot theo ca)** — chọn ngày (calendar strip ngang), lưới khung giờ trạng thái trống/đã đặt/đang chọn, mỗi ca = 2 tiếng
9. **Terms & Conditions Confirmation** — hiển thị gọn chính sách hủy/hoàn tiền/mưa dạng bullet, checkbox "Tôi đồng ý", nút "Tiếp tục thanh toán" chỉ active khi đã tích
10. **Payment (WebView placeholder)** — màn chờ/kết quả thanh toán (pending/success/failed) với icon trạng thái rõ ràng
11. **Booking History** — danh sách các lượt đặt, mỗi item có badge trạng thái màu khác nhau (dùng đúng màu badge đã định nghĩa ở Design Token), nút hủy nếu đủ điều kiện
12. **Favorites** — danh sách sân yêu thích dạng card
13. **Write Review** — chọn sao (1-5), ô nhập bình luận
14. **Profile** — avatar, thông tin cá nhân, nút đổi mật khẩu, đăng xuất
15. **Notifications** — danh sách thông báo nhắc lịch (local notification)

### Nhóm Owner (5 màn hình)
16. **Owner Pending Screen** — màn chờ duyệt, hiển thị lý do nếu bị từ chối
17. **My Courts** — danh sách sân của Owner, nút thêm sân mới, mỗi card có nút sửa/xóa, toggle đánh dấu sân ngoài trời (`is_outdoor`)
18. **Court Schedule Config** — chọn khung giờ hoạt động theo từng ngày trong tuần (dạng lịch/toggle)
19. **Owner Bookings** — danh sách người đặt sân của Owner, lọc theo trạng thái
20. **Mark Rain Cancellation** — màn xác nhận đánh dấu 1 buổi "hủy do mưa" (chỉ hiện với sân outdoor), có cảnh báo rõ đây là hành động kích hoạt hoàn tiền tự động

### Nhóm Admin (3 màn hình)
21. **Owner Approval List** — danh sách chờ duyệt, nút Duyệt/Từ chối (từ chối mở dialog bắt buộc nhập lý do)
22. **User & Court Management** — danh sách User/Sân, toggle khóa/mở, ẩn/hiện
23. **Transactions List** — danh sách giao dịch thanh toán (chỉ đọc), có filter theo mã booking/user, hiển thị trạng thái gồm cả refund

## THỨ TỰ THIẾT KẾ ĐỀ XUẤT

1. Design Token System (bảng màu, typography, spacing, component chuẩn) — chốt trước tiên
2. Nhóm User (màn 1-15) — áp dụng đúng token đã chốt
3. Nhóm Owner (màn 16-20) — cùng token, không đổi phong cách
4. Nhóm Admin (màn 21-23) — cùng token, không đổi phong cách


## YÊU CẦU KỸ THUẬT KHI XUẤT THIẾT KẾ

- Thiết kế ở kích thước khung hình điện thoại Android tiêu chuẩn (ví dụ 360x800 hoặc tương đương)
- Với mỗi màn hình, ưu tiên thiết kế đủ chi tiết để có thể chuyển thẳng thành Flutter widget (bố cục rõ ràng, khoảng cách nhất quán, không mơ hồ)

## LƯU Ý

- Đây là app portfolio xin thực tập Flutter, nên thiết kế cần trông **chuyên nghiệp, đủ chỉn chu để đưa vào CV/portfolio**, không cần quá cầu kỳ nhưng phải nhất quán và có điểm nhấn riêng, tránh trông như mẫu UI kit có sẵn.
