import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/skeleton.dart';
import '../bloc/transactions_cubit.dart';

/// TASK-035 — "Giao dịch" (chỉ Admin), khớp mockup
/// `docs/screens/transactions list.png`. Xem doc comment
/// [TransactionsCubit] vì sao dựng từ `bookings` thay vì collection
/// `payments` thật.
class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TransactionsCubit>()..load(),
      child: const _TransactionsView(),
    );
  }
}

class _TransactionsView extends StatelessWidget {
  const _TransactionsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Giao dịch',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _SearchBox(
            onChanged: (value) => context.read<TransactionsCubit>().setQuery(value),
          ),
        ),
        const SizedBox(height: 8),
        BlocBuilder<TransactionsCubit, TransactionsState>(
          buildWhen: (_, state) => state is TransactionsLoaded,
          builder: (context, state) {
            if (state is! TransactionsLoaded) return const SizedBox.shrink();
            return _FilterRow(
              selected: state.filter,
              onSelected: (filter) => context.read<TransactionsCubit>().setFilter(filter),
            );
          },
        ),
        const SizedBox(height: 8),
        Expanded(
          child: BlocBuilder<TransactionsCubit, TransactionsState>(
            builder: (context, state) => _buildBody(context, state),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, TransactionsState state) {
    if (state is TransactionsLoading) {
      return SkeletonList(itemBuilder: () => const SkeletonListCard(), spacing: 12);
    }
    if (state is TransactionsError) {
      return ErrorState(
        message: state.message,
        onRetry: () => context.read<TransactionsCubit>().load(),
      );
    }
    final loaded = state as TransactionsLoaded;
    if (loaded.items.isEmpty) {
      return const EmptyState(
        message: 'Không có giao dịch nào',
        icon: Icons.receipt_long_outlined,
      );
    }
    return RefreshIndicator(
      onRefresh: () => context.read<TransactionsCubit>().load(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: loaded.items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _TransactionCard(item: loaded.items[index]),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _SearchBox({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Tìm theo mã booking / user...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final TransactionFilter selected;
  final ValueChanged<TransactionFilter> onSelected;

  const _FilterRow({required this.selected, required this.onSelected});

  static const _labels = {
    TransactionFilter.all: 'Tất cả',
    TransactionFilter.success: 'Thành công',
    TransactionFilter.refunded: 'Hoàn tiền',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final filter in TransactionFilter.values) ...[
            ChoiceChip(
              label: Text(_labels[filter]!),
              selected: selected == filter,
              onSelected: (_) => onSelected(filter),
              selectedColor: theme.colorScheme.primary,
              labelStyle: TextStyle(
                color: selected == filter
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final TransactionItem item;

  const _TransactionCard({required this.item});

  String _formatDate(String yyyyMMdd) {
    final parts = yyyyMMdd.split('-');
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  String _shortId(String id) => '#${id.length > 8 ? id.substring(0, 8) : id}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final booking = item.booking;
    final refunded = item.status == TransactionStatus.refunded;

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
                  _shortId(booking.id),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              _StatusBadge(status: item.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${booking.userName} · ${item.courtName} · ${_formatDate(booking.date)}'
            '${booking.cancelReason == 'rain' ? ' · Hủy do mưa' : ''}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            refunded
                ? '-${formatVnd(booking.pricePerSlot)}'
                : formatVnd(booking.pricePerSlot),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: refunded ? Colors.blue : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final TransactionStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color) = switch (status) {
      TransactionStatus.success => ('Thành công', Colors.green),
      TransactionStatus.refunded => ('Đã hoàn tiền', Colors.blue),
      TransactionStatus.failed => ('Thất bại', theme.colorScheme.error),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
