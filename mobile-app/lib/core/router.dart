import 'package:go_router/go_router.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/home/home_screen.dart';
import '../features/academic_hub/academic_hub_screen.dart';
import '../features/jobs/job_listings_screen.dart';
import '../features/results/results_screen.dart';
import '../features/aptitude/aptitude_screen.dart';
import '../features/documents_vault/documents_vault_screen.dart';
import '../features/uploaded_files/uploaded_files_screen.dart';
import '../features/ai_interview/ai_interview_screen.dart';
import '../features/internships/screens/internship_catalog_screen.dart';
import 'package:flutter/material.dart';

/// App router — opens directly to /home with all feature routes wired up.
final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(path: '/home',            builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/login',           builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register',        builder: (context, state) => const RegisterScreen()),
    GoRoute(path: '/academic-hub',    builder: (context, state) => const AcademicHubScreen()),
    GoRoute(path: '/documents-vault', builder: (context, state) => const DocumentsVaultScreen()),
    GoRoute(path: '/uploaded-files',  builder: (context, state) => const UploadedFilesScreen()),
    GoRoute(path: '/ai-interview',    builder: (context, state) => const AiInterviewScreen()),
    GoRoute(path: '/internships-lms', builder: (context, state) => const InternshipCatalogScreen()),
    GoRoute(
      path: '/internships',
      builder: (context, state) => const JobListingsScreen(
        type: 'INTERNSHIP',
        title: 'Internships',
        icon: Icons.work_outline_rounded,
      ),
    ),
    GoRoute(
      path: '/placements',
      builder: (context, state) => const JobListingsScreen(
        type: 'PLACEMENT',
        title: 'Placements',
        icon: Icons.business_center_outlined,
      ),
    ),
    GoRoute(
      path: '/govt-jobs',
      builder: (context, state) => const JobListingsScreen(
        type: 'GOVT_JOB',
        title: 'Govt Jobs',
        icon: Icons.account_balance_outlined,
      ),
    ),
    GoRoute(path: '/results',  builder: (context, state) => const ResultsScreen()),
    GoRoute(path: '/aptitude', builder: (context, state) => const AptitudeScreen()),
  ],
);
