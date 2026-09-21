import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../review/presentation/pages/write_review_page.dart';
import '../../domain/entities/booking_entity.dart';
import '../bloc/booking_history_cubit.dart';
import '../widgets/booking_status_badge.dart';

/// TASK-027 — nhúng vào tab "Lịch sử" của [HomePage] (không phải màn hình
/// riêng, giống cách tab "Trang chủ" nhúng thẳng nội dung Home).
class BookingHistoryPage extends StatelessWidget {
  final String userId;

  const BookingHistoryPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BookingHistoryCubit>(param1: userId),
      child: const _BookingHistoryView(),
    );
  }
}

class _BookingHistoryView extends StatelessWidget {
  const _BookingHistoryView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<BookingHistoryCubit, BookingHistoryState>(
      listener: (context, state) {
        if (state is BookingHistoryLoaded && state.message != null) {
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
                'Lịch sử đặt sân',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (state is BookingHistoryLoaded)
              _FilterRow(
                selected: state.filter,
                onSelected: (filter) =>
                    context.read<BookingHistoryCubit>().setFilter(filter),
              ),
            const SizedBox(height: 8),
            Expanded(child: _buildBody(context, state)),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, BookingHistoryState state) {
    if (state is BookingHistoryLoading) {
      return SkeletonList(itemBuilder: () => const SkeletonListCard(), spacing: 12);
    }
    if (state is BookingHistoryError) {
      return ErrorState(
        message: state.message,
        onRetry: () => context.read<BookingHistoryCubit>().retry(),
      );
    }
    final loaded = state as BookingHistoryLoaded;
    if (loaded.items.isEmpty) {
      return const EmptyState(
        message: 'Chưa có booking nào',
        icon: Icons.calendar_month_outlined,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: loaded.items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = loaded.items[index];
        return _BookingCard(
          item: item,
          cancelling: loaded.cancellingBookingId == item.booking.id,
          onCancel: () =>
              context.read<BookingHistoryCubit>().cancelBooking(item.booking.id),
          onWriteReview: () async {
            final cubit = context.read<BookingHistoryCubit>();
            final reviewed = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => WriteReviewPage(
                  bookingId: item.booking.id,
                  courtId: item.booking.courtId,
                  courtName: item.courtName,
                  date: item.booking.date,
                  timeSlot: item.booking.timeSlot,
                ),
              ),
            );
            if (reviewed == true) {
              await cubit.refreshReviewedIds();
            }
          },
        );
      },
    );
  }
}

class _FilterRow extends StatelessWidget {
  final BookingHistoryFilter selected;
  final ValueChanged<BookingHistoryFilter> onSelected;

  const _FilterRow({required this.selected, required this.onSelected});

  static const _labels = {
    BookingHistoryFilter.all: 'Tất cả',
    BookingHistoryFilter.upcoming: 'Sắp tới',
    BookingHistoryFilter.cancelled: 'Đã hủy',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final filter in BookingHistoryFilter.values) ...[
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

class _BookingCard extends StatelessWidget {
  final BookingHistoryItem item;
  final bool cancelling;
  final VoidCallback onCancel;
  final VoidCallback onWriteReview;

  const _BookingCard({
    required this.item,
    required this.cancelling,
    required this.onCancel,
    required this.onWriteReview,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final booking = item.booking;
    final isConfirmed = booking.status == BookingStatus.confirmed;
    final canCancel = isConfirmed && !item.hasSlotEnded;
    final canReview = isConfirmed && item.hasSlotEnded && !item.hasReviewed;

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
                  'Sân ${item.courtName}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              BookingStatusBadge(booking: booking),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${_formatDate(booking.date)} · ${booking.timeSlot} · ${formatVnd(booking.pricePerSlot)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (canCancel) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: cancelling ? null : onCancel,
                child: cancelling
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Hủy đặt sân'),
              ),
            ),
          ],
          if (canReview) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onWriteReview,
                child: const Text('Viết đánh giá'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String yyyyMMdd) {
    final parts = yyyyMMdd.split('-');
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }
}
