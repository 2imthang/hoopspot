import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/user_entity.dart';
import '../bloc/account_status_cubit.dart';
import 'login_page.dart';

/// Gate screen shown after login for any account that isn't `active` yet:
/// Owner waiting for Admin approval (`pending`), Owner rejected
/// (`rejected`, can resubmit), or any account `locked` by Admin.
class AccountStatusPage extends StatelessWidget {
  final UserEntity user;

  const AccountStatusPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AccountStatusCubit>(),
      child: _AccountStatusView(user: user),
    );
  }
}

class _AccountStatusView extends StatelessWidget {
  final UserEntity user;

  const _AccountStatusView({required this.user});

  void _onStateChanged(BuildContext context, AccountStatusState state) {
    final messenger = ScaffoldMessenger.of(context);
    if (state is AccountStatusFailure) {
      messenger.showSnackBar(SnackBar(content: Text(state.message)));
    }
    if (state is AccountStatusResubmitted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã nộp lại hồ sơ, vui lòng chờ duyệt')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AccountStatusPage(user: state.user),
        ),
      );
    }
    if (state is AccountStatusSignedOut) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AccountStatusCubit, AccountStatusState>(
          listener: _onStateChanged,
          builder: (context, state) {
            final isBusy = state is AccountStatusLoading;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ..._content(context),
                  const SizedBox(height: 32),
                  if (user.status == UserStatus.rejected)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: isBusy
                            ? null
                            : () => context.read<AccountStatusCubit>().resubmit(),
                        child: isBusy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Nộp lại hồ sơ'),
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: isBusy
                        ? null
                        : () => context.read<AccountStatusCubit>().signOut(),
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

  List<Widget> _content(BuildContext context) {
    switch (user.status) {
      case UserStatus.pending:
        return [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.amber.shade100,
            child: const Icon(
              Icons.access_time_rounded,
              size: 36,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Hồ sơ đang chờ duyệt',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Tài khoản Chủ sân của bạn đang được Admin xem xét. '
            'Thời gian duyệt thường trong vòng 24 giờ.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ];
      case UserStatus.rejected:
        return [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.red.shade100,
            child: const Icon(
              Icons.close_rounded,
              size: 36,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Hồ sơ bị từ chối',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lý do từ chối',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.rejectReason?.isNotEmpty == true
                      ? user.rejectReason!
                      : 'Admin không cung cấp lý do cụ thể.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ];
      case UserStatus.locked:
        return [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.red.shade100,
            child: const Icon(
              Icons.lock_outline_rounded,
              size: 36,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Tài khoản đã bị khóa',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Tài khoản của bạn đã bị khóa. Vui lòng liên hệ hỗ trợ để biết thêm chi tiết.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ];
      case UserStatus.active:
        return const [];
    }
  }
}
