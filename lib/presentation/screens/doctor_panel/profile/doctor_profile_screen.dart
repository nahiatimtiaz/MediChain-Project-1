import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/validators.dart';
import '../../../../data/services/doctor_services/doctor_auth_service.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final _authService = DoctorAuthService();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFormKey = GlobalKey<FormState>();

  Map<String, dynamic>? _doctor;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _newPassVisible = false;
  bool _confirmPassVisible = false;

  @override
  void initState() {
    super.initState();
    _loadDoctor();
  }

  Future<void> _loadDoctor() async {
    final doctor = await _authService.getCurrentDoctor();
    if (doctor == null) {
      if (mounted) context.go('/doctor-login');
      return;
    }
    setState(() {
      _doctor = doctor;
      _isLoading = false;
    });
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final success = await _authService.changePassword(
      _newPasswordController.text,
    );

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Password changed successfully'
                : 'Failed to change password',
          ),
        ),
      );
      if (success) {
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    }
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blueDark,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.bluePrimary))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _buildInfoCard(),
                        const SizedBox(height: 14),
                        _buildPasswordCard(),
                        const SizedBox(height: 14),
                        _buildSignOutButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _buildBottomNav(context, 3),
    );
  }

  Widget _buildHeader() {
    final initials = (_doctor?['full_name'] as String? ?? 'D')
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.bluePrimary, AppColors.blueDark],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 3),
                  image: _doctor?['profile_image_url'] != null
                      ? DecorationImage(
                          image: NetworkImage(_doctor!['profile_image_url']),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _doctor?['profile_image_url'] == null
                    ? Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                _doctor?['full_name'] ?? 'Doctor',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_doctor?['department'] ?? ''} · ${_doctor?['doctor_id'] ?? ''}',
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _doctor?['account_status'] == true ? '🟢 Active' : '🔴 Inactive',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final infoRows = [
      {'icon': Icons.email_outlined, 'label': 'Email', 'value': _doctor?['email'] ?? '-'},
      {'icon': Icons.local_hospital_outlined, 'label': 'Department', 'value': _doctor?['department'] ?? '-'},
      {'icon': Icons.currency_rupee, 'label': 'Consultation Fee', 'value': '৳${_doctor?['consultation_fee'] ?? 0}'},
      {'icon': Icons.timer_outlined, 'label': 'Slot Duration', 'value': '${_doctor?['slot_duration'] ?? 20} minutes'},
    ];

    return Transform.translate(
      offset: const Offset(0, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DOCTOR INFO',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 14),
            ...infoRows.asMap().entries.map((entry) {
              final i = entry.key;
              final row = entry.value;
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: i < infoRows.length - 1
                      ? const Border(bottom: BorderSide(color: Color(0xFFF9FAFB)))
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.blueLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(row['icon'] as IconData, color: AppColors.blueMid, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row['label'] as String,
                          style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                        ),
                        Text(
                          row['value'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordCard() {
    return Transform.translate(
      offset: const Offset(0, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Form(
          key: _passwordFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CHANGE PASSWORD',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 14),
              const Text('New Password', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _newPasswordController,
                obscureText: !_newPassVisible,
                validator: Validators.validatePassword,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline, size: 18, color: AppColors.textTertiary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _newPassVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 18,
                      color: AppColors.textTertiary,
                    ),
                    onPressed: () => setState(() => _newPassVisible = !_newPassVisible),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Confirm Password', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_confirmPassVisible,
                validator: (value) => Validators.validateConfirmPassword(
                  value,
                  _newPasswordController.text,
                ),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline, size: 18, color: AppColors.textTertiary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _confirmPassVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 18,
                      color: AppColors.textTertiary,
                    ),
                    onPressed: () => setState(() => _confirmPassVisible = !_confirmPassVisible),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blueMid,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Update Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return Transform.translate(
      offset: const Offset(0, 0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            await _authService.logout();
            if (mounted) context.go('/');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.redLight,
            foregroundColor: AppColors.redText,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

Widget _buildBottomNav(BuildContext context, int currentIndex) {
  return Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
    ),
    child: SafeArea(
      top: false,
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.bluePrimary,
        unselectedItemColor: AppColors.textTertiary,
        selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        onTap: (index) {
          if (index == 0) context.go('/doctor-schedule');
          if (index == 1) context.go('/doctor-patients');
          if (index == 2) context.go('/doctor-notifications');
          if (index == 3) context.go('/doctor-profile');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Schedule'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Patients'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), activeIcon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    ),
  );
}