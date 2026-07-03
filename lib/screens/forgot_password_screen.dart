import 'package:flutter/material.dart';
import '../widgets/auth_background.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập email')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate API Call
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi liên kết khôi phục mật khẩu vào email của bạn!')),
        );
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: Color(0xFF0F2050)),
          ),
          const SizedBox(height: 24),
          
          // Title
          const Text(
            'Khôi phục mật khẩu',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F2050),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nhập email bạn đã đăng ký để nhận liên kết khôi phục mật khẩu.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Email Field
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Email đăng ký', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
          ),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              hintText: 'Nhập email của bạn',
              prefixIcon: const Icon(Icons.mail_outline, color: Colors.black45),
              filled: true,
              fillColor: Colors.white.withOpacity(0.9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF4EE1F1), width: 2),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 32),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F2050),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading 
                ? const SizedBox(
                    height: 20, 
                    width: 20, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                : const Text(
                    'Gửi yêu cầu',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
