import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/doctor_service.dart';
import '../../../data/models/admin_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _authService = AuthService();
  final _doctorService = DoctorService();

  AdminModel? _admin;
  int _totalDoctors = 0;
  int _activeDoctors = 0;
  int _inactiveDoctors = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Load dashboard data
  Future<void> _loadData() async {
    final admin = await _authService.getCurrentAdmin();
    final doctors = await _doctorService.getAllDoctors();

    setState(() {
      _admin = admin;
      _totalDoctors = doctors.length;
      _activeDoctors = doctors.where((d) => d.accountStatus).length;
      _inactiveDoctors = doctors.where((d) => !d.accountStatus).length;
      _isLoading = false;
    });
  }

  // Logout
  Future<void> _handleLogout() async {
    await _authService.logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(),

          // Main Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildMainContent(),
          ),
        ],
      ),
    );
  }

  // Sidebar Widget
  Widget _buildSidebar() {
    return Container(
      width: 240,
      color: AppColors.sidebarBg,
      child: Column(
        children: [
          // App Logo
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const Icon(Icons.local_hospital, color: Colors.white, size: 28),
                const SizedBox(width: 8),
                const Text(
                  'MediChain',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white24),

          // Admin Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    _admin?.fullName.substring(0, 1).toUpperCase() ?? 'A',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _admin?.fullName ?? 'Admin',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _admin?.username ?? '',
                        style: TextStyle(
                          color: AppColors.sidebarText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white24),
          const SizedBox(height: 8),

          // Navigation Items
          _buildNavItem(Icons.dashboard, 'Dashboard', '/dashboard', true),
          _buildNavItem(Icons.people, 'Doctors', '/doctors', false),
          _buildNavItem(Icons.person, 'My Profile', '/profile', false),

          const Spacer(),

          // Logout Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout, color: Colors.white70),
              label: const Text(
                'Logout',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Sidebar Navigation Item
  Widget _buildNavItem(
    IconData icon,
    String title,
    String route,
    bool isActive,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? Colors.white : AppColors.sidebarText,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? Colors.white : AppColors.sidebarText,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      tileColor: isActive ? AppColors.sidebarActive : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () => context.go(route),
    );
  }

  // Main Content Area
  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            'Welcome back, ${_admin?.fullName ?? 'Admin'}',
            style: TextStyle(color: AppColors.textSecondary),
          ),

          const SizedBox(height: 24),

          // Stats Cards Row
          Row(
            children: [
              Expanded(
                child: _buildStatsCard(
                  'Total Doctors',
                  _totalDoctors.toString(),
                  Icons.people,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatsCard(
                  'Active Doctors',
                  _activeDoctors.toString(),
                  Icons.check_circle,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatsCard(
                  'Inactive Doctors',
                  _inactiveDoctors.toString(),
                  Icons.cancel,
                  AppColors.error,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Quick Actions
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              _buildQuickAction(
                'Add Doctor',
                Icons.person_add,
                AppColors.primary,
                () => context.go('/doctors/add'),
              ),
              const SizedBox(width: 16),
              _buildQuickAction(
                'View Doctors',
                Icons.people,
                AppColors.success,
                () => context.go('/doctors'),
              ),
              const SizedBox(width: 16),
              _buildQuickAction(
                'My Profile',
                Icons.manage_accounts,
                AppColors.warning,
                () => context.go('/profile'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Stats Card Widget
  Widget _buildStatsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                title,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Quick Action Card Widget
  Widget _buildQuickAction(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
