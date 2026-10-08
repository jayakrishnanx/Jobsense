import 'package:flutter/material.dart';
import '../models/job.dart';
import '../data/app_state.dart';
import 'eligibility_badge.dart';

class JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;
  final VoidCallback? onSaveToggle;
  final EdgeInsetsGeometry? margin;
  final double? width;

  const JobCard({
    super.key,
    required this.job,
    required this.onTap,
    this.onSaveToggle,
    this.margin,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = appState.currentUser;
    final eligibility = job.checkEligibility(user);
    final isSaved = appState.isJobSaved(job.id);

    final cardWidget = Card(
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row: Organization & Bookmark
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.organization,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                            letterSpacing: 0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          job.title,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: isSaved ? theme.colorScheme.primary : Colors.grey,
                      size: 22,
                    ),
                    onPressed: () {
                      if (onSaveToggle != null) {
                        onSaveToggle!();
                      } else {
                        appState.toggleSaveJob(job.id);
                      }
                    },
                    tooltip: isSaved ? 'Remove from Saved' : 'Save Job',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(2),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Chips / Badges row: Qualification, Location, Vacancies
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _infoChip(Icons.school_outlined, job.qualification, context),
                  _infoChip(Icons.location_on_outlined, job.location, context),
                  _infoChip(Icons.people_alt_outlined, job.vacancies, context),
                ],
              ),

              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Bottom row: Eligibility Badge, Last Date & Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  EligibilityBadge(
                    isEligible: eligibility.isEligible,
                    compact: true,
                  ),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Ends: ${job.lastDate}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: cardWidget);
    }
    return cardWidget;
  }

  Widget _infoChip(IconData icon, String label, BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
