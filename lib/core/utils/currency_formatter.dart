/// Formats a plain VND integer amount with dot thousand separators,
/// e.g. `250000` -> `"250.000đ"`. Shared across every screen that shows a
/// price (Home/Search now, Court Detail/Booking/Payment later).
String formatVnd(int amount) {
  final digits = amount.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final digitsLeftIncludingThis = digits.length - i;
    buffer.write(digits[i]);
    if (digitsLeftIncludingThis > 1 && digitsLeftIncludingThis % 3 == 1) {
      buffer.write('.');
    }
  }
  return '$bufferđ';
}
