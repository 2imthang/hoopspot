import '../../domain/entities/payment_url_entity.dart';

class PaymentUrlModel extends PaymentUrlEntity {
  const PaymentUrlModel({required super.paymentUrl, required super.txnRef});

  factory PaymentUrlModel.fromJson(Map<String, dynamic> json) {
    return PaymentUrlModel(
      paymentUrl: json['paymentUrl'] as String,
      txnRef: json['txnRef'] as String,
    );
  }
}
