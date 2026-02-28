import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repository/notification_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository notificationRepository;
  String? _currentNpp;

  NotificationBloc({required this.notificationRepository})
      : super(NotificationInitial()) {
    on<InitializeNotifications>(_onInitializeNotifications);
    on<LoadNotifications>(_onLoadNotifications);
    on<GetUnreadCount>(_onGetUnreadCount);
    on<MarkNotificationAsRead>(_onMarkNotificationAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllNotificationsAsRead);
    on<DeleteNotification>(_onDeleteNotification);
    on<UpdateNotificationPreferences>(_onUpdateNotificationPreferences);
    on<RefreshNotifications>(_onRefreshNotifications);
    on<HandlePushNotification>(_onHandlePushNotification);
    on<RegisterFcmToken>(_onRegisterFcmToken);
    on<UnregisterFcmToken>(_onUnregisterFcmToken);
  }

  Future<void> _onInitializeNotifications(
    InitializeNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await notificationRepository.initializeNotifications();
      // Don't auto-load here - need npp from login first
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      emit(NotificationLoading());
      _currentNpp = event.npp;

      final preferences = await notificationRepository.getNotificationPreferences();
      final result = await notificationRepository.getNotifications(
        npp: event.npp,
        isRead: event.isRead,
        type: event.type,
        perPage: event.perPage,
      );

      // Get unread count
      final unreadCount = await notificationRepository.getUnreadCount(npp: event.npp);

      emit(NotificationsLoadSuccess(
        notifications: result['notifications'],
        preferences: preferences,
        unreadCount: unreadCount,
        hasMore: result['hasMore'] ?? false,
        currentPage: result['currentPage'] ?? 1,
      ));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onGetUnreadCount(
    GetUnreadCount event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final unreadCount = await notificationRepository.getUnreadCount(npp: event.npp);
      
      if (state is NotificationsLoadSuccess) {
        final currentState = state as NotificationsLoadSuccess;
        emit(currentState.copyWith(unreadCount: unreadCount));
      }
    } catch (e) {
      // Don't emit error for unread count fetch failure
      print('Error fetching unread count: $e');
    }
  }

  Future<void> _onMarkNotificationAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      if (state is NotificationsLoadSuccess) {
        final currentState = state as NotificationsLoadSuccess;
        
        await notificationRepository.markNotificationAsRead(event.notificationId);

        final updatedNotifications = currentState.notifications.map((notification) {
          if (notification.id == event.notificationId) {
            return notification.copyWith(
              isRead: true,
              readAt: DateTime.now(),
            );
          }
          return notification;
        }).toList();

        // Recalculate unread count
        final newUnreadCount = updatedNotifications.where((n) => !n.isRead).length;

        emit(currentState.copyWith(
          notifications: updatedNotifications,
          unreadCount: newUnreadCount,
        ));
      }
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onMarkAllNotificationsAsRead(
    MarkAllNotificationsAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      if (state is NotificationsLoadSuccess) {
        final currentState = state as NotificationsLoadSuccess;
        
        await notificationRepository.markAllNotificationsAsRead(npp: event.npp);

        final updatedNotifications = currentState.notifications.map((notification) {
          return notification.copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
        }).toList();

        emit(currentState.copyWith(
          notifications: updatedNotifications,
          unreadCount: 0,
        ));
      }
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onDeleteNotification(
    DeleteNotification event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      if (state is NotificationsLoadSuccess) {
        final currentState = state as NotificationsLoadSuccess;
        
        await notificationRepository.deleteNotification(event.notificationId);

        // Remove from local list
        final updatedNotifications = currentState.notifications
            .where((n) => n.id != event.notificationId)
            .toList();

        // Recalculate unread count
        final newUnreadCount = updatedNotifications.where((n) => !n.isRead).length;

        emit(currentState.copyWith(
          notifications: updatedNotifications,
          unreadCount: newUnreadCount,
        ));
      }
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onUpdateNotificationPreferences(
    UpdateNotificationPreferences event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      if (state is NotificationsLoadSuccess) {
        final currentState = state as NotificationsLoadSuccess;
        
        final preferences = NotificationPreferences(
          pushEnabled: event.pushEnabled,
          emailEnabled: event.emailEnabled,
          attendanceAlerts: event.attendanceAlerts,
          announcementAlerts: event.announcementAlerts,
          scheduleReminders: event.scheduleReminders,
        );

        await notificationRepository.updateNotificationPreferences(preferences);

        emit(currentState.copyWith(preferences: preferences));
        emit(NotificationPreferencesUpdated(preferences));
      }
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onRefreshNotifications(
    RefreshNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      _currentNpp = event.npp;
      
      final preferences = await notificationRepository.getNotificationPreferences();
      final result = await notificationRepository.getNotifications(
        npp: event.npp,
        perPage: 20,
      );
      final unreadCount = await notificationRepository.getUnreadCount(npp: event.npp);

      emit(NotificationsLoadSuccess(
        notifications: result['notifications'],
        preferences: preferences,
        unreadCount: unreadCount,
        hasMore: result['hasMore'] ?? false,
        currentPage: 1,
      ));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onHandlePushNotification(
    HandlePushNotification event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final title = event.payload['title'] as String? ?? '';
      final body = event.payload['body'] as String? ?? '';
      final data = event.payload['data'] as Map<String, dynamic>?;

      await notificationRepository.showLocalNotification(
        title: title,
        body: body,
        payload: data != null ? json.encode(data) : null,
      );

      // Refresh notifications list if we have npp
      if (_currentNpp != null) {
        add(RefreshNotifications(npp: _currentNpp!));
      }
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onRegisterFcmToken(
    RegisterFcmToken event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await notificationRepository.registerFcmToken(
        npp: event.npp,
        fcmToken: event.fcmToken,
        deviceId: event.deviceId,
      );
      _currentNpp = event.npp;
    } catch (e) {
      // Don't emit error state for FCM registration failure
      // Just log it
      print('Error registering FCM token: $e');
    }
  }

  Future<void> _onUnregisterFcmToken(
    UnregisterFcmToken event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await notificationRepository.unregisterFcmToken(fcmToken: event.fcmToken);
      _currentNpp = null;
    } catch (e) {
      // Don't emit error state for FCM unregistration failure
      // Just log it
      print('Error unregistering FCM token: $e');
    }
  }
}
