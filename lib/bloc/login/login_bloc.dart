import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repository/login_repository.dart';
import '../../services/secure_storage_service.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginRepository loginRepository;
  final _secureStorage = SecureStorageService();

  LoginBloc({required this.loginRepository}) : super(LoginInitial()) {
    on<InitializeLoginData>(_onInitializeLoginData);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<CheckLoginStatus>(_onCheckLoginStatus);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onInitializeLoginData(
    InitializeLoginData event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginInitial());
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());

    try {
      final result = await loginRepository.login(
        email: event.email,
        password: event.password,
        deviceId: event.deviceId,
      );

      if (result['success']) {
        // Mark app as initialized immediately after successful login
        await _secureStorage.markAppInitialized();
        emit(LoginSuccess());
      } else {
        emit(LoginFailure(result['message'] ?? 'Login failed'));
      }
    } catch (e) {
      emit(LoginFailure(e.toString()));
    }
  }

  Future<void> _onCheckLoginStatus(
    CheckLoginStatus event,
    Emitter<LoginState> emit,
  ) async {
    try {
      final isLoggedIn = await loginRepository.isLoggedIn();
      if (isLoggedIn) {
        // If already logged in, ensure app is marked as initialized
        await _secureStorage.markAppInitialized();
      } else {
        emit(LoginInitial());
      }
    } catch (e) {
      emit(LoginFailure(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<LoginState> emit,
  ) async {
    try {
      await loginRepository.logout();
      emit(LoginInitial());
    } catch (e) {
      emit(LoginFailure(e.toString()));
    }
  }
}
