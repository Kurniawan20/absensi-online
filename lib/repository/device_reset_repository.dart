import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/io_client.dart' show IOClient;
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../models/device_reset_request.dart';

/// Repository untuk mengelola request reset device
class DeviceResetRepository {
  late final IOClient _client;

  /// Timeout untuk request (dalam detik)
  static const int _requestTimeout = 30;

  DeviceResetRepository() {
    final httpClient = HttpClient()
      ..badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true)
      ..connectionTimeout = const Duration(seconds: 15);
    _client = IOClient(httpClient);
  }

  /// Submit request reset device
  ///
  /// [npp] - NPP karyawan
  /// [reason] - Alasan reset device (min 10 karakter)
  ///
  /// Returns Map dengan:
  /// - 'success': bool
  /// - 'message': String
  /// - 'data': DeviceResetRequest (jika success)
  /// - 'rcode': String
  Future<Map<String, dynamic>> submitResetRequest({
    required String npp,
    required String reason,
  }) async {
    try {
      debugPrint('DeviceResetRepository: Submitting reset request');
      debugPrint('  NPP: $npp');
      debugPrint('  Reason: $reason');

      final response = await _client
          .post(
            Uri.parse(ApiConstants.deviceResetRequest),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'npp': npp,
              'reason': reason,
            }),
          )
          .timeout(Duration(seconds: _requestTimeout));

      debugPrint(
          'DeviceResetRepository: Response status: ${response.statusCode}');
      debugPrint('DeviceResetRepository: Response body: ${response.body}');

      final data = json.decode(response.body);
      final rcode = data['rcode']?.toString() ?? '';

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (rcode == '00') {
          // Success
          final request = DeviceResetRequest.fromJson(data['data'] ?? {});
          return {
            'success': true,
            'message': data['message'] ?? 'Permintaan berhasil diajukan',
            'data': request,
            'rcode': rcode,
          };
        } else if (rcode == '81') {
          // User not found
          return {
            'success': false,
            'message': data['message'] ?? 'User tidak ditemukan',
            'rcode': rcode,
          };
        } else if (rcode == '82') {
          // Already has pending request
          return {
            'success': false,
            'message': data['message'] ??
                'Anda sudah memiliki permintaan yang sedang diproses',
            'rcode': rcode,
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Terjadi kesalahan',
            'rcode': rcode,
          };
        }
      } else {
        return {
          'success': false,
          'message': data['message'] ??
              'Gagal mengirim permintaan (${response.statusCode})',
          'rcode': rcode,
        };
      }
    } on SocketException catch (e) {
      debugPrint('DeviceResetRepository: Network error: $e');
      return {
        'success': false,
        'message':
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
        'rcode': 'network_error',
      };
    } on TimeoutException catch (e) {
      debugPrint('DeviceResetRepository: Timeout error: $e');
      return {
        'success': false,
        'message': 'Koneksi timeout. Silakan coba lagi.',
        'rcode': 'timeout',
      };
    } on HandshakeException catch (e) {
      debugPrint('DeviceResetRepository: SSL error: $e');
      return {
        'success': false,
        'message': 'Gagal membuat koneksi aman ke server.',
        'rcode': 'ssl_error',
      };
    } catch (e) {
      debugPrint('DeviceResetRepository: Unexpected error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
        'rcode': 'error',
      };
    }
  }

  /// Check status request reset device
  ///
  /// [npp] - NPP karyawan
  ///
  /// Returns Map dengan:
  /// - 'success': bool
  /// - 'message': String
  /// - 'data': `List<DeviceResetRequest>` (jika success)
  Future<Map<String, dynamic>> getMyRequests({
    required String npp,
  }) async {
    try {
      debugPrint('DeviceResetRepository: Getting my requests');
      debugPrint('  NPP: $npp');

      final response = await _client
          .post(
            Uri.parse(ApiConstants.deviceResetStatus),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'npp': npp,
            }),
          )
          .timeout(Duration(seconds: _requestTimeout));

      debugPrint(
          'DeviceResetRepository: Response status: ${response.statusCode}');
      debugPrint('DeviceResetRepository: Response body: ${response.body}');

      final data = json.decode(response.body);
      final rcode = data['rcode']?.toString() ?? '';

      if (response.statusCode == 200 && rcode == '00') {
        final List<dynamic> requestsJson = data['data'] ?? [];
        final requests = requestsJson
            .map((json) => DeviceResetRequest.fromJson(json))
            .toList();

        return {
          'success': true,
          'message': data['message'] ?? 'Success',
          'data': requests,
          'rcode': rcode,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengambil data',
          'rcode': rcode,
        };
      }
    } on SocketException catch (e) {
      debugPrint('DeviceResetRepository: Network error: $e');
      return {
        'success': false,
        'message': 'Tidak dapat terhubung ke server.',
        'rcode': 'network_error',
      };
    } on TimeoutException catch (e) {
      debugPrint('DeviceResetRepository: Timeout error: $e');
      return {
        'success': false,
        'message': 'Koneksi timeout.',
        'rcode': 'timeout',
      };
    } catch (e) {
      debugPrint('DeviceResetRepository: Unexpected error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
        'rcode': 'error',
      };
    }
  }

  void dispose() {
    _client.close();
  }
}
