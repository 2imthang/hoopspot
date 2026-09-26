part of 'change_password_cubit.dart';

class ChangePasswordState extends Equatable {
  final bool submitting;
  final String? errorMessage;

  const ChangePasswordState({this.submitting = false, this.errorMessage});

  ChangePasswordState copyWith({
    bool? submitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChangePasswordState(
      submitting: submitting ?? this.submitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [submitting, errorMessage];
}
