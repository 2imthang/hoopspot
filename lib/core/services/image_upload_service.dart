import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../constants/cloudinary_constants.dart';
import '../error/failures.dart';

/// Shared across features that need to upload a photo (court images now,
/// avatar later) — everything goes to Cloudinary, never Firebase Storage.
abstract class ImageUploadService {
  Future<Either<Failure, String>> uploadImage(File imageFile);
}

class CloudinaryImageUploadService implements ImageUploadService {
  final Dio dio;

  const CloudinaryImageUploadService(this.dio);

  @override
  Future<Either<Failure, String>> uploadImage(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'upload_preset': CloudinaryConstants.uploadPreset,
        'file': await MultipartFile.fromFile(imageFile.path),
      });
      final response = await dio.post<Map<String, dynamic>>(
        CloudinaryConstants.uploadUrl,
        data: formData,
      );
      return Right(response.data!['secure_url'] as String);
    } on DioException catch (e) {
      final message =
          e.response?.data?['error']?['message'] as String? ??
          'Tải ảnh lên thất bại';
      return Left(ServerFailure(message));
    }
  }
}
