import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import 'change_password_page.dart';
import 'edit_profile_page.dart';

/// Tab "Cá nhân" (functional-spec 4.2, mockup `docs/screens/profile.png`) —
/// chỉ giữ lại các mục có logic thật đứng sau: "Thông tin cá nhân", "Đổi
/// mật khẩu", "Đăng xuất". Mockup còn có "Phương thức thanh toán"/"Trợ
/// giúp & Hỗ trợ"/"Điều khoản & Chính sách" nhưng không mục nào trong số đó
/// được mô tả trong functional-spec — cố làm sẽ chỉ là nút bấm vào trống
/// rỗng, nên bỏ qua có chủ đích.
class ProfilePage extends StatefulWidget {
  final UserEntity user;
  final VoidCallback onSignOut;

  const ProfilePage({super.key, required this.user, required this.onSignOut});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late UserEntity _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  Future<void> _openEdit(BuildContext context) async {
    final updated = await Navigator.of(context).push<UserEntity>(
      MaterialPageRoute(builder: (_) => EditProfilePage(user: _user)),
    );
    if (updated != null && mounted) setState(() => _user = updated);
  }

  void _openChangePassword(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ChangePasswordPage()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canChangePassword = sl<AuthRepository>().isPasswordAccount();
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(theme),
            const SizedBox(height: 24),
            _MenuTile(
              icon: Icons.person_outline,
              label: 'Thông tin cá nhân',
              onTap: () => _openEdit(context),
            ),
            if (canChangePassword)
              _MenuTile(
                icon: Icons.lock_outline,
                label: 'Đổi mật khẩu',
                onTap: () => _openChangePassword(context),
              ),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: widget.onSignOut,
                child: Text(
                  'Đăng xuất',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: theme.colorScheme.surface,
            backgroundImage: _user.avatarUrl != null ? NetworkImage(_user.avatarUrl!) : null,
            child: _user.avatarUrl == null
                ? Icon(Icons.person, size: 40, color: theme.colorScheme.onSurfaceVariant)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            _user.displayName,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(_user.phone, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
