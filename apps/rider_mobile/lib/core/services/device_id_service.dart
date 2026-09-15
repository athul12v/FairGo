// lib/core/services/device_id_service.dart

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class DeviceIdService {
  static const _storage = FlutterSecureStorage();
  static const _key = 'fairgo_device_id';

  static Future<void> ensureDeviceId() async {
    final existing = await _storage.read(key: _key);
    if (existing != null) return;

    // Try to get a stable device identifier
    final info = DeviceInfoPlugin();
    String? deviceId;
    try {
      final androidInfo = await info.androidInfo;
      deviceId = androidInfo.id;
    } catch (_) {
      try {
        final iosInfo = await info.iosInfo;
        deviceId = iosInfo.identifierForVendor;
      } catch (_) {}
    }

    // Fallback to random UUID persisted in secure storage
    deviceId ??= const Uuid().v4();
    await _storage.write(key: _key, value: deviceId);
  }

  static Future<String?> getDeviceId() async {
    return _storage.read(key: _key);
  }
}
