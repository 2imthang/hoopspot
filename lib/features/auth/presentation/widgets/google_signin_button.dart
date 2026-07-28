import 'package:flutter/material.dart';

/// "Đăng nhập với Google" button used on both Login screens. Draws a plain
/// "G" badge instead of pulling in the real Google logo asset/network image,
/// to keep this dependency-free.
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const GoogleSignInButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 10,
              backgroundColor: Colors.red,
              child: Text(
                'G',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text('Đăng nhập với Google', style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}
