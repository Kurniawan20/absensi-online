import 'package:equatable/equatable.dart';

abstract class PresenceEvent extends Equatable {
  const PresenceEvent();

  @override
  List<Object?> get props => [];
}

class InitializePresence extends PresenceEvent {}

class CheckInRequested extends PresenceEvent {
  final double latitude;
  final double longitude;
  final String deviceId;
  final String? imageBase64;

  const CheckInRequested({
    required this.latitude,
    required this.longitude,
    required this.deviceId,
    this.imageBase64,
  });

  @override
  List<Object?> get props => [latitude, longitude, deviceId, imageBase64];
}

class CheckOutRequested extends PresenceEvent {
  final double latitude;
  final double longitude;
  final String deviceId;
  final String? imageBase64;

  const CheckOutRequested({
    required this.latitude,
    required this.longitude,
    required this.deviceId,
    this.imageBase64,
  });

  @override
  List<Object?> get props => [latitude, longitude, deviceId, imageBase64];
}

class CheckLocationPermission extends PresenceEvent {}

class VerifyLocation extends PresenceEvent {
  final double latitude;
  final double longitude;

  const VerifyLocation({
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [latitude, longitude];
}

class CaptureImage extends PresenceEvent {}
