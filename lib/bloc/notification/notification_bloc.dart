import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repository/notification_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository notificationRepository;

  NotificationBloc({required this.notificationRepository})
      : super(NotificationInitial()) {
    on<InitializeNotifications>(_onInitializeNotifications);
    on<LoadNotifications>(_onLoadNotifications);
    on<MarkNotificationAsRead>(_onMarkNotificationAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllNotificationsAsRead);
    on<DeleteNotification>(_onDeleteNotification);
    on<ClearAllNotifications>(_onClearAllNotifications);
    on<UpdateNotificationPreferences>(_onUpdateNotificationPreferences);
    on<RefreshNotifications>(_onRefreshNotifications);
    on<HandlePushNotification>(_onHandlePushNotification);
  }

  Future<void> _onInitializeNotifications(
    InitializeNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await notificationRepository.initializeNotifications();
      add(LoadNotifications());
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

      final preferences = await notificationRepository.getNotificationPreferences();
      final result = await notificationRepository.getNotifications(
        page: event.page,
        limit: event.limit,
      );

      emit(NotificationsLoadSuccess(
        notifications: result['notifications'],
        preferences: preferences,
        unreadCount: result['unreadCount'],
        hasMore: result['hasMore'],
        currentPage: result['currentPage'],
      ));
    } catch (e) {
      emit(NotificationError(e.toString()));
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
            return NotificationItem(
              id: notification.id,
              title: notification.title,
              message: notification.message,
              type: notification.type,
              timestamp: notification.timestamp,
              isRead: true,
              data: notification.data,
            );
          }
          return notification;
        }).toList();

        emit(currentState.copyWith(
          notifications: updatedNotifications,
          unreadCount: currentState.unreadCount - 1,
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
        
        await notificationRepository.markAllNotificationsAsRead();

        final updatedNotifications = currentState.notifications.map((notification) {
          return NotificationItem(
            id: notification.id,
            title: notification.title,
            message: notification.message,
            type: notification.type,
            timestamp: notification.timestamp,
            isRead: true,
            data: notification.data,
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

        final updatedNotifications = currentState.notifications
            .where((notification) => notification.id != event.notificationId)
            .toList();

        final updatedUnreadCount = updatedNotifications
            .where((notification) => !notification.isRead)
            .length;

        emit(currentState.copyWith(
          notifications: updatedNotifications,
          unreadCount: updatedUnreadCount,
        ));
      }
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onClearAllNotifications(
    ClearAllNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      if (state is NotificationsLoadSuccess) {
        final currentState = state as NotificationsLoadSuccess;
        
        await notificationRepository.clearAllNotifications();

        emit(currentState.copyWith(
          notifications: [],
          unreadCount: 0,
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
      if (state is NotificationsLoadSuccess) {
        final preferences = await notificationRepository.getNotificationPreferences();
        final result = await notificationRepository.getNotifications(
          page: 1,
          limit: 20,
        );

        emit(NotificationsLoadSuccess(
          notifications: result['notifications'],
          preferences: preferences,
          unreadCount: result['unreadCount'],
          hasMore: result['hasMore'],
          currentPage: 1,
        ));
      }
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onHandlePushNotification(
    HandlePushNotification event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final title = event.payload['title'] as String;
      final body = event.payload['body'] as String;
      final data = event.payload['data'] as Map<String, dynamic>?;

      await notificationRepository.showLocalNotification(
        title: title,
        body: body,
        payload: data != null ? json.encode(data) : null,
      );

      // Refresh notifications list
      add(RefreshNotifications());
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }
}
