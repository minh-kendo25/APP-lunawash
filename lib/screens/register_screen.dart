import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import '../services/api_service.dart';
import 'main_layout.dart';
import '../widgets/auth_background.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (fullName.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu xác nhận không khớp')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await ApiService.register(fullName, email, phone, password);

    setState(() {
      _isLoading = false;
    });

    if (result.containsKey('error')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Đăng ký thất bại')),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng ký thành công! Vui lòng đăng nhập.')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final String clientId = '897520379970-6qi5jkhmqgnmsisintk6gopj0mi1a6sm.apps.googleusercontent.com';
      
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? clientId : null, 
        serverClientId: clientId,
      );
      GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) {
        setState(() => _isLoading = false);
        return; 
      }
      
      GoogleSignInAuthentication auth = await account.authentication;
      String? idToken = auth.idToken;

      // Workaround for Flutter Web (Google Identity Services doesn't return idToken on signIn)
      if (idToken == null) {
        account = await googleSignIn.signInSilently();
        if (account != null) {
          auth = await account.authentication;
          idToken = auth.idToken;
        }
      }
      
      if (idToken != null) {
        final result = await ApiService.googleLogin(idToken);
        if (result.containsKey('error')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] ?? 'Đăng nhập Google thất bại')),
          );
        } else {
          if (result['token'] != null) {
            await ApiService.saveToken(result['token']);
          }
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainLayout()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đăng ký bằng Google: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildTextField(String hint, IconData icon, {
    TextEditingController? controller, 
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.black45),
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
    );
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
            'Đăng ký tài khoản',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F2050),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Điền thông tin bên dưới để tạo tài khoản mới.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 32),

          // Full Name
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Họ và tên', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
          ),
          _buildTextField('Nhập họ và tên của bạn', Icons.person_outline, controller: _fullNameController),
          const SizedBox(height: 16),

          // Email
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Email', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
          ),
          _buildTextField('Nhập email của bạn', Icons.mail_outline, keyboardType: TextInputType.emailAddress, controller: _emailController),
          const SizedBox(height: 16),

          // Phone
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Số điện thoại', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
          ),
          _buildTextField('Nhập số điện thoại', Icons.phone_outlined, keyboardType: TextInputType.phone, controller: _phoneController),
          const SizedBox(height: 16),

          // Password
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Mật khẩu', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
          ),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: 'Nhập mật khẩu',
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

          // Confirm Password
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Xác nhận mật khẩu', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
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

          // Register Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _register,
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
                    'Đăng ký',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
            ),
          ),
          
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: Divider()),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Hoặc đăng ký bằng', style: TextStyle(color: Colors.black45)),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 24),
          
          // Google Sign In Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _googleSignIn,
              icon: Image.network(
                'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
                height: 24,
              ),
              label: const Text(
                'Tiếp tục với Google',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
