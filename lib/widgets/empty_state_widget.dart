import 'package:flutter/material.dart';

/// Empty state widget for when there's no data
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onActionPressed;
  final String? actionLabel;

  const EmptyStateWidget({
    Key? key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.iconColor,
    this.onActionPressed,
    this.actionLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveIconColor =
        iconColor ?? (isDark ? Colors.grey[600] : Colors.grey[400]);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: effectiveIconColor!.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 60,
                color: effectiveIconColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onActionPressed != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onActionPressed,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Predefined empty states for common scenarios
class EmptyStates {
  static Widget noData({VoidCallback? onRetry}) => EmptyStateWidget(
        title: 'Tidak Ada Data',
        subtitle: 'Belum ada data yang tersedia',
        icon: Icons.inbox_outlined,
        onActionPressed: onRetry,
        actionLabel: 'Muat Ulang',
      );

  static Widget noAttendance() => const EmptyStateWidget(
        title: 'Belum Ada Kehadiran',
        subtitle: 'Anda belum melakukan absen hari ini',
        icon: Icons.calendar_today_outlined,
        iconColor: Color.fromRGBO(1, 101, 65, 1),
      );

  static Widget noNotifications() => const EmptyStateWidget(
        title: 'Tidak Ada Notifikasi',
        subtitle: 'Anda tidak memiliki notifikasi baru',
        icon: Icons.notifications_none_outlined,
      );

  static Widget noSearchResults(String query) => EmptyStateWidget(
        title: 'Tidak Ditemukan',
        subtitle: 'Tidak ada hasil untuk "$query"',
        icon: Icons.search_off_outlined,
      );

  static Widget networkError({VoidCallback? onRetry}) => EmptyStateWidget(
        title: 'Koneksi Bermasalah',
        subtitle: 'Periksa koneksi internet Anda',
        icon: Icons.wifi_off_outlined,
        iconColor: Colors.orange,
        onActionPressed: onRetry,
        actionLabel: 'Coba Lagi',
      );

  static Widget locationError({VoidCallback? onRetry}) => EmptyStateWidget(
        title: 'Lokasi Tidak Tersedia',
        subtitle: 'Aktifkan GPS untuk melanjutkan',
        icon: Icons.location_off_outlined,
        iconColor: Colors.red,
        onActionPressed: onRetry,
        actionLabel: 'Coba Lagi',
      );
}
