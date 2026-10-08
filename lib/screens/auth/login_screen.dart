import 'package:flutter/material.dart';
import '../../data/app_state.dart';
import '../../services/session_storage_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../admin/admin_main_screen.dart';
import '../home/home_screen.dart';
import 'forgot_password_screen.dart';
import 'otp_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _selectedMethodIndex = 0; // 0: Email & Password, 1: Email OTP

  // Email & Password Form
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();
  bool _isLoginLoading = false;
  bool _obscurePassword = true;

  // Email OTP Form
  final TextEditingController otpEmailController = TextEditingController();
  final GlobalKey<FormState> _otpFormKey = GlobalKey<FormState>();
  bool _isOtpLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLastIdentifier();
  }

  Future<void> _loadLastIdentifier() async {
    final lastId = await SessionStorageService.instance.getLastIdentifier();
    if (lastId != null && lastId.isNotEmpty && mounted) {
      setState(() {
        emailController.text = lastId;
        otpEmailController.text = lastId;
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    otpEmailController.dispose();
    super.dispose();
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

  void _loginWithPassword() async {
    if (!_loginFormKey.currentState!.validate()) {
      return;
    }

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    setState(() => _isLoginLoading = true);

    final res = await appState.loginDetailedAsync(email, password);

    if (!mounted) return;
    setState(() => _isLoginLoading = false);

    if (res['success'] == true) {
      final role = res['role'] as AuthRole;
      if (role == AuthRole.admin) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome, ${appState.currentAdmin?.name ?? "Administrator"}!'),
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
            content: Text('Welcome back, ${appState.currentUser?.name ?? "User"}!'),
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
      // If email is not registered, show the dedicated Alert Dialog
      if (res['notRegistered'] == true) {
        _showNotRegisteredAlert(email);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Incorrect password. Please verify your credentials.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _sendEmailOtp() async {
    if (!_otpFormKey.currentState!.validate()) {
      return;
    }

    final email = otpEmailController.text.trim().toLowerCase();
    setState(() => _isOtpLoading = true);

    // Call backend send-email-otp
    final res = await appState.sendEmailOtp(email);

    if (!mounted) return;
    setState(() => _isOtpLoading = false);

    if (res == null || res['success'] != true) {
      if (res != null && res['notRegistered'] == true) {
        _showNotRegisteredAlert(email);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res?['message'] ?? 'This email is not registered. Please register first.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('A 6-digit verification code has been dispatched to $email. Please check your inbox.'),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtpScreen(
          email: email,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Logo Header
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                const Center(
                  child: Text(
                    'Welcome to JobSense',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                Center(
                  child: Text(
                    'Sign in to access Kerala PSC, SSC, and UPSC job updates & eligibility alerts.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Method Tabs: [ Email & Password ] [ Email OTP ]
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedMethodIndex = 0);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedMethodIndex == 0
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                  size: 18,
                                  color: _selectedMethodIndex == 0
                                      ? Colors.white
                                      : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Password Login',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: _selectedMethodIndex == 0
                                        ? Colors.white
                                        : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedMethodIndex = 1);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedMethodIndex == 1
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.mail_outline_rounded,
                                  size: 18,
                                  color: _selectedMethodIndex == 1
                                      ? Colors.white
                                      : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Email OTP',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: _selectedMethodIndex == 1
                                        ? Colors.white
                                        : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // TAB 1: Password Login Form
                if (_selectedMethodIndex == 0) ...[
                  Form(
                    key: _loginFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomTextField(
                          controller: emailController,
                          label: 'Email Address or Username',
                          hint: 'e.g. rahul.sharma@example.com or admin',
                          prefixIcon: const Icon(Icons.email_outlined),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email or username';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        CustomTextField(
                          controller: passwordController,
                          label: 'Password',
                          hint: 'Enter your password',
                          obscureText: _obscurePassword,
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),

                        // Forgot Password Link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ForgotPasswordScreen(
                                    initialEmail: emailController.text.trim(),
                                  ),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Demo Credentials Hint
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Default Portal Credentials (Tap to autofill):',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.person, size: 14),
                                      label: const Text(
                                        'Candidate (Rahul)',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        backgroundColor: theme.colorScheme.surface,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          emailController.text = 'rahul.sharma@example.com';
                                          passwordController.text = 'rahul123';
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.admin_panel_settings, size: 14),
                                      label: const Text(
                                        'Admin (Portal)',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        backgroundColor: theme.colorScheme.surface,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          emailController.text = 'admin@jobsense.gov.in';
                                          passwordController.text = 'admin123';
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '• Candidate: rahul.sharma@example.com / rahul123\n• Administrator: admin@jobsense.gov.in / admin123',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Login Button
                        CustomButton(
                          text: 'Sign In',
                          isLoading: _isLoginLoading,
                          onPressed: _loginWithPassword,
                        ),
                      ],
                    ),
                  ),
                ],

                // TAB 2: Email OTP Form
                if (_selectedMethodIndex == 1) ...[
                  Form(
                    key: _otpFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomTextField(
                          controller: otpEmailController,
                          label: 'Email Address',
                          hint: 'Enter your registered email',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.mark_email_unread_outlined),
                          validator: (value) {
                            final val = value?.trim() ?? '';
                            if (val.isEmpty) {
                              return 'Please enter your email address';
                            }
                            if (!val.contains('@') || !val.contains('.')) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        // Info Box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.verified_user_outlined,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'A 6-digit verification code will be generated by the system and sent directly to your email inbox.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Send OTP Button
                        CustomButton(
                          text: 'Send Email Verification OTP',
                          isLoading: _isOtpLoading,
                          onPressed: _sendEmailOtp,
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Register Link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Don\'t have an account? ',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(email: ''),
                            ),
                          );
                        },
                        child: const Text(
                          'Register Here',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Center(
                  child: Text(
                    'By continuing, you agree to our Terms of Service & Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}