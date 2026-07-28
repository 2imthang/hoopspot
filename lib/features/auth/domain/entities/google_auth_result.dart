import 'package:equatable/equatable.dart';
import 'user_entity.dart';

/// Info needed to show the role-selection screen for a Google account that
/// signed in successfully but has no `users/{uid}` Firestore doc yet.
class PendingGoogleProfile extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String? avatarUrl;

  const PendingGoogleProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.avatarUrl,
  });

  @override
  List<Object?> get props => [uid, email, displayName, avatarUrl];
}

/// Result of a Google sign-in attempt. Firebase Auth itself always succeeds
/// once the user picks an account; whether they already have a HoopSpot
/// profile is a separate (Firestore) check reflected here.
class GoogleAuthResult extends Equatable {
  final UserEntity? user;
  final PendingGoogleProfile? pendingProfile;

  const GoogleAuthResult.existingUser(this.user) : pendingProfile = null;

  const GoogleAuthResult.needsRoleSelection(PendingGoogleProfile profile)
    : user = null,
      pendingProfile = profile;

  bool get needsRoleSelection => pendingProfile != null;

  @override
  List<Object?> get props => [user, pendingProfile];
}
