import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadHomeData extends HomeEvent {}

class LoadUserProfile extends HomeEvent {}

class LoadAttendanceStatus extends HomeEvent {}

class LoadAnnouncements extends HomeEvent {}

class LoadBlogPosts extends HomeEvent {
  final int page;
  final int limit;

  const LoadBlogPosts({
    this.page = 1,
    this.limit = 10,
  });

  @override
  List<Object?> get props => [page, limit];
}

class RefreshHomeData extends HomeEvent {}

class LogoutRequested extends HomeEvent {}
