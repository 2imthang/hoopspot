import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/google_auth_result.dart';
import '../../domain/entities/user_entity.dart';
import '../bloc/complete_profile_cubit.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/role_selector.dart';
import 'home_placeholder_page.dart';

/// Shown once, right after a brand-new Google account signs in — Google
/// doesn't ask for role/phone, so we collect them here before creating the
/// `users/{uid}` doc that every other screen assumes exists.
class CompleteGoogleProfilePage extends StatelessWidget {
  final PendingGoogleProfile profile;

  const CompleteGoogleProfilePage({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CompleteProfileCubit>(),
      child: _CompleteGoogleProfileView(profile: profile),
    );
  }
}

class _CompleteGoogleProfileView extends StatefulWidget {
  final PendingGoogleProfile profile;

  const _CompleteGoogleProfileView({required this.profile});

  @override
  State<_CompleteGoogleProfileView> createState() =>
      _CompleteGoogleProfileViewState();
}

class _CompleteGoogleProfileViewState
    extends State<_CompleteGoogleProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  UserRole _role = UserRole.user;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    final digitsOnly = value?.replaceAll(' ', '') ?? '';
    if (!RegExp(r'^0\d{9}$').hasMatch(digitsOnly)) {
      return 'Số điện thoại không hợp lệ (10 số, bắt đầu bằng 0)';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<CompleteProfileCubit>().submit(
      uid: widget.profile.uid,
      email: widget.profile.email,
      displayName: widget.profile.displayName,
      avatarUrl: widget.profile.avatarUrl,
      phone: _phoneController.text.trim(),
      role: _role,
    );
  }

  void _onStateChanged(BuildContext context, CompleteProfileState state) {
    if (state is CompleteProfileFailure) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.message)));
    }
    if (state is CompleteProfileSuccess) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomePlaceholderPage(user: state.user),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<CompleteProfileCubit, CompleteProfileState>(
          listener: _onStateChanged,
          builder: (context, state) {
            final isLoading = state is CompleteProfileLoading;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Form(
                key: _formKey,
                child: _buildForm(context, isLoading),
              ),
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
        const SizedBox(height: 24),
        Text(
          'Hoàn tất hồ sơ',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Chào ${widget.profile.displayName}, cho HoopSpot biết thêm 1 chút nhé',
          style: Theme.of(context).textTheme.bodyMedium,
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
          label: 'Số điện thoại',
          hint: '090 123 4567',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          validator: _validatePhone,
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
                : const Text('Hoàn tất'),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
