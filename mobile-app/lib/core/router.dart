import 'package:go_router/go_router.dart';
import '../features/splash/splash_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/home/home_screen.dart';
import '../features/academic_hub/academic_hub_screen.dart';
import 'api_client.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/academic-hub', builder: (context, state) => const AcademicHubScreen()),
  ],
  redirect: (context, state) async {
    // Splash handles its own instant redirect once the token check resolves;
    // this guard just protects authenticated routes from direct navigation.
    final protected = {'/home', '/academic-hub'};
    if (protected.contains(state.matchedLocation)) {
      final token = await ApiClient.instance.readToken();
      if (token == null) return '/login';
    }
    return null;
  },
);
