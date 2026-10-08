import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/app_state.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'register_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String? initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Step 1: Email Form
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _emailFormKey = GlobalKey<FormState>();
  bool _isSendingOtp = false;

  // Step 2: Reset Form
  int _currentStep = 0; // 0 = Enter Email, 1 = Enter OTP & New Password
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final GlobalKey<FormState> _resetFormKey = GlobalKey<FormState>();
  bool _isResetting = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // Timer for Resend OTP
  Timer? _resendTimer;
  int _resendSeconds = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  void _showNotRegisteredAlert(String email) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_off_outlined, color: Colors.amber.shade900, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Account Not Found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No registered JobSense candidate account was found for:',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                email,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please check your email address or click "Register Now" to create your free candidate account.',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RegisterScreen(email: email),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Register Now'),
          ),
        ],
      ),
    );
  }

  void _sendResetCode() async {
    if (!_emailFormKey.currentState!.validate()) return;

    final email = _emailController.text.trim().toLowerCase();
    setState(() => _isSendingOtp = true);

    final res = await appState.forgotPasswordAsync(email);

    if (!mounted) return;
    setState(() => _isSendingOtp = false);

    if (res != null && res['success'] == true) {
      _startResendTimer();
      setState(() => _currentStep = 1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Password reset code sent to $email'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      if (res != null && res['notRegistered'] == true) {
        _showNotRegisteredAlert(email);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res?['message'] ?? 'Failed to send reset code. Please try again.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _resendCode() async {
    if (_resendSeconds > 0) return;
    final email = _emailController.text.trim().toLowerCase();
    final res = await appState.forgotPasswordAsync(email);

    if (!mounted) return;
    if (res != null && res['success'] == true) {
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A fresh reset code has been sent to $email'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res?['message'] ?? 'Failed to resend code.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _submitResetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;

    final email = _emailController.text.trim().toLowerCase();
    final otp = _otpController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    setState(() => _isResetting = true);

    final res = await appState.resetPasswordAsync(
      email: email,
      otp: otp,
      newPassword: newPassword,
    );

    if (!mounted) return;
    setState(() => _isResetting = false);

    if (res != null && res['success'] == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Password Reset',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: const Text(
            'Your password has been reset successfully! You can now log in with your new credentials.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context); // Go back to login screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Back to Sign In'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res?['message'] ?? 'Failed to reset password. Please check your OTP.'),
          backgroundColor: Colors.red.shade700,
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
        title: const Text('Reset Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep == 1) {
              setState(() => _currentStep = 0);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Icon
              Center(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _currentStep == 0 ? Icons.lock_reset_rounded : Icons.mark_email_read_outlined,
                    size: 36,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title & Subtitle
              Center(
                child: Text(
                  _currentStep == 0 ? 'Forgot Your Password?' : 'Enter Verification Code',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              Center(
                child: Text(
                  _currentStep == 0
                      ? 'Enter your registered email address and we will send you a 6-digit OTP code to securely reset your password.'
                      : 'We sent a 6-digit password reset code to your email. Enter the code and your new password below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // STEP 0: Email Input
              if (_currentStep == 0) ...[
                Form(
                  key: _emailFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        controller: _emailController,
                        label: 'Registered Email Address',
                        hint: 'e.g. rahul.sharma@example.com',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter your email address';
                          }
                          if (!val.contains('@') || !val.contains('.')) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'Send Reset Code',
                        isLoading: _isSendingOtp,
                        onPressed: _sendResetCode,
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, size: 16),
                          label: const Text('Back to Sign In'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // STEP 1: OTP + New Password Input
              if (_currentStep == 1) ...[
                // Destination Email Chip with Change Option
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.mail_outline_rounded, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Code sent to:',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                            Text(
                              _emailController.text.trim().toLowerCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _currentStep = 0),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Change', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Form(
                  key: _resetFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        controller: _otpController,
                        label: '6-Digit Reset Code',
                        hint: 'Enter 6-digit OTP from email',
                        keyboardType: TextInputType.number,
                        prefixIcon: const Icon(Icons.pin_outlined),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter the 6-digit OTP code';
                          }
                          if (val.trim().length != 6) {
                            return 'OTP code must be 6 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _newPasswordController,
                        label: 'New Password',
                        hint: 'At least 6 characters',
                        obscureText: _obscureNewPassword,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() => _obscureNewPassword = !_obscureNewPassword);
                          },
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter a new password';
                          }
                          if (val.trim().length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm New Password',
                        hint: 'Re-enter your new password',
                        obscureText: _obscureConfirmPassword,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                          },
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please confirm your new password';
                          }
                          if (val.trim() != _newPasswordController.text.trim()) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'Reset Password & Proceed',
                        isLoading: _isResetting,
                        onPressed: _submitResetPassword,
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: _resendSeconds > 0
                            ? Text(
                                'Resend code in ${_resendSeconds}s',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              )
                            : TextButton.icon(
                                onPressed: _resendCode,
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('Resend Reset Code'),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
