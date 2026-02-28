import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../bloc/home/home_state.dart';
import '../models/working_hours.dart';

class HomeRepository {
  /// Get active working hours from API
  Future<WorkingHours?> getActiveWorkingHours() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse(ApiConstants.workingHoursActive),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (data['rcode'] == '00' && data['data'] != null) {
        return WorkingHours.fromJson(data['data']);
      } else {
        // No active working hours found
        return null;
      }
    } catch (e) {
      print('Error loading working hours: $e');
      return null;
    }
  }

  Future<UserProfile> getUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse(ApiConstants.profile),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (data['rcode'] == '00') {
        return UserProfile.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to load profile');
      }
    } catch (e) {
      throw Exception('Failed to load profile: ${e.toString()}');
    }
  }

  Future<AttendanceStatus> getAttendanceStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse(ApiConstants.attendanceStatus),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (data['rcode'] == '00') {
        return AttendanceStatus.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to load attendance status');
      }
    } catch (e) {
      throw Exception('Failed to load attendance status: ${e.toString()}');
    }
  }

  Future<List<Announcement>> getAnnouncements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse(ApiConstants.announcements),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (data['rcode'] == '00') {
        return (data['data'] as List)
            .map((item) => Announcement.fromJson(item))
            .toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to load announcements');
      }
    } catch (e) {
      throw Exception('Failed to load announcements: ${e.toString()}');
    }
  }

  /// Get published blog posts
  /// [category] - Filter by category: announcement, news, event, info, other
  /// [limit] - Number of posts to return (default: 10)
  Future<List<BlogPost>> getBlogPosts({
    BlogCategory? category,
    int limit = 10,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // Build query parameters
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };
      if (category != null) {
        queryParams['category'] = category.value;
      }

      final uri = Uri.parse(ApiConstants.blogsPublished)
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (data['rcode'] == '00') {
        final List<BlogPost> posts = (data['data'] as List)
            .map((item) => BlogPost.fromJson(item))
            .toList();
        return posts;
      } else {
        throw Exception(data['message'] ?? 'Failed to load blog posts');
      }
    } catch (e) {
      throw Exception('Failed to load blog posts: ${e.toString()}');
    }
  }

  /// Get featured blog posts for banner/carousel
  /// [limit] - Number of posts to return (default: 5)
  Future<List<BlogPost>> getFeaturedBlogs({int limit = 5}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final uri = Uri.parse(ApiConstants.blogsFeatured)
          .replace(queryParameters: {'limit': limit.toString()});

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (data['rcode'] == '00') {
        final List<BlogPost> posts = (data['data'] as List)
            .map((item) => BlogPost.fromJson(item))
            .toList();
        return posts;
      } else {
        throw Exception(data['message'] ?? 'Failed to load featured blogs');
      }
    } catch (e) {
      throw Exception('Failed to load featured blogs: ${e.toString()}');
    }
  }

  /// Get blog post detail by ID
  Future<BlogPostDetail> getBlogDetail(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('${ApiConstants.blogsDetail}/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (data['rcode'] == '00') {
        return BlogPostDetail.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to load blog detail');
      }
    } catch (e) {
      throw Exception('Failed to load blog detail: ${e.toString()}');
    }
  }

  /// Get blog post detail by slug
  Future<BlogPostDetail> getBlogBySlug(String slug) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('${ApiConstants.blogsBySlug}/$slug'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (data['rcode'] == '00') {
        return BlogPostDetail.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to load blog');
      }
    } catch (e) {
      throw Exception('Failed to load blog: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      throw Exception('Failed to logout: ${e.toString()}');
    }
  }
}
