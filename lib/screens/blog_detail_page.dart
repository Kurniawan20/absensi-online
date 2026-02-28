import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

import 'package:path_provider/path_provider.dart';

import '../models/blog_post.dart';
import '../repository/home_repository.dart';
import '../constants/api_constants.dart';

class BlogDetailPage extends StatefulWidget {
  final int blogId;
  final String? title;

  const BlogDetailPage({
    super.key,
    required this.blogId,
    this.title,
  });

  @override
  State<BlogDetailPage> createState() => _BlogDetailPageState();
}

class _BlogDetailPageState extends State<BlogDetailPage> {
  final HomeRepository _repository = HomeRepository();
  final ScrollController _scrollController = ScrollController();
  BlogPostDetail? _blogDetail;
  bool _isLoading = true;
  String? _error;

  // Use ValueNotifier for better performance - avoids full widget rebuild
  final ValueNotifier<bool> _showTitleNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _loadBlogDetail();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _showTitleNotifier.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Only update when crossing threshold - reduces rebuilds significantly
    final showTitle = _scrollController.offset > 150;
    if (showTitle != _showTitleNotifier.value) {
      _showTitleNotifier.value = showTitle;
    }
  }

  Future<void> _loadBlogDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final detail = await _repository.getBlogDetail(widget.blogId);
      if (mounted) {
        setState(() {
          _blogDetail = detail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
  }

  String _getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    if (imagePath.startsWith('http')) return imagePath;
    final baseUrl = ApiConstants.baseUrl.replaceAll('/api', '');
    return '$baseUrl/storage/$imagePath';
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _blogDetail?.image != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main Content - Use physics for smoother scrolling
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // Hero Image Section
              if (hasImage)
                SliverToBoxAdapter(
                  child: _buildHeroImage(),
                ),
              // Content
              SliverToBoxAdapter(
                child: _buildContent(),
              ),
            ],
          ),
          // Custom App Bar - Uses ValueListenableBuilder for targeted rebuild
          _buildAppBar(hasImage),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool hasImage) {
    return ValueListenableBuilder<bool>(
      valueListenable: _showTitleNotifier,
      builder: (context, showTitle, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: showTitle ? Colors.white : Colors.transparent,
            boxShadow: showTitle
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: SafeArea(
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  // Back Button
                  _buildIconButton(
                    icon: FluentIcons.arrow_left_24_regular,
                    onPressed: () => Navigator.pop(context),
                    showBackground: !showTitle && hasImage,
                    iconColor: showTitle
                        ? Colors.black87
                        : (hasImage ? Colors.white : Colors.black87),
                  ),
                  const SizedBox(width: 8),
                  // Title (appears on scroll)
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: showTitle ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _blogDetail?.title ?? widget.title ?? '',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool showBackground = false,
    Color iconColor = Colors.white,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 40,
          height: 40,
          decoration: showBackground
              ? BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                )
              : null,
          child: Icon(
            icon,
            color: iconColor,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImage() {
    return SizedBox(
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image - use RepaintBoundary to isolate repaints
          RepaintBoundary(
            child: CachedNetworkImage(
              imageUrl: _getImageUrl(_blogDetail!.image),
              fit: BoxFit.cover,
              memCacheHeight: 600, // Optimize memory
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color.fromRGBO(1, 101, 65, 1),
                    strokeWidth: 2,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      FluentIcons.image_off_24_regular,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gambar tidak tersedia',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_blogDetail == null) {
      return _buildEmptyState();
    }

    return _buildArticleContent();
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 100),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 200,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 180,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: List.generate(
                6,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 100,
        left: 24,
        right: 24,
        bottom: 24,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              FluentIcons.warning_24_regular,
              size: 48,
              color: Colors.red[400],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Gagal Memuat Artikel',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loadBlogDetail,
              icon: const Icon(FluentIcons.arrow_clockwise_24_regular),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(1, 101, 65, 1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 100,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FluentIcons.document_search_24_regular,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Artikel tidak ditemukan',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleContent() {
    final hasImage = _blogDetail!.image != null;
    final hasAttachments = _blogDetail!.attachments.isNotEmpty;

    return Container(
      padding: EdgeInsets.only(
        top: hasImage ? 16 : MediaQuery.of(context).padding.top + 60,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category & Badges
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildCategoryBadge(_blogDetail!.category),
                    if (_blogDetail!.isPinned) _buildPinnedBadge(),
                    if (_blogDetail!.isFeatured) _buildFeaturedBadge(),
                  ],
                ),
                const SizedBox(height: 16),
                // Title
                Text(
                  _blogDetail!.title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 20),
                // Meta Info Card
                _buildMetaInfoCard(),
                const SizedBox(height: 24),
              ],
            ),
          ),
          // Divider
          Container(
            height: 8,
            color: Colors.grey[100],
          ),
          // Content - Wrap in RepaintBoundary for isolation
          RepaintBoundary(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Html(
                data: _blogDetail!.content,
                style: _getHtmlStyles(),
              ),
            ),
          ),
          // Attachments Section
          if (hasAttachments) ...[
            Container(
              height: 8,
              color: Colors.grey[100],
            ),
            _buildAttachmentsSection(),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAttachmentsSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(1, 101, 65, 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  FluentIcons.attach_24_regular,
                  size: 20,
                  color: Color.fromRGBO(1, 101, 65, 1),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Lampiran (${_blogDetail!.attachments.length})',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Attachment List
          ...(_blogDetail!.attachments
              .map((attachment) => _buildAttachmentItem(attachment))),
        ],
      ),
    );
  }

  Widget _buildAttachmentItem(BlogAttachment attachment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _downloadAttachment(attachment),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // File Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        _getFileIconColor(attachment.fileType).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getFileIcon(attachment.fileType),
                    color: _getFileIconColor(attachment.fileType),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                // File Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attachment.fileName,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            attachment.fileType.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _getFileIconColor(attachment.fileType),
                            ),
                          ),
                          Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(
                            attachment.fileSizeHuman,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Download Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(1, 101, 65, 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    FluentIcons.arrow_download_24_regular,
                    color: Color.fromRGBO(1, 101, 65, 1),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadAttachment(BlogAttachment attachment) async {
    final url = attachment.downloadUrl;
    if (url.isEmpty) {
      _showSnackBar('URL file tidak tersedia');
      return;
    }

    // Tampilkan loading indicator
    _showSnackBar('Mengunduh ${attachment.fileName}...');

    try {
      // Gunakan Dio dengan konfigurasi khusus untuk emulator
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 120),
        headers: {
          'Connection': 'close', // Hindari keep-alive issues di dev server
          'Accept': '*/*',
        },
      ));

      // Bypass SSL certificate untuk development
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback = (cert, host, port) => true;
          return client;
        },
      );

      // Simpan ke folder Download agar mudah ditemukan
      final downloadDir = Directory('/storage/emulated/0/Download');
      final savePath = downloadDir.existsSync()
          ? '${downloadDir.path}/${attachment.fileName}'
          : '${(await getTemporaryDirectory()).path}/${attachment.fileName}';

      debugPrint('Downloading: $url -> $savePath');

      // Download langsung ke file (streaming, hemat memory)
      final response = await dio.download(url, savePath);

      debugPrint('Download status: ${response.statusCode}');
      dio.close();

      if (response.statusCode == 200) {
        _showSnackBar('✅ ${attachment.fileName} berhasil diunduh');
      } else {
        _showSnackBar('Gagal mengunduh file (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Error download attachment: $e');
      _showSnackBar('Gagal mengunduh file');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return FluentIcons.document_pdf_24_regular;
      case 'doc':
      case 'docx':
        return FluentIcons.document_text_24_regular;
      case 'xls':
      case 'xlsx':
        return FluentIcons.document_table_24_regular;
      default:
        return FluentIcons.document_24_regular;
    }
  }

  Color _getFileIconColor(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Colors.red[600]!;
      case 'doc':
      case 'docx':
        return Colors.blue[600]!;
      case 'xls':
      case 'xlsx':
        return Colors.green[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  // Extracted to avoid rebuilding styles map on every build
  Map<String, Style> _getHtmlStyles() {
    return {
      "body": Style(
        fontFamily: 'Poppins',
        fontSize: FontSize(16),
        lineHeight: const LineHeight(1.8),
        color: Colors.grey[800],
        margin: Margins.zero,
        padding: HtmlPaddings.zero,
      ),
      "p": Style(
        margin: Margins.only(bottom: 16),
      ),
      "h1": Style(
        fontFamily: 'Poppins',
        fontSize: FontSize(22),
        fontWeight: FontWeight.bold,
        margin: Margins.only(bottom: 12, top: 20),
        color: Colors.black87,
      ),
      "h2": Style(
        fontFamily: 'Poppins',
        fontSize: FontSize(20),
        fontWeight: FontWeight.bold,
        margin: Margins.only(bottom: 10, top: 16),
        color: Colors.black87,
      ),
      "h3": Style(
        fontFamily: 'Poppins',
        fontSize: FontSize(18),
        fontWeight: FontWeight.w600,
        margin: Margins.only(bottom: 8, top: 14),
        color: Colors.black87,
      ),
      "ul": Style(
        margin: Margins.only(left: 8, bottom: 16),
        padding: HtmlPaddings.only(left: 16),
      ),
      "ol": Style(
        margin: Margins.only(left: 8, bottom: 16),
        padding: HtmlPaddings.only(left: 16),
      ),
      "li": Style(
        margin: Margins.only(bottom: 6),
        lineHeight: const LineHeight(1.6),
      ),
      "a": Style(
        color: const Color.fromRGBO(1, 101, 65, 1),
        fontWeight: FontWeight.w500,
        textDecoration: TextDecoration.none,
      ),
      "img": Style(
        margin: Margins.symmetric(vertical: 16),
      ),
      "blockquote": Style(
        margin: Margins.symmetric(vertical: 16),
        padding: HtmlPaddings.all(16),
        border: const Border(
          left: BorderSide(
            color: Color.fromRGBO(1, 101, 65, 1),
            width: 4,
          ),
        ),
        backgroundColor: const Color.fromRGBO(1, 101, 65, 0.05),
        fontStyle: FontStyle.italic,
      ),
      "strong": Style(
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      "em": Style(
        fontStyle: FontStyle.italic,
      ),
    };
  }

  Widget _buildMetaInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          if (_blogDetail!.authorName != null) ...[
            _buildMetaRow(
              icon: FluentIcons.person_24_regular,
              label: 'Penulis',
              value: _blogDetail!.authorName!,
            ),
            const SizedBox(height: 12),
          ],
          _buildMetaRow(
            icon: FluentIcons.calendar_24_regular,
            label: 'Dipublikasikan',
            value: _formatDate(_blogDetail!.publishedAt),
          ),
          if (_blogDetail!.viewCount > 0) ...[
            const SizedBox(height: 12),
            _buildMetaRow(
              icon: FluentIcons.eye_24_regular,
              label: 'Dilihat',
              value: '${_blogDetail!.viewCount} kali',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(1, 101, 65, 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: const Color.fromRGBO(1, 101, 65, 1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBadge(BlogCategory category) {
    final color = _getCategoryColor(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getCategoryIcon(category),
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            category.displayName,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinnedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            FluentIcons.pin_16_filled,
            size: 12,
            color: Colors.amber[700],
          ),
          const SizedBox(width: 4),
          Text(
            'Disematkan',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.amber[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            FluentIcons.star_16_filled,
            size: 12,
            color: Colors.blue[700],
          ),
          const SizedBox(width: 4),
          Text(
            'Unggulan',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(BlogCategory category) {
    switch (category) {
      case BlogCategory.announcement:
        return const Color(0xFFE65100);
      case BlogCategory.news:
        return const Color(0xFF1565C0);
      case BlogCategory.event:
        return const Color(0xFF7B1FA2);
      case BlogCategory.info:
        return const Color.fromRGBO(1, 101, 65, 1);
      case BlogCategory.other:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(BlogCategory category) {
    switch (category) {
      case BlogCategory.announcement:
        return FluentIcons.megaphone_24_regular;
      case BlogCategory.news:
        return FluentIcons.news_24_regular;
      case BlogCategory.event:
        return FluentIcons.calendar_star_24_regular;
      case BlogCategory.info:
        return FluentIcons.info_24_regular;
      case BlogCategory.other:
        return FluentIcons.document_24_regular;
    }
  }
}
