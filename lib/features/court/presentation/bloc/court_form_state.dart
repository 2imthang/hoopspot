part of 'court_form_cubit.dart';

class CourtFormState extends Equatable {
  final List<String> imageUrls;
  final bool uploadingImage;
  final bool submitting;
  final String? errorMessage;

  const CourtFormState({
    this.imageUrls = const [],
    this.uploadingImage = false,
    this.submitting = false,
    this.errorMessage,
  });

  CourtFormState copyWith({
    List<String>? imageUrls,
    bool? uploadingImage,
    bool? submitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CourtFormState(
      imageUrls: imageUrls ?? this.imageUrls,
      uploadingImage: uploadingImage ?? this.uploadingImage,
      submitting: submitting ?? this.submitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [imageUrls, uploadingImage, submitting, errorMessage];
}
