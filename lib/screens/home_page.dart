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

extension StringCasingExtension on String {
  String toTitleCase() => this
      .split(' ')
      .map((str) => str.length > 0
          ? '${str[0].toUpperCase()}${str.substring(1).toLowerCase()}'
          : '')
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

class _HomeScreenState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isLoadingAttendance = true;
  String userName = '';
  String? jamMasuk;
  String? jamPulang;
  String? imageUrl;
  AnimationController? _animationController;
  Animation<double>? _pulseAnimation;
  final AttendanceRecapRepository _attendanceRepository =
      AttendanceRecapRepository();
  final _attendanceService = AttendanceService();
  final storage = const FlutterSecureStorage();

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

  // Sample announcement data
  final List<Map<String, String>> announcements = [
    {
      'title': 'Notice of position promotion for "Marsha Lenathea"',
      'subtitle': 'from Jr. UI/UX Designer becomes Sr. UI/UX Designer',
      'sender': 'Kimberly Violon',
      'role': 'Head of HR',
      'attachment': 'Promotion Letter Sr. UI/UX Designer.pdf',
      'avatar': 'assets/images/avatar_hr.jpg',
    },
    {
      'title': 'Notice of position promotion for "Shania Gracia"',
      'subtitle': 'from Jr. Mobile Developer becomes Sr. Mobile Developer',
      'sender': 'Georgina Collaby',
      'role': 'HR Management',
      'attachment': 'Promotion Letter Sr. Mobile Developer.pdf',
      'avatar': 'assets/images/avatar_hr2.jpg',
    },
  ];

  @override
  void initState() {
    super.initState();

    // Initialize animation controller first
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    // Create pulse animation
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    ));

    _loadUserData();
    _loadTodayAttendance();

    // Add listener to attendance service
    _attendanceService.addListener(_loadTodayAttendance);
  }

  @override
  void dispose() {
    // Remove listener when disposing
    _attendanceService.removeListener(_loadTodayAttendance);
    
    _animationController?.dispose();
    super.dispose();
  }

  bool _isLate() {
    if (jamMasuk == null || jamMasuk == '--:--') return false;
    final clockIn = DateFormat('HH:mm').parse(jamMasuk!);
    final targetTime = DateFormat('HH:mm').parse('07:55');
    return clockIn.isAfter(targetTime);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Light gray background
      body: Stack(
        children: [
          // Header Background
          Container(
            height: 280,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(1, 101, 65, 1),
            ),
            child: Stack(
              children: [
                CustomPaint(
                  painter: GeometricPatternPainter(),
                  size: Size(double.infinity, 280),
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
                                    builder: (context) => const NotificationScreen(),
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
              ],
            ),
          ),

          SingleChildScrollView(
            child: Column(
              children: [
                // Profile Section
                Container(
                  padding: const EdgeInsets.fromLTRB(0, 60, 0, 60),
                  child: Column(
                    children: [
                      // Profile Image
                      AnimatedBuilder(
                        animation: _animationController ??
                            AnimationController(vsync: this),
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _isLate()
                                ? _pulseAnimation?.value ?? 1.0
                                : 1.0,
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _isLate()
                                          ? Colors.red.withOpacity(0.8)
                                          : const Color.fromARGB(
                                              255, 212, 212, 212),
                                      width: 4,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/images/avatar_3d.jpg',
                                      fit: BoxFit.cover,
                                      width: 80,
                                      height: 80,
                                    ),
                                  ),
                                ),
                                if (_isLate())
                                  Positioned(
                                    right: -2,
                                    top: -2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.red.withOpacity(0.8),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Text(
                                        'Telat',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 8),
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
                      decoration: const BoxDecoration(
                        color: Colors.white,
                      ),
                      child: const SizedBox(
                        width: double.infinity,
                        height: 130,
                      ),
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
                                        horizontal: 32),
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
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
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
                        ),
                        _buildQuickAction(
                          icon: FluentIcons
                              .calendar_checkmark_24_regular, // Calendar with checkmark for attendance
                          label: 'Kehadiran',
                          color: const Color(0xFF6A1B9A), // Dark Purple
                          onTap: _onKehadiranTap,
                        ),
                        _buildQuickAction(
                          icon: FluentIcons
                              .calendar_cancel_24_regular, // Calendar for time off
                          label: 'Izin',
                          color: const Color(0xFF1565C0), // Dark Blue
                          onTap: () {},
                        ),
                        _buildQuickAction(
                          icon: FluentIcons
                              .mail_inbox_24_regular, // Inbox/approval icon
                          label: 'Persetujuan',
                          color: const Color(0xFFC62828), // Dark Red
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                // Office Announcement Section
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,  // Changed back to white
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AnnouncementListPage(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Lihat Semua',
                                style: TextStyle(
                                  color: Color.fromRGBO(1, 101, 65, 1),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Announcement Cards in ScrollView
                        SizedBox(
                          height: 300, // Fixed height for scroll view
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: announcements.length,
                            itemBuilder: (context, index) => Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 0,
                              color: Colors.white,  // Explicit white background for card
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AnnouncementDetailPage(
                                        announcement: announcements[index],
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Header with avatar
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundImage: AssetImage(
                                              announcements[index]['avatar']!,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  announcements[index]['sender']!,
                                                  style: const TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  announcements[index]['role']!,
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      // Announcement content
                                      Text(
                                        announcements[index]['title']!,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        announcements[index]['subtitle']!,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Attachment
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              FluentIcons.document_pdf_24_regular,
                                              size: 20,
                                              color: Colors.grey[700],
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                announcements[index]['attachment']!,
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 12,
                                                  color: Colors.grey[700],
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
          return const Center(
            child: CircularProgressIndicator(),
          );
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
  }) {
    return InkWell(
      onTap: () {
        // Add haptic feedback for better interaction
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      splashColor: color.withOpacity(0.1),
      highlightColor: color.withOpacity(0.05),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w500,
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
      imageUrl = prefs.getString('image_url');
      _isLoading = false;
    });
  }
}
