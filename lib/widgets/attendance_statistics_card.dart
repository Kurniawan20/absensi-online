import 'package:flutter/material.dart';
import '../models/attendance_statistics.dart';

class AttendanceStatisticsCard extends StatelessWidget {
  final AttendanceStatistics statistics;

  const AttendanceStatisticsCard({
    Key? key,
    required this.statistics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildStatisticRow(
              'Total Working Days',
              statistics.totalDays.toString(),
              Icons.calendar_today,
            ),
            _buildStatisticRow(
              'Present Days',
              statistics.presentDays.toString(),
              Icons.check_circle,
              color: Colors.green,
            ),
            _buildStatisticRow(
              'Late Days',
              statistics.lateDays.toString(),
              Icons.access_time,
              color: Colors.orange,
            ),
            _buildStatisticRow(
              'Absent Days',
              statistics.absentDays.toString(),
              Icons.cancel,
              color: Colors.red,
            ),
            const Divider(),
            _buildStatisticRow(
              'Attendance Rate',
              '${(statistics.attendanceRate * 100).toStringAsFixed(1)}%',
              Icons.percent,
              color: _getAttendanceRateColor(statistics.attendanceRate),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticRow(String label, String value, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.grey, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAttendanceRateColor(double rate) {
    if (rate >= 0.9) return Colors.green;
    if (rate >= 0.8) return Colors.orange;
    return Colors.red;
  }
}
