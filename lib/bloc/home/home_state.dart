import 'package:equatable/equatable.dart';
import '../../models/blog_post.dart';

export '../../models/blog_post.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoadSuccess extends HomeState {
  final UserProfile userProfile;
  final AttendanceStatus attendanceStatus;
  final List<Announcement> announcements;
  final List<BlogPost> blogPosts;
  final List<BlogPost> featuredBlogs;
  final bool hasMorePosts;

  const HomeLoadSuccess({
    required this.userProfile,
    required this.attendanceStatus,
    required this.announcements,
    required this.blogPosts,
    this.featuredBlogs = const [],
    this.hasMorePosts = false,
  });

  @override
  List<Object?> get props => [
        userProfile,
        attendanceStatus,
        announcements,
        blogPosts,
        featuredBlogs,
        hasMorePosts,
      ];

  HomeLoadSuccess copyWith({
    UserProfile? userProfile,
    AttendanceStatus? attendanceStatus,
    List<Announcement>? announcements,
    List<BlogPost>? blogPosts,
    List<BlogPost>? featuredBlogs,
    bool? hasMorePosts,
  }) {
    return HomeLoadSuccess(
      userProfile: userProfile ?? this.userProfile,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      announcements: announcements ?? this.announcements,
      blogPosts: blogPosts ?? this.blogPosts,
      featuredBlogs: featuredBlogs ?? this.featuredBlogs,
      hasMorePosts: hasMorePosts ?? this.hasMorePosts,
    );
  }
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}

// Models
class UserProfile {
  final String npp;
  final String nama;
  final String kodeKantor;
  final String namaKantor;
  final String? ketBidang;
  final String? imageUrl;

  UserProfile({
    required this.npp,
    required this.nama,
    required this.kodeKantor,
    required this.namaKantor,
    this.ketBidang,
    this.imageUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      npp: json['npp'] ?? '',
      nama: json['nama'] ?? '',
      kodeKantor: json['kode_kantor'] ?? '',
      namaKantor: json['nama_kantor'] ?? '',
      ketBidang: json['ket_bidang'],
      imageUrl: json['image_url'],
    );
  }
}

class AttendanceStatus {
  final bool hasCheckedIn;
  final bool hasCheckedOut;
  final DateTime? lastCheckIn;
  final DateTime? lastCheckOut;
  final String? status;

  AttendanceStatus({
    required this.hasCheckedIn,
    required this.hasCheckedOut,
    this.lastCheckIn,
    this.lastCheckOut,
    this.status,
  });

  factory AttendanceStatus.fromJson(Map<String, dynamic> json) {
    return AttendanceStatus(
      hasCheckedIn: json['has_checked_in'] ?? false,
      hasCheckedOut: json['has_checked_out'] ?? false,
      lastCheckIn: json['last_check_in'] != null
          ? DateTime.parse(json['last_check_in'])
          : null,
      lastCheckOut: json['last_check_out'] != null
          ? DateTime.parse(json['last_check_out'])
          : null,
      status: json['status'],
    );
  }
}

class Announcement {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final String? imageUrl;
  final bool isImportant;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    this.imageUrl,
    this.isImportant = false,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      imageUrl: json['image_url'],
      isImportant: json['is_important'] ?? false,
    );
  }
}
