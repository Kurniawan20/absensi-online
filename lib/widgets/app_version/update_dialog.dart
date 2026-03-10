import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/app_version_info.dart';

/// Bottom Sheet untuk menampilkan update tersedia
/// Bisa force (non-dismissible) atau optional (dismissible)
class UpdateDialog extends StatefulWidget {
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

  /// Show update bottom sheet
  static Future<void> show(
    BuildContext context, {
    required AppVersionInfo info,
    required bool isForced,
    VoidCallback? onSkip,
    VoidCallback? onUpdate,
  }) {
    // Gunakan PopScope di dalam builder untuk menangkap tombol back
    return showModalBottomSheet(
      context: context,
      isDismissible: false, // User requested never dismissible
      enableDrag: false, // User requested never dismissible
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PopScope(
        canPop: false, // User requested never dismissible
        child: UpdateDialog(
          info: info,
          isForced: isForced,
          onSkip: onSkip,
          onUpdate: onUpdate,
        ),
      ),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Avatar Image (Static - Generated staff avatar v6 matte)
          Image.asset(
            'assets/images/update_avatar_staff_white_v6.png',
            width: 140,
            height: 140,
            fit: BoxFit.contain,
          ),

          const SizedBox(height: 16),

          // Title
          Text(
            widget.isForced ? 'Update Diperlukan' : 'Update Tersedia',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Message
          Text(
            widget.info.updateMessage ??
                (widget.isForced
                    ? 'Versi aplikasi saat ini tidak lagi didukung. Harap perbarui aplikasi Anda.'
                    : 'Versi baru dengan peningkatan fitur dan perbaikan bug telah tersedia!'),
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontFamily: 'Poppins',
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),

          // Changelog if available
          if (widget.info.changelog != null &&
              widget.info.changelog!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        FluentIcons.document_text_24_regular,
                        size: 16,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Yang Baru:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.info.changelog!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Buttons
          Column(
            children: [
              // Update button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: widget.onUpdate ?? () => _openStore(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF016541), // Theme Green
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 1,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(FluentIcons.store_microsoft_24_filled,
                          size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Update Sekarang',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Skip button (only for optional updates)
              if (!widget.isForced) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed:
                        widget.onSkip ?? () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Nanti Saja',
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
    );
  }

  /// Fallback URL jika server tidak mengirim store_url
  static const String _fallbackStoreUrl =
      'https://play.google.com/store/apps/details?id=id.basitd.absensi.mobile';

  Future<void> _openStore(BuildContext context) async {
    final url =
        (widget.info.storeUrl != null && widget.info.storeUrl!.isNotEmpty)
            ? widget.info.storeUrl!
            : _fallbackStoreUrl;

    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error membuka store: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Tidak dapat membuka store. Pastikan aplikasi Google Play Store tersedia.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
