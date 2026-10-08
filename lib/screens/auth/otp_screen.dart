import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/app_state.dart';
import '../../widgets/custom_button.dart';
import '../admin/admin_main_screen.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';

class OtpScreen extends StatefulWidget {
  final String email;

  const OtpScreen({
    super.key,
    required this.email,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController otpController = TextEditingController();
  bool _isLoading = false;
  int _resendCountdown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Keep text field blank so candidate enters code received in real email
    otpController.text = '';
    _startCountdown();
  }

  void _startCountdown() {
    setState(() => _resendCountdown = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    otpController.dispose();
    super.dispose();
  }

  void _verifyOtp() async {
    final enteredOtp = otpController.text.trim();

    if (enteredOtp.isEmpty || enteredOtp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the full 6-digit OTP code sent to your email'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Call real backend verify-email-otp endpoint
    final verifyRes = await appState.verifyEmailOtp(widget.email, enteredOtp);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (verifyRes == null || verifyRes['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(verifyRes?['message'] ?? 'Invalid or expired OTP. Please check your email and try again.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final isNewUser = verifyRes['isNewUser'] == true;
    final role = verifyRes['role'];

    if (!isNewUser) {
      if (role == 'admin') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome, ${appState.currentAdmin?.name ?? 'Administrator'}!'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AdminMainScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome back, ${appState.currentUser?.name ?? 'User'}!'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email verified! Please complete your candidate registration.'),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RegisterScreen(email: widget.email),
        ),
      );
    }
  }

  void _resendOtp() async {
    if (_resendCountdown > 0) return;

    setState(() => _isLoading = true);
    final res = await appState.sendEmailOtp(widget.email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res != null && res['success'] == true) {
      _startCountdown();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A fresh verification code has been dispatched to ${widget.email}'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to resend email OTP. Please check your connection.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Verification'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Icon
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mark_email_read_outlined,
                  size: 36,
                  color: theme.colorScheme.primary,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Enter Verification Code',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Dispatched to ${widget.email}',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Change'),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // 6-digit OTP Field (User types code from real email)
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 12,
                ),
                decoration: const InputDecoration(
                  hintText: '------',
                  hintStyle: TextStyle(
                    fontSize: 28,
                    letterSpacing: 12,
                    color: Colors.grey,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                  helperText: 'Check your email inbox & enter the 6-digit code',
                  helperStyle: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onSubmitted: (_) => _verifyOtp(),
              ),

              const SizedBox(height: 24),

              // Verify OTP Button
              CustomButton(
                text: 'Verify & Sign In',
                isLoading: _isLoading,
                onPressed: _verifyOtp,
              ),

              const SizedBox(height: 20),

              // Resend with countdown
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Didn\'t receive the email? ',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                  TextButton(
                    onPressed: _resendCountdown == 0 ? _resendOtp : null,
                    child: Text(
                      _resendCountdown > 0
                          ? 'Resend in ${_resendCountdown}s'
                          : 'Resend Code',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _resendCountdown > 0
                            ? Colors.grey
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}