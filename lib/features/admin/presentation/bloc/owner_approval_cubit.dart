import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/usecases/approve_owner_usecase.dart';
import '../../domain/usecases/reject_owner_usecase.dart';
import '../../domain/usecases/watch_pending_owners_usecase.dart';

part 'owner_approval_state.dart';

/// TASK-033 — màn "Duyệt Chủ sân" (chỉ Admin). Danh sách Owner đang
/// `pending`, realtime qua Firestore stream — duyệt xong hoặc từ chối xong,
/// tài khoản tự biến mất khỏi danh sách vì không còn khớp filter
/// `status == pending` nữa, không cần tự cập nhật state thủ công.
class OwnerApprovalCubit extends Cubit<OwnerApprovalState> {
  final WatchPendingOwnersUseCase watchPendingOwnersUseCase;
  final ApproveOwnerUseCase approveOwnerUseCase;
  final RejectOwnerUseCase rejectOwnerUseCase;

  StreamSubscription<List<UserEntity>>? _subscription;

  OwnerApprovalCubit({
    required this.watchPendingOwnersUseCase,
    required this.approveOwnerUseCase,
    required this.rejectOwnerUseCase,
  }) : super(const OwnerApprovalLoading()) {
    _subscribe();
  }

  void _subscribe() {
    _subscription?.cancel();
    _subscription = watchPendingOwnersUseCase().listen(
      (owners) => emit(OwnerApprovalLoaded(owners: owners)),
      onError: (_) => emit(const OwnerApprovalError('Không thể tải danh sách Chủ sân')),
    );
  }

  /// Đăng ký lại stream từ đầu — dùng cho nút "Thử lại" ở [OwnerApprovalError].
  void retry() {
    emit(const OwnerApprovalLoading());
    _subscribe();
  }

  Future<void> approve(String uid) async {
    final current = state;
    if (current is! OwnerApprovalLoaded) return;

    emit(current.copyWith(busyUid: uid, clearMessage: true));
    final result = await approveOwnerUseCase(uid);
    result.fold(
      (failure) => _updateAfterAction(message: failure.message),
      (_) => _updateAfterAction(),
    );
  }

  Future<void> reject(String uid, String reason) async {
    final current = state;
    if (current is! OwnerApprovalLoaded) return;

    emit(current.copyWith(busyUid: uid, clearMessage: true));
    final result = await rejectOwnerUseCase(
      RejectOwnerParams(uid: uid, reason: reason),
    );
    result.fold(
      (failure) => _updateAfterAction(message: failure.message),
      (_) => _updateAfterAction(),
    );
  }

  void _updateAfterAction({String? message}) {
    if (state is! OwnerApprovalLoaded) return;
    emit(
      (state as OwnerApprovalLoaded).copyWith(
        clearBusy: true,
        message: message,
        clearMessage: message == null,
      ),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
