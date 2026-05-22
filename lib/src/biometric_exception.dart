import 'package:local_auth/local_auth.dart';

enum BiometricErrorCode {
  noBiometricHardware,  // Tidak ada sensor biometrik di perangkat
  notEnrolled,          // Sensor ada, tapi belum ada data sidik jari/wajah terdaftar
  temporaryLockout,     // Terkunci sementara (terlalu banyak percobaan gagal)
  biometricLockout,     // Terkunci permanen (butuh buka kunci perangkat dengan PIN dulu)
  userCanceled,         // User menekan tombol Batal
  systemCanceled,       // Sistem membatalkan (mis. ada telepon masuk)
  unknown,
}

class BiometricException implements Exception {
  final BiometricErrorCode code;    // kategori error
  final String message;             // pesan teknis (untuk debugging/log)
  final String userMessage;         // pesan untuk ditampilkan ke user

  BiometricException({
    required this.code,
    required this.message,
    required this.userMessage,
  });

  // Constructor dari LocalAuthException (konversi error OS → custom model)
  factory BiometricException.fromLocalAuthException(LocalAuthException e) {
    switch (e.code) {
      case LocalAuthExceptionCode.noBiometricHardware:
        return BiometricException(
          code: BiometricErrorCode.noBiometricHardware,
          message: e.description ?? '',
          userMessage: 'Perangkat tidak memiliki sensor biometrik.',
        );
      case LocalAuthExceptionCode.noBiometricsEnrolled:
        return BiometricException(
          code: BiometricErrorCode.notEnrolled,
          message: e.description ?? '',
          userMessage: 'Belum ada sidik jari tersimpan. Daftarkan di Pengaturan.',
        );
      case LocalAuthExceptionCode.temporaryLockout:
        return BiometricException(
          code: BiometricErrorCode.temporaryLockout,
          message: e.description ?? '',
          userMessage: 'Terlalu banyak percobaan gagal. Coba beberapa saat lagi.',
        );
      case LocalAuthExceptionCode.biometricLockout:
        return BiometricException(
          code: BiometricErrorCode.biometricLockout,
          message: e.description ?? '',
          userMessage: 'Biometrik terkunci. Buka dengan PIN/Password.',
        );
      case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
        return BiometricException(
          code: BiometricErrorCode.noBiometricHardware,
          message: e.description ?? '',
          userMessage: 'Sensor biometrik sementara tidak tersedia.',
        );
      case LocalAuthExceptionCode.noCredentialsSet:
        return BiometricException(
          code: BiometricErrorCode.unknown,
          message: e.description ?? '',
          userMessage: 'Perangkat tidak memiliki pengaturan keamanan PIN/Password.',
        );
      case LocalAuthExceptionCode.userCanceled:
        return BiometricException(
          code: BiometricErrorCode.userCanceled,
          message: e.description ?? '',
          userMessage: 'Autentikasi dibatalkan oleh pengguna.',
        );
      case LocalAuthExceptionCode.systemCanceled:
        return BiometricException(
          code: BiometricErrorCode.systemCanceled,
          message: e.description ?? '',
          userMessage: 'Autentikasi dibatalkan oleh sistem.',
        );
      default:
        return BiometricException(
          code: BiometricErrorCode.unknown,
          message: e.description ?? 'Unknown error',
          userMessage: 'Terjadi kesalahan saat memverifikasi biometrik.',
        );
    }
  }

  // Tampilkan tombol "Coba Lagi"?
  bool get isRetryable => code == BiometricErrorCode.userCanceled ||
      code == BiometricErrorCode.systemCanceled ||
      code == BiometricErrorCode.unknown;

  // Tampilkan tombol "Buka Pengaturan"?
  bool get requiresSettings => code == BiometricErrorCode.notEnrolled;

  // Otomatis pindah ke form password?
  bool get requiresFallback => code == BiometricErrorCode.noBiometricHardware ||
      code == BiometricErrorCode.biometricLockout;
}
