import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../bloc/verify_email_cubit.dart';
import '../navigation/route_after_auth.dart';
import 'login_page.dart';

/// Gate screen shown after register/login when the account's email hasn't
/// been confirmed yet. Visual pattern mirrors the "Owner Pending" screen
/// (icon + title + subtitle + action card) for consistency.
class VerifyEmailPage extends StatelessWidget {
  final String email;

  const VerifyEmailPage({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<VerifyEmailCubit>(),
      child: _VerifyEmailView(email: email),
    );
  }
}

class _VerifyEmailView extends StatelessWidget {
  final String email;

  const _VerifyEmailView({required this.email});

  void _onStateChanged(BuildContext context, VerifyEmailState state) {
    final messenger = ScaffoldMessenger.of(context);
    if (state is VerifyEmailFailure) {
      messenger.showSnackBar(SnackBar(content: Text(state.message)));
    }
    if (state is VerifyEmailNotYet) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Bạn chưa xác nhận email, thử lại sau')),
      );
    }
    if (state is VerifyEmailResent) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã gửi lại email xác nhận')),
      );
    }
    if (state is VerifyEmailVerified) {
      routeAfterAuth(context, state.user);
    }
    if (state is VerifyEmailSignedOut) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<VerifyEmailCubit, VerifyEmailState>(
          listener: _onStateChanged,
          builder: (context, state) {
            final isBusy = state is VerifyEmailChecking;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.orange.shade100,
                    child: const Icon(
                      Icons.mark_email_unread_outlined,
                      size: 36,
                      color: Colors.deepOrange,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Xác nhận email của bạn',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Chúng tôi đã gửi email xác nhận đến $email. '
                    'Vui lòng kiểm tra hộp thư (kể cả mục Spam) rồi bấm nút bên dưới.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isBusy
                          ? null
                          : () => context.read<VerifyEmailCubit>().checkVerified(),
                      child: isBusy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Tôi đã xác nhận'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: isBusy
                        ? null
                        : () => context.read<VerifyEmailCubit>().resend(),
                    child: const Text('Gửi lại email xác nhận'),
                  ),
                  TextButton(
                    onPressed: isBusy
                        ? null
                        : () => context.read<VerifyEmailCubit>().signOut(),
                    child: const Text('Đăng xuất'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
