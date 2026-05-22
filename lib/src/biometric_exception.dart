import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

enum BiometricErrorCode {
  noBiometricHardware,
  notEnrolled,
  temporaryLockout,
  biometricLockout,
  userCanceled,
  systemCanceled,
  unknown,
}

class BiometricException implements Exception {
  final BiometricErrorCode code;
  final String message;
  final String userMessage;

  BiometricException({
    required this.code,
    required this.message,
    required this.userMessage,
  });

  factory BiometricException.fromPlatformException(PlatformException e) {
    switch (e.code) {
      case auth_error.noBiometricsEnrolled:
        return BiometricException(
          code: BiometricErrorCode.notEnrolled,
          message: e.message ?? '',
          userMessage: 'Belum ada sidik jari tersimpan. Daftarkan di Pengaturan.',
        );
      case auth_error.lockedOut:
        return BiometricException(
          code: BiometricErrorCode.temporaryLockout,
          message: e.message ?? '',
          userMessage: 'Terlalu banyak percobaan gagal. Coba beberapa saat lagi.',
        );
      case auth_error.permanentlyLockedOut:
        return BiometricException(
          code: BiometricErrorCode.biometricLockout,
          message: e.message ?? '',
          userMessage: 'Biometrik terkunci. Buka dengan PIN/Password.',
        );
      case auth_error.notAvailable:
      case auth_error.notEnrolled:
        return BiometricException(
          code: BiometricErrorCode.noBiometricHardware,
          message: e.message ?? '',
          userMessage: 'Perangkat tidak memiliki sensor biometrik atau tidak tersedia.',
        );
      case auth_error.passcodeNotSet:
        return BiometricException(
          code: BiometricErrorCode.unknown,
          message: e.message ?? '',
          userMessage: 'Perangkat tidak memiliki pengaturan keamanan PIN/Password.',
        );
      default:
        return BiometricException(
          code: BiometricErrorCode.unknown,
          message: e.message ?? 'Unknown error',
          userMessage: 'Terjadi kesalahan saat memverifikasi biometrik.',
        );
    }
  }

  bool get isRetryable => code == BiometricErrorCode.userCanceled ||
      code == BiometricErrorCode.systemCanceled ||
      code == BiometricErrorCode.unknown;

  bool get requiresSettings => code == BiometricErrorCode.notEnrolled;

  bool get requiresFallback => code == BiometricErrorCode.noBiometricHardware ||
      code == BiometricErrorCode.biometricLockout;
}
