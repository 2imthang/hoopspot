import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import 'login_page.dart';

/// Temporary landing screen once login succeeds. Real Home (search/filter,
/// TASK-013) and Splash-based routing (TASK-008) will replace this.
class HomePlaceholderPage extends StatelessWidget {
  final UserEntity user;

  const HomePlaceholderPage({super.key, required this.user});

  Future<void> _signOut(BuildContext context) async {
    await sl<SignOutUseCase>()(const NoParams());
    if (!context.mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Xin chào, ${user.displayName} 👋',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${user.email} · ${user.role.name} · ${user.status.name}',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () => _signOut(context),
                  child: const Text('Đăng xuất'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
