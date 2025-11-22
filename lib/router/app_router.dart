import 'package:go_router/go_router.dart';
import '../models/vehicle.dart';
import '../providers/auth_provider.dart';
import '../screens/add_vehicle_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/main_screen.dart';
import '../screens/vehicle_details_screen.dart';

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: authProvider,
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(path: '/home', builder: (_, __) => const MainScreen()),
        GoRoute(path: '/add-vehicle', builder: (_, __) => const AddVehicleScreen()),
        GoRoute(
          path: '/vehicle-details',
          builder: (context, state) {
            final vehicle = state.extra as Vehicle;
            return VehicleDetailsScreen(vehicle: vehicle);
          },
        ),
      ],
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';

        if (!isAuthenticated && !isAuthRoute && state.matchedLocation != '/splash') {
          return '/login';
        }
        if (isAuthenticated && (isAuthRoute || state.matchedLocation == '/splash')) {
          return '/home';
        }
        return null;
      },
    );
  }
}
