import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../court/domain/entities/court_entity.dart';
import '../bloc/booking_slots_cubit.dart';
import 'terms_confirmation_page.dart';

/// TASK-018 — chọn ngày + 1 hoặc nhiều "ca" (2 tiếng/ca) rồi giữ slot 10
/// phút qua [BookingSlotsCubit.confirmBooking]. Giữ slot thành công thì
/// chuyển sang màn Xác nhận điều khoản (TASK-024) trước khi vào Thanh toán.
class BookingSlotsPage extends StatelessWidget {
  final CourtEntity court;

  const BookingSlotsPage({super.key, required this.court});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BookingSlotsCubit>(param1: court)
        ..selectDate(DateTime.now()),
      child: _BookingSlotsView(court: court),
    );
  }
}

class _BookingSlotsView extends StatelessWidget {
  final CourtEntity court;

  const _BookingSlotsView({required this.court});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(court.name, overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        top: false,
        child: BlocConsumer<BookingSlotsCubit, BookingSlotsState>(
          listener: (context, state) {
            if (state is! BookingSlotsLoaded) return;
            if (state.message != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message!)),
              );
            }
            if (state.success) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => TermsConfirmationPage(
                    court: court,
                    date: state.date,
                    timeSlots: state.confirmedTimeSlots,
                    bookingIds: state.createdBookingIds,
                    userId: FirebaseAuth.instance.currentUser!.uid,
                  ),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is BookingSlotsError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(state.message, textAlign: TextAlign.center),
                ),
              );
            }
            final loaded = state is BookingSlotsLoaded ? state : null;
            return Column(
              children: [
                _DateStrip(
                  selectedDate: loaded?.date,
                  onDateSelected: (date) =>
                      context.read<BookingSlotsCubit>().selectDate(date),
                ),
                const Divider(height: 1),
                Expanded(
                  child: loaded == null
                      ? const Center(child: CircularProgressIndicator())
                      : _SlotGrid(state: loaded),
                ),
                _BottomBar(
                  pricePerSlot: court.pricePerSlot,
                  selectedCount: loaded?.selectedSlots.length ?? 0,
                  submitting: loaded?.submitting ?? false,
                  onConfirm: loaded == null || loaded.selectedSlots.isEmpty
                      ? null
                      : () => context.read<BookingSlotsCubit>().confirmBooking(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

const _weekdayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

class _DateStrip extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _DateStrip({required this.selectedDate, required this.onDateSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: 14,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final date = startOfToday.add(Duration(days: i));
          final isSelected = selectedDate != null &&
              selectedDate!.year == date.year &&
              selectedDate!.month == date.month &&
              selectedDate!.day == date.day;
          return GestureDetector(
            onTap: () => onDateSelected(date),
            child: Container(
              width: 52,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _weekdayLabels[date.weekday - 1],
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SlotGrid extends StatelessWidget {
  final BookingSlotsLoaded state;

  const _SlotGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.allSlots.isEmpty) {
      return const Center(child: Text('Sân không mở cửa vào ngày này'));
    }
    final cubit = context.read<BookingSlotsCubit>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: state.allSlots.map((slot) {
          final isBooked = state.bookedSlots.contains(slot);
          final isPast = !isBooked && cubit.isPastSlot(state.date, slot);
          final isSelected = state.selectedSlots.contains(slot);
          return _SlotChip(
            label: slot,
            isBooked: isBooked,
            isPast: isPast,
            isSelected: isSelected,
            onTap: state.submitting || isBooked || isPast
                ? null
                : () => cubit.toggleSlot(slot),
          );
        }).toList(),
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  final String label;
  final bool isBooked;
  final bool isPast;
  final bool isSelected;
  final VoidCallback? onTap;

  const _SlotChip({
    required this.label,
    required this.isBooked,
    required this.isPast,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color background;
    Color foreground;
    if (isSelected) {
      background = theme.colorScheme.primary;
      foreground = theme.colorScheme.onPrimary;
    } else if (isBooked || isPast) {
      background = theme.colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.5,
      );
      foreground = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5);
    } else {
      background = theme.colorScheme.surfaceContainerHighest;
      foreground = theme.colorScheme.onSurface;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: foreground,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            decoration: isBooked ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int pricePerSlot;
  final int selectedCount;
  final bool submitting;
  final VoidCallback? onConfirm;

  const _BottomBar({
    required this.pricePerSlot,
    required this.selectedCount,
    required this.submitting,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tổng ($selectedCount ca)', style: theme.textTheme.bodySmall),
                  Text(
                    formatVnd(pricePerSlot * selectedCount),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: submitting ? null : onConfirm,
              child: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Đặt sân'),
            ),
          ],
        ),
      ),
    );
  }
}
