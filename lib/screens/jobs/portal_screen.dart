import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/job.dart';
import '../../widgets/custom_button.dart';

class OfficialPortalScreen extends StatefulWidget {
  final Job job;
  final String targetUrl;
  final bool isNotificationPdf;

  const OfficialPortalScreen({
    super.key,
    required this.job,
    required this.targetUrl,
    this.isNotificationPdf = false,
  });

  @override
  State<OfficialPortalScreen> createState() => _OfficialPortalScreenState();
}

class _OfficialPortalScreenState extends State<OfficialPortalScreen> {
  bool _isLaunching = false;

  Future<void> _openExternalBrowser() async {
    setState(() => _isLaunching = true);
    final url = widget.targetUrl.trim();
    try {
      final uri = Uri.parse(url);
      bool ok = false;
      try {
        ok = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      } catch (_) {}

      if (!ok) {
        try {
          ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {}
      }

      if (!ok) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open browser: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLaunching = false);
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.targetUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Official Portal URL copied to clipboard!'),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPdf = widget.isNotificationPdf;

    return Scaffold(
      appBar: AppBar(
        title: Text(isPdf ? 'Official Notification' : 'Online Application Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Copy Link',
            onPressed: _copyToClipboard,
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded),
            tooltip: 'Open in Chrome / Browser',
            onPressed: _openExternalBrowser,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.verified_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Official Government Portal',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.job.organization,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.job.title,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Portal Destination Box
              const Text(
                'Direct Portal Destination',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lock_rounded, size: 16, color: Colors.green.shade600),
                        const SizedBox(width: 6),
                        const Text(
                          'HTTPS Secure Official Address',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      widget.targetUrl,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Primary Launch Action
              CustomButton(
                text: isPdf ? 'Open Official PDF / Notice' : 'Open Official Apply Portal',
                icon: Icons.launch_rounded,
                isLoading: _isLaunching,
                onPressed: _openExternalBrowser,
              ),

              const SizedBox(height: 12),

              CustomButton(
                text: 'Copy Portal Web Link',
                type: ButtonType.outlined,
                icon: Icons.copy_rounded,
                onPressed: _copyToClipboard,
              ),

              const SizedBox(height: 28),

              // Step-by-Step Candidate Instructions
              const Text(
                'Application Guidelines & Checklist',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              _buildInstructionStep(
                number: '1',
                title: 'One-Time Registration (OTR)',
                description:
                    'Log in with your existing Candidate User ID and Password, or register a new OTR profile on the official portal.',
              ),
              _buildInstructionStep(
                number: '2',
                title: 'Post Code & Notification Selection',
                description:
                    'Search for Category / Post: "${widget.job.title}" and verify your educational eligibility matches.',
              ),
              _buildInstructionStep(
                number: '3',
                title: 'Upload Required Documents',
                description:
                    'Keep your Photo (JPEG), Signature, SSLC 10th DOB proof, Degree Certificate, and Community/EWS certificates ready.',
              ),
              _buildInstructionStep(
                number: '4',
                title: 'Fee Payment & Confirmation Slip',
                description:
                    'Submit fee (${widget.job.applicationFee}) if applicable and download the final application confirmation PDF.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionStep({
    required String number,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
