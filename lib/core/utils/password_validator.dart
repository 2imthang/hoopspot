/// functional-spec 4.1 — mật khẩu tối thiểu 8 ký tự, có cả chữ và số.
/// Dùng chung cho Đăng ký và Đổi mật khẩu để không lặp lại quy tắc ở 2 nơi.
String? validatePassword(String? value) {
  final password = value ?? '';
  if (password.length < 8) return 'Mật khẩu tối thiểu 8 ký tự';
  final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
  final hasDigit = RegExp(r'\d').hasMatch(password);
  if (!hasLetter || !hasDigit) return 'Mật khẩu phải có cả chữ và số';
  return null;
}
