import 'package:equatable/equatable.dart';

abstract class PresenceState extends Equatable {
  const PresenceState();

  @override
  List<Object?> get props => [];
}

class PresenceInitial extends PresenceState {}

class PresenceLoading extends PresenceState {}

class PresenceLocationPermissionDenied extends PresenceState {
  final String message;

  const PresenceLocationPermissionDenied(this.message);

  @override
  List<Object?> get props => [message];
}

class PresenceLocationVerified extends PresenceState {
  final bool isWithinRadius;
  final double distance;

  const PresenceLocationVerified({
    required this.isWithinRadius,
    required this.distance,
  });

  @override
  List<Object?> get props => [isWithinRadius, distance];
}

class PresenceCheckInSuccess extends PresenceState {
  final String message;
  final DateTime checkInTime;

  const PresenceCheckInSuccess({
    required this.message,
    required this.checkInTime,
  });

  @override
  List<Object?> get props => [message, checkInTime];
}

class PresenceCheckOutSuccess extends PresenceState {
  final String message;
  final DateTime checkOutTime;

  const PresenceCheckOutSuccess({
    required this.message,
    required this.checkOutTime,
  });

  @override
  List<Object?> get props => [message, checkOutTime];
}

class PresenceError extends PresenceState {
  final String message;

  const PresenceError(this.message);

  @override
  List<Object?> get props => [message];
}

class PresenceImageCaptured extends PresenceState {
  final String base64Image;

  const PresenceImageCaptured(this.base64Image);

  @override
  List<Object?> get props => [base64Image];
}
