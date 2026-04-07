import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../repository/home_repository.dart';
import '../bloc/notification/notification_bloc.dart';
import '../bloc/notification/notification_state.dart';
import '../models/blog_post.dart';
import '../models/working_hours.dart';
import './notification_screen.dart';
import './blog_detail_page.dart';
import './blog_list_page.dart';
import '../widgets/skeleton_text.dart';
import 'page_rekap_absensi.dart';
import 'package:intl/intl.dart';

import '../services/attendance_service.dart';
import '../utils/storage_config.dart';
import '../services/avatar_service.dart';
import '../painters/geometric_pattern_painter.dart';

import '../constants/api_constants.dart';

extension StringCasingExtension on String {
  String toTitleCase() => split(' ')
      .map(
        (str) => str.isNotEmpty
            ? '${str[0].toUpperCase()}${str.substring(1).toLowerCase()}'
            : '',
      )
      .join(' ');
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomePage> {
  bool _isLoading = true;
  bool _isLoadingAttendance = true;
  bool _isLoadingBlogs = true;
  bool _isLoadingWorkingHours = true;
  String userName = '';
  String? userNpp;
  String? jamMasuk;
  String? jamPulang;
  String? imageUrl;
  String _selectedAvatar = AvatarService.defaultAvatar;
  List<BlogPost> _blogPosts = [];
  WorkingHours? _workingHours;

  final HomeRepository _homeRepository = HomeRepository();
  final _attendanceService = AttendanceService();
  final storage = StorageConfig.secureStorage;

  // Salam berdasarkan jam — di-cache sekali di initState agar tidak dihitung setiap build()
  late String _greeting;

  String _computeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  // Avatar service instance for listening to changes
  final AvatarService _avatarService = AvatarService();

  // Announcements feature - coming soon

  @override
  void initState() {
    super.initState();

    _greeting = _computeGreeting();
    _loadUserData();
    _loadTodayAttendance();
    _loadSelectedAvatar();
    _loadBlogPosts();
    _loadWorkingHours();
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

  /// Refresh semua data dashboard
  Future<void> _onRefresh() async {
    await Future.wait([
      _loadUserData(),
      _loadTodayAttendance(),
      _loadBlogPosts(),
      _loadWorkingHours(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Light gray background
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: const Color.fromRGBO(1, 101, 65, 1),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Green Header with Profile Section (now scrolls with content)
              Container(
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(1, 101, 65, 1),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: GeometricPatternPainter(),
                      ),
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
                                  color: Colors.white.withValues(alpha: 0.1),
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
                                    TextSpan(text: '$_greeting, '),
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
                                    color: Colors.white.withValues(alpha: 0.8),
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
                            color: Colors.black.withValues(alpha: 0.08),
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
                            _isLoadingWorkingHours
                                ? const SkeletonText(
                                    width: 150,
                                    height: 16,
                                  )
                                : Text(
                                    _workingHours != null
                                        ? 'Jam Kerja : ${_workingHours!.endJamMasuk ?? _workingHours!.startJamMasuk} - ${_workingHours!.startJamPulang}'
                                        : 'Jam Kerja : --:-- - --:--',
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
              // Blog/Announcement Section
              _buildBlogSection(),
            ],
          ),
        ),
      ),
    );
  }

  void _onKehadiranTap() async {
    try {
      // Langsung ambil token dan NPP, tidak perlu loading spinner 
      // karena akses SharedPreferences/SecureStorage berlangsung instan
      final token = await storage.read(key: 'auth_token');
      final prefs = await SharedPreferences.getInstance();
      final npp = prefs.getString('npp');

      if (!mounted) return;

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi anda telah berakhir. Silakan login kembali.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Navigate to RekapAbsensi
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
      splashColor:
          isDisabled ? Colors.transparent : color.withValues(alpha: 0.1),
      highlightColor:
          isDisabled ? Colors.transparent : color.withValues(alpha: 0.05),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        width: (MediaQuery.of(context).size.width - 48) / 4,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: isDisabled
                    ? []
                    : [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
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
      if (!mounted) return;
      if (data['success']) {
        setState(() {
          jamMasuk = data['check_in_time'];
          jamPulang = data['check_out_time'];
          _isLoadingAttendance = false;
        });
      } else {
        setState(() {
          _isLoadingAttendance = false;
        });
      }
    } catch (e) {
      print('Error loading today attendance: $e');
      if (!mounted) return;
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

  // ==================== WORKING HOURS METHODS ====================

  Future<void> _loadWorkingHours() async {
    if (!mounted) return;
    setState(() {
      _isLoadingWorkingHours = true;
    });

    try {
      final workingHours = await _homeRepository.getActiveWorkingHours();
      if (!mounted) return;
      setState(() {
        _workingHours = workingHours;
        _isLoadingWorkingHours = false;
      });
    } catch (e) {
      print('Error loading working hours: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingWorkingHours = false;
      });
    }
  }

  // ==================== BLOG METHODS ====================

  Future<void> _loadBlogPosts() async {
    if (!mounted) return;
    setState(() {
      _isLoadingBlogs = true;
    });

    try {
      final posts = await _homeRepository.getBlogPosts(limit: 5);
      if (!mounted) return;

      // Sort posts: pinned first, then by published date
      posts.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        if (a.publishedAt != null && b.publishedAt != null) {
          return b.publishedAt!.compareTo(a.publishedAt!);
        }
        return 0;
      });

      // Take only first 5 after sorting
      final displayPosts = posts.take(5).toList();

      setState(() {
        _blogPosts = displayPosts;
        _isLoadingBlogs = false;
      });
    } catch (e) {
      print('Error loading blog posts: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingBlogs = false;
      });
    }
  }

  Widget _buildBlogSection() {
    return Container(
      decoration: const BoxDecoration(color: Colors.white),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with "See All" button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text(
                      'Pengumuman',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.campaign_rounded,
                      size: 22,
                      color: Color.fromRGBO(1, 101, 65, 1),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BlogListPage(),
                      ),
                    );
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lihat Semua',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color.fromRGBO(1, 101, 65, 1),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Color.fromRGBO(1, 101, 65, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Blog Posts
            _isLoadingBlogs
                ? _buildBlogSkeleton()
                : _blogPosts.isEmpty
                    ? _buildEmptyBlogState()
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _blogPosts.length,
                        itemBuilder: (context, index) {
                          return _buildBlogCard(_blogPosts[index]);
                        },
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlogSkeleton() {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, 2),
                blurRadius: 4,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              const SkeletonText(
                width: 80,
                height: 80,
                borderRadius: 8,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonText(
                      height: 16,
                      width: double.infinity,
                      borderRadius: 4,
                    ),
                    SizedBox(height: 8),
                    SkeletonText(
                      height: 12,
                      width: 150,
                      borderRadius: 4,
                    ),
                    SizedBox(height: 8),
                    SkeletonText(
                      height: 12,
                      width: 100,
                      borderRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyBlogState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
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
            'Belum Ada Pengumuman',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pengumuman kantor akan tampil di sini',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlogCard(BlogPost post) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlogDetailPage(
              blogId: post.id,
              title: post.title,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, 2),
              blurRadius: 4,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: post.imageThumbnail != null || post.image != null
                  ? CachedNetworkImage(
                      imageUrl:
                          _getBlogImageUrl(post.imageThumbnail ?? post.image!),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 80,
                        height: 80,
                        color: _getBlogCategoryColor(post.category)
                            .withValues(alpha: 0.1),
                        child: Icon(
                          _getBlogCategoryIcon(post.category),
                          color: _getBlogCategoryColor(post.category),
                          size: 32,
                        ),
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _getBlogCategoryColor(post.category)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getBlogCategoryIcon(post.category),
                        color: _getBlogCategoryColor(post.category),
                        size: 32,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category and Pinned Badges
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getBlogCategoryColor(post.category)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          post.category.displayName,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _getBlogCategoryColor(post.category),
                          ),
                        ),
                      ),
                      if (post.isPinned)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                FluentIcons.pin_16_filled,
                                size: 10,
                                color: Colors.amber[700],
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Pinned',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Title
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Date and views
                  Row(
                    children: [
                      Icon(
                        FluentIcons.calendar_16_regular,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        post.publishedAt != null
                            ? DateFormat('dd MMM yyyy')
                                .format(post.publishedAt!)
                            : '-',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      if (post.viewCount > 0) ...[
                        const SizedBox(width: 12),
                        Icon(
                          FluentIcons.eye_16_regular,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.viewCount}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              FluentIcons.chevron_right_16_regular,
              size: 20,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  String _getBlogImageUrl(String path) {
    if (path.startsWith('http')) return path;

    // Hapus hanya sufiks '/api' di akhir baseUrl, bukan semua kemunculannya
    final rawBase = ApiConstants.baseUrl;
    final storageBase = rawBase.endsWith('/api')
        ? rawBase.substring(0, rawBase.length - 4)
        : rawBase;

    return '$storageBase/storage/$path';
  }

  Color _getBlogCategoryColor(BlogCategory category) {
    switch (category) {
      case BlogCategory.announcement:
        return const Color(0xFFE65100);
      case BlogCategory.news:
        return const Color(0xFF1565C0);
      case BlogCategory.event:
        return const Color(0xFF7B1FA2);
      case BlogCategory.info:
        return const Color.fromRGBO(1, 101, 65, 1);
      case BlogCategory.other:
        return Colors.grey;
    }
  }

  IconData _getBlogCategoryIcon(BlogCategory category) {
    switch (category) {
      case BlogCategory.announcement:
        return FluentIcons.megaphone_24_regular;
      case BlogCategory.news:
        return FluentIcons.news_24_regular;
      case BlogCategory.event:
        return FluentIcons.calendar_star_24_regular;
      case BlogCategory.info:
        return FluentIcons.info_24_regular;
      case BlogCategory.other:
        return FluentIcons.document_24_regular;
    }
  }
}
