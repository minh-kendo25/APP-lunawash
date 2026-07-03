import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _p1 = 'AQ.Ab8RN6KaJwRN';
  static const String _p2 = '7t91-VgUGbY0ZQ2W5';
  static const String _p3 = 'FHL9wZL5QeoLD-Y4NFWsQ';
  static const String _apiKey = '$_p1$_p2$_p3';
  static const String _apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey';

  static const String _systemInstruction = '''
Bạn là Luna AI Assistant - Trợ lý hỗ trợ khách hàng thông minh của hệ thống rửa xe cao cấp LunaWash.
Sứ mệnh của bạn là tư vấn dịch vụ, hướng dẫn đặt lịch và giải đáp thắc mắc nhiệt tình, chuyên nghiệp.

QUY TẮC GIAO TIẾP VÀ ĐỊNH DẠNG:
1. Luôn chào hỏi thân thiện, xưng "tôi" hoặc "Luna AI", gọi khách hàng là "bạn" hoặc "quý khách".
2. BẮT BUỘC TRÌNH BÀY DỄ NHÌN: Xuống hàng rõ ràng, chia đoạn ngắn, sử dụng gạch đầu dòng (-) hoặc các biểu tượng (✅, 📍, 💰) để liệt kê. KHÔNG viết một đoạn văn dài ngoằn.
3. Trả lời chính xác dựa trên thông tin được cung cấp bên dưới. Nếu không biết, hãy khuyên khách gọi Hotline.

THÔNG TIN VỀ LUNAWASH:
- Hotline: 1900 8888 | Email: support@lunawash.vn
- Các chi nhánh:
  + LunaWash Linh Đông (Thủ Đức, HCM)
''';

  static List<Map<String, dynamic>> _chatHistory = [];

  static Future<String> sendMessage(String message) async {
    // Add user message to history
    _chatHistory.add({
      'role': 'user',
      'parts': [{'text': message}]
    });

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'systemInstruction': {
            'parts': [{'text': _systemInstruction}]
          },
          'contents': _chatHistory,
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 1000,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponseText = data['candidates'][0]['content']['parts'][0]['text'] as String;
        
        // Add AI response to history
        _chatHistory.add({
          'role': 'model',
          'parts': [{'text': aiResponseText}]
        });
        
        return aiResponseText;
      } else {
        throw Exception('Failed to communicate with Gemini API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // Remove the last user message if failed
      _chatHistory.removeLast();
      throw Exception('Lỗi kết nối AI: $e');
    }
  }

  static void resetChat() {
    _chatHistory.clear();
  }
}
