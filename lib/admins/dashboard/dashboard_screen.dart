import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/doctor_service.dart';
import '../../data/models/admin_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _authService = AuthService();
  final _doctorService = DoctorService();
  final _supabase = Supabase.instance.client;

  AdminModel? _admin;
  int _totalDoctors = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final admin = await _authService.getCurrentAdmin();
    final doctors = await _doctorService.getAllDoctors();

    final activities = await _supabase
        .from('audit_logs')
        .select()
        .order('created_at', ascending: false)
        .limit(10);

    setState(() {
      _admin = admin;
      _totalDoctors = doctors.length;
      _recentActivities = List<Map<String, dynamic>>.from(activities);
      _isLoading = false;
    });
  }

  IconData _getActivityIcon(String actionType) {
    switch (actionType) {
      case 'ADD_DOCTOR':
        return Icons.person_add_outlined;
      case 'UPDATE_DOCTOR':
        return Icons.edit_outlined;
      case 'DELETE_DOCTOR':
        return Icons.block_outlined;
      case 'RESET_PASSWORD':
        return Icons.key_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _getActivityBg(String actionType) {
    switch (actionType) {
      case 'ADD_DOCTOR':
        return AppColors.primaryLight;
      case 'UPDATE_DOCTOR':
        return AppColors.blueLight;
      case 'DELETE_DOCTOR':
        return AppColors.redLight;
      case 'RESET_PASSWORD':
        return AppColors.amberLight;
      default:
        return AppColors.grayLight;
    }
  }

  Color _getActivityColor(String actionType) {
    switch (actionType) {
      case 'ADD_DOCTOR':
        return AppColors.primaryText;
      case 'UPDATE_DOCTOR':
        return AppColors.blueText;
      case 'DELETE_DOCTOR':
        return AppColors.redText;
      case 'RESET_PASSWORD':
        return AppColors.amberText;
      default:
        return AppColors.grayText;
    }
  }

  String _timeAgo(String createdAt) {
    if (createdAt.isEmpty) return '';
    try {
      final date = DateTime.parse(createdAt).toLocal();
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: _buildQuickActions(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
                      child: _buildRecentActivity(),
                    ),
                  ),
                ],
              ),
            ),
      //bottomNavigationBar: _buildBottomNav(context, 0),
    );
  }

  Widget _buildHeader() {
    final firstName = _admin?.fullName.split(' ').first ?? 'Admin';
    final initials =
        _admin?.fullName
            .split(' ')
            .take(2)
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
            .join() ??
        'A';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Good morning,',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            firstName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => context.go('/profile'),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            '👨‍⚕️',
                            style: TextStyle(fontSize: 22),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _totalDoctors.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Text(
                              'Total Registered Doctors',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'label': 'Add Doctor',
        'sub': 'Register new info',
        'icon': Icons.person_add_outlined,
        'bg': AppColors.primaryLight,
        'color': AppColors.primaryText,
        'route': '/doctors/add',
      },
      {
        'label': 'Doctors List',
        'sub': 'Manage medical staff',
        'icon': Icons.people_outline,
        'bg': AppColors.blueLight,
        'color': AppColors.blueText,
        'route': '/doctors',
      },
      {
        'label': 'My Profile',
        'sub': 'Update settings',
        'icon': Icons.settings_outlined,
        'bg': AppColors.amberLight,
        'color': AppColors.amberText,
        'route': '/profile',
      },
      {
        'label': 'Audit Log',
        'sub': 'See full history',
        'icon': Icons.bar_chart_outlined,
        'bg': AppColors.grayLight,
        'color': AppColors.grayText,
        'route': '/admin-activities',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUICK ACTIONS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 3.0,
          children: actions.map((a) {
            return GestureDetector(
              onTap: a['route'] != null
                  ? () => context.go(a['route'] as String)
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: a['bg'] as Color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        a['icon'] as IconData,
                        color: a['color'] as Color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            a['label'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            a['sub'] as String,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textTertiary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'RECENT ACTIVITY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/admin-activities'),
              child: Text(
                'See all →',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primaryMid,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: _recentActivities.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No recent activity',
                      style: TextStyle(color: AppColors.textTertiary),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentActivities.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFF9FAFB)),
                  itemBuilder: (context, index) {
                    final activity = _recentActivities[index];
                    final actionType = activity['action_type'] ?? '';
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: _getActivityBg(actionType),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getActivityIcon(actionType),
                              color: _getActivityColor(actionType),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activity['description'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _timeAgo(activity['created_at'] ?? ''),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
