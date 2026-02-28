import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/leave/leave_bloc.dart';
import '../../bloc/leave/leave_event.dart';
import '../../bloc/leave/leave_state.dart';
import '../../models/leave_type.dart';
import '../../models/leave_request.dart';
import '../../widgets/leave/leave_type_card.dart';
import '../../widgets/leave/leave_summary_card.dart';
import '../../widgets/leave/leave_history_item.dart';
import 'leave_request_form.dart';
import 'leave_history_page.dart';
import 'leave_detail_page.dart';

/// Halaman utama fitur Izin & Cuti
class LeaveMainPage extends StatefulWidget {
  const LeaveMainPage({super.key});

  @override
  State<LeaveMainPage> createState() => _LeaveMainPageState();
}

class _LeaveMainPageState extends State<LeaveMainPage> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    context.read<LeaveBloc>().add(LoadLeaveBalance());
    context.read<LeaveBloc>().add(const LoadRecentRequests());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: BlocConsumer<LeaveBloc, LeaveState>(
        listener: (context, state) {
          if (state is LeaveError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is LeaveLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF016541),
              ),
            );
          }

          if (state is LeaveLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                _loadData();
              },
              color: const Color(0xFF016541),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Saldo Cuti Card
                    if (state.annualLeaveBalance != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: LeaveSummaryCard(
                          balance: state.annualLeaveBalance!,
                        ),
                      ),

                    // Jenis Izin Section
                    _buildLeaveTypesSection(context),

                    const SizedBox(height: 8),

                    // Pengajuan Terbaru Section
                    _buildRecentRequestsSection(context, state),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          }

          // Initial state or error - show loading
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF016541),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF016541),
      elevation: 0,
      centerTitle: true,
      toolbarHeight: 64,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Izin & Cuti',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.history_rounded, color: Colors.white),
          onPressed: () => _navigateToHistory(context),
          tooltip: 'Riwayat',
        ),
      ],
    );
  }

  Widget _buildLeaveTypesSection(BuildContext context) {
    final leaveTypes = [
      LeaveType.cutiTahunan,
      LeaveType.izinPribadi,
      LeaveType.izinSakit,
      LeaveType.cutiMelahirkan,
      LeaveType.cutiMenikah,
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Jenis Izin',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemCount: leaveTypes.length,
            itemBuilder: (context, index) {
              final type = leaveTypes[index];
              return LeaveTypeCard(
                type: type,
                onTap: () => _navigateToRequestForm(context, type),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRequestsSection(BuildContext context, LeaveLoaded state) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pengajuan Terbaru',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  fontFamily: 'Poppins',
                ),
              ),
              TextButton(
                onPressed: () => _navigateToHistory(context),
                child: const Text(
                  'Lihat Semua',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF016541),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (state.recentRequests.isEmpty)
            _buildEmptyState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.recentRequests.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final request = state.recentRequests[index];
                return LeaveHistoryItem(
                  request: request,
                  onTap: () => _navigateToDetail(context, request),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada pengajuan',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajukan izin atau cuti dengan memilih jenis izin di atas',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToRequestForm(BuildContext context, LeaveType type) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LeaveRequestForm(leaveType: type),
      ),
    ).then((_) {
      // Refresh data setelah kembali dari form
      _loadData();
    });
  }

  void _navigateToHistory(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LeaveHistoryPage(),
      ),
    ).then((_) {
      // Refresh data setelah kembali
      _loadData();
    });
  }

  void _navigateToDetail(BuildContext context, LeaveRequest request) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LeaveDetailPage(request: request),
      ),
    ).then((_) {
      // Refresh data setelah kembali
      _loadData();
    });
  }
}
