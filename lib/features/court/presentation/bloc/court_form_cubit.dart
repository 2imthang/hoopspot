import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/geocoding_service.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../domain/usecases/create_court_usecase.dart';
import '../../domain/usecases/update_court_usecase.dart';

part 'court_form_state.dart';

/// TASK-031 — dùng chung cho cả Thêm sân mới và Sửa sân (`courtId == null`
/// tức đang tạo mới). Chỉ giữ state cho phần bất đồng bộ (upload ảnh, gửi
/// form) — các field nhập liệu khác (tên, giá, tiện ích...) do
/// [CourtFormPage] tự quản qua `TextEditingController`/state cục bộ, chỉ
/// gom lại đúng lúc gọi [submit].
class CourtFormCubit extends Cubit<CourtFormState> {
  final CreateCourtUseCase createCourtUseCase;
  final UpdateCourtUseCase updateCourtUseCase;
  final ImageUploadService imageUploadService;
  final GeocodingService geocodingService;

  CourtFormCubit({
    required this.createCourtUseCase,
    required this.updateCourtUseCase,
    required this.imageUploadService,
    required this.geocodingService,
    List<String> initialImageUrls = const [],
  }) : super(CourtFormState(imageUrls: initialImageUrls));

  /// Trả về tọa độ tìm được để trang tự di chuyển bản đồ (`MapController`) —
  /// cubit không cầm `LatLng`/`MapController` vì đó là chi tiết UI thuần
  /// túy, không phải state cần lưu lại giữa các lần rebuild.
  Future<GeocodedPoint?> searchAddress(String address) async {
    emit(state.copyWith(geocoding: true, clearError: true));
    final result = await geocodingService.search(address);
    return result.fold(
      (failure) {
        emit(state.copyWith(geocoding: false, errorMessage: failure.message));
        return null;
      },
      (point) {
        emit(state.copyWith(geocoding: false));
        return point;
      },
    );
  }

  Future<void> addImage(File file) async {
    emit(state.copyWith(uploadingImage: true, clearError: true));
    final result = await imageUploadService.uploadImage(file);
    result.fold(
      (failure) => emit(state.copyWith(uploadingImage: false, errorMessage: failure.message)),
      (url) => emit(
        state.copyWith(uploadingImage: false, imageUrls: [...state.imageUrls, url]),
      ),
    );
  }

  void removeImage(String url) {
    emit(state.copyWith(imageUrls: state.imageUrls.where((u) => u != url).toList()));
  }

  /// `null` cho biết gửi thất bại (lỗi đã nằm trong state để UI hiện); `true`
  /// nghĩa là thành công, trang gọi nên `Navigator.pop(context, true)`.
  Future<bool> submit({
    String? courtId,
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    required int pricePerSlot,
    required List<String> amenities,
    required bool isOutdoor,
  }) async {
    emit(state.copyWith(submitting: true, clearError: true));
    final result = courtId == null
        ? await createCourtUseCase(
            CreateCourtParams(
              name: name,
              address: address,
              latitude: latitude,
              longitude: longitude,
              imageUrls: state.imageUrls,
              pricePerSlot: pricePerSlot,
              amenities: amenities,
              isOutdoor: isOutdoor,
            ),
          )
        : await updateCourtUseCase(
            UpdateCourtParams(
              courtId: courtId,
              name: name,
              address: address,
              latitude: latitude,
              longitude: longitude,
              imageUrls: state.imageUrls,
              pricePerSlot: pricePerSlot,
              amenities: amenities,
              isOutdoor: isOutdoor,
            ),
          );
    return result.fold(
      (failure) {
        emit(state.copyWith(submitting: false, errorMessage: failure.message));
        return false;
      },
      (_) {
        emit(state.copyWith(submitting: false));
        return true;
      },
    );
  }
}
