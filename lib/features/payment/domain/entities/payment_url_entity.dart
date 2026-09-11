import 'package:equatable/equatable.dart';

class PaymentUrlEntity extends Equatable {
  final String paymentUrl;
  final String txnRef;

  const PaymentUrlEntity({required this.paymentUrl, required this.txnRef});

  @override
  List<Object?> get props => [paymentUrl, txnRef];
}
