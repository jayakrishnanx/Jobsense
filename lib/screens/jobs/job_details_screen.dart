import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/app_state.dart';
import '../../models/job.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/eligibility_badge.dart';
import 'portal_screen.dart';

class JobDetailsScreen extends StatefulWidget {
  final Job job;

  const JobDetailsScreen({
    super.key,
    required this.job,
  });

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  late Job _currentJob;
  bool _isSummarizing = false;

  @override
  void initState() {
    super.initState();
    _currentJob = widget.job;
  }

  Future<void> _triggerAiSummary() async {
    setState(() => _isSummarizing = true);
    try {
      final summary = await ApiService.instance.generateJobAiSummary(_currentJob.id);
      if (summary != null) {
        setState(() {
          _currentJob = _currentJob.copyWith(
            aiSummary: summary,
            description: summary.executiveBrief.isNotEmpty ? summary.executiveBrief : _currentJob.description,
          );
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✨ AI Summary and notification insights refreshed!'),
              backgroundColor: Colors.teal,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isSummarizing = false);
      }
    }
  }

  void _openPortal(String urlStr, {bool isPdf = false}) async {
    String normalized = urlStr.trim();
    if (normalized.isEmpty) {
      normalized = widget.job.effectiveApplyUrl;
    }
    if (!normalized.startsWith('http://') && !normalized.startsWith('https://')) {
      normalized = 'https://$normalized';
    }

    // Try background direct launcher
    try {
      final uri = Uri.parse(normalized);
      bool launched = false;
      try {
        launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      } catch (_) {}

      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {}
      }

      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {}

    // Also navigate to the dedicated In-App Official Portal Screen for immediate UI feedback
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OfficialPortalScreen(
            job: widget.job,
            targetUrl: normalized,
            isNotificationPdf: isPdf,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = appState.currentUser;
    final eligibility = widget.job.checkEligibility(user);
    final isSaved = appState.isJobSaved(widget.job.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
        actions: [
          IconButton(
            icon: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: isSaved ? theme.colorScheme.primary : null,
            ),
            onPressed: () {
              setState(() {
                appState.toggleSaveJob(widget.job.id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isSaved
                        ? 'Removed from Saved Jobs'
                        : 'Saved to your bookmarked jobs',
                  ),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Sharing link for "${widget.job.title}"'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top sector tag & vacancy badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _currentJob.jobType,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _currentJob.vacancies,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Job Title
            Text(
              _currentJob.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),

            // Organization & Department
            Text(
              _currentJob.organization,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              _currentJob.department,
              style: TextStyle(
                fontSize: 13,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),

            // SECTION: WHY YOU RECEIVED THIS ALERT (ELIGIBILITY BREAKDOWN)
            _buildEligibilitySection(context, eligibility),

            const SizedBox(height: 24),

            // Key Overview Cards Grid
            _buildOverviewGrid(context),

            const SizedBox(height: 24),

            // AI Smart Summary & Insights Section
            _buildAiSummarySection(context),

            const SizedBox(height: 24),

            // Important Dates & Application Fee
            const Text(
              'Important Dates & Fees',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _infoRow(Icons.calendar_month, 'Application Opens', _currentJob.applicationStartDate),
            _infoRow(Icons.event_busy, 'Last Date to Apply', _currentJob.lastDate),
            _infoRow(Icons.payment, 'Application Fee', _currentJob.applicationFee),

            const SizedBox(height: 24),

            // Detailed Requirements
            const Text(
              'Eligibility & Selection Criteria',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _infoRow(Icons.school, 'Educational Qualification', _currentJob.qualification),
            _infoRow(Icons.menu_book, 'Course / Degree Allowed', _currentJob.courseRequirements),
            _infoRow(Icons.cake, 'Age Limit', '${_currentJob.ageMin} to ${_currentJob.ageMax} years'),
            _infoRow(Icons.category, 'Categories Eligible', _currentJob.category),
            _infoRow(Icons.work_history, 'Experience Required', _currentJob.experience),
            _infoRow(Icons.assignment, 'Selection Process', _currentJob.selectionProcess),

            const SizedBox(height: 24),

            // SECTION: DOCUMENTS REQUIRED FOR YOUR APPLICATION
            _buildDocumentsSection(context, user),

            const SizedBox(height: 32),

            // Action Buttons
            CustomButton(
              text: 'Apply Now (Direct Online Portal)',
              icon: Icons.open_in_new,
              onPressed: () {
                _openPortal(_currentJob.effectiveApplyUrl, isPdf: false);
              },
            ),

            const SizedBox(height: 12),

            CustomButton(
              text: 'View Official Notification PDF',
              type: ButtonType.outlined,
              icon: Icons.picture_as_pdf_outlined,
              onPressed: () {
                _openPortal(_currentJob.officialNotificationUrl, isPdf: true);
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAiSummarySection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final summary = _currentJob.aiSummary;
    final brief = (summary != null && summary.executiveBrief.isNotEmpty)
        ? summary.executiveBrief
        : (_currentJob.description.isNotEmpty
            ? _currentJob.description
            : 'Official notification released by ${_currentJob.organization} for ${_currentJob.title}.');

    final highlights = (summary != null && summary.keyHighlights.isNotEmpty)
        ? summary.keyHighlights
        : [
            '🏛️ Organization: ${_currentJob.organization} (${_currentJob.department})',
            '🎓 Qualification: ${_currentJob.qualification}',
            '💰 Remuneration: ${_currentJob.salary}',
            '📍 Location: ${_currentJob.location}',
            '⏳ Deadline: ${_currentJob.lastDate}',
            '📋 Selection: ${_currentJob.selectionProcess}',
          ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.teal.shade700.withValues(alpha: 0.4)
              : Colors.teal.shade300.withValues(alpha: 0.7),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with AI Sparkle and Re-analyze button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_awesome, size: 18, color: Colors.teal),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'AI Smart Summary & Insights',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (_isSummarizing)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18, color: Colors.teal),
                  tooltip: 'Re-Analyze with AI',
                  onPressed: _triggerAiSummary,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Executive Brief Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.25)
                  : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              brief,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: isDark ? Colors.grey.shade200 : const Color(0xFF1E293B),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Key Highlights Header
          const Text(
            'Key Highlights at a Glance',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.teal,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),

          // Key Highlights list
          ...highlights.map((h) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                    Expanded(
                      child: Text(
                        h,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              )),

          if (summary != null && summary.examPattern.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            const Text(
              'Exam & Selection Scheme',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.teal),
            ),
            const SizedBox(height: 6),
            ...summary.examPattern.map((p) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 14, color: Colors.teal),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          p,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],

          if (summary != null && summary.importantTips.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            const Text(
              'Application Guidelines & Tips',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.teal),
            ),
            const SizedBox(height: 6),
            ...summary.importantTips.map((t) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.tips_and_updates_outlined, size: 14, color: Colors.amber),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          t,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentsSection(BuildContext context, User? user) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final category = user?.category ?? 'General';
    final isGeneral = category.toLowerCase() == 'general';
    final isObc = category.toLowerCase().contains('obc');
    final isScSt = category.toLowerCase().contains('sc') || category.toLowerCase().contains('st');
    final isEws = category.toLowerCase().contains('ews');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25)
            : Colors.blueGrey.shade50.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.blueGrey.shade200.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.folder_shared_outlined, color: theme.colorScheme.primary, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Documents Required to Apply',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Personalized based on your profile ($category Category, ${user?.qualification ?? 'Degree'})',
            style: TextStyle(
              fontSize: 12,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 14),
          Divider(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 10),

          // Standard Mandatory Documents for all candidates
          _documentItem(
            icon: Icons.badge_outlined,
            title: 'Valid Government Photo ID',
            description: 'Aadhaar Card, Voter ID, Passport, or PAN Card.',
            tag: 'Mandatory',
            tagColor: Colors.blue,
            context: context,
          ),
          _documentItem(
            icon: Icons.photo_camera_front_outlined,
            title: 'Photograph & Signature Scans',
            description: 'Recent passport-size photo (white background) & digital signature.',
            tag: 'Mandatory',
            tagColor: Colors.blue,
            context: context,
          ),
          _documentItem(
            icon: Icons.calendar_today_outlined,
            title: '10th / SSLC Certificate',
            description: 'Mandatory proof of Date of Birth (Matriculation Certificate).',
            tag: 'Mandatory',
            tagColor: Colors.blue,
            context: context,
          ),
          _documentItem(
            icon: Icons.school_outlined,
            title: '${user?.qualification ?? 'Degree'} Certificate / Marksheet',
            description: 'Proof of educational qualification (${user?.course ?? widget.job.qualification}).',
            tag: 'Mandatory',
            tagColor: Colors.blue,
            context: context,
          ),

          // Category-Specific Dynamic Documents:
          if (isObc)
            _documentItem(
              icon: Icons.verified_outlined,
              title: 'OBC Non-Creamy Layer (NCL) Certificate',
              description: 'Required for OBC age & reservation benefits (issued in current financial year).',
              tag: 'Required for OBC',
              tagColor: Colors.orange,
              context: context,
            )
          else if (isScSt)
            _documentItem(
              icon: Icons.verified_outlined,
              title: 'SC / ST Community Certificate',
              description: 'Required for SC/ST fee exemption and age relaxation.',
              tag: 'Required for $category',
              tagColor: Colors.orange,
              context: context,
            )
          else if (isEws)
            _documentItem(
              icon: Icons.verified_outlined,
              title: 'EWS Income & Asset Certificate',
              description: 'Required to claim Economically Weaker Section 10% quota.',
              tag: 'Required for EWS',
              tagColor: Colors.orange,
              context: context,
            )
          else if (isGeneral)
            _documentItem(
              icon: Icons.check_circle_outline,
              title: 'No Caste Certificate Needed',
              description: 'As a General / Unreserved applicant, no reservation or community certificate is required.',
              tag: 'Not Required',
              tagColor: Colors.grey,
              isOptional: true,
              context: context,
            ),

          // State Domicile if State Govt Job
          if (widget.job.jobType == 'State Govt' || widget.job.location.toLowerCase().contains('kerala'))
            _documentItem(
              icon: Icons.home_work_outlined,
              title: 'State Domicile / Nativity Certificate',
              description: 'Proof of permanent residency in ${user?.state ?? widget.job.location} for state quota.',
              tag: 'State Specific',
              tagColor: Colors.teal,
              context: context,
            ),
        ],
      ),
    );
  }

  Widget _documentItem({
    required IconData icon,
    required String title,
    required String description,
    required String tag,
    required MaterialColor tagColor,
    required BuildContext context,
    bool isOptional = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: isOptional ? Colors.grey : theme.colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isOptional
                              ? (isDark ? Colors.grey.shade400 : Colors.grey.shade700)
                              : null,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: tagColor.withValues(alpha: isDark ? 0.25 : 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? tagColor.shade200 : tagColor.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEligibilitySection(BuildContext context, EligibilityResult result) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEligible = result.isEligible;

    final containerBg = isDark
        ? (isEligible
            ? const Color(0xFF064E3B).withValues(alpha: 0.35)
            : const Color(0xFF7F1D1D).withValues(alpha: 0.35))
        : (isEligible ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2));

    final containerBorder = isDark
        ? (isEligible
            ? const Color(0xFF059669).withValues(alpha: 0.6)
            : const Color(0xFFDC2626).withValues(alpha: 0.6))
        : (isEligible ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA));

    final headerColor = isDark
        ? (isEligible ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5))
        : (isEligible ? const Color(0xFF166534) : const Color(0xFF991B1B));

    final itemTitleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final itemExplanationColor =
        isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: containerBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Why you received this alert',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: headerColor,
                ),
              ),
              EligibilityBadge(isEligible: isEligible, compact: true),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result.summary,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: headerColor,
            ),
          ),
          const SizedBox(height: 14),
          Divider(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 10),

          // Points Checklist
          ...result.points.map((point) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    point.isMet ? Icons.check_circle : Icons.cancel,
                    size: 20,
                    color: point.isMet
                        ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A))
                        : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          point.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: itemTitleColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          point.explanation,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: itemExplanationColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOverviewGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _overviewTile(
                Icons.currency_rupee,
                'Salary / Pay',
                widget.job.salary,
                context,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _overviewTile(
                Icons.location_on_outlined,
                'Location',
                widget.job.location,
                context,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _overviewTile(IconData icon, String label, String value, BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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