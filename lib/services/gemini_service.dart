import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiUrl = 'http://10.0.2.2:5010/api/AI/chat';
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
          'contents': _chatHistory
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponseText = data['text'] as String;
        
        // Add AI response to history
        _chatHistory.add({
          'role': 'model',
          'parts': [{'text': aiResponseText}]
        });
        
        return aiResponseText;
      } else {
        throw Exception('Failed to communicate with Backend AI API: ${response.statusCode} - ${response.body}');
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
