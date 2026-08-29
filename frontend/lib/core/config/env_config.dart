import 'dart:io';
import 'package:flutter/foundation.dart';

enum Environment {
  dev,
  staging,
  prod,
}

class EnvConfig {
  final Environment environment;
  final int connectTimeoutMs;
  final int receiveTimeoutMs;

  const EnvConfig({
    this.environment = Environment.dev,
    this.connectTimeoutMs = 5000,
    this.receiveTimeoutMs = 5000,
  });

  static Environment get currentEnvironment {
    const envStr = String.fromEnvironment('ENVIRONMENT', defaultValue: '');
    if (envStr.toLowerCase() == 'prod') {
      return Environment.prod;
    } else if (envStr.toLowerCase() == 'staging') {
      return Environment.staging;
    }
    return Environment.dev;
  }

  /// Returns the canonical API Base URL with /api/v1 prefix
  static String get apiBaseUrl {
    const overrideUrl = String.fromEnvironment('API_BASE_URL');
    if (overrideUrl.isNotEmpty) {
      return overrideUrl.endsWith('/api/v1') ? overrideUrl : '$overrideUrl/api/v1';
    }

    const overrideLanIp = String.fromEnvironment('PC_LAN_IP');
    if (overrideLanIp.isNotEmpty) {
      return 'http://$overrideLanIp:8000/api/v1';
    }

    final isTest = !kIsWeb && (Platform.environment.containsKey('FLUTTER_TEST') ||
        const bool.fromEnvironment('FLUTTER_TEST'));

    if (isTest) {
      return 'http://127.0.0.1:8000/api/v1';
    }

    // Web browser environment
    if (kIsWeb) {
      if (Uri.base.host == 'localhost' || Uri.base.host == '127.0.0.1') {
        return 'http://127.0.0.1:8000/api/v1';
      }
      return 'https://srm-rmp-od-app.onrender.com/api/v1';
    }

    if (currentEnvironment == Environment.prod || kReleaseMode) {
      return 'https://srm-rmp-od-app.onrender.com/api/v1';
    }

    // Default to production cloud backend
    return 'https://srm-rmp-od-app.onrender.com/api/v1';
  }

  /// Returns the root server URL (without /api/v1 suffix) for static file attachments
  static String get serverRootUrl {
    final base = apiBaseUrl;
    if (base.endsWith('/api/v1')) {
      return base.substring(0, base.length - '/api/v1'.length);
    }
    return base;
  }

  /// Resolves any relative or legacy attachment path into a fully accessible absolute URL.
  static String resolveAttachmentUrl(String? rawPath) {
    if (rawPath == null || rawPath.trim().isEmpty) return '';

    final path = rawPath.trim();

    // Handle full URLs saved in DB
    if (path.startsWith('http://') || path.startsWith('https://')) {
      // Convert historical localhost/127.0.0.1 URLs when accessed from Android Emulator
      if (defaultTargetPlatform == TargetPlatform.android && !kIsWeb) {
        return path
            .replaceAll('127.0.0.1:8000', '10.0.2.2:8000')
            .replaceAll('localhost:8000', '10.0.2.2:8000')
            .replaceAll('/api/v1/uploads/', '/uploads/');
      }
      return path.replaceAll('/api/v1/uploads/', '/uploads/');
    }

    // Handle legacy /api/v1/uploads/ paths
    if (path.startsWith('/api/v1/uploads/')) {
      final clean = path.replaceFirst('/api/v1', '');
      return '$serverRootUrl$clean';
    }

    // Handle standard relative /uploads/ paths
    if (path.startsWith('/uploads/')) {
      return '$serverRootUrl$path';
    }

    if (path.startsWith('uploads/')) {
      return '$serverRootUrl/$path';
    }

    return '$serverRootUrl/uploads/$path';
  }
}
