import 'package:go_router/go_router.dart';
import '../presentation/screens/entry/entry_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/dashboard/dashboard_screen.dart';
import '../presentation/screens/doctors/doctor_list_screen.dart';
import '../presentation/screens/doctors/add_edit_doctor_screen.dart';
import '../presentation/screens/profile/admin_profile_screen.dart';
import '../presentation/screens/doctor_panel/auth/doctor_login_screen.dart';
import '../presentation/screens/doctor_panel/schedule/schedule_screen.dart';
import '../presentation/screens/doctor_panel/schedule/appointment_detail_screen.dart';
import '../presentation/screens/doctor_panel/patient_history/patient_search_screen.dart';
import '../presentation/screens/doctor_panel/patient_history/patient_detail_screen.dart';
import '../presentation/screens/doctor_panel/prescription/add_prescription_screen.dart';
import '../presentation/screens/doctor_panel/profile/doctor_profile_screen.dart';
import '../presentation/screens/doctor_panel/notifications/notification_screen.dart';
import '../data/models/doctor_models/appointment_model.dart';
import '../patient/login_page.dart';
import '../patient/doctor_search_page.dart';
import '../patient/home_page.dart';
import '../patient/patient_history.dart';
import '../patient/patient_reg.dart';

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
      GoRoute(
        path: '/patient-login',
        builder: (context, state) => const PatientLoginScreen(),
      ),
      GoRoute(
        path: '/doctor-search-page',
        builder: (context, state) => const DoctorSearchPage(),
      ),
      GoRoute(
        path: '/patient-home-page',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/patient-history',
        builder: (context, state) => const PatientHistoryPage(),
      ),
      GoRoute(
        path: '/patient-reg',
        builder:(context, state) => const PatientRegistrationScreen(),
        
        )
    ],
  );
}
