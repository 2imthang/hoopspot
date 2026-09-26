part of 'edit_profile_cubit.dart';

class EditProfileState extends Equatable {
  final String? avatarUrl;
  final bool uploadingAvatar;
  final bool submitting;
  final String? errorMessage;

  const EditProfileState({
    this.avatarUrl,
    this.uploadingAvatar = false,
    this.submitting = false,
    this.errorMessage,
  });

  EditProfileState copyWith({
    String? avatarUrl,
    bool? uploadingAvatar,
    bool? submitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return EditProfileState(
      avatarUrl: avatarUrl ?? this.avatarUrl,
      uploadingAvatar: uploadingAvatar ?? this.uploadingAvatar,
      submitting: submitting ?? this.submitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [avatarUrl, uploadingAvatar, submitting, errorMessage];
}
