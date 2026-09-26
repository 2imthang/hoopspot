import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/update_profile_usecase.dart';

part 'edit_profile_state.dart';

/// Màn "Thông tin cá nhân" (functional-spec 4.2) — sửa tên/SĐT/ảnh đại
/// diện. Theo đúng mẫu [CourtFormCubit]: state chỉ giữ phần bất đồng bộ
/// (upload ảnh, gửi form), tên/SĐT do trang tự quản qua `TextEditingController`.
class EditProfileCubit extends Cubit<EditProfileState> {
  final UpdateProfileUseCase updateProfileUseCase;
  final ImageUploadService imageUploadService;

  EditProfileCubit({
    required this.updateProfileUseCase,
    required this.imageUploadService,
    String? initialAvatarUrl,
  }) : super(EditProfileState(avatarUrl: initialAvatarUrl));

  Future<void> pickAvatar(File file) async {
    emit(state.copyWith(uploadingAvatar: true, clearError: true));
    final result = await imageUploadService.uploadImage(file);
    result.fold(
      (failure) => emit(state.copyWith(uploadingAvatar: false, errorMessage: failure.message)),
      (url) => emit(state.copyWith(uploadingAvatar: false, avatarUrl: url)),
    );
  }

  /// `null` nghĩa là gửi thất bại (lỗi đã nằm trong state để UI hiện); khác
  /// null nghĩa là thành công, trang gọi nên `Navigator.pop(context, user)`.
  Future<UserEntity?> submit({
    required String displayName,
    required String phone,
  }) async {
    emit(state.copyWith(submitting: true, clearError: true));
    final result = await updateProfileUseCase(
      UpdateProfileParams(displayName: displayName, phone: phone, avatarUrl: state.avatarUrl),
    );
    return result.fold(
      (failure) {
        emit(state.copyWith(submitting: false, errorMessage: failure.message));
        return null;
      },
      (user) {
        emit(state.copyWith(submitting: false));
        return user;
      },
    );
  }
}
