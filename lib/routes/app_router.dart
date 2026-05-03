import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/dashboard/dashboard_screen.dart';
import '../presentation/screens/doctors/doctor_list_screen.dart';
import '../presentation/screens/doctors/add_edit_doctor_screen.dart';
import '../presentation/screens/profile/admin_profile_screen.dart';

class AppRouter {
  static final router = GoRouter(
    // Check if admin is already logged in
    initialLocation: Supabase.instance.client.auth.currentUser != null
        ? '/dashboard'
        : '/login',

    routes: [
      // Login Route
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

      // Dashboard Route
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),

      // Doctor List Route
      GoRoute(
        path: '/doctors',
        builder: (context, state) => const DoctorListScreen(),
      ),

      // Add Doctor Route
      GoRoute(
        path: '/doctors/add',
        builder: (context, state) => const AddEditDoctorScreen(),
      ),

      // Edit Doctor Route
      GoRoute(
        path: '/doctors/edit',
        builder: (context, state) =>
            AddEditDoctorScreen(doctor: state.extra as dynamic),
      ),

      // Admin Profile Route
      GoRoute(
        path: '/profile',
        builder: (context, state) => const AdminProfileScreen(),
      ),
    ],
  );
}
