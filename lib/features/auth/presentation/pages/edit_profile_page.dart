import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/user_entity.dart';
import '../bloc/edit_profile_cubit.dart';
import '../widgets/auth_text_field.dart';

/// Màn "Thông tin cá nhân" (functional-spec 4.2) — xem/sửa tên, ảnh đại
/// diện, số điện thoại. Trả về [UserEntity] mới qua `Navigator.pop` khi lưu
/// thành công để [ProfilePage] cập nhật lại phần hiển thị.
class EditProfilePage extends StatelessWidget {
  final UserEntity user;

  const EditProfilePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<EditProfileCubit>(param1: user.avatarUrl),
      child: _EditProfileView(user: user),
    );
  }
}

class _EditProfileView extends StatefulWidget {
  final UserEntity user;

  const _EditProfileView({required this.user});

  @override
  State<_EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<_EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.displayName);
    _phoneController = TextEditingController(text: widget.user.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar(BuildContext context) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null || !context.mounted) return;
    context.read<EditProfileCubit>().pickAvatar(File(picked.path));
  }

  String? _validatePhone(String? value) {
    final digitsOnly = value?.replaceAll(' ', '') ?? '';
    if (!RegExp(r'^0\d{9}$').hasMatch(digitsOnly)) {
      return 'Số điện thoại không hợp lệ (10 số, bắt đầu bằng 0)';
    }
    return null;
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    final updated = await context.read<EditProfileCubit>().submit(
      displayName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );
    if (updated != null && context.mounted) {
      Navigator.of(context).pop(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin cá nhân')),
      body: SafeArea(
        child: BlocConsumer<EditProfileCubit, EditProfileState>(
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
                  Center(
                    child: _AvatarPicker(
                      avatarUrl: state.avatarUrl,
                      uploading: state.uploadingAvatar,
                      onTap: state.uploadingAvatar ? null : () => _pickAvatar(context),
                    ),
                  ),
                  const SizedBox(height: 32),
                  AuthTextField(
                    label: 'Họ và tên',
                    hint: 'Nguyễn Văn A',
                    controller: _nameController,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên' : null,
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
                  _ReadOnlyField(label: 'Email', value: widget.user.email),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: state.submitting ? null : () => _submit(context),
                    child: state.submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Lưu thay đổi'),
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

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  final String? avatarUrl;
  final bool uploading;
  final VoidCallback? onTap;

  const _AvatarPicker({required this.avatarUrl, required this.uploading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
            child: uploading
                ? const CircularProgressIndicator(strokeWidth: 2)
                : (avatarUrl == null
                    ? Icon(Icons.person, size: 48, color: theme.colorScheme.onSurfaceVariant)
                    : null),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary,
              child: Icon(Icons.edit, size: 16, color: theme.colorScheme.onPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
