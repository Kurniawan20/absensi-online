import 'package:equatable/equatable.dart';

abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => [];
}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {
  const LoginSuccess();

  @override
  List<Object?> get props => [];
}

class LoginFailure extends LoginState {
  final String error;

  const LoginFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class LoginLocationError extends LoginState {
  final String error;

  const LoginLocationError(this.error);

  @override
  List<Object?> get props => [error];
}
