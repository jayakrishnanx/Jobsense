import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/job.dart';
import '../models/notification.dart';
import '../models/user.dart';

class ApiService {
  static final ApiService instance = ApiService._internal();
  ApiService._internal();

  String? authToken;

  /// Automatically resolves host based on runtime platform
  String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:5000/api';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5000/api';
      }
    } catch (_) {}
    return 'http://127.0.0.1:5000/api';
  }

  Map<String, String> get _headers {
    final map = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (authToken != null && authToken!.isNotEmpty) {
      map['Authorization'] = 'Bearer $authToken';
    }
    return map;
  }

  // ==================== JOBS API ====================

  Future<List<Job>> fetchJobs({String? search, String? category, String? qualification}) async {
    try {
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (category != null && category != 'All' && category != 'All Categories') {
        queryParams['category'] = category;
      }
      if (qualification != null && qualification != 'All') {
        queryParams['qualification'] = qualification;
      }

      final uri = Uri.parse('$baseUrl/jobs').replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] is List) {
          return (data['data'] as List).map((j) => Job.fromJson(j)).toList();
        }
      }
    } catch (e) {
      debugPrint('ApiService.fetchJobs error: $e');
    }
    return [];
  }

  Future<Job?> fetchJobById(String id) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/jobs/$id'), headers: _headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] != null) {
          return Job.fromJson(data['data']);
        }
      }
    } catch (e) {
      debugPrint('ApiService.fetchJobById error: $e');
    }
    return null;
  }

  Future<AiSummaryData?> generateJobAiSummary(String jobId) async {
    try {
      final res = await http
          .post(Uri.parse('$baseUrl/jobs/$jobId/ai-summary'), headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] != null) {
          return AiSummaryData.fromJson(data['data']);
        }
      }
    } catch (e) {
      debugPrint('ApiService.generateJobAiSummary error: $e');
    }
    return null;
  }

  // ==================== AUTH API (EMAIL OTP & EMAIL PASSWORD) ====================

  /// Trigger system auto-generated 6-digit OTP dispatched to candidate's email
  Future<Map<String, dynamic>?> sendEmailOtp(String email, {bool forLogin = false}) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/send-email-otp'),
            headers: _headers,
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
              'forLogin': forLogin,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      return data;
    } catch (e) {
      debugPrint('ApiService.sendEmailOtp error: $e');
    }
    return null;
  }

  /// Verify 6-digit system Email OTP
  Future<Map<String, dynamic>?> verifyEmailOtp(String email, String otp) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/verify-email-otp'),
            headers: _headers,
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
              'otp': otp.trim(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        if (data['token'] != null) {
          authToken = data['token'];
        }
      }
      return data;
    } catch (e) {
      debugPrint('ApiService.verifyEmailOtp error: $e');
    }
    return null;
  }

  /// Unified Login with Email/Username and Password
  Future<Map<String, dynamic>?> login({required String identifier, required String password}) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: _headers,
            body: jsonEncode({
              'identifier': identifier.trim(),
              'password': password.trim(),
            }),
          )
          .timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        authToken = data['token'];
      }
      return data;
    } catch (e) {
      debugPrint('ApiService.login error: $e');
    }
    return null;
  }

  /// Send Password Reset OTP Code to email
  Future<Map<String, dynamic>?> forgotPassword(String email) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/forgot-password'),
            headers: _headers,
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      return data;
    } catch (e) {
      debugPrint('ApiService.forgotPassword error: $e');
    }
    return null;
  }

  /// Verify OTP and Reset Password
  Future<Map<String, dynamic>?> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/reset-password'),
            headers: _headers,
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
              'otp': otp.trim(),
              'newPassword': newPassword.trim(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      return data;
    } catch (e) {
      debugPrint('ApiService.resetPassword error: $e');
    }
    return null;
  }

  /// Candidate Registration with Email & Password
  Future<Map<String, dynamic>?> registerUser(Map<String, dynamic> userData) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: _headers,
            body: jsonEncode(userData),
          )
          .timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body);
      if ((res.statusCode == 200 || res.statusCode == 201) && data['success'] == true) {
        authToken = data['token'];
        return {
          'token': data['token'],
          'user': User.fromJson(data['user']),
        };
      }
    } catch (e) {
      debugPrint('ApiService.registerUser error: $e');
    }
    return null;
  }

  Future<User?> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    try {
      final res = await http
          .put(
            Uri.parse('$baseUrl/users/$userId'),
            headers: _headers,
            body: jsonEncode(updates),
          )
          .timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true && data['data'] != null) {
        return User.fromJson(data['data']);
      }
    } catch (e) {
      debugPrint('ApiService.updateUserProfile error: $e');
    }
    return null;
  }

  Future<List<JobNotification>> fetchNotifications() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/notifications'), headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] is List) {
          return (data['data'] as List).map((n) => JobNotification.fromJson(n)).toList();
        }
      }
    } catch (e) {
      debugPrint('ApiService.fetchNotifications error: $e');
    }
    return [];
  }

  Future<bool> markAllNotificationsRead() async {
    try {
      final res = await http
          .post(Uri.parse('$baseUrl/notifications/mark-all-read'), headers: _headers)
          .timeout(const Duration(seconds: 8));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService.markAllNotificationsRead error: $e');
      return false;
    }
  }
}

