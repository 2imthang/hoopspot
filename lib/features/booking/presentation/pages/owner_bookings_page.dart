import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/booking_entity.dart';
import '../bloc/owner_bookings_cubit.dart';
import 'rain_cancel_confirmation_page.dart';

/// TASK-032 — tab "Đặt sân của khách" (chỉ Owner), khớp mockup
/// `docs/screens/owner bookings.png`. Không có nút xác nhận/từ chối thanh
/// toán — xem doc comment [OwnerBookingsCubit] vì sao.
class OwnerBookingsPage extends StatelessWidget {
  final String ownerId;

  const OwnerBookingsPage({super.key, required this.ownerId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OwnerBookingsCubit>(param1: ownerId),
      child: const _OwnerBookingsView(),
    );
  }
}

class _OwnerBookingsView extends StatelessWidget {
  const _OwnerBookingsView();

  Future<void> _openRainCancel(BuildContext context, OwnerBookingsItem item) async {
    final cubit = context.read<OwnerBookingsCubit>();
    final confirmed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RainCancelConfirmationPage(
          ownerId: cubit.ownerId,
          courtName: item.courtName,
          customerName: item.booking.userName,
          booking: item.booking,
        ),
      ),
    );
    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã hủy do mưa, hoàn tiền cho khách')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<OwnerBookingsCubit, OwnerBookingsState>(
      listener: (context, state) {
        if (state is OwnerBookingsLoaded && state.message != null) {
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
                'Đặt sân của khách',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            if (state is OwnerBookingsLoaded)
              _FilterRow(
                selected: state.filter,
                onSelected: (filter) => context.read<OwnerBookingsCubit>().setFilter(filter),
              ),
            const SizedBox(height: 8),
            Expanded(child: _buildBody(context, state)),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, OwnerBookingsState state) {
    if (state is OwnerBookingsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final loaded = state as OwnerBookingsLoaded;
    if (loaded.items.isEmpty) {
      return const Center(child: Text('Chưa có booking nào'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: loaded.items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = loaded.items[index];
        return _BookingCard(
          item: item,
          busy: loaded.busyBookingId == item.booking.id,
          onRainCancel: () => _openRainCancel(context, item),
        );
      },
    );
  }
}

class _FilterRow extends StatelessWidget {
  final OwnerBookingsFilter selected;
  final ValueChanged<OwnerBookingsFilter> onSelected;

  const _FilterRow({required this.selected, required this.onSelected});

  static const _labels = {
    OwnerBookingsFilter.all: 'Tất cả',
    OwnerBookingsFilter.pendingPayment: 'Chờ xác nhận',
    OwnerBookingsFilter.confirmed: 'Đã xác nhận',
    OwnerBookingsFilter.cancelled: 'Đã hủy',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final filter in OwnerBookingsFilter.values) ...[
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
  final OwnerBookingsItem item;
  final bool busy;
  final VoidCallback onRainCancel;

  const _BookingCard({required this.item, required this.busy, required this.onRainCancel});

  String _formatDate(String yyyyMMdd) {
    final parts = yyyyMMdd.split('-');
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final booking = item.booking;

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
                  '${booking.userName} · ${item.courtName}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _StatusBadge(booking: booking),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${_formatDate(booking.date)} · ${booking.timeSlot} · ${formatVnd(booking.pricePerSlot)}'
            '${booking.cancelReason == 'rain' ? ' · Hủy do mưa' : ''}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (item.canRainCancel) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: busy ? null : onRainCancel,
                style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
                child: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Hủy do mưa'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final BookingEntity booking;

  const _StatusBadge({required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color) = switch (booking.status) {
      BookingStatus.pendingPayment => ('Chờ xác nhận', Colors.amber),
      BookingStatus.confirmed => ('Đã xác nhận', Colors.green),
      BookingStatus.completed => ('Hoàn thành', theme.colorScheme.primary),
      BookingStatus.cancelled => booking.refundStatus == 'refunded'
          ? ('Đã hoàn tiền', Colors.blue)
          : ('Đã hủy', theme.colorScheme.error),
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
