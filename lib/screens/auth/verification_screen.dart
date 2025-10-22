import 'package:flutter/material.dart';
import 'package:ecom_frontend/providers/auth_provider.dart';
import 'package:ecom_frontend/screens/auth/create_new_password_screen.dart';
import 'package:ecom_frontend/screens/auth/login_screen.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:ecom_frontend/widgets/primary_button.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

// Enum để xác định mục đích của màn hình OTP
enum VerificationPurpose { verifyEmail, resetPassword }

class VerificationScreen extends StatefulWidget {
  final String email;
  final VerificationPurpose purpose;

  const VerificationScreen({
    super.key,
    required this.email,
    required this.purpose,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _pinController = TextEditingController();
  bool _isLoading = false;

  Future<void> _confirmCode() async {
    if (_pinController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đủ 6 số OTP")),
      );
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();
    String? error;

    if (widget.purpose == VerificationPurpose.verifyEmail) {
      // Logic cho xác thực email
      error = await authProvider.verifyEmail(widget.email, _pinController.text);
      if (mounted && error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Xác thực thành công! Vui lòng đăng nhập."),
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } else {
      // Logic cho reset mật khẩu
      error = null;
      if (mounted && error == null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateNewPasswordScreen(
              email: widget.email,
              code: _pinController.text,
            ),
          ),
        );
      }
    }

    if (mounted && error != null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- PHẦN CHỈNH SỬA ---
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: const TextStyle(fontSize: 22, color: kTextColor),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // Thay vì Colors.transparent, chúng ta dùng màu xám nhạt
        border: Border.all(color: kSecondaryTextColor.withValues(alpha: 0.4)),
      ),
    );
    // --- KẾT THÚC PHẦN CHỈNH SỬA ---

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text("Verification", style: TextStyle(color: kTextColor)),
        backgroundColor: kBackgroundColor,
        elevation: 0,
        leading: const BackButton(color: kTextColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kDefaultPadding * 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "OTP Code Verification",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "We have sent an OTP code to your email\n${widget.email}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: kSecondaryTextColor),
            ),
            const SizedBox(height: 32),
            Pinput(
              controller: _pinController,
              length: 6, // Backend yêu cầu 6 số
              defaultPinTheme: defaultPinTheme, // Sử dụng theme đã chỉnh sửa
              focusedPinTheme: defaultPinTheme.copyWith(
                decoration: defaultPinTheme.decoration!.copyWith(
                  border: Border.all(color: kPrimaryColor, width: 2),
                ),
              ),
              onCompleted: (pin) => _confirmCode(),
            ),
            const SizedBox(height: 24),
            // TODO: Thêm logic resend code
            TextButton(
              onPressed: () {
                /* TODO: Resend logic */
              },
              child: const Text(
                "Didn't receive email? Resend code",
                style: TextStyle(color: kSecondaryTextColor),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: "Confirm",
              onPressed: _confirmCode,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
