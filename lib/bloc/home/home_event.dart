import 'package:equatable/equatable.dart';
import '../../models/blog_post.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadHomeData extends HomeEvent {}

class LoadUserProfile extends HomeEvent {}

class LoadAttendanceStatus extends HomeEvent {}

class LoadAnnouncements extends HomeEvent {}

/// Event untuk load blog posts dengan optional category filter
class LoadBlogPosts extends HomeEvent {
  final BlogCategory? category;
  final int limit;

  const LoadBlogPosts({
    this.category,
    this.limit = 10,
  });

  @override
  List<Object?> get props => [category, limit];
}

/// Event untuk load featured blogs (untuk carousel/banner)
class LoadFeaturedBlogs extends HomeEvent {
  final int limit;

  const LoadFeaturedBlogs({this.limit = 5});

  @override
  List<Object?> get props => [limit];
}

class RefreshHomeData extends HomeEvent {}

class LogoutRequested extends HomeEvent {}
