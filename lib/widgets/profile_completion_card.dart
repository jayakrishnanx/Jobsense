import 'package:flutter/material.dart';
import '../models/user.dart';

class ProfileCompletionCard extends StatelessWidget {
  final User? user;
  final VoidCallback onCompleteTap;
  final bool showWhenComplete;

  const ProfileCompletionCard({
    super.key,
    required this.user,
    required this.onCompleteTap,
    this.showWhenComplete = false,
  });

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox.shrink();
    if (!showWhenComplete && user!.completionPercentage >= 100) {
      return const SizedBox.shrink();
    }

    final percentage = user!.completionPercentage;
    final missing = user!.missingFields;
    final isComplete = percentage >= 100;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isComplete ? Icons.verified_user : Icons.pending_actions,
                      color: isComplete ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Profile Strength',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? (isComplete
                            ? const Color(0xFF064E3B).withValues(alpha: 0.6)
                            : const Color(0xFF78350F).withValues(alpha: 0.6))
                        : (isComplete ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? (isComplete ? const Color(0xFF86EFAC) : const Color(0xFFFCD34D))
                          : (isComplete ? const Color(0xFF15803D) : const Color(0xFFB45309)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percentage / 100.0,
                minHeight: 8,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isComplete ? const Color(0xFF10B981) : const Color(0xFF2B6CB0),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (!isComplete && missing.isNotEmpty) ...[
              Text(
                'Missing: ${missing.take(2).join(', ')}${missing.length > 2 ? ' & more' : ''}',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onCompleteTap,
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Complete Profile'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ] else ...[
              Text(
                'Great job! Your profile is 100% complete for accurate eligibility matching.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF4ADE80) : Colors.green.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
