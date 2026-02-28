import 'package:equatable/equatable.dart';

/// Model untuk blog attachment
class BlogAttachment extends Equatable {
  final int id;
  final String fileName;
  final String filePath;
  final String fileType;
  final int fileSize;
  final String fileSizeHuman;
  final String fileIcon;
  final String downloadUrl;
  final String? description;
  final DateTime? createdAt;

  const BlogAttachment({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
    required this.fileSizeHuman,
    required this.fileIcon,
    required this.downloadUrl,
    this.description,
    this.createdAt,
  });

  factory BlogAttachment.fromJson(Map<String, dynamic> json) {
    return BlogAttachment(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      fileName: json['file_name'] ?? '',
      filePath: json['file_path'] ?? '',
      fileType: json['file_type'] ?? '',
      fileSize: json['file_size'] is int
          ? json['file_size']
          : int.tryParse(json['file_size']?.toString() ?? '0') ?? 0,
      fileSizeHuman: json['file_size_human'] ?? '',
      fileIcon: json['file_icon'] ?? 'file',
      downloadUrl: json['download_url'] ?? '',
      description: json['description'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_name': fileName,
      'file_path': filePath,
      'file_type': fileType,
      'file_size': fileSize,
      'file_size_human': fileSizeHuman,
      'file_icon': fileIcon,
      'download_url': downloadUrl,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        fileName,
        filePath,
        fileType,
        fileSize,
        fileSizeHuman,
        fileIcon,
        downloadUrl,
        description,
        createdAt,
      ];
}

/// Enum untuk kategori blog
enum BlogCategory {
  announcement,
  news,
  event,
  info,
  other;

  static BlogCategory fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'announcement':
        return BlogCategory.announcement;
      case 'news':
        return BlogCategory.news;
      case 'event':
        return BlogCategory.event;
      case 'info':
        return BlogCategory.info;
      default:
        return BlogCategory.other;
    }
  }

  String get displayName {
    switch (this) {
      case BlogCategory.announcement:
        return 'Pengumuman';
      case BlogCategory.news:
        return 'Berita';
      case BlogCategory.event:
        return 'Event';
      case BlogCategory.info:
        return 'Informasi';
      case BlogCategory.other:
        return 'Lainnya';
    }
  }

  String get value {
    switch (this) {
      case BlogCategory.announcement:
        return 'announcement';
      case BlogCategory.news:
        return 'news';
      case BlogCategory.event:
        return 'event';
      case BlogCategory.info:
        return 'info';
      case BlogCategory.other:
        return 'other';
    }
  }
}

/// Model untuk blog post list (tanpa content lengkap)
class BlogPost extends Equatable {
  final int id;
  final String title;
  final String slug;
  final String excerpt;
  final String? imageThumbnail;
  final String? image;
  final BlogCategory category;
  final bool isFeatured;
  final bool isPinned;
  final DateTime? publishedAt;
  final int viewCount;

  const BlogPost({
    required this.id,
    required this.title,
    required this.slug,
    required this.excerpt,
    this.imageThumbnail,
    this.image,
    required this.category,
    this.isFeatured = false,
    this.isPinned = false,
    this.publishedAt,
    this.viewCount = 0,
  });

  factory BlogPost.fromJson(Map<String, dynamic> json) {
    return BlogPost(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      excerpt: json['excerpt'] ?? '',
      imageThumbnail: json['image_thumbnail'],
      image: json['image'],
      category: BlogCategory.fromString(json['category']),
      isFeatured: json['is_featured'] == true || json['is_featured'] == 1,
      isPinned: json['is_pinned'] == true || json['is_pinned'] == 1,
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'])
          : null,
      viewCount: json['view_count'] is int
          ? json['view_count']
          : int.tryParse(json['view_count']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'excerpt': excerpt,
      'image_thumbnail': imageThumbnail,
      'image': image,
      'category': category.value,
      'is_featured': isFeatured,
      'is_pinned': isPinned,
      'published_at': publishedAt?.toIso8601String(),
      'view_count': viewCount,
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        slug,
        excerpt,
        imageThumbnail,
        image,
        category,
        isFeatured,
        isPinned,
        publishedAt,
        viewCount,
      ];
}

/// Model untuk blog post detail (dengan content lengkap)
class BlogPostDetail extends BlogPost {
  final String content;
  final String status;
  final String? authorName;
  final DateTime? createdAt;
  final List<BlogAttachment> attachments;

  const BlogPostDetail({
    required super.id,
    required super.title,
    required super.slug,
    required super.excerpt,
    super.imageThumbnail,
    super.image,
    required super.category,
    super.isFeatured,
    super.isPinned,
    super.publishedAt,
    super.viewCount,
    required this.content,
    required this.status,
    this.authorName,
    this.createdAt,
    this.attachments = const [],
  });

  factory BlogPostDetail.fromJson(Map<String, dynamic> json) {
    // Parse attachments
    List<BlogAttachment> attachmentList = [];
    if (json['attachments'] != null && json['attachments'] is List) {
      attachmentList = (json['attachments'] as List)
          .map((item) => BlogAttachment.fromJson(item))
          .toList();
    }

    return BlogPostDetail(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      excerpt: json['excerpt'] ?? '',
      imageThumbnail: json['image_thumbnail'],
      image: json['image'],
      category: BlogCategory.fromString(json['category']),
      isFeatured: json['is_featured'] == true || json['is_featured'] == 1,
      isPinned: json['is_pinned'] == true || json['is_pinned'] == 1,
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'])
          : null,
      viewCount: json['view_count'] is int
          ? json['view_count']
          : int.tryParse(json['view_count']?.toString() ?? '0') ?? 0,
      content: json['content'] ?? '',
      status: json['status'] ?? 'published',
      authorName: json['author_name'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      attachments: attachmentList,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    baseJson['content'] = content;
    baseJson['status'] = status;
    baseJson['author_name'] = authorName;
    baseJson['created_at'] = createdAt?.toIso8601String();
    baseJson['attachments'] = attachments.map((a) => a.toJson()).toList();
    return baseJson;
  }

  @override
  List<Object?> get props => [
        ...super.props,
        content,
        status,
        authorName,
        createdAt,
        attachments,
      ];
}
