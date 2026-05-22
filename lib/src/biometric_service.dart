import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'biometric_exception.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (e) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  Future<bool> authenticate({String reason = 'Verifikasi biometrik diperlukan'}) async {
    try {
      final bool available = await isBiometricAvailable();
      if (!available) {
        throw BiometricException(
          code: BiometricErrorCode.noBiometricHardware,
          message: 'Hardware not available',
          userMessage: 'Perangkat tidak memiliki sensor biometrik.',
        );
      }

      final List<BiometricType> types = await getAvailableBiometrics();
      if (types.isEmpty) {
        throw BiometricException(
          code: BiometricErrorCode.notEnrolled,
          message: 'No biometrics enrolled',
          userMessage: 'Belum ada sidik jari tersimpan. Daftarkan di Pengaturan.',
        );
      }

      final bool result = await _auth.authenticate(
        localizedReason: reason,
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Verifikasi Diperlukan',
            cancelButton: 'Batal',
            signInHint: 'Tempelkan jari atau arahkan wajah',
          ),
        ],
        biometricOnly: false,
        sensitiveTransaction: true,
        persistAcrossBackgrounding: true,
      );

      if (!result) {
        throw BiometricException(
          code: BiometricErrorCode.userCanceled,
          message: 'User canceled',
          userMessage: 'Autentikasi dibatalkan oleh pengguna.',
        );
      }

      return true;
    } on LocalAuthException catch (e) {
      throw BiometricException.fromLocalAuthException(e);
    } catch (e) {
      throw BiometricException(
        code: BiometricErrorCode.unknown,
        message: e.toString(),
        userMessage: 'Terjadi kesalahan tidak dikenal.',
      );
    }
  }
}
