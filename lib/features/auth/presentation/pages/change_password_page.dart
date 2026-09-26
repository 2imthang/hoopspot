import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../bloc/change_password_cubit.dart';
import '../widgets/auth_text_field.dart';

/// Màn "Đổi mật khẩu" (functional-spec 4.2) — riêng biệt với "Thông tin cá
/// nhân", bắt buộc nhập mật khẩu hiện tại (Firebase yêu cầu
/// reauthenticate trước khi đổi mật khẩu vì lý do bảo mật).
class ChangePasswordPage extends StatelessWidget {
  const ChangePasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ChangePasswordCubit>(),
      child: const _ChangePasswordView(),
    );
  }
}

class _ChangePasswordView extends StatefulWidget {
  const _ChangePasswordView();

  @override
  State<_ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<_ChangePasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateNewPassword(String? value) {
    if ((value ?? '').length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _newPasswordController.text) return 'Mật khẩu xác nhận không khớp';
    return null;
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    final success = await context.read<ChangePasswordCubit>().submit(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );
    if (success && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đổi mật khẩu thành công')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đổi mật khẩu')),
      body: SafeArea(
        child: BlocConsumer<ChangePasswordCubit, ChangePasswordState>(
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
            }
          },
          builder: (context, state) {
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  AuthTextField(
                    label: 'Mật khẩu hiện tại',
                    hint: '',
                    controller: _currentPasswordController,
                    obscureText: true,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Vui lòng nhập mật khẩu hiện tại' : null,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    label: 'Mật khẩu mới',
                    hint: 'Tối thiểu 6 ký tự',
                    controller: _newPasswordController,
                    obscureText: true,
                    validator: _validateNewPassword,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    label: 'Xác nhận mật khẩu mới',
                    hint: '',
                    controller: _confirmPasswordController,
                    obscureText: true,
                    validator: _validateConfirmPassword,
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: state.submitting ? null : () => _submit(context),
                    child: state.submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Đổi mật khẩu'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
