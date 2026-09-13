import 'package:flutter/material.dart';
import 'custom_button.dart';

class JobFilterCriteria {
  String jobType;
  String qualification;
  String location;
  String category;
  bool eligibleOnly;

  JobFilterCriteria({
    this.jobType = 'All',
    this.qualification = 'All',
    this.location = 'All',
    this.category = 'All',
    this.eligibleOnly = false,
  });

  bool get hasActiveFilters =>
      jobType != 'All' ||
      qualification != 'All' ||
      location != 'All' ||
      category != 'All' ||
      eligibleOnly;

  void reset() {
    jobType = 'All';
    qualification = 'All';
    location = 'All';
    category = 'All';
    eligibleOnly = false;
  }
}

class JobFilterSheet extends StatefulWidget {
  final JobFilterCriteria initialCriteria;
  final ValueChanged<JobFilterCriteria> onApply;

  const JobFilterSheet({
    super.key,
    required this.initialCriteria,
    required this.onApply,
  });

  @override
  State<JobFilterSheet> createState() => _JobFilterSheetState();
}

class _JobFilterSheetState extends State<JobFilterSheet> {
  late String _jobType;
  late String _qualification;
  late String _location;
  late String _category;
  late bool _eligibleOnly;

  @override
  void initState() {
    super.initState();
    _jobType = widget.initialCriteria.jobType;
    _qualification = widget.initialCriteria.qualification;
    _location = widget.initialCriteria.location;
    _category = widget.initialCriteria.category;
    _eligibleOnly = widget.initialCriteria.eligibleOnly;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Jobs',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _jobType = 'All';
                      _qualification = 'All';
                      _location = 'All';
                      _category = 'All';
                      _eligibleOnly = false;
                    });
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),

            // Eligible Only Switch
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Show only Eligible Jobs',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Jobs that match your qualification & state'),
              value: _eligibleOnly,
              onChanged: (val) {
                setState(() => _eligibleOnly = val);
              },
            ),
            const SizedBox(height: 16),

            // Job Type Chips
            _buildSectionTitle('Job Sector / Type'),
            _buildChipGroup(
              options: ['All', 'Central Govt', 'State Govt', 'Banking', 'Defense'],
              selected: _jobType,
              onSelected: (val) => setState(() => _jobType = val),
            ),
            const SizedBox(height: 16),

            // Qualification
            _buildSectionTitle('Minimum Qualification'),
            _buildChipGroup(
              options: ['All', 'Degree', 'SSLC / 10th Pass'],
              selected: _qualification,
              onSelected: (val) => setState(() => _qualification = val),
            ),
            const SizedBox(height: 16),

            // Location / State
            _buildSectionTitle('Job Location'),
            _buildChipGroup(
              options: ['All', 'Kerala', 'All India'],
              selected: _location,
              onSelected: (val) => setState(() => _location = val),
            ),
            const SizedBox(height: 16),

            // Category
            _buildSectionTitle('Category / Quota'),
            _buildChipGroup(
              options: ['All', 'General', 'OBC', 'SC', 'ST'],
              selected: _category,
              onSelected: (val) => setState(() => _category = val),
            ),
            const SizedBox(height: 24),

            // Apply Button
            CustomButton(
              text: 'Apply Filters',
              onPressed: () {
                final result = JobFilterCriteria(
                  jobType: _jobType,
                  qualification: _qualification,
                  location: _location,
                  category: _category,
                  eligibleOnly: _eligibleOnly,
                );
                widget.onApply(result);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildChipGroup({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = opt == selected;
        return FilterChip(
          label: Text(opt),
          selected: isSelected,
          onSelected: (_) => onSelected(opt),
          selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
          checkmarkColor: Theme.of(context).colorScheme.primary,
          labelStyle: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
}
