import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../bloc/notification/notification_bloc.dart';
import '../bloc/notification/notification_event.dart';
import '../bloc/notification/notification_state.dart';
import './blog_detail_page.dart';
import './page_rekap_absensi.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String? _npp;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    _npp = prefs.getString('npp');
    
    if (_npp != null && mounted) {
      context.read<NotificationBloc>().add(LoadNotifications(npp: _npp!));
    }
  }

  Future<void> _refreshNotifications() async {
    if (_npp != null) {
      context.read<NotificationBloc>().add(RefreshNotifications(npp: _npp!));
    }
  }

  void _markAsRead(int notificationId) {
    context.read<NotificationBloc>().add(MarkNotificationAsRead(notificationId));
  }

  void _markAllAsRead() {
    if (_npp != null) {
      context.read<NotificationBloc>().add(MarkAllNotificationsAsRead(npp: _npp!));
    }
  }

  void _deleteNotification(int notificationId) {
    context.read<NotificationBloc>().add(DeleteNotification(notificationId));
    _showSnackBar('Notifikasi dihapus');
  }

  /// Handle notification tap - navigate based on type
  Future<void> _handleNotificationTap(NotificationItem notification) async {
    final type = notification.type;
    final data = notification.data;

    switch (type) {
      case 'news':
      case 'announcement':
        // Navigate to blog detail
        await _navigateToBlogDetail(data);
        break;
      case 'attendance':
        // Attendance notification (check_in / check_out) - navigate to attendance recap
        _navigateToAttendanceRecap();
        break;
      case 'attendance_success':
      case 'attendance_reminder':
        // Navigate to attendance recap
        _navigateToAttendanceRecap();
        break;
      case 'device_reset_approved':
      case 'device_reset_rejected':
        // Could navigate to device reset status
        _showSnackBar('Notifikasi reset device');
        break;
      default:
        // General notification - just mark as read
        break;
    }
  }

  void _navigateToAttendanceRecap() {
    if (mounted && _npp != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RekapAbsensi(id: _npp!),
        ),
      );
    }
  }

  Future<void> _navigateToBlogDetail(Map<String, dynamic>? data) async {
    if (data == null) {
      _showSnackBar('Data blog tidak tersedia');
      return;
    }

    // Get blog_id from notification data
    final blogIdValue = data['blog_id'] ?? data['id'];

    if (blogIdValue == null) {
      _showSnackBar('ID blog tidak ditemukan');
      return;
    }

    // Parse blog ID
    final blogId = blogIdValue is int ? blogIdValue : int.tryParse(blogIdValue.toString());
    if (blogId == null) {
      _showSnackBar('ID blog tidak valid');
      return;
    }

    // Navigate to blog detail page
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlogDetailPage(blogId: blogId),
        ),
      );
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: const Color(0xFF016541),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              if (state is NotificationsLoadSuccess && state.unreadCount > 0) {
                return TextButton(
                  onPressed: _markAllAsRead,
                  child: const Text(
                    'Tandai Semua Dibaca',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF016541),
              ),
            );
          }

          if (state is NotificationError) {
            return _buildErrorState(state.message);
          }

          if (state is NotificationsLoadSuccess) {
            if (state.notifications.isEmpty) {
              return _buildEmptyState();
            }
            return _buildNotificationList(state.notifications);
          }

          // Initial state - trigger load
          return _buildEmptyState();
        },
      ),
    );
  }

  Widget _buildNotificationList(List<NotificationItem> notifications) {
    return RefreshIndicator(
      onRefresh: _refreshNotifications,
      color: const Color(0xFF016541),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return Dismissible(
            key: Key('notification_${notification.id}'),
            direction: DismissDirection.endToStart,
            confirmDismiss: (direction) async {
              return await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: const Text('Hapus Notifikasi'),
                    content: const Text('Apakah Anda yakin ingin menghapus notifikasi ini?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(
                          'Batal',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Hapus'),
                      ),
                    ],
                  );
                },
              ) ?? false;
            },
            onDismissed: (direction) {
              _deleteNotification(notification.id);
            },
            background: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    FluentIcons.delete_24_filled,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Hapus',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            child: _buildNotificationCard(notification),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    final isUnread = !notification.isRead;
    // Extract action from notification data for attendance type
    final action = notification.data?['action'] as String?;
    final icon = _getNotificationIcon(notification.type, action: action);
    final iconColor = _getNotificationColor(notification.type, action: action);
    final typeLabel = _getNotificationTypeLabel(notification.type, action: action);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isUnread ? Colors.white : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: isUnread
            ? Border.all(color: const Color(0xFF016541).withValues(alpha: 0.3), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (isUnread) {
              _markAsRead(notification.id);
            }
            _handleNotificationTap(notification);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF016541),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            FluentIcons.clock_16_regular,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDateTime(notification.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: iconColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              typeLabel,
                              style: TextStyle(
                                fontSize: 10,
                                color: iconColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _refreshNotifications,
      color: const Color(0xFF016541),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF016541).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    FluentIcons.alert_off_24_filled,
                    size: 64,
                    color: Color(0xFF016541),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Belum ada notifikasi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tarik ke bawah untuk refresh',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              FluentIcons.error_circle_24_filled,
              size: 64,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Gagal memuat notifikasi',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshNotifications,
            icon: const Icon(FluentIcons.arrow_sync_24_regular),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF016541),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(String type, {String? action}) {
    switch (type) {
      case 'attendance':
        // Handle attendance with action (check_in / check_out)
        if (action == 'check_out') {
          return FluentIcons.sign_out_24_filled;
        }
        return FluentIcons.checkmark_circle_24_filled; // check_in default
      case 'attendance_reminder':
        return FluentIcons.clock_alarm_24_filled;
      case 'attendance_success':
        return FluentIcons.checkmark_circle_24_filled;
      case 'device_reset_approved':
        return FluentIcons.checkmark_circle_24_filled;
      case 'device_reset_rejected':
        return FluentIcons.dismiss_circle_24_filled;
      case 'announcement':
        return FluentIcons.megaphone_24_filled;
      case 'news':
        return FluentIcons.news_24_filled;
      default:
        return FluentIcons.alert_24_filled;
    }
  }

  Color _getNotificationColor(String type, {String? action}) {
    switch (type) {
      case 'attendance':
        // Green for check_in, blue for check_out
        if (action == 'check_out') {
          return Colors.blue;
        }
        return const Color(0xFF016541); // check_in default
      case 'attendance_reminder':
        return Colors.orange;
      case 'attendance_success':
        return const Color(0xFF016541);
      case 'device_reset_approved':
        return Colors.blue;
      case 'device_reset_rejected':
        return Colors.red;
      case 'announcement':
        return Colors.purple;
      case 'news':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _getNotificationTypeLabel(String type, {String? action}) {
    switch (type) {
      case 'attendance':
        if (action == 'check_in') {
          return 'Absen Masuk';
        } else if (action == 'check_out') {
          return 'Absen Pulang';
        }
        return 'Absensi';
      case 'attendance_reminder':
        return 'Pengingat';
      case 'attendance_success':
        return 'Absensi';
      case 'device_reset_approved':
        return 'Reset Device';
      case 'device_reset_rejected':
        return 'Reset Device';
      case 'announcement':
        return 'Pengumuman';
      case 'news':
        return 'Berita';
      default:
        return 'Umum';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dateTime);
    }
  }
}
