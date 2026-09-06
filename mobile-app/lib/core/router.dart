import 'package:go_router/go_router.dart';
import '../features/home/home_screen.dart';
import '../features/academic_hub/academic_hub_screen.dart';
import '../features/results/results_screen.dart';
import '../features/documents_vault/documents_vault_screen.dart';
import '../features/uploaded_files/uploaded_files_screen.dart';
import '../features/ai_interview/ai_interview_screen.dart';
import '../features/internships/internship_hub_screen.dart';

/// App router — opens directly to /home with all active feature routes wired up.
final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(path: '/home',            builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/internships',     builder: (context, state) => const InternshipHubScreen()),
    GoRoute(path: '/academic-hub',    builder: (context, state) => const AcademicHubScreen()),
    GoRoute(path: '/documents-vault', builder: (context, state) => const DocumentsVaultScreen()),
    GoRoute(path: '/uploaded-files',  builder: (context, state) => const UploadedFilesScreen()),
    GoRoute(path: '/ai-interview',    builder: (context, state) => const AiInterviewScreen()),
    GoRoute(path: '/results',         builder: (context, state) => const ResultsScreen()),
  ],
);
