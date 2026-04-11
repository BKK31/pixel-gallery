import 'package:flutter/services.dart';

class WindowService {
  static const MethodChannel _channel = MethodChannel('com.pixel.gallery/window');

  /// Checks if the device supports HDR display.
  static Future<bool> supportsHdr() async {
    try {
      final bool? supports = await _channel.invokeMethod('supportsHdr');
      return supports ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Sets the window color mode (HDR or Wide Gamut).
  static Future<void> setColorMode({required bool wideColorGamut, required bool hdr}) async {
    try {
      await _channel.invokeMethod('setColorMode', {
        'wideColorGamut': wideColorGamut,
        'hdr': hdr,
      });
    } catch (e) {
      // Ignore
    }
  }

  /// Checks if system auto-rotate is locked.
  static Future<bool> isRotationLocked() async {
    try {
      final bool? locked = await _channel.invokeMethod('isRotationLocked');
      return locked ?? true;
    } catch (e) {
      return true;
    }
  }

  /// Gets the current display rotation in degrees (0, 90, 180, 270).
  static Future<int> getOrientation() async {
    try {
      final int? orientation = await _channel.invokeMethod('getOrientation');
      return orientation ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Requests a specific orientation (e.g. ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE).
  static Future<void> requestOrientation(int orientation) async {
    try {
      await _channel.invokeMethod('requestOrientation', {'orientation': orientation});
    } catch (e) {
      // Ignore
    }
  }

  /// Gets the physical sensor orientation.
  /// Returns: 0 (Portrait), 1 (Reverse Portrait), 2 (Landscape), 3 (Reverse Landscape), -1 (Unknown)
  static Future<int> getSensorOrientation() async {
    try {
      final int? orientation = await _channel.invokeMethod('getSensorOrientation');
      return orientation ?? -1;
    } catch (e) {
      return -1;
    }
  }

  // Orientation Constants (match native WindowHandler.kt)
  static const sensorPortrait = 0;
  static const sensorReversePortrait = 1;
  static const sensorLandscape = 2;
  static const sensorReverseLandscape = 3;

  // ActivityInfo Screen Orientation Constants
  static const screenOrientationUnspecified = -1;
  static const screenOrientationLandscape = 0;
  static const screenOrientationPortrait = 1;
  static const screenOrientationSensorLandscape = 6;
  static const screenOrientationSensorPortrait = 7;
  static const screenOrientationReverseLandscape = 8;
  static const screenOrientationReversePortrait = 9;
  static const screenOrientationUserLandscape = 11;
  static const screenOrientationUserPortrait = 12;
}
