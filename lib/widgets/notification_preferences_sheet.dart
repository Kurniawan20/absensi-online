import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/notification/notification_bloc.dart';
import '../bloc/notification/notification_event.dart';
import '../bloc/notification/notification_state.dart';

class NotificationPreferencesSheet extends StatefulWidget {
  const NotificationPreferencesSheet({super.key});

  @override
  State<NotificationPreferencesSheet> createState() =>
      _NotificationPreferencesSheetState();
}

class _NotificationPreferencesSheetState
    extends State<NotificationPreferencesSheet> {
  late bool _pushEnabled;
  late bool _emailEnabled;
  late bool _attendanceAlerts;
  late bool _announcementAlerts;
  late bool _scheduleReminders;

  @override
  void initState() {
    super.initState();
    final state = context.read<NotificationBloc>().state;
    if (state is NotificationsLoadSuccess) {
      final preferences = state.preferences;
      _pushEnabled = preferences.pushEnabled;
      _emailEnabled = preferences.emailEnabled;
      _attendanceAlerts = preferences.attendanceAlerts;
      _announcementAlerts = preferences.announcementAlerts;
      _scheduleReminders = preferences.scheduleReminders;
    } else {
      _pushEnabled = true;
      _emailEnabled = true;
      _attendanceAlerts = true;
      _announcementAlerts = true;
      _scheduleReminders = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              _buildHandle(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Notification Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'General',
                      children: [
                        _buildSwitchTile(
                          title: 'Push Notifications',
                          subtitle:
                              'Receive notifications on your device',
                          value: _pushEnabled,
                          onChanged: (value) {
                            setState(() => _pushEnabled = value);
                            _updatePreferences();
                          },
                        ),
                        _buildSwitchTile(
                          title: 'Email Notifications',
                          subtitle:
                              'Receive notifications via email',
                          value: _emailEnabled,
                          onChanged: (value) {
                            setState(() => _emailEnabled = value);
                            _updatePreferences();
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    _buildSection(
                      title: 'Notification Types',
                      children: [
                        _buildSwitchTile(
                          title: 'Attendance Alerts',
                          subtitle:
                              'Check-in/out reminders and confirmations',
                          value: _attendanceAlerts,
                          onChanged: _pushEnabled
                              ? (value) {
                                  setState(
                                      () => _attendanceAlerts = value);
                                  _updatePreferences();
                                }
                              : null,
                        ),
                        _buildSwitchTile(
                          title: 'Announcements',
                          subtitle:
                              'Important updates and announcements',
                          value: _announcementAlerts,
                          onChanged: _pushEnabled
                              ? (value) {
                                  setState(() =>
                                      _announcementAlerts = value);
                                  _updatePreferences();
                                }
                              : null,
                        ),
                        _buildSwitchTile(
                          title: 'Schedule Reminders',
                          subtitle:
                              'Upcoming schedule and deadline reminders',
                          value: _scheduleReminders,
                          onChanged: _pushEnabled
                              ? (value) {
                                  setState(
                                      () => _scheduleReminders = value);
                                  _updatePreferences();
                                }
                              : null,
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'Note: Some notifications cannot be disabled as they are essential for the proper functioning of the app.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Container(
      height: 4,
      width: 40,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool)? onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: Theme.of(context).primaryColor,
    );
  }

  void _updatePreferences() {
    context.read<NotificationBloc>().add(
          UpdateNotificationPreferences(
            pushEnabled: _pushEnabled,
            emailEnabled: _emailEnabled,
            attendanceAlerts: _attendanceAlerts,
            announcementAlerts: _announcementAlerts,
            scheduleReminders: _scheduleReminders,
          ),
        );
  }
}
