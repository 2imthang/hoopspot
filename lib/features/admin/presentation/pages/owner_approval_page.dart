import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../bloc/owner_approval_cubit.dart';
import '../widgets/reject_reason_dialog.dart';

/// TASK-033 — "Duyệt Chủ sân" (chỉ Admin), khớp mockup
/// `docs/screens/owner approval.png`. Mockup gốc dùng tên sân làm tiêu đề
/// thẻ, nhưng Owner CHƯA thể tạo sân khi còn `pending` (phải duyệt trước) và
/// đăng ký không có trường "tên sân" — nên thẻ hiển thị đúng dữ liệu thật có
/// sẵn: họ tên + số điện thoại đã đăng ký.
class OwnerApprovalPage extends StatelessWidget {
  const OwnerApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OwnerApprovalCubit>(),
      child: const _OwnerApprovalView(),
    );
  }
}

class _OwnerApprovalView extends StatelessWidget {
  const _OwnerApprovalView();

  Future<void> _approve(BuildContext context, UserEntity owner) {
    return context.read<OwnerApprovalCubit>().approve(owner.uid);
  }

  Future<void> _reject(BuildContext context, UserEntity owner) async {
    final cubit = context.read<OwnerApprovalCubit>();
    final reason = await showRejectReasonDialog(context);
    if (reason == null || !context.mounted) return;
    await cubit.reject(owner.uid, reason);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<OwnerApprovalCubit, OwnerApprovalState>(
      listener: (context, state) {
        if (state is OwnerApprovalLoaded && state.message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message!)));
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Duyệt Chủ sân',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(child: _buildBody(context, state)),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, OwnerApprovalState state) {
    if (state is OwnerApprovalLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final loaded = state as OwnerApprovalLoaded;
    if (loaded.owners.isEmpty) {
      return const Center(child: Text('Không có Chủ sân nào đang chờ duyệt'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: loaded.owners.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final owner = loaded.owners[index];
        return _OwnerCard(
          owner: owner,
          busy: loaded.busyUid == owner.uid,
          onApprove: () => _approve(context, owner),
          onReject: () => _reject(context, owner),
        );
      },
    );
  }
}

class _OwnerCard extends StatelessWidget {
  final UserEntity owner;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _OwnerCard({
    required this.owner,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  owner.displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Chờ duyệt',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.amber.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            owner.phone,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error),
                  ),
                  child: const Text('Từ chối'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: busy ? null : onApprove,
                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                  child: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Duyệt'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
