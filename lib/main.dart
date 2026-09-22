import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app.dart';
import 'core/di/injection_container.dart' as di;
import 'core/services/notification_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _setUpGlobalErrorHandling();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await di.initDependencies();
  // Xin quyền thông báo sớm (TASK-030) — không chặn nếu bị từ chối, xem
  // NotificationService.
  await di.sl<NotificationService>().init();
  runApp(const HoopSpotApp());
}

/// TASK-041 — lưới an toàn cuối cùng cho lỗi KHÔNG lọt qua try/catch cụ
/// thể nào (lỗi khi build widget, Future không await bị throw...) — không
/// phải để thay cho try/catch đúng chỗ (mọi datasource/repository đã tự
/// bắt lỗi mạng/server riêng, xem `core/error/network_error_mapper.dart`),
/// chỉ để app không "chết trắng" không rõ lý do nếu có gì đó sót. Không
/// gắn dịch vụ báo lỗi trả phí nào (Crashlytics/Sentry...) — ngoài phạm vi
/// portfolio project này — nên chỉ log ra console, đủ để thấy khi debug.
void _setUpGlobalErrorHandling() {
  // Lỗi trong lúc build/layout/paint 1 widget — giữ nguyên màn đỏ debug
  // mặc định của Flutter lúc đang code (rất hữu ích), CHỈ đổi sang giao
  // diện thân thiện khi đã build release, tránh lộ chi tiết kỹ thuật cho
  // người dùng thật.
  if (kReleaseMode) {
    ErrorWidget.builder = (details) => const _GlobalErrorFallback();
  }

  // Lỗi bất đồng bộ không rơi vào Zone/try-catch nào (vd 1 Future không
  // await bị throw) — trả về true để Flutter biết đã xử lý, không cần tự
  // in thêm ra ngoài ý muốn.
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
    return true;
  };
}

class _GlobalErrorFallback extends StatelessWidget {
  const _GlobalErrorFallback();

  @override
  Widget build(BuildContext context) {
    // Cố tình không dùng Theme.of(context) — widget này thay thế cho 1
    // widget bị lỗi bất kỳ, có thể không có Theme/Material tổ tiên nào cả.
    return Container(
      color: const Color(0xFFFDEDEA),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: const Text(
        'Đã có lỗi xảy ra, vui lòng thử lại',
        style: TextStyle(color: Color(0xFF8B2C2C), fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }
}
