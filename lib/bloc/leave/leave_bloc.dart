import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repository/leave_repository.dart';
import '../../models/leave_request.dart';
import 'leave_event.dart';
import 'leave_state.dart';

/// BLoC untuk mengelola state fitur izin/cuti
class LeaveBloc extends Bloc<LeaveEvent, LeaveState> {
  final LeaveRepository leaveRepository;

  LeaveBloc({required this.leaveRepository}) : super(LeaveInitial()) {
    on<LoadLeaveBalance>(_onLoadLeaveBalance);
    on<LoadLeaveHistory>(_onLoadLeaveHistory);
    on<LoadRecentRequests>(_onLoadRecentRequests);
    on<LoadLeaveDetail>(_onLoadLeaveDetail);
    on<SubmitLeaveRequest>(_onSubmitLeaveRequest);
    on<CancelLeaveRequest>(_onCancelLeaveRequest);
    on<RefreshLeaveData>(_onRefreshLeaveData);
    on<ResetLeaveState>(_onResetLeaveState);
  }

  /// Handle load saldo cuti
  Future<void> _onLoadLeaveBalance(
    LoadLeaveBalance event,
    Emitter<LeaveState> emit,
  ) async {
    try {
      // Check if we need to show loading
      if (state is! LeaveLoaded) {
        emit(const LeaveLoading(message: 'Memuat saldo cuti...'));
      }

      final result = await leaveRepository.getLeaveBalance();

      if (result['success']) {
        final data = result['data'];
        final annualBalance = data['annual_leave'] as LeaveBalance;
        final personalBalance = data['personal_leave'] as LeaveBalance;
        final sickBalance = data['sick_leave'] as LeaveBalance;

        // Re-check state right before emitting to avoid race condition
        final latestState = state;
        if (latestState is LeaveLoaded) {
          emit(latestState.copyWith(
            annualLeaveBalance: annualBalance,
            personalLeaveBalance: personalBalance,
            sickLeaveBalance: sickBalance,
          ));
        } else {
          emit(LeaveLoaded(
            annualLeaveBalance: annualBalance,
            personalLeaveBalance: personalBalance,
            sickLeaveBalance: sickBalance,
          ));
        }
      } else {
        final latestState = state;
        emit(LeaveError(
          message: result['message'] ?? 'Gagal memuat saldo cuti',
          previousState: latestState is LeaveLoaded ? latestState : null,
        ));
      }
    } catch (e) {
      emit(LeaveError(message: 'Error: ${e.toString()}'));
    }
  }

  /// Handle load riwayat pengajuan
  Future<void> _onLoadLeaveHistory(
    LoadLeaveHistory event,
    Emitter<LeaveState> emit,
  ) async {
    try {
      final currentState = state;

      if (event.refresh || currentState is! LeaveLoaded) {
        emit(const LeaveLoading(message: 'Memuat riwayat...'));
      }

      final result = await leaveRepository.getLeaveHistory(
        statusFilter: event.statusFilter,
        typeFilter: event.typeFilter,
        page: event.page,
      );

      if (result['success']) {
        final requests = result['data'] as List<LeaveRequest>;
        final hasMore = result['hasMore'] as bool;

        if (currentState is LeaveLoaded && !event.refresh && event.page > 1) {
          // Append to existing list for pagination
          emit(currentState.copyWith(
            historyRequests: [...currentState.historyRequests, ...requests],
            hasMoreHistory: hasMore,
            currentPage: event.page,
            currentStatusFilter: event.statusFilter,
            currentTypeFilter: event.typeFilter,
          ));
        } else {
          // Fresh load or refresh
          if (currentState is LeaveLoaded) {
            emit(currentState.copyWith(
              historyRequests: requests,
              hasMoreHistory: hasMore,
              currentPage: event.page,
              currentStatusFilter: event.statusFilter,
              currentTypeFilter: event.typeFilter,
            ));
          } else {
            emit(LeaveLoaded(
              historyRequests: requests,
              hasMoreHistory: hasMore,
              currentPage: event.page,
              currentStatusFilter: event.statusFilter,
              currentTypeFilter: event.typeFilter,
            ));
          }
        }
      } else {
        emit(LeaveError(
          message: result['message'] ?? 'Gagal memuat riwayat',
          previousState: currentState is LeaveLoaded ? currentState : null,
        ));
      }
    } catch (e) {
      emit(LeaveError(message: 'Error: ${e.toString()}'));
    }
  }

  /// Handle load pengajuan terbaru
  Future<void> _onLoadRecentRequests(
    LoadRecentRequests event,
    Emitter<LeaveState> emit,
  ) async {
    try {
      final result = await leaveRepository.getRecentRequests(limit: event.limit);

      if (result['success']) {
        final requests = result['data'] as List<LeaveRequest>;

        // Re-check state right before emitting to avoid race condition
        final latestState = state;
        if (latestState is LeaveLoaded) {
          emit(latestState.copyWith(recentRequests: requests));
        } else {
          emit(LeaveLoaded(recentRequests: requests));
        }
      }
    } catch (e) {
      // Silent fail for recent requests, don't emit error
      print('Error loading recent requests: $e');
    }
  }

  /// Handle load detail pengajuan
  Future<void> _onLoadLeaveDetail(
    LoadLeaveDetail event,
    Emitter<LeaveState> emit,
  ) async {
    try {
      emit(const LeaveLoading(message: 'Memuat detail...'));

      final result = await leaveRepository.getLeaveDetail(event.id);

      if (result['success']) {
        emit(LeaveDetailLoaded(request: result['data'] as LeaveRequest));
      } else {
        emit(LeaveError(
          message: result['message'] ?? 'Gagal memuat detail',
        ));
      }
    } catch (e) {
      emit(LeaveError(message: 'Error: ${e.toString()}'));
    }
  }

  /// Handle submit pengajuan baru
  Future<void> _onSubmitLeaveRequest(
    SubmitLeaveRequest event,
    Emitter<LeaveState> emit,
  ) async {
    try {
      emit(const LeaveSubmitting());

      final result = await leaveRepository.submitLeaveRequest(
        type: event.type,
        startDate: event.startDate,
        endDate: event.endDate,
        reason: event.reason,
        attachmentPath: event.attachmentPath,
        attachmentName: event.attachmentName,
      );

      if (result['success']) {
        emit(LeaveSubmitSuccess(
          message: result['message'],
          request: result['data'] as LeaveRequest,
        ));
      } else {
        emit(LeaveError(message: result['message'] ?? 'Gagal mengirim pengajuan'));
      }
    } catch (e) {
      emit(LeaveError(message: 'Error: ${e.toString()}'));
    }
  }

  /// Handle pembatalan pengajuan
  Future<void> _onCancelLeaveRequest(
    CancelLeaveRequest event,
    Emitter<LeaveState> emit,
  ) async {
    try {
      final currentState = state;
      emit(const LeaveLoading(message: 'Membatalkan pengajuan...'));

      final result = await leaveRepository.cancelLeaveRequest(event.id);

      if (result['success']) {
        emit(LeaveCancelSuccess(message: result['message']));
      } else {
        emit(LeaveError(
          message: result['message'] ?? 'Gagal membatalkan pengajuan',
          previousState: currentState is LeaveLoaded ? currentState : null,
        ));
      }
    } catch (e) {
      emit(LeaveError(message: 'Error: ${e.toString()}'));
    }
  }

  /// Handle refresh semua data
  Future<void> _onRefreshLeaveData(
    RefreshLeaveData event,
    Emitter<LeaveState> emit,
  ) async {
    try {
      emit(const LeaveLoading(message: 'Memperbarui data...'));

      // Load balance
      final balanceResult = await leaveRepository.getLeaveBalance();
      
      // Load recent requests
      final recentResult = await leaveRepository.getRecentRequests();

      if (balanceResult['success']) {
        final data = balanceResult['data'];
        emit(LeaveLoaded(
          annualLeaveBalance: data['annual_leave'] as LeaveBalance,
          personalLeaveBalance: data['personal_leave'] as LeaveBalance,
          sickLeaveBalance: data['sick_leave'] as LeaveBalance,
          recentRequests: recentResult['success'] 
              ? recentResult['data'] as List<LeaveRequest>
              : [],
        ));
      } else {
        emit(LeaveError(
          message: balanceResult['message'] ?? 'Gagal memperbarui data',
        ));
      }
    } catch (e) {
      emit(LeaveError(message: 'Error: ${e.toString()}'));
    }
  }

  /// Handle reset state
  void _onResetLeaveState(
    ResetLeaveState event,
    Emitter<LeaveState> emit,
  ) {
    emit(LeaveInitial());
  }
}
