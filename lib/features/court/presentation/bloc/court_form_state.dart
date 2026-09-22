part of 'court_form_cubit.dart';

class CourtFormState extends Equatable {
  final List<String> imageUrls;
  final bool uploadingImage;
  final bool geocoding;
  final bool submitting;
  final String? errorMessage;

  const CourtFormState({
    this.imageUrls = const [],
    this.uploadingImage = false,
    this.geocoding = false,
    this.submitting = false,
    this.errorMessage,
  });

  CourtFormState copyWith({
    List<String>? imageUrls,
    bool? uploadingImage,
    bool? geocoding,
    bool? submitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CourtFormState(
      imageUrls: imageUrls ?? this.imageUrls,
      uploadingImage: uploadingImage ?? this.uploadingImage,
      geocoding: geocoding ?? this.geocoding,
      submitting: submitting ?? this.submitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      [imageUrls, uploadingImage, geocoding, submitting, errorMessage];
}
