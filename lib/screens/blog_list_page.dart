import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/blog_post.dart';
import '../repository/home_repository.dart';
import '../constants/api_constants.dart';
import './blog_detail_page.dart';

class BlogListPage extends StatefulWidget {
  const BlogListPage({super.key});

  @override
  State<BlogListPage> createState() => _BlogListPageState();
}

class _BlogListPageState extends State<BlogListPage> {
  final HomeRepository _homeRepository = HomeRepository();
  final ScrollController _scrollController = ScrollController();

  List<BlogPost> _blogPosts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  BlogCategory? _selectedCategory;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadBlogPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMorePosts();
    }
  }

  Future<void> _loadBlogPosts({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _hasMore = true;
      });
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final posts = await _homeRepository.getBlogPosts(
        category: _selectedCategory,
        limit: _pageSize,
      );

      if (!mounted) return;

      // Sort posts: pinned first, then by date
      posts.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        if (a.publishedAt != null && b.publishedAt != null) {
          return b.publishedAt!.compareTo(a.publishedAt!);
        }
        return 0;
      });

      setState(() {
        _blogPosts = posts;
        _isLoading = false;
        _hasMore = posts.length >= _pageSize;
      });
    } catch (e) {
      print('Error loading blog posts: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Gagal memuat pengumuman');
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      // Note: Current API doesn't support pagination, so this is a placeholder
      // When API supports pagination, update this
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _isLoadingMore = false;
        _hasMore = false; // No more posts for now
      });
    } catch (e) {
      print('Error loading more posts: $e');
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(1, 101, 65, 1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pengumuman Kantor',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Category Filter
          _buildCategoryFilter(),
          // Blog List
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _blogPosts.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () => _loadBlogPosts(refresh: true),
                        color: const Color.fromRGBO(1, 101, 65, 1),
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount:
                              _blogPosts.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _blogPosts.length) {
                              return _buildLoadingMoreIndicator();
                            }
                            return _buildBlogCard(_blogPosts[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildCategoryChip(null, 'Semua'),
            const SizedBox(width: 8),
            _buildCategoryChip(BlogCategory.announcement, 'Pengumuman'),
            const SizedBox(width: 8),
            _buildCategoryChip(BlogCategory.news, 'Berita'),
            const SizedBox(width: 8),
            _buildCategoryChip(BlogCategory.event, 'Event'),
            const SizedBox(width: 8),
            _buildCategoryChip(BlogCategory.info, 'Info'),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(BlogCategory? category, String label) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedCategory = category;
        });
        _loadBlogPosts(refresh: true);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromRGBO(1, 101, 65, 1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color.fromRGBO(1, 101, 65, 1)
                : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => _buildSkeletonCard(),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 18,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 18,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 14,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
            'Tidak Ada Pengumuman',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedCategory != null
                ? 'Tidak ada pengumuman untuk kategori ini'
                : 'Belum ada pengumuman yang dipublikasikan',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          if (_selectedCategory != null)
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = null;
                });
                _loadBlogPosts(refresh: true);
              },
              child: const Text(
                'Lihat Semua Kategori',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Color.fromRGBO(1, 101, 65, 1),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(
          color: Color.fromRGBO(1, 101, 65, 1),
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildBlogCard(BlogPost post) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlogDetailPage(
              blogId: post.id,
              title: post.title,
            ),
          ),
        ).then((_) {
          // Refresh list after viewing detail (view count may have changed)
          _loadBlogPosts();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: post.imageThumbnail != null || post.image != null
                  ? CachedNetworkImage(
                      imageUrl:
                          _getImageUrl(post.imageThumbnail ?? post.image!),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 100,
                        height: 100,
                        color:
                            _getCategoryColor(post.category).withValues(alpha: 0.1),
                        child: Icon(
                          _getCategoryIcon(post.category),
                          color: _getCategoryColor(post.category),
                          size: 40,
                        ),
                      ),
                    )
                  : Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color:
                            _getCategoryColor(post.category).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getCategoryIcon(post.category),
                        color: _getCategoryColor(post.category),
                        size: 40,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _buildCategoryBadge(post.category),
                      if (post.isPinned) _buildPinnedBadge(),
                      if (post.isFeatured) _buildFeaturedBadge(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  ...[
                    const SizedBox(height: 4),
                    Text(
                      post.excerpt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Meta info - use Flexible to prevent overflow
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            FluentIcons.calendar_16_regular,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            post.publishedAt != null
                                ? DateFormat('dd MMM yyyy')
                                    .format(post.publishedAt!)
                                : '-',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      if (post.viewCount > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              FluentIcons.eye_16_regular,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${post.viewCount} views',
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(BlogCategory category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getCategoryColor(category).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        category.displayName,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _getCategoryColor(category),
        ),
      ),
    );
  }

  Widget _buildPinnedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            FluentIcons.pin_16_filled,
            size: 10,
            color: Colors.amber[700],
          ),
          const SizedBox(width: 2),
          Text(
            'Pinned',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            FluentIcons.star_16_filled,
            size: 10,
            color: Colors.blue[700],
          ),
          const SizedBox(width: 2),
          Text(
            'Featured',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  String _getImageUrl(String path) {
    if (path.startsWith('http')) {
      return path;
    }
    final baseUrl = ApiConstants.baseUrl.replaceAll('/api', '');
    return '$baseUrl/storage/$path';
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
