import 'package:flutter/material.dart';
import 'package:ecom_frontend/providers/auth_provider.dart';
import 'package:ecom_frontend/screens/auth/forgot_password_screen.dart';
import 'package:ecom_frontend/screens/auth/register_screen.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:ecom_frontend/widgets/custom_text_field.dart';
import 'package:ecom_frontend/widgets/primary_button.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Đã cập nhật giá trị theo log bạn gửi
  final _emailController = TextEditingController(text: "seller1@tempmail.vn");
  final _passwordController = TextEditingController(text: "admin123");
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  // --- HÀM _login ĐÃ SỬA LỖI RÁCH THỜI GIAN (RACE CONDITION) ---
  Future<void> _login() async {
    // 1. Chỉ bật spinner nếu widget còn tồn tại
    if (!mounted) return;
    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    String? error; // Biến local để lưu lỗi

    try {
      // 2. Gọi hàm login
      error = await authProvider.login(
        _emailController.text,
        _passwordController.text,
      );
    } catch (e) {
      // 3. Bắt lỗi không mong muốn (nếu có)
      error = e.toString();
    } finally {
      // 4. KHỐI FINALLY: LUÔN CHẠY SAU TRY/CATCH/AWAIT
      if (mounted) {
        // Đặt _isLoading về false để giải phóng nút. BẮT BUỘC phải gọi
        setState(() => _isLoading = false);

        if (error != null) {
          // 5. Nếu có lỗi, hiển thị lỗi.
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error!)));
        }
        // Nếu thành công (error == null), AuthProvider đã chuyển trạng thái
        // và AppWrapper sẽ tự động điều hướng.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(backgroundColor: kBackgroundColor, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kDefaultPadding * 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome Back",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Please enter your email and password to sign in",
              style: TextStyle(fontSize: 16, color: kSecondaryTextColor),
            ),
            const SizedBox(height: 32),
            CustomTextField(
              controller: _emailController,
              labelText: "Email",
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _passwordController,
              labelText: "Password",
              prefixIcon: Icons.lock_outline,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: kSecondaryTextColor,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() => _rememberMe = value ?? false);
                      },
                      activeColor: kPrimaryColor,
                    ),
                    const Text(
                      "Remember me",
                      style: TextStyle(color: kSecondaryTextColor),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(color: kPrimaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: "Login with Email",
              onPressed: _login,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account? ",
                  style: TextStyle(color: kSecondaryTextColor),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: const Text(
                    "Register",
                    style: TextStyle(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
