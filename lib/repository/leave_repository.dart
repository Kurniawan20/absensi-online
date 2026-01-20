import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/leave_type.dart';
import '../models/leave_request.dart';

/// Repository untuk mengelola data izin/cuti
/// Saat ini menggunakan mock data, akan diganti dengan API calls
class LeaveRepository {
  // Simulated delay untuk mock API calls
  static const Duration _mockDelay = Duration(milliseconds: 800);

  // Mock data storage
  final List<LeaveRequest> _mockRequests = [];
  bool _initialized = false;

  /// Initialize mock data
  Future<void> _initializeMockData() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    final employeeId = prefs.getString('npp') ?? 'EMP001';
    final employeeName = prefs.getString('nama') ?? 'Karyawan';

    // Generate sample leave requests
    _mockRequests.addAll([
      LeaveRequest(
        id: 'LV001',
        type: LeaveType.cutiTahunan,
        startDate: DateTime.now().add(const Duration(days: 7)),
        endDate: DateTime.now().add(const Duration(days: 9)),
        reason: 'Keperluan keluarga',
        status: LeaveStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        employeeId: employeeId,
        employeeName: employeeName,
      ),
      LeaveRequest(
        id: 'LV002',
        type: LeaveType.izinSakit,
        startDate: DateTime.now().subtract(const Duration(days: 5)),
        endDate: DateTime.now().subtract(const Duration(days: 5)),
        reason: 'Demam dan flu',
        status: LeaveStatus.approved,
        createdAt: DateTime.now().subtract(const Duration(days: 6)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        approverName: 'Budi Santoso',
        approverNote: 'Semoga lekas sembuh',
        attachmentName: 'surat_dokter.pdf',
        employeeId: employeeId,
        employeeName: employeeName,
      ),
      LeaveRequest(
        id: 'LV003',
        type: LeaveType.izinPribadi,
        startDate: DateTime.now().subtract(const Duration(days: 15)),
        endDate: DateTime.now().subtract(const Duration(days: 15)),
        reason: 'Mengurus dokumen penting',
        status: LeaveStatus.approved,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now().subtract(const Duration(days: 18)),
        approverName: 'Budi Santoso',
        employeeId: employeeId,
        employeeName: employeeName,
      ),
      LeaveRequest(
        id: 'LV004',
        type: LeaveType.cutiTahunan,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now().subtract(const Duration(days: 28)),
        reason: 'Liburan keluarga',
        status: LeaveStatus.rejected,
        createdAt: DateTime.now().subtract(const Duration(days: 35)),
        updatedAt: DateTime.now().subtract(const Duration(days: 33)),
        approverName: 'Budi Santoso',
        approverNote: 'Mohon maaf, periode tersebut bertepatan dengan deadline project',
        employeeId: employeeId,
        employeeName: employeeName,
      ),
    ]);

    _initialized = true;
  }

  /// Mendapatkan saldo/jatah cuti
  Future<Map<String, dynamic>> getLeaveBalance() async {
    await _initializeMockData();
    await Future.delayed(_mockDelay);

    // Calculate used leave from approved requests
    int usedAnnualLeave = 0;
    int usedPersonalLeave = 0;
    int usedSickLeave = 0;
    int pendingAnnualLeave = 0;

    for (final request in _mockRequests) {
      if (request.status == LeaveStatus.approved) {
        switch (request.type) {
          case LeaveType.cutiTahunan:
            usedAnnualLeave += request.totalDays;
            break;
          case LeaveType.izinPribadi:
            usedPersonalLeave += request.totalDays;
            break;
          case LeaveType.izinSakit:
            usedSickLeave += request.totalDays;
            break;
          default:
            break;
        }
      } else if (request.status == LeaveStatus.pending) {
        if (request.type == LeaveType.cutiTahunan) {
          pendingAnnualLeave += request.totalDays;
        }
      }
    }

    return {
      'success': true,
      'data': {
        'annual_leave': LeaveBalance(
          type: LeaveType.cutiTahunan,
          totalAllowance: 12,
          used: usedAnnualLeave,
          pending: pendingAnnualLeave,
        ),
        'personal_leave': LeaveBalance(
          type: LeaveType.izinPribadi,
          totalAllowance: 3,
          used: usedPersonalLeave,
        ),
        'sick_leave': LeaveBalance(
          type: LeaveType.izinSakit,
          totalAllowance: 14,
          used: usedSickLeave,
        ),
      },
    };
  }

  /// Mendapatkan riwayat pengajuan izin/cuti
  Future<Map<String, dynamic>> getLeaveHistory({
    LeaveStatus? statusFilter,
    LeaveType? typeFilter,
    int page = 1,
    int limit = 10,
  }) async {
    await _initializeMockData();
    await Future.delayed(_mockDelay);

    var filteredRequests = List<LeaveRequest>.from(_mockRequests);

    // Apply filters
    if (statusFilter != null) {
      filteredRequests = filteredRequests
          .where((r) => r.status == statusFilter)
          .toList();
    }
    if (typeFilter != null) {
      filteredRequests = filteredRequests
          .where((r) => r.type == typeFilter)
          .toList();
    }

    // Sort by created date (newest first)
    filteredRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Pagination
    final startIndex = (page - 1) * limit;
    final endIndex = min(startIndex + limit, filteredRequests.length);
    final paginatedRequests = startIndex < filteredRequests.length
        ? filteredRequests.sublist(startIndex, endIndex)
        : <LeaveRequest>[];

    return {
      'success': true,
      'data': paginatedRequests,
      'total': filteredRequests.length,
      'page': page,
      'limit': limit,
      'hasMore': endIndex < filteredRequests.length,
    };
  }

  /// Mendapatkan detail pengajuan
  Future<Map<String, dynamic>> getLeaveDetail(String id) async {
    await _initializeMockData();
    await Future.delayed(_mockDelay);

    final request = _mockRequests.firstWhere(
      (r) => r.id == id,
      orElse: () => throw Exception('Pengajuan tidak ditemukan'),
    );

    return {
      'success': true,
      'data': request,
    };
  }

  /// Submit pengajuan izin/cuti baru
  Future<Map<String, dynamic>> submitLeaveRequest({
    required LeaveType type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    String? attachmentPath,
    String? attachmentName,
  }) async {
    await _initializeMockData();
    await Future.delayed(_mockDelay);

    // Validation
    if (startDate.isAfter(endDate)) {
      return {
        'success': false,
        'message': 'Tanggal mulai tidak boleh setelah tanggal selesai',
      };
    }

    // Check for overlapping requests
    final hasOverlap = _mockRequests.any((r) =>
        r.status != LeaveStatus.rejected &&
        r.status != LeaveStatus.cancelled &&
        !(endDate.isBefore(r.startDate) || startDate.isAfter(r.endDate)));

    if (hasOverlap) {
      return {
        'success': false,
        'message': 'Sudah ada pengajuan di tanggal tersebut',
      };
    }

    // Check leave balance for annual leave
    if (type == LeaveType.cutiTahunan) {
      final balanceResult = await getLeaveBalance();
      final annualBalance =
          balanceResult['data']['annual_leave'] as LeaveBalance;
      final requestedDays = endDate.difference(startDate).inDays + 1;

      if (requestedDays > annualBalance.remaining) {
        return {
          'success': false,
          'message': 'Sisa cuti tahunan tidak mencukupi',
        };
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final employeeId = prefs.getString('npp') ?? 'EMP001';
    final employeeName = prefs.getString('nama') ?? 'Karyawan';

    // Create new request
    final newRequest = LeaveRequest(
      id: 'LV${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      startDate: startDate,
      endDate: endDate,
      reason: reason,
      status: LeaveStatus.pending,
      attachmentPath: attachmentPath,
      attachmentName: attachmentName,
      createdAt: DateTime.now(),
      employeeId: employeeId,
      employeeName: employeeName,
    );

    _mockRequests.insert(0, newRequest);

    return {
      'success': true,
      'message': 'Pengajuan berhasil dikirim',
      'data': newRequest,
    };
  }

  /// Batalkan pengajuan
  Future<Map<String, dynamic>> cancelLeaveRequest(String id) async {
    await _initializeMockData();
    await Future.delayed(_mockDelay);

    final index = _mockRequests.indexWhere((r) => r.id == id);
    if (index == -1) {
      return {
        'success': false,
        'message': 'Pengajuan tidak ditemukan',
      };
    }

    final request = _mockRequests[index];
    if (!request.canBeCancelled) {
      return {
        'success': false,
        'message': 'Pengajuan tidak dapat dibatalkan',
      };
    }

    _mockRequests[index] = request.copyWith(
      status: LeaveStatus.cancelled,
      updatedAt: DateTime.now(),
    );

    return {
      'success': true,
      'message': 'Pengajuan berhasil dibatalkan',
    };
  }

  /// Mendapatkan pengajuan terbaru (untuk dashboard)
  Future<Map<String, dynamic>> getRecentRequests({int limit = 3}) async {
    await _initializeMockData();
    await Future.delayed(const Duration(milliseconds: 500));

    final sortedRequests = List<LeaveRequest>.from(_mockRequests)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return {
      'success': true,
      'data': sortedRequests.take(limit).toList(),
    };
  }
}
