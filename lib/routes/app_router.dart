import 'package:go_router/go_router.dart';
import 'package:medichain/blog/blog.dart';
import 'package:medichain/doctors/bottom_nav_w/bottom_nav.dart';
import 'package:medichain/doctors/doctor_main_layout/doc_main_layout.dart';
import '../presentation/screens/entry/entry_screen.dart';
import '../admins/auth/login_screen.dart';
import '../admins/dashboard/dashboard_screen.dart';
import '../admins/doctors/doctor_list_screen.dart';
import '../admins/doctors/add_edit_doctor_screen.dart';
import '../admins/profile/admin_profile_screen.dart';
import '../admins/activiti/admin_activities_screen.dart';
import '../doctors/auth/doctor_login_screen.dart';
import '../doctors/schedule_screen.dart';
import '../doctors/appointment_detail_screen.dart';
import '../doctors/patient_history/patient_search_screen.dart';
import '../doctors/patient_history/patient_detail_screen.dart';
import '../doctors/profile/doctor_profile_screen.dart';
import '../doctors/prescription/add_prescription_screen.dart';
import '../data/models/doctor_models/appointment_model.dart';
import '../patient/login_page.dart';
import '../patient/doctor_search_page.dart';
import '../patient/home_page.dart';
import '../patient/patient_history.dart';
import '../patient/patient_reg.dart';
import 'package:flutter/material.dart';
//why dont we need flutter material here? 
import '../splash_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      // Splash Screen
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),

      GoRoute(path: '/entry', builder: (context, state) => const EntryScreen()),

      // Admin Routes
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) =>
            const AdminBottomNav(currentIndex: 0, child: DashboardScreen()),
      ),
      GoRoute(
        path: '/doctors',
        builder: (context, state) =>
            const AdminBottomNav(currentIndex: 1, child: DoctorListScreen()),
      ),
      GoRoute(
        path: '/admin-blog',
        builder: (context, state) => const AdminBottomNav(
          currentIndex: 2,
          child: CommunityPage(isPinnedInShell: true),
        ),
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
        builder: (context, state) =>
            const AdminBottomNav(currentIndex: 3, child: AdminProfileScreen()),
      ),
      GoRoute(
        path: '/admin-activities',
        builder: (context, state) => const AdminActivitiesScreen(),
      ),

      // Doctor Panel Routes
      GoRoute(
        path: '/doctor-login',
        builder: (context, state) => const DoctorLoginScreen(),
      ),
      GoRoute(
        path: '/doctor-schedule',
        builder: (context, state) =>
            const DoctorMainLayout(currentIndex: 0, child: ScheduleScreen()),
      ),
      GoRoute(
        path: '/doctor-appointment-detail',
        builder: (context, state) => AppointmentDetailScreen(
          appointment: state.extra as AppointmentModel,
        ),
      ),
      GoRoute(
        path: '/doctor-patients',
        builder: (context, state) => const DoctorMainLayout(
          currentIndex: 1,
          child: PatientSearchScreen(),
        ),
      ),
      GoRoute(
        path: '/doctor-patient-detail',
        builder: (context, state) =>
            PatientDetailScreen(patientId: state.extra as String),
      ),
      GoRoute(
        path: '/doctor-prescription',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return AddPrescriptionScreen(extra: args);
        },
      ),

      GoRoute(
        path: '/doctor-blog',
        builder: (context, state) => const DoctorMainLayout(
          currentIndex: 2,
          child: CommunityPage(isPinnedInShell: true),
        ),
      ),
      GoRoute(
        path: '/doctor-profile',
        builder: (context, state) => const DoctorMainLayout(
          currentIndex: 3,
          child: DoctorProfileScreen(),
        ),
      ),

      // Patient Routes
      GoRoute(
        path: '/patient-reg',
        builder: (context, state) => const PatientRegistrationScreen(),
      ),
      GoRoute(
        path: '/patient-login',
        builder: (context, state) => const PatientLoginScreen(),
      ),
      GoRoute(
        path: '/patient-home-page',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/doctor-search-page',
        builder: (context, state) => const DoctorSearchPage(),
      ),
      GoRoute(
        path: '/patient-history',
        builder: (context, state) => const PatientHistoryPage(),
      ),

      // Patient Blog Only (Admin Blog handled above in the Admin segment safely)
      GoRoute(
        path: '/patient-blog',
        builder: (context, state) => const CommunityPage(),
      ),
    ],
  );
}
