part of 'transactions_cubit.dart';

enum TransactionFilter { all, success, refunded }

/// Trạng thái giao dịch suy ra từ `BookingEntity.status`/`refundStatus` —
/// xem doc comment [TransactionsCubit._deriveStatus].
enum TransactionStatus { success, refunded, failed }

class TransactionItem extends Equatable {
  final BookingEntity booking;
  final String courtName;
  final TransactionStatus status;

  const TransactionItem({
    required this.booking,
    required this.courtName,
    required this.status,
  });

  @override
  List<Object?> get props => [booking, courtName, status];
}

abstract class TransactionsState extends Equatable {
  const TransactionsState();

  @override
  List<Object?> get props => [];
}

class TransactionsLoading extends TransactionsState {
  const TransactionsLoading();
}

class TransactionsError extends TransactionsState {
  final String message;

  const TransactionsError(this.message);

  @override
  List<Object?> get props => [message];
}

class TransactionsLoaded extends TransactionsState {
  final List<TransactionItem> items;
  final TransactionFilter filter;
  final String query;

  const TransactionsLoaded({
    required this.items,
    required this.filter,
    required this.query,
  });

  TransactionsLoaded copyWith({
    List<TransactionItem>? items,
    TransactionFilter? filter,
    String? query,
  }) {
    return TransactionsLoaded(
      items: items ?? this.items,
      filter: filter ?? this.filter,
      query: query ?? this.query,
    );
  }

  @override
  List<Object?> get props => [items, filter, query];
}
