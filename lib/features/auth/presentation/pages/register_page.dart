import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/user_entity.dart';
import '../bloc/register_cubit.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/role_selector.dart';
import 'login_page.dart';
import 'verify_email_page.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<RegisterCubit>(),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _role = UserRole.user;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<RegisterCubit>().submit(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      role: _role,
    );
  }

  String? _validateEmail(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Vui lòng nhập email';
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(trimmed)) return 'Email không hợp lệ';
    return null;
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) return 'Không được để trống';
    return null;
  }

  String? _validatePhone(String? value) {
    final digitsOnly = value?.replaceAll(' ', '') ?? '';
    if (!RegExp(r'^0\d{9}$').hasMatch(digitsOnly)) {
      return 'Số điện thoại không hợp lệ (10 số, bắt đầu bằng 0)';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
    return null;
  }

  void _onStateChanged(BuildContext context, RegisterState state) {
    if (state is RegisterFailure) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.message)));
    }
    if (state is RegisterSuccess) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VerifyEmailPage(email: state.user.email),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<RegisterCubit, RegisterState>(
          listener: _onStateChanged,
          builder: (context, state) {
            final isLoading = state is RegisterLoading;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Form(key: _formKey, child: _buildForm(context, isLoading)),
            );
          },
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
        Text(
          'Tạo tài khoản',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Text('Bạn là ai?', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        RoleSelector(
          selectedRole: _role,
          onChanged: (role) => setState(() => _role = role),
        ),
        if (_role == UserRole.owner) ...[
          const SizedBox(height: 8),
          Text(
            'Tài khoản cần được Admin duyệt trước khi sử dụng',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.orange),
          ),
        ],
        const SizedBox(height: 24),
        AuthTextField(
          label: 'Email',
          hint: 'ban@email.com',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          validator: _validateEmail,
          autocorrect: false,
          enableSuggestions: false,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          label: 'Họ và tên',
          hint: 'Nguyễn Văn A',
          controller: _nameController,
          validator: _validateRequired,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          label: 'Số điện thoại',
          hint: '090 123 4567',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          validator: _validatePhone,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          label: 'Mật khẩu',
          hint: '••••••••',
          controller: _passwordController,
          obscureText: true,
          validator: _validatePassword,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: isLoading ? null : _submit,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Tiếp tục'),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginPage()),
            ),
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                children: [
                  const TextSpan(text: 'Đã có tài khoản? '),
                  TextSpan(
                    text: 'Đăng nhập',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
