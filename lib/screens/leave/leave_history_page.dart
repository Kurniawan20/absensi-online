import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/leave/leave_bloc.dart';
import '../../bloc/leave/leave_event.dart';
import '../../bloc/leave/leave_state.dart';
import '../../models/leave_type.dart';
import '../../models/leave_request.dart';
import '../../widgets/leave/leave_history_item.dart';
import 'leave_detail_page.dart';

/// Helper class untuk filter
class _FilterOption {
  final LeaveStatus? status;
  final String label;

  const _FilterOption(this.status, this.label);
}

/// Halaman riwayat pengajuan izin/cuti
class LeaveHistoryPage extends StatefulWidget {
  const LeaveHistoryPage({super.key});

  @override
  State<LeaveHistoryPage> createState() => _LeaveHistoryPageState();
}

class _LeaveHistoryPageState extends State<LeaveHistoryPage> {
  LeaveStatus? _selectedStatus;
  final ScrollController _scrollController = ScrollController();

  static const List<_FilterOption> _filters = [
    _FilterOption(null, 'Semua'),
    _FilterOption(LeaveStatus.pending, 'Menunggu'),
    _FilterOption(LeaveStatus.approved, 'Disetujui'),
    _FilterOption(LeaveStatus.rejected, 'Ditolak'),
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadHistory({bool refresh = false}) {
    context.read<LeaveBloc>().add(
          LoadLeaveHistory(
            statusFilter: _selectedStatus,
            refresh: refresh,
            page: 1,
          ),
        );
  }

  void _onScroll() {
    final state = context.read<LeaveBloc>().state;
    if (state is LeaveLoaded && state.hasMoreHistory) {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<LeaveBloc>().add(
              LoadLeaveHistory(
                statusFilter: _selectedStatus,
                page: state.currentPage + 1,
              ),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Filter Tabs
          _buildFilterTabs(),
          // List
          Expanded(
            child: BlocBuilder<LeaveBloc, LeaveState>(
              builder: (context, state) {
                if (state is LeaveLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF016541),
                    ),
                  );
                }

                if (state is LeaveLoaded) {
                  if (state.historyRequests.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      _loadHistory(refresh: true);
                    },
                    color: const Color(0xFF016541),
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: state.historyRequests.length +
                          (state.hasMoreHistory ? 1 : 0),
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == state.historyRequests.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                color: Color(0xFF016541),
                              ),
                            ),
                          );
                        }

                        final request = state.historyRequests[index];
                        return LeaveHistoryItem(
                          request: request,
                          showFullDate: true,
                          onTap: () => _navigateToDetail(request),
                        );
                      },
                    ),
                  );
                }

                return _buildEmptyState();
              },
            ),
          ),
        ],
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
        'Riwayat Pengajuan',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _filters.map((filter) {
            final isSelected = _selectedStatus == filter.status;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(filter.label),
                selected: isSelected,
                onSelected: (selected) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedStatus = filter.status;
                  });
                  _loadHistory(refresh: true);
                },
                backgroundColor: Colors.grey[100],
                selectedColor: const Color(0xFF016541).withValues(alpha: 0.15),
                checkmarkColor: const Color(0xFF016541),
                labelStyle: TextStyle(
                  color:
                      isSelected ? const Color(0xFF016541) : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontFamily: 'Poppins',
                  fontSize: 13,
                ),
                side: BorderSide(
                  color:
                      isSelected ? const Color(0xFF016541) : Colors.transparent,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _selectedStatus != null
                ? 'Tidak ada pengajuan ${_selectedStatus!.name.toLowerCase()}'
                : 'Belum ada riwayat pengajuan',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(LeaveRequest request) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LeaveDetailPage(request: request),
      ),
    ).then((_) {
      _loadHistory(refresh: true);
    });
  }
}
