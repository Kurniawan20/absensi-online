import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../bloc/home/home_state.dart';

class HomeRepository {
  Future<UserProfile> getUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('${ApiConstants.BASE_URL}/profile'),
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
        Uri.parse('${ApiConstants.BASE_URL}/absen/status'),
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
        Uri.parse('${ApiConstants.BASE_URL}/pengumuman'),
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

  Future<Map<String, dynamic>> getBlogPosts({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse(
          '${ApiConstants.BASE_URL}/blog?page=$page&limit=$limit',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (data['rcode'] == '00') {
        final List<BlogPost> posts = (data['data'] as List)
            .map((item) => BlogPost.fromJson(item))
            .toList();

        return {
          'posts': posts,
          'hasMore': data['has_more'] ?? false,
        };
      } else {
        throw Exception(data['message'] ?? 'Failed to load blog posts');
      }
    } catch (e) {
      throw Exception('Failed to load blog posts: ${e.toString()}');
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
