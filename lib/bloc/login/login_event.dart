import 'package:equatable/equatable.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => [];
}

class LoginSubmitted extends LoginEvent {
  final String email;
  final String password;
  final String deviceId;
  final bool isBiometricLogin;

  const LoginSubmitted({
    required this.email,
    required this.password,
    required this.deviceId,
    this.isBiometricLogin = false,
  });

  @override
  List<Object?> get props => [email, password, deviceId, isBiometricLogin];
}

class InitializeLoginData extends LoginEvent {}

class CheckLoginStatus extends LoginEvent {}

class LogoutRequested extends LoginEvent {}
