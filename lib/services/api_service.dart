import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Tự động nhận diện nền tảng để trỏ đúng IP của Backend
  static String get baseUrl {
    // Dùng Render Backend cho Production
    return 'https://lunawash-be.onrender.com/api';
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

  static Future<List<dynamic>> fetchBanners() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/banners?platform=App'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'] ?? [];
        }
        return [];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> saveVoucher(String voucherId) async {
    try {
      final token = await getToken();
      if (token == null) return {'error': 'Unauthorized'};
      
      final response = await http.post(
        Uri.parse('$baseUrl/vouchers/save/$voucherId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'error': data['message'] ?? 'Failed to save voucher'};
      }
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  static Future<List<dynamic>> getMyVouchers() async {
    try {
      final token = await getToken();
      if (token == null) return [];
      
      final response = await http.get(
        Uri.parse('$baseUrl/vouchers/my-vouchers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'] ?? [];
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getMembershipSettings() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/Membership/settings'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
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

  static Future<List<dynamic>> getVehicles() async {
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

  static Future<Map<String, dynamic>> googleLogin(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/google-login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': token}),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        try {
          final errData = json.decode(response.body);
          return {'error': errData['message'] ?? 'Google login failed'};
        } catch (_) {
          return {'error': 'Google login failed: ${response.statusCode}'};
        }
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

  // Hủy lịch đặt
  static Future<bool> cancelBooking(String bookingId) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('$baseUrl/bookings/$bookingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Xóa cứng lịch đặt (khi VNPAY hủy)
  static Future<bool> hardDeleteBooking(String id) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('$baseUrl/bookings/hard-delete/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Lấy link thanh toán VNPAY
  static Future<String?> getVnPayUrl(String bookingId) async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/Payments/create-vnpay-url/$bookingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['url'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Lấy đánh giá của một booking
  static Future<Map<String, dynamic>?> getReviewByBooking(String bookingId) async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/reviews/booking/$bookingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Gửi hoặc cập nhật đánh giá
  static Future<bool> submitReview(Map<String, dynamic> payload, {bool isEdit = false, String? bookingId}) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final url = isEdit ? '$baseUrl/reviews/$bookingId' : '$baseUrl/reviews';
      final method = isEdit ? http.put : http.post;

      final response = await method(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payload),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // Lấy danh sách khung giờ đã được đặt
  static Future<List<dynamic>> getOccupiedSlots(String date, String washSlotId) async {
    try {
      final token = await getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/bookings/occupied-slots?date=$date&washSlotId=$washSlotId'),
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

  // Tạo lịch đặt mới
  static Future<Map<String, dynamic>> createBooking(Map<String, dynamic> payload) async {
    try {
      final token = await getToken();
      if (token == null) return {'error': 'Unauthorized'};

      final response = await http.post(
        Uri.parse('$baseUrl/bookings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        String errText = 'Không thể tạo lịch đặt.';
        try {
          final errData = json.decode(response.body);
          if (errData['message'] != null) errText = errData['message'];
        } catch (_) {}
        return {'error': errText};
      }
    } catch (e) {
      return {'error': 'Lỗi mạng: $e'};
    }
  }
}
