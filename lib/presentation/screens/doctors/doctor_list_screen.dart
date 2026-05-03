import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medichain/data/services/auth_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/doctor_service.dart';
import '../../../data/models/doctor_model.dart';

class DoctorListScreen extends StatefulWidget {
  const DoctorListScreen({super.key});

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  final _doctorService = DoctorService();
  final _searchController = TextEditingController();

  List<DoctorModel> _doctors = [];
  List<DoctorModel> _filteredDoctors = [];
  bool _isLoading = true;
  String _selectedDepartment = 'All';

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  // Load all doctors
  Future<void> _loadDoctors() async {
    final doctors = await _doctorService.getAllDoctors();
    setState(() {
      _doctors = doctors;
      _filteredDoctors = doctors;
      _isLoading = false;
    });
  }

  // Search doctors by name or ID
  void _searchDoctors(String query) {
    setState(() {
      _filteredDoctors = _doctors.where((doctor) {
        final matchesName = doctor.fullName.toLowerCase().contains(
          query.toLowerCase(),
        );
        final matchesId =
            doctor.doctorId?.toLowerCase().contains(query.toLowerCase()) ??
            false;
        final matchesDept =
            _selectedDepartment == 'All' ||
            doctor.department == _selectedDepartment;
        return (matchesName || matchesId) && matchesDept;
      }).toList();
    });
  }

  // Filter by department
  void _filterByDepartment(String department) {
    setState(() {
      _selectedDepartment = department;
      _searchDoctors(_searchController.text);
    });
  }

  // Toggle doctor active/inactive
  Future<void> _toggleStatus(DoctorModel doctor) async {
    await _doctorService.toggleDoctorStatus(doctor.id!, !doctor.accountStatus);
    _loadDoctors();
  }

  // Delete doctor confirmation dialog
  Future<void> _confirmDelete(DoctorModel doctor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Doctor'),
        content: Text(
          'Are you sure you want to delete ${doctor.fullName}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _doctorService.deleteDoctor(doctor.id!, doctor.fullName);
      _loadDoctors();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doctor deleted successfully')),
        );
      }
    }
  }

  // Show password reset dialog
  Future<void> _showPasswordResetDialog(DoctorModel doctor) async {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isVisible = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Reset Password - ${doctor.fullName}'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: passwordController,
                  obscureText: !isVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 8) return 'Minimum 8 characters';
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        isVisible ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setDialogState(() => isVisible = !isVisible),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  await _doctorService.resetDoctorPassword(
                    doctor.email,
                    passwordController.text,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password reset successfully'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
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

  // Sidebar
  Widget _buildSidebar() {
    return Container(
      width: 240,
      color: AppColors.sidebarBg,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            child: const Row(
              children: [
                Icon(Icons.local_hospital, color: Colors.white, size: 28),
                SizedBox(width: 8),
                Text(
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
          const SizedBox(height: 8),
          _buildNavItem(Icons.dashboard, 'Dashboard', '/dashboard', false),
          _buildNavItem(Icons.people, 'Doctors', '/doctors', true),
          _buildNavItem(Icons.person, 'My Profile', '/profile', false),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextButton.icon(
              onPressed: () async {
                await AuthService().logout();
                if (mounted) context.go('/login');
              },
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

  // Main Content
  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Doctors',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${_filteredDoctors.length} doctors found',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
              // Add Doctor Button
              ElevatedButton.icon(
                onPressed: () async {
                  await context.push('/doctors/add');
                  _loadDoctors();
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Doctor'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(140, 44),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Search and Filter Row
          Row(
            children: [
              // Search Field
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _searchController,
                  onChanged: _searchDoctors,
                  decoration: const InputDecoration(
                    hintText: 'Search by name or doctor ID...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Department Filter Dropdown
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedDepartment,
                  decoration: const InputDecoration(labelText: 'Department'),
                  items: ['All', ...AppStrings.departments]
                      .map(
                        (dept) =>
                            DropdownMenuItem(value: dept, child: Text(dept)),
                      )
                      .toList(),
                  onChanged: (value) => _filterByDepartment(value!),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Doctors Table
          Expanded(
            child: _filteredDoctors.isEmpty
                ? Center(
                    child: Text(
                      'No doctors found',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(1),
                          1: FlexColumnWidth(2),
                          2: FlexColumnWidth(1.5),
                          3: FlexColumnWidth(1),
                          4: FlexColumnWidth(1),
                          5: FlexColumnWidth(2),
                        },
                        children: [
                          // Table Header
                          TableRow(
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.05),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            children: [
                              _tableHeader('Doctor ID'),
                              _tableHeader('Name'),
                              _tableHeader('Department'),
                              _tableHeader('Fee'),
                              _tableHeader('Status'),
                              _tableHeader('Actions'),
                            ],
                          ),

                          // Table Rows
                          ..._filteredDoctors.map(
                            (doctor) => TableRow(
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Color(0xFFEEEEEE)),
                                ),
                              ),
                              children: [
                                _tableCell(doctor.doctorId ?? '-'),
                                // Doctor name with photo
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundImage:
                                            doctor.profileImageUrl != null
                                            ? NetworkImage(
                                                doctor.profileImageUrl!,
                                              )
                                            : null,
                                        child: doctor.profileImageUrl == null
                                            ? Text(
                                                doctor.fullName.substring(0, 1),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          doctor.fullName,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _tableCell(doctor.department),
                                _tableCell(
                                  '৳${doctor.consultationFee.toInt()}',
                                ),
                                // Status Toggle
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Switch(
                                    value: doctor.accountStatus,
                                    activeColor: AppColors.success,
                                    onChanged: (_) => _toggleStatus(doctor),
                                  ),
                                ),
                                // Action Buttons
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Row(
                                    children: [
                                      // Edit
                                      IconButton(
                                        icon: Icon(
                                          Icons.edit,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                        onPressed: () async {
                                          await context.push(
                                            '/doctors/edit',
                                            extra: doctor,
                                          );
                                          _loadDoctors();
                                        },
                                      ),
                                      // Reset Password
                                      IconButton(
                                        icon: Icon(
                                          Icons.lock_reset,
                                          color: AppColors.warning,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            _showPasswordResetDialog(doctor),
                                      ),
                                      // Delete
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color: AppColors.error,
                                          size: 20,
                                        ),
                                        onPressed: () => _confirmDelete(doctor),
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
                  ),
          ),
        ],
      ),
    );
  }

  // Table Header Cell
  Widget _tableHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  // Table Data Cell
  Widget _tableCell(String value) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(value, style: TextStyle(color: AppColors.textPrimary)),
    );
  }
}
