import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

/// Service wrapping `local_auth` to provide biometric / screen-lock
/// authentication for the Locked Folder feature.
class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Returns `true` when biometric or device-credential authentication
  /// is available on this device.
  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck || isDeviceSupported;
    } on PlatformException {
      return false;
    }
  }

  /// Prompts the user for biometric or screen-lock authentication.
  /// Returns `true` on success.
  Future<bool> authenticate({
    String reason = 'Authenticate to access Locked Folder',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // allow PIN/pattern/password fallback
        ),
      );
    } on PlatformException catch (e) {
      // If the user's device doesn't have a screen lock or biometrics set up,
      // allow them straight through to display the images.
      if (e.code == 'NotEnrolled' ||
          e.code == 'PasscodeNotSet' ||
          e.code == 'NotAvailable') {
        return true;
      }
      return false;
    }
  }
}
