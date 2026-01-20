import 'package:equatable/equatable.dart';
import '../../models/leave_type.dart';
import '../../models/leave_request.dart';

/// Base class untuk semua Leave States
abstract class LeaveState extends Equatable {
  const LeaveState();

  @override
  List<Object?> get props => [];
}

/// State awal
class LeaveInitial extends LeaveState {}

/// State saat loading data
class LeaveLoading extends LeaveState {
  final String? message;

  const LeaveLoading({this.message});

  @override
  List<Object?> get props => [message];
}

/// State saat data berhasil dimuat
class LeaveLoaded extends LeaveState {
  final LeaveBalance? annualLeaveBalance;
  final LeaveBalance? personalLeaveBalance;
  final LeaveBalance? sickLeaveBalance;
  final List<LeaveRequest> recentRequests;
  final List<LeaveRequest> historyRequests;
  final bool hasMoreHistory;
  final int currentPage;
  final LeaveStatus? currentStatusFilter;
  final LeaveType? currentTypeFilter;

  const LeaveLoaded({
    this.annualLeaveBalance,
    this.personalLeaveBalance,
    this.sickLeaveBalance,
    this.recentRequests = const [],
    this.historyRequests = const [],
    this.hasMoreHistory = false,
    this.currentPage = 1,
    this.currentStatusFilter,
    this.currentTypeFilter,
  });

  @override
  List<Object?> get props => [
        annualLeaveBalance,
        personalLeaveBalance,
        sickLeaveBalance,
        recentRequests,
        historyRequests,
        hasMoreHistory,
        currentPage,
        currentStatusFilter,
        currentTypeFilter,
      ];

  LeaveLoaded copyWith({
    LeaveBalance? annualLeaveBalance,
    LeaveBalance? personalLeaveBalance,
    LeaveBalance? sickLeaveBalance,
    List<LeaveRequest>? recentRequests,
    List<LeaveRequest>? historyRequests,
    bool? hasMoreHistory,
    int? currentPage,
    LeaveStatus? currentStatusFilter,
    LeaveType? currentTypeFilter,
    bool clearStatusFilter = false,
    bool clearTypeFilter = false,
  }) {
    return LeaveLoaded(
      annualLeaveBalance: annualLeaveBalance ?? this.annualLeaveBalance,
      personalLeaveBalance: personalLeaveBalance ?? this.personalLeaveBalance,
      sickLeaveBalance: sickLeaveBalance ?? this.sickLeaveBalance,
      recentRequests: recentRequests ?? this.recentRequests,
      historyRequests: historyRequests ?? this.historyRequests,
      hasMoreHistory: hasMoreHistory ?? this.hasMoreHistory,
      currentPage: currentPage ?? this.currentPage,
      currentStatusFilter:
          clearStatusFilter ? null : (currentStatusFilter ?? this.currentStatusFilter),
      currentTypeFilter:
          clearTypeFilter ? null : (currentTypeFilter ?? this.currentTypeFilter),
    );
  }
}

/// State saat melihat detail pengajuan
class LeaveDetailLoaded extends LeaveState {
  final LeaveRequest request;

  const LeaveDetailLoaded({required this.request});

  @override
  List<Object?> get props => [request];
}

/// State saat sedang submit pengajuan
class LeaveSubmitting extends LeaveState {
  final String message;

  const LeaveSubmitting({this.message = 'Mengirim pengajuan...'});

  @override
  List<Object?> get props => [message];
}

/// State saat submit berhasil
class LeaveSubmitSuccess extends LeaveState {
  final String message;
  final LeaveRequest request;

  const LeaveSubmitSuccess({
    required this.message,
    required this.request,
  });

  @override
  List<Object?> get props => [message, request];
}

/// State saat pembatalan berhasil
class LeaveCancelSuccess extends LeaveState {
  final String message;

  const LeaveCancelSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

/// State saat terjadi error
class LeaveError extends LeaveState {
  final String message;
  final LeaveState? previousState;

  const LeaveError({
    required this.message,
    this.previousState,
  });

  @override
  List<Object?> get props => [message, previousState];
}
