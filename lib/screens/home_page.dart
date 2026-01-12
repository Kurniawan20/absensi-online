import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/attendance_recap_repository.dart';
import '../bloc/notification/notification_bloc.dart';
import '../bloc/notification/notification_state.dart';
import './notification_screen.dart';
import './announcement_list_page.dart';
import './announcement_detail_page.dart';
import '../models/attendance_record.dart';
import '../widgets/skeleton_text.dart';
import 'page_rekap_absensi.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import './attendance_recap_screen.dart';
import '../services/attendance_service.dart';
import '../utils/storage_config.dart';
import '../services/avatar_service.dart';

extension StringCasingExtension on String {
  String toTitleCase() => this
      .split(' ')
      .map(
        (str) => str.length > 0
            ? '${str[0].toUpperCase()}${str.substring(1).toLowerCase()}'
            : '',
      )
      .join(' ');
}

class GeometricPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Create overlapping rectangles
    var path1 = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.7, 0)
      ..lineTo(size.width * 0.5, size.height)
      ..lineTo(0, size.height)
      ..close();

    var path2 = Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.8, size.height)
      ..lineTo(size.width * 0.3, size.height)
      ..close();

    // Draw the paths with different opacities
    canvas.drawPath(path1, paint..color = Colors.black.withOpacity(0.05));
    canvas.drawPath(path2, paint..color = Colors.black.withOpacity(0.07));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomePage> {
  bool _isLoading = true;
  bool _isLoadingAttendance = true;
  String userName = '';
  String? userNpp;
  String? jamMasuk;
  String? jamPulang;
  String? imageUrl;
  String _selectedAvatar = AvatarService.defaultAvatar;
  final AttendanceRecapRepository _attendanceRepository =
      AttendanceRecapRepository();
  final _attendanceService = AttendanceService();
  final storage = StorageConfig.secureStorage;

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Selamat Pagi';
    } else if (hour < 15) {
      return 'Selamat Siang';
    } else if (hour < 18) {
      return 'Selamat Sore';
    } else {
      return 'Selamat Malam';
    }
  }

  // Avatar service instance for listening to changes
  final AvatarService _avatarService = AvatarService();

  // Announcements feature - coming soon

  @override
  void initState() {
    super.initState();

    _loadUserData();
    _loadTodayAttendance();
    _loadSelectedAvatar();

    // Add listener to attendance service
    _attendanceService.addListener(_loadTodayAttendance);

    // Add listener to avatar service for real-time updates
    _avatarService.addListener(_onAvatarChanged);
  }

  @override
  void dispose() {
    // Remove listener when disposing
    _attendanceService.removeListener(_loadTodayAttendance);
    _avatarService.removeListener(_onAvatarChanged);
    super.dispose();
  }

  void _onAvatarChanged() {
    if (mounted) {
      setState(() {
        _selectedAvatar = _avatarService.currentAvatar;
      });
    }
  }

  Future<void> _loadSelectedAvatar() async {
    final avatar = await AvatarService.getSelectedAvatar();
    if (mounted) {
      setState(() {
        _selectedAvatar = avatar;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Light gray background
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Green Header with Profile Section (now scrolls with content)
            Container(
              decoration: const BoxDecoration(
                color: Color.fromRGBO(1, 101, 65, 1),
              ),
              child: Stack(
                children: [
                  CustomPaint(
                    painter: GeometricPatternPainter(),
                    size: const Size(double.infinity, 280),
                  ),
                  // Notification Icon
                  Positioned(
                    top: 40,
                    right: 16,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  FluentIcons.alert_24_regular,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const NotificationScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            // Red dot for unread notifications
                            BlocBuilder<NotificationBloc, NotificationState>(
                              builder: (context, state) {
                                if (state is NotificationsLoadSuccess &&
                                    state.unreadCount > 0) {
                                  return Positioned(
                                    top: 12,
                                    right: 14,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Profile Section (inside the green header)
                  SafeArea(
                    bottom: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 30, 0, 80),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Profile Image
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color.fromARGB(
                                    255,
                                    212,
                                    212,
                                    212,
                                  ),
                                  width: 4,
                                ),
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  _selectedAvatar,
                                  fit: BoxFit.cover,
                                  width: 80,
                                  height: 80,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Greeting Text
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                                children: [
                                  TextSpan(text: '${_getGreeting()}, '),
                                  const TextSpan(text: '👋'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (userNpp != null && userNpp!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                userNpp!,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Stack(
              clipBehavior: Clip.none,
              children: [
                // White Background Card
                Container(
                  decoration: const BoxDecoration(color: Colors.white),
                  child: const SizedBox(width: double.infinity, height: 130),
                ),
                // Attendance Card (Floating)
                Positioned(
                  top: -50,
                  left: 20,
                  right: 20,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          offset: const Offset(0, 4),
                          blurRadius: 16,
                          spreadRadius: -1,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Text(
                            'Kehadiran',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Jam Kerja : 07.45 - 17.00',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Clock Times
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Column(
                                children: [
                                  _isLoadingAttendance
                                      ? const SkeletonText(
                                          width: 80,
                                          height: 24,
                                        )
                                      : Text(
                                          jamMasuk ?? '--:--',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 20,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[800],
                                            letterSpacing: 3,
                                          ),
                                        ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Jam Masuk',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                ),
                                child: Container(
                                  width: 1,
                                  height: 32,
                                  color: Colors.grey[300],
                                ),
                              ),
                              Column(
                                children: [
                                  _isLoadingAttendance
                                      ? const SkeletonText(
                                          width: 80,
                                          height: 24,
                                        )
                                      : Text(
                                          jamPulang ?? '--:--',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 20,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[800],
                                            letterSpacing: 3,
                                          ),
                                        ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Jam Pulang',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            // Quick Actions
            Container(
              decoration: const BoxDecoration(color: Colors.white),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQuickAction(
                      icon: FluentIcons
                          .receipt_24_regular, // Receipt/payroll icon
                      label: 'Gaji Saya',
                      color: const Color(0xFFE65100), // Dark Orange
                      onTap: () {},
                      isDisabled: true,
                    ),
                    _buildQuickAction(
                      icon: FluentIcons
                          .calendar_checkmark_24_regular, // Calendar with checkmark for attendance
                      label: 'Kehadiran',
                      color: const Color.fromRGBO(
                        1,
                        101,
                        65,
                        1,
                      ), // Exact match with Header Green
                      onTap: _onKehadiranTap,
                    ),
                    _buildQuickAction(
                      icon: FluentIcons
                          .calendar_cancel_24_regular, // Calendar for time off
                      label: 'Izin',
                      color: const Color(0xFF1565C0), // Dark Blue
                      onTap: () {},
                      isDisabled: true,
                    ),
                    _buildQuickAction(
                      icon: FluentIcons
                          .mail_inbox_24_regular, // Inbox/approval icon
                      label: 'Persetujuan',
                      color: const Color(0xFFC62828), // Dark Red
                      onTap: () {},
                      isDisabled: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5),
            // Office Announcement Section
            Container(
              decoration: const BoxDecoration(color: Colors.white),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pengumuman Kantor',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Coming Soon Message
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!, width: 1),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            FluentIcons.megaphone_24_regular,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Fitur Segera Hadir',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pengumuman kantor akan tersedia dalam pembaruan mendatang',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onKehadiranTap() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      // Get token and NPP
      final token = await storage.read(key: 'auth_token');
      final prefs = await SharedPreferences.getInstance();
      final npp = prefs.getString('npp');

      // Pop loading dialog
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi anda telah berakhir. Silakan login kembali.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Navigate to RekapAbsensi
      if (!mounted) return;
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return FadeTransition(
              opacity: animation,
              child: RekapAbsensi(id: npp ?? ''),
            );
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      );
    } catch (e) {
      // Pop loading dialog if it's still showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    // Styling for Active vs Disabled state
    final backgroundColor = isDisabled ? Colors.grey[100]! : color;
    final iconColor = isDisabled ? Colors.grey[400]! : Colors.white;
    final textColor = isDisabled ? Colors.grey[500]! : Colors.black87;
    final fontWeight = isDisabled ? FontWeight.w500 : FontWeight.w600;

    return InkWell(
      onTap: isDisabled
          ? null
          : () {
              // Add haptic feedback for better interaction
              HapticFeedback.lightImpact();
              onTap();
            },
      borderRadius: BorderRadius.circular(16),
      splashColor: isDisabled ? Colors.transparent : color.withOpacity(0.1),
      highlightColor: isDisabled ? Colors.transparent : color.withOpacity(0.05),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        width: (MediaQuery.of(context).size.width - 48) /
            4, // Dynamic width: (Screen - Padding) / 4
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 200),
          tween: Tween<double>(begin: 1, end: 1),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(
                        18,
                      ), // Slightly more rounded
                      boxShadow: isDisabled
                          ? []
                          : [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                                spreadRadius: -2,
                              ),
                            ],
                    ),
                    child: Icon(icon, color: iconColor, size: 26),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: textColor,
                      fontWeight: fontWeight,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            );
          },
          onEnd: () {},
        ),
      ),
    );
  }

  Future<void> _loadTodayAttendance() async {
    if (!mounted) return;
    setState(() {
      _isLoadingAttendance = true;
    });

    try {
      final data = await _attendanceService.getTodayAttendance();
      if (data['success']) {
        setState(() {
          jamMasuk = data['check_in_time'];
          jamPulang = data['check_out_time'];
          _isLoadingAttendance = false;
        });
      }
    } catch (e) {
      print('Error loading today attendance: $e');
      setState(() {
        _isLoadingAttendance = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('nama')?.toTitleCase() ?? '';
      userNpp = prefs.getString('npp');
      imageUrl = prefs.getString('image_url');
      _isLoading = false;
    });
  }
}
