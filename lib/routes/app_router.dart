import 'package:go_router/go_router.dart';
import '../doctors/entry_screen.dart';
import '../admin/login_screen.dart';
import '../admin/dashboard_screen.dart';
import '../doctors/doctor_list_screen.dart';
import '../doctors/add_edit_doctor_screen.dart';
import '../admin/admin_profile_screen.dart';
import '../admin/activiti/admin_activities_screen.dart'; // Added for activity log screen
import '../doctors/doctor_login_screen.dart';
import '../doctors/schedule_screen.dart';
import '../doctors/appointment_detail_screen.dart';
import '../doctors/patient_search_screen.dart';
import '../doctors/patient_detail_screen.dart';
import '../doctors/add_prescription_screen.dart';
import '../doctors/doctor_profile_screen.dart';
import '../doctors/notification_screen.dart';
import '../doctors/appointment_model.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      // Entry Screen
      GoRoute(path: '/', builder: (context, state) => const EntryScreen()),

      // Admin Routes
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/doctors',
        builder: (context, state) => const DoctorListScreen(),
      ),
      GoRoute(
        path: '/doctors/add',
        builder: (context, state) => const AddEditDoctorScreen(),
      ),
      GoRoute(
        path: '/doctors/edit',
        builder: (context, state) =>
            AddEditDoctorScreen(doctor: state.extra as dynamic),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const AdminProfileScreen(),
      ),
      GoRoute(
        path: '/admin-activities', // Route added for See All action
        builder: (context, state) => const AdminActivitiesScreen(),
      ),

      // Doctor Panel Routes
      GoRoute(
        path: '/doctor-login',
        builder: (context, state) => const DoctorLoginScreen(),
      ),
      GoRoute(
        path: '/doctor-schedule',
        builder: (context, state) => const ScheduleScreen(),
      ),
      GoRoute(
        path: '/doctor-appointment-detail',
        builder: (context, state) => AppointmentDetailScreen(
          appointment: state.extra as AppointmentModel,
        ),
      ),
      GoRoute(
        path: '/doctor-patients',
        builder: (context, state) => const PatientSearchScreen(),
      ),
      GoRoute(
        path: '/doctor-patient-detail',
        builder: (context, state) =>
            PatientDetailScreen(patientId: state.extra as String),
      ),
      GoRoute(
        path: '/doctor-prescription',
        builder: (context, state) =>
            AddPrescriptionScreen(extra: state.extra as Map<String, dynamic>),
      ),
      GoRoute(
        path: '/doctor-profile',
        builder: (context, state) => const DoctorProfileScreen(),
      ),
      GoRoute(
        path: '/doctor-notifications',
        builder: (context, state) => const NotificationScreen(),
      ),
    ],
  );
}
