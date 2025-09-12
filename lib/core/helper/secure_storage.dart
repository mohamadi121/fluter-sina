import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static final FlutterSecureStorage storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static Future<void> writeSecureStorage(String key, String value) async {
    try {
      await storage.write(key: key, value: value);
    } catch (e) {
      throw SecureStorageException('Failed to write secure storage: $e');
    }
  }

  static Future<String?> readSecureStorage(String key) async {
    try {
      return await storage.read(key: key);
    } catch (e) {
      throw SecureStorageException('Failed to read secure storage: $e');
    }
  }

  static Future<void> deleteSecureStorage(String key) async {
    try {
      await storage.delete(key: key);
    } catch (e) {
      throw SecureStorageException('Failed to delete secure storage: $e');
    }
  }

  static Future<void> deleteAllSecureStorage() async {
    try {
      await storage.deleteAll();
    } catch (e) {
      throw SecureStorageException('Failed to delete all secure storage: $e');
    }
  }
}

class SecureStorageException implements Exception {
  final String message;
  SecureStorageException(this.message);
  
  @override
  String toString() => 'SecureStorageException: $message';
}
