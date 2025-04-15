import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repository/home_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository homeRepository;

  HomeBloc({required this.homeRepository}) : super(HomeInitial()) {
    on<LoadHomeData>(_onLoadHomeData);
    on<LoadUserProfile>(_onLoadUserProfile);
    on<LoadAttendanceStatus>(_onLoadAttendanceStatus);
    on<LoadAnnouncements>(_onLoadAnnouncements);
    on<LoadBlogPosts>(_onLoadBlogPosts);
    on<RefreshHomeData>(_onRefreshHomeData);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLoadHomeData(
    LoadHomeData event,
    Emitter<HomeState> emit,
  ) async {
    try {
      emit(HomeLoading());

      final userProfile = await homeRepository.getUserProfile();
      final attendanceStatus = await homeRepository.getAttendanceStatus();
      final announcements = await homeRepository.getAnnouncements();
      final blogResult = await homeRepository.getBlogPosts();

      emit(HomeLoadSuccess(
        userProfile: userProfile,
        attendanceStatus: attendanceStatus,
        announcements: announcements,
        blogPosts: blogResult['posts'],
        hasMorePosts: blogResult['hasMore'],
      ));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> _onLoadUserProfile(
    LoadUserProfile event,
    Emitter<HomeState> emit,
  ) async {
    try {
      if (state is HomeLoadSuccess) {
        final currentState = state as HomeLoadSuccess;
        emit(HomeLoading());

        final userProfile = await homeRepository.getUserProfile();

        emit(currentState.copyWith(userProfile: userProfile));
      }
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> _onLoadAttendanceStatus(
    LoadAttendanceStatus event,
    Emitter<HomeState> emit,
  ) async {
    try {
      if (state is HomeLoadSuccess) {
        final currentState = state as HomeLoadSuccess;
        emit(HomeLoading());

        final attendanceStatus = await homeRepository.getAttendanceStatus();

        emit(currentState.copyWith(attendanceStatus: attendanceStatus));
      }
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> _onLoadAnnouncements(
    LoadAnnouncements event,
    Emitter<HomeState> emit,
  ) async {
    try {
      if (state is HomeLoadSuccess) {
        final currentState = state as HomeLoadSuccess;
        emit(HomeLoading());

        final announcements = await homeRepository.getAnnouncements();

        emit(currentState.copyWith(announcements: announcements));
      }
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> _onLoadBlogPosts(
    LoadBlogPosts event,
    Emitter<HomeState> emit,
  ) async {
    try {
      if (state is HomeLoadSuccess) {
        final currentState = state as HomeLoadSuccess;
        final blogResult = await homeRepository.getBlogPosts(
          page: event.page,
          limit: event.limit,
        );

        final updatedPosts = event.page == 1
            ? blogResult['posts']
            : [...currentState.blogPosts, ...blogResult['posts']];

        emit(currentState.copyWith(
          blogPosts: updatedPosts,
          hasMorePosts: blogResult['hasMore'],
        ));
      }
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> _onRefreshHomeData(
    RefreshHomeData event,
    Emitter<HomeState> emit,
  ) async {
    try {
      if (state is HomeLoadSuccess) {
        final userProfile = await homeRepository.getUserProfile();
        final attendanceStatus = await homeRepository.getAttendanceStatus();
        final announcements = await homeRepository.getAnnouncements();
        final blogResult = await homeRepository.getBlogPosts();

        emit(HomeLoadSuccess(
          userProfile: userProfile,
          attendanceStatus: attendanceStatus,
          announcements: announcements,
          blogPosts: blogResult['posts'],
          hasMorePosts: blogResult['hasMore'],
        ));
      }
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<HomeState> emit,
  ) async {
    try {
      await homeRepository.logout();
      emit(HomeInitial());
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }
}
