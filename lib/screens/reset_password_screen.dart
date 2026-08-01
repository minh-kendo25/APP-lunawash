import 'package:flutter/material.dart';
import '../widgets/auth_background.dart';
import '../services/api_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() async {
    final otp = _otpController.text.trim();
    final newPassword = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (otp.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu xác nhận không khớp')),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu phải có ít nhất 6 ký tự')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await ApiService.resetPassword(widget.email, otp, newPassword);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (result.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'].toString()), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đổi mật khẩu thành công! Vui lòng đăng nhập lại.'), backgroundColor: Colors.green),
        );
        // Quay về màn hình đăng nhập (pop 2 lần: màn hình này và màn hình quên pass)
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    }
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
            'Đặt lại mật khẩu',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F2050),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mã xác nhận đã được gửi đến:\n${widget.email}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // OTP Field
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Mã xác nhận (OTP)', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
          ),
          TextField(
            controller: _otpController,
            decoration: InputDecoration(
              hintText: 'Nhập mã OTP',
              prefixIcon: const Icon(Icons.security, color: Colors.black45),
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
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // New Password Field
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Mật khẩu mới', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
          ),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: 'Nhập mật khẩu mới',
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.black45),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.black45,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
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
          ),
          const SizedBox(height: 16),

          // Confirm Password Field
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Xác nhận mật khẩu mới', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
          ),
          TextField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              hintText: 'Nhập lại mật khẩu',
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.black45),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.black45,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
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
                    'Đặt lại mật khẩu',
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
