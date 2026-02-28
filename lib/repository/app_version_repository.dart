import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:math' show min, pow;
import 'package:http/io_client.dart' show IOClient;
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../models/app_version_info.dart';

/// Repository untuk mengecek versi aplikasi dengan server
class AppVersionRepository {
  late final IOClient _client;

  /// Maximum delay untuk retry (dalam detik)
  static const int _maxRetryDelay = 30;

  /// Initial delay untuk retry (dalam detik)
  static const int _initialRetryDelay = 2;

  /// Timeout untuk request (dalam detik)
  static const int _requestTimeout = 15;

  AppVersionRepository() {
    final httpClient = HttpClient()
      ..badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true)
      ..connectionTimeout = const Duration(seconds: 10);
    _client = IOClient(httpClient);
  }

  /// Check versi aplikasi dengan server
  /// 
  /// [platform] - 'android' atau 'ios'
  /// [buildNumber] - Build number dari app (e.g., 4)
  /// [versionCode] - Version string (e.g., "1.0.1")
  /// 
  /// Returns Map dengan:
  /// - 'success': bool
  /// - 'data': AppVersionInfo (jika success)
  /// - 'error': String (jika gagal)
  /// - 'retryCount': int (jumlah retry yang dilakukan)
  Future<Map<String, dynamic>> checkVersion({
    required String platform,
    required int buildNumber,
    String? versionCode,
    Function(int retryCount, int nextRetrySeconds)? onRetry,
  }) async {
    int retryCount = 0;

    while (true) {
      try {
        debugPrint('AppVersionRepository: Checking version (attempt ${retryCount + 1})');
        debugPrint('  Platform: $platform');
        debugPrint('  Build Number: $buildNumber');
        debugPrint('  Version Code: $versionCode');

        final response = await _client
            .post(
              Uri.parse(ApiConstants.appVersionCheck),
              headers: {
                'Content-Type': 'application/json; charset=UTF-8',
                'Accept': 'application/json',
              },
              body: jsonEncode({
                'platform': platform,
                'build_number': buildNumber,
                if (versionCode != null) 'version_code': versionCode,
              }),
            )
            .timeout(Duration(seconds: _requestTimeout));

        debugPrint('AppVersionRepository: Response status: ${response.statusCode}');
        debugPrint('AppVersionRepository: Response body: ${response.body}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data['rcode'] == '00') {
            final versionInfo = AppVersionInfo.fromJson(data['data'] ?? {});
            debugPrint('AppVersionRepository: Version check success');
            debugPrint('  Needs Update: ${versionInfo.needsUpdate}');
            debugPrint('  Force Update: ${versionInfo.forceUpdate}');
            debugPrint('  Maintenance: ${versionInfo.maintenanceMode}');

            return {
              'success': true,
              'data': versionInfo,
              'retryCount': retryCount,
            };
          } else {
            throw Exception(data['message'] ?? 'Unknown error from server');
          }
        } else {
          throw Exception('Server returned status code: ${response.statusCode}');
        }
      } on SocketException catch (e) {
        debugPrint('AppVersionRepository: Network error: $e');
        retryCount++;
        final delay = _calculateRetryDelay(retryCount);
        
        // Notify about retry
        onRetry?.call(retryCount, delay);
        
        debugPrint('AppVersionRepository: Retrying in $delay seconds (attempt $retryCount)');
        await Future.delayed(Duration(seconds: delay));
        
      } on TimeoutException catch (e) {
        debugPrint('AppVersionRepository: Timeout error: $e');
        retryCount++;
        final delay = _calculateRetryDelay(retryCount);
        
        onRetry?.call(retryCount, delay);
        
        debugPrint('AppVersionRepository: Retrying in $delay seconds (attempt $retryCount)');
        await Future.delayed(Duration(seconds: delay));
        
      } on HandshakeException catch (e) {
        debugPrint('AppVersionRepository: SSL error: $e');
        retryCount++;
        final delay = _calculateRetryDelay(retryCount);
        
        onRetry?.call(retryCount, delay);
        
        debugPrint('AppVersionRepository: Retrying in $delay seconds (attempt $retryCount)');
        await Future.delayed(Duration(seconds: delay));
        
      } catch (e) {
        debugPrint('AppVersionRepository: Unexpected error: $e');
        retryCount++;
        final delay = _calculateRetryDelay(retryCount);
        
        onRetry?.call(retryCount, delay);
        
        debugPrint('AppVersionRepository: Retrying in $delay seconds (attempt $retryCount)');
        await Future.delayed(Duration(seconds: delay));
      }
    }
  }

  /// Calculate retry delay dengan exponential backoff
  /// 2s, 4s, 8s, 16s, max 30s
  int _calculateRetryDelay(int retryCount) {
    final delay = _initialRetryDelay * pow(2, retryCount - 1).toInt();
    return min(delay, _maxRetryDelay);
  }

  /// Get info versi terbaru untuk platform tertentu
  Future<Map<String, dynamic>> getLatestVersion(String platform) async {
    try {
      final response = await _client
          .get(
            Uri.parse('${ApiConstants.appVersionLatest}/$platform'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(Duration(seconds: _requestTimeout));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['rcode'] == '00') {
          return {
            'success': true,
            'data': data['data'],
          };
        }
      }

      return {
        'success': false,
        'error': 'Failed to get latest version info',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  void dispose() {
    _client.close();
  }
}
