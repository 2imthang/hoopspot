import 'package:flutter/material.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../domain/entities/user_entity.dart';
import '../pages/account_status_page.dart';

/// Single place that decides where to land after any successful auth step
/// (login, email verified, Google profile completed): `active` users go to
/// Home, everyone else (`pending`/`rejected`/`locked`) is blocked on
/// [AccountStatusPage] until Admin approves them or unlocks the account.
void routeAfterAuth(BuildContext context, UserEntity user) {
  final page = user.status == UserStatus.active
      ? HomePage(user: user)
      : AccountStatusPage(user: user);
  Navigator.of(
    context,
  ).pushReplacement(MaterialPageRoute(builder: (_) => page));
}
