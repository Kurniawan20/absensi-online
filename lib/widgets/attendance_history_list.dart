import 'package:flutter/material.dart';
import '../models/attendance_record.dart';
import 'package:intl/intl.dart';

class AttendanceHistoryList extends StatelessWidget {
  final List<AttendanceRecord> records;
  final ScrollController scrollController;

  const AttendanceHistoryList({
    super.key,
    required this.records,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Center(
        child: Text('No attendance records found'),
      );
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: ListTile(
            leading: _buildAttendanceIcon(record.type),
            title: Text(
              DateFormat('EEEE, MMMM d, y').format(record.date),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (record.checkInTime != '-')
                  Text('Check-in: ${record.checkInTime}'),
                if (record.checkOutTime != '-')
                  Text('Check-out: ${record.checkOutTime}'),
                Text('Status: ${record.notes}'),
              ],
            ),
            trailing: _buildStatusChip(record.type),
            onTap: () => _showAttendanceDetails(context, record),
          ),
        );
      },
    );
  }

  Widget _buildAttendanceIcon(String type) {
    IconData iconData;
    Color iconColor;

    switch (type.toLowerCase()) {
      case 'present':
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'late':
        iconData = Icons.warning;
        iconColor = Colors.orange;
        break;
      case 'absent':
        iconData = Icons.cancel;
        iconColor = Colors.red;
        break;
      default:
        iconData = Icons.help;
        iconColor = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: iconColor.withValues(alpha: 0.1),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  Widget _buildStatusChip(String type) {
    Color chipColor;
    String label;

    switch (type.toLowerCase()) {
      case 'present':
        chipColor = Colors.green;
        label = 'Hadir';
        break;
      case 'late':
        chipColor = Colors.orange;
        label = 'Telat';
        break;
      case 'absent':
        chipColor = Colors.red;
        label = 'Tidak Hadir';
        break;
      default:
        chipColor = Colors.grey;
        label = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: chipColor,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showAttendanceDetails(BuildContext context, AttendanceRecord record) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE, MMMM d, y').format(record.date),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Check-in', record.checkInTime),
            _buildDetailRow('Check-out', record.checkOutTime),
            if (record.batasJamMasuk != null)
              _buildDetailRow('Batas Masuk', record.batasJamMasuk!),
            _buildDetailRow('Status', record.notes),
            _buildDetailRow('Keterlambatan', record.isLate ? 'Ya' : 'Tidak'),
            const SizedBox(height: 16),
            _buildStatusChip(record.type),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}
