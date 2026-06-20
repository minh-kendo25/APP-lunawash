import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Tự động nhận diện nền tảng để trỏ đúng IP của Backend
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5010/api';
    }
    // Nếu chạy trên máy ảo Android
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5010/api';
    }
    return 'http://localhost:5010/api';
  }

  static Future<List<dynamic>> fetchServices() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/services'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load services: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Login failed: ${response.statusCode}'};
      }
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> register(String fullName, String email, String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'fullName': fullName,
          'email': email,
          'phone': phone,
          'password': password
        }),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Registration failed: ${response.statusCode}'};
      }
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }
  // Lưu Token sau khi login thành công
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  // Lấy Token hiện tại
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // Đăng xuất (xóa token)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  // Lấy User Profile
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final token = await getToken();
      if (token == null) return {'error': 'Unauthorized'};

      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Failed to fetch profile'};
      }
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  // Cập nhật Profile
  static Future<Map<String, dynamic>> updateProfile(String fullName, String phone, String address) async {
    try {
      final token = await getToken();
      if (token == null) return {'error': 'Unauthorized'};

      final response = await http.put(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'fullName': fullName,
          'phone': phone,
          'address': address,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Cập nhật thất bại: ${response.statusCode}'};
      }
    } catch (e) {
      return {'error': 'Lỗi mạng: $e'};
    }
  }

  // Lấy danh sách xe
  static Future<List<dynamic>> getMyVehicles() async {
    try {
      final token = await getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/vehicles'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Thêm xe
  static Future<Map<String, dynamic>> addVehicle(String name, String license, String color, String vehicleTypeId) async {
    try {
      final token = await getToken();
      if (token == null) return {'error': 'Unauthorized'};

      final response = await http.post(
        Uri.parse('$baseUrl/vehicles'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'name': name,
          'license': license,
          'color': color,
          'vehicleTypeId': vehicleTypeId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Thêm xe thất bại: ${response.statusCode}'};
      }
    } catch (e) {
      return {'error': 'Lỗi mạng: $e'};
    }
  }

  // Xóa xe
  static Future<Map<String, dynamic>> deleteVehicle(String id) async {
    try {
      final token = await getToken();
      if (token == null) return {'error': 'Unauthorized'};

      final response = await http.delete(
        Uri.parse('$baseUrl/vehicles/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Xóa xe thất bại: ${response.statusCode}'};
      }
    } catch (e) {
      return {'error': 'Lỗi mạng: $e'};
    }
  }

  // Lấy lịch sử đặt lịch
  static Future<List<dynamic>> getBookingHistory() async {
    try {
      final token = await getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/bookings/history'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
