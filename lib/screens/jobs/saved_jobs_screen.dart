import 'package:flutter/material.dart';
import '../../data/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/job_card.dart';
import 'job_details_screen.dart';

class SavedJobsScreen extends StatelessWidget {
  const SavedJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Jobs'),
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final savedJobs = appState.savedJobs;

          if (savedJobs.isEmpty) {
            return EmptyState(
              icon: Icons.bookmark_border,
              title: 'No Saved Jobs Yet',
              message:
                  'Jobs you bookmark while browsing will be saved here so you can easily track application deadlines.',
              actionText: 'Browse Jobs',
              onActionPressed: () => Navigator.pop(context),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: savedJobs.length,
            itemBuilder: (context, index) {
              final job = savedJobs[index];
              return JobCard(
                job: job,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JobDetailsScreen(job: job),
                    ),
                  );
                },
                onSaveToggle: () {
                  appState.toggleSaveJob(job.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Removed from saved jobs'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
