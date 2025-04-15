import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repository/presence_repository.dart';
import 'presence_event.dart';
import 'presence_state.dart';

class PresenceBloc extends Bloc<PresenceEvent, PresenceState> {
  final PresenceRepository presenceRepository;

  PresenceBloc({required this.presenceRepository}) : super(PresenceInitial()) {
    on<InitializePresence>(_onInitializePresence);
    on<CheckInRequested>(_onCheckInRequested);
    on<CheckOutRequested>(_onCheckOutRequested);
    on<CheckLocationPermission>(_onCheckLocationPermission);
    on<VerifyLocation>(_onVerifyLocation);
  }

  Future<void> _onInitializePresence(
    InitializePresence event,
    Emitter<PresenceState> emit,
  ) async {
    try {
      emit(PresenceLoading());
      
      final hasPermission = await presenceRepository.checkLocationPermission();
      if (!hasPermission) {
        emit(const PresenceLocationPermissionDenied(
          'Location permission is required for attendance',
        ));
        return;
      }

      emit(PresenceInitial());
    } catch (e) {
      emit(PresenceError(e.toString()));
    }
  }

  Future<void> _onCheckInRequested(
    CheckInRequested event,
    Emitter<PresenceState> emit,
  ) async {
    try {
      emit(PresenceLoading());

      // First verify location
      final locationVerification = await presenceRepository.verifyLocation(
        event.latitude,
        event.longitude,
      );

      if (!locationVerification['success']) {
        emit(PresenceError(locationVerification['error']));
        return;
      }

      if (!locationVerification['isWithinRadius']) {
        emit(PresenceError('You are not within the allowed radius for check-in'));
        return;
      }

      // Proceed with check-in
      final result = await presenceRepository.checkIn(
        latitude: event.latitude,
        longitude: event.longitude,
        deviceId: event.deviceId,
        imageBase64: event.imageBase64,
      );

      if (result['success']) {
        emit(PresenceCheckInSuccess(
          message: result['message'],
          checkInTime: DateTime.parse(result['checkInTime']),
        ));
      } else {
        emit(PresenceError(result['error']));
      }
    } catch (e) {
      emit(PresenceError(e.toString()));
    }
  }

  Future<void> _onCheckOutRequested(
    CheckOutRequested event,
    Emitter<PresenceState> emit,
  ) async {
    try {
      emit(PresenceLoading());

      // First verify location
      final locationVerification = await presenceRepository.verifyLocation(
        event.latitude,
        event.longitude,
      );

      if (!locationVerification['success']) {
        emit(PresenceError(locationVerification['error']));
        return;
      }

      if (!locationVerification['isWithinRadius']) {
        emit(PresenceError('You are not within the allowed radius for check-out'));
        return;
      }

      // Proceed with check-out
      final result = await presenceRepository.checkOut(
        latitude: event.latitude,
        longitude: event.longitude,
        deviceId: event.deviceId,
        imageBase64: event.imageBase64,
      );

      if (result['success']) {
        emit(PresenceCheckOutSuccess(
          message: result['message'],
          checkOutTime: DateTime.parse(result['checkOutTime']),
        ));
      } else {
        emit(PresenceError(result['error']));
      }
    } catch (e) {
      emit(PresenceError(e.toString()));
    }
  }

  Future<void> _onCheckLocationPermission(
    CheckLocationPermission event,
    Emitter<PresenceState> emit,
  ) async {
    try {
      emit(PresenceLoading());

      final hasPermission = await presenceRepository.checkLocationPermission();
      if (!hasPermission) {
        emit(const PresenceLocationPermissionDenied(
          'Location permission is required for attendance',
        ));
      } else {
        emit(PresenceInitial());
      }
    } catch (e) {
      emit(PresenceError(e.toString()));
    }
  }

  Future<void> _onVerifyLocation(
    VerifyLocation event,
    Emitter<PresenceState> emit,
  ) async {
    try {
      emit(PresenceLoading());

      final result = await presenceRepository.verifyLocation(
        event.latitude,
        event.longitude,
      );

      if (result['success']) {
        emit(PresenceLocationVerified(
          isWithinRadius: result['isWithinRadius'],
          distance: result['distance'],
        ));
      } else {
        emit(PresenceError(result['error']));
      }
    } catch (e) {
      emit(PresenceError(e.toString()));
    }
  }
}
