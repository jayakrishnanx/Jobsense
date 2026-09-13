import 'package:flutter/material.dart';
import '../../data/app_state.dart';
import '../../models/job.dart';
import '../../models/user.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/eligibility_badge.dart';

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
                    widget.job.jobType,
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
                    widget.job.vacancies,
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
              widget.job.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),

            // Organization & Department
            Text(
              widget.job.organization,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              widget.job.department,
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

            // Job Description
            const Text(
              'About the Notification',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.job.description,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),

            const SizedBox(height: 24),

            // Important Dates & Application Fee
            const Text(
              'Important Dates & Fees',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _infoRow(Icons.calendar_month, 'Application Opens', widget.job.applicationStartDate),
            _infoRow(Icons.event_busy, 'Last Date to Apply', widget.job.lastDate),
            _infoRow(Icons.payment, 'Application Fee', widget.job.applicationFee),

            const SizedBox(height: 24),

            // Detailed Requirements
            const Text(
              'Eligibility & Selection Criteria',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _infoRow(Icons.school, 'Educational Qualification', widget.job.qualification),
            _infoRow(Icons.menu_book, 'Course / Degree Allowed', widget.job.courseRequirements),
            _infoRow(Icons.cake, 'Age Limit', '${widget.job.ageMin} to ${widget.job.ageMax} years'),
            _infoRow(Icons.category, 'Categories Eligible', widget.job.category),
            _infoRow(Icons.work_history, 'Experience Required', widget.job.experience),
            _infoRow(Icons.assignment, 'Selection Process', widget.job.selectionProcess),

            const SizedBox(height: 24),

            // SECTION: DOCUMENTS REQUIRED FOR YOUR APPLICATION
            _buildDocumentsSection(context, user),

            const SizedBox(height: 32),

            // Action Buttons
            CustomButton(
              text: 'Apply Now (Official Portal)',
              icon: Icons.open_in_new,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Apply for Job'),
                    content: Text(
                      'You are navigating to the official application portal:\n\n${widget.job.officialNotificationUrl}\n\nMake sure to keep your documents and registration details ready.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Opened portal: ${widget.job.officialNotificationUrl}'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: const Text('Proceed to Portal'),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            CustomButton(
              text: 'View Official Notification PDF',
              type: ButtonType.outlined,
              icon: Icons.picture_as_pdf_outlined,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Downloading official notification from ${widget.job.organization}...'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
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