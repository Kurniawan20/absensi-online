import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/app_version_info.dart';

/// Dialog untuk menampilkan update tersedia
/// Bisa force (non-dismissible) atau optional (dismissible)
class UpdateDialog extends StatelessWidget {
  final AppVersionInfo info;
  final bool isForced;
  final VoidCallback? onSkip;
  final VoidCallback? onUpdate;

  const UpdateDialog({
    super.key,
    required this.info,
    required this.isForced,
    this.onSkip,
    this.onUpdate,
  });

  /// Show update dialog
  static Future<void> show(
    BuildContext context, {
    required AppVersionInfo info,
    required bool isForced,
    VoidCallback? onSkip,
    VoidCallback? onUpdate,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: !isForced,
      builder: (context) => UpdateDialog(
        info: info,
        isForced: isForced,
        onSkip: onSkip,
        onUpdate: onUpdate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isForced,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isForced
                      ? const Color(0xFFFFEBEE)
                      : const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(
                  isForced
                      ? FluentIcons.arrow_download_24_filled
                      : FluentIcons.arrow_sync_24_regular,
                  size: 40,
                  color: isForced
                      ? const Color(0xFFE53935)
                      : const Color(0xFF1976D2),
                ),
              ),

              const SizedBox(height: 20),

              // Title
              Text(
                isForced ? 'Update Diperlukan' : 'Update Tersedia',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Message
              Text(
                info.updateMessage ??
                    (isForced
                        ? 'Anda harus memperbarui aplikasi untuk melanjutkan.'
                        : 'Versi baru tersedia dengan fitur-fitur terbaru!'),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              // Changelog if available
              if (info.changelog != null && info.changelog!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            FluentIcons.document_text_24_regular,
                            size: 18,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Yang Baru:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        info.changelog!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontFamily: 'Poppins',
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Buttons
              Column(
                children: [
                  // Update button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: onUpdate ?? () => _openStore(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF016541),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Update Sekarang',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),

                  // Skip button (only for optional updates)
                  if (!isForced) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton(
                        onPressed: onSkip ?? () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Nanti',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Fallback URL jika server tidak mengirim store_url
  static const String _fallbackStoreUrl =
      'https://play.google.com/store/apps/details?id=id.basitd.absensi.mobile';

  Future<void> _openStore(BuildContext context) async {
    // Gunakan store_url dari server, fallback ke URL default
    final url = (info.storeUrl != null && info.storeUrl!.isNotEmpty)
        ? info.storeUrl!
        : _fallbackStoreUrl;

    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error membuka store: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat membuka store'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
