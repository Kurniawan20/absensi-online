import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/leave_type.dart';
import '../../models/leave_request.dart';

/// Widget item untuk menampilkan item riwayat pengajuan
class LeaveHistoryItem extends StatelessWidget {
  final LeaveRequest request;
  final VoidCallback? onTap;
  final bool showFullDate;

  const LeaveHistoryItem({
    Key? key,
    required this.request,
    this.onTap,
    this.showFullDate = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy', 'id');
    final startDateStr = dateFormat.format(request.startDate);
    final endDateStr = dateFormat.format(request.endDate);
    
    final dateRangeText = request.totalDays == 1
        ? startDateStr
        : '$startDateStr - $endDateStr';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: request.type.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  request.type.icon,
                  color: request.type.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.type.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            dateRangeText,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontFamily: 'Poppins',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (request.reason.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        request.reason,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Status & Days
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildStatusBadge(request.status),
                  const SizedBox(height: 8),
                  Text(
                    '${request.totalDays} hari',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(LeaveStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.icon,
            size: 12,
            color: status.color,
          ),
          const SizedBox(width: 4),
          Text(
            status.name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: status.color,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}
