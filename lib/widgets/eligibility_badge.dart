import 'package:flutter/material.dart';

class EligibilityBadge extends StatelessWidget {
  final bool isEligible;
  final bool compact;

  const EligibilityBadge({
    super.key,
    required this.isEligible,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark
        ? (isEligible
            ? const Color(0xFF064E3B).withValues(alpha: 0.6)
            : const Color(0xFF7F1D1D).withValues(alpha: 0.6))
        : (isEligible ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2));

    final fg = isDark
        ? (isEligible ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5))
        : (isEligible ? const Color(0xFF15803D) : const Color(0xFFB91C1C));

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isEligible ? Icons.check_circle : Icons.cancel,
              size: 14,
              color: fg,
            ),
            const SizedBox(width: 4),
            Text(
              isEligible ? 'Eligible' : 'Not Eligible',
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isEligible ? Icons.verified : Icons.info_outline,
            size: 16,
            color: fg,
          ),
          const SizedBox(width: 6),
          Text(
            isEligible ? 'Eligible for You' : 'Check Criteria',
            style: TextStyle(
              color: fg,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
