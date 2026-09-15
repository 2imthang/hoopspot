import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app.dart';
import 'core/di/injection_container.dart' as di;
import 'core/services/notification_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await di.initDependencies();
  // Xin quyền thông báo sớm (TASK-030) — không chặn nếu bị từ chối, xem
  // NotificationService.
  await di.sl<NotificationService>().init();
  runApp(const HoopSpotApp());
}
