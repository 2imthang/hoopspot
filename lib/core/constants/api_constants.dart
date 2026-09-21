/// TASK-039 — trước đây có thêm `baseUrl` trỏ `http://10.0.2.2:3000`
/// (backend NestJS tự viết ban đầu, đã bỏ khi pivot sang Firebase — xem
/// CLAUDE.md "THAY ĐỔI KIẾN TRÚC QUAN TRỌNG"). Mọi request thật hiện tại
/// (Cloudinary, Cloudflare Worker) đều tự truyền URL tuyệt đối riêng
/// ([CloudinaryConstants]/[PaymentWorkerConstants]), nên `baseUrl` đó
/// chưa từng được dùng thật — bỏ hẳn cho khỏi gây hiểu lầm còn 1 backend
/// tự host nào đó, chỉ giữ lại timeout dùng chung cho [DioClient].
class ApiConstants {
  const ApiConstants._();

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
