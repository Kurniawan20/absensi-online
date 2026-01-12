import 'package:flutter/foundation.dart';

/// Manages user session timeout based on inactivity
class SessionManager {
  static DateTime? _lastActivity;
  static const int _timeoutMinutes = 30; // Session timeout after 30 minutes of inactivity
  
  /// Update the last activity timestamp
  static void updateActivity() {
    _lastActivity = DateTime.now();
    if (kDebugMode) {
      print('Session activity updated: $_lastActivity');
    }
  }
  
  /// Check if the session has expired due to inactivity
  static bool isSessionExpired() {
    if (_lastActivity == null) {
      // No activity recorded yet, session is valid
      return false;
    }
    
    final difference = DateTime.now().difference(_lastActivity!);
    final isExpired = difference.inMinutes >= _timeoutMinutes;
    
    if (kDebugMode) {
      print('Session check - Last activity: $_lastActivity');
      print('Time since last activity: ${difference.inMinutes} minutes');
      print('Session expired: $isExpired');
    }
    
    return isExpired;
  }
  
  /// Get remaining session time in minutes
  static int getRemainingMinutes() {
    if (_lastActivity == null) return _timeoutMinutes;
    
    final difference = DateTime.now().difference(_lastActivity!);
    final remaining = _timeoutMinutes - difference.inMinutes;
    return remaining > 0 ? remaining : 0;
  }
  
  /// Reset session (clear last activity)
  static void resetSession() {
    _lastActivity = null;
    if (kDebugMode) {
      print('Session reset');
    }
  }
  
  /// Initialize session with current time
  static void initializeSession() {
    _lastActivity = DateTime.now();
    if (kDebugMode) {
      print('Session initialized: $_lastActivity');
    }
  }
  
  /// Get timeout duration in minutes
  static int getTimeoutMinutes() => _timeoutMinutes;
}
