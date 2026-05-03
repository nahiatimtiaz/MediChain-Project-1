import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/admin_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final _authService = AuthService();
  final _storageService = StorageService();
  final _supabase = Supabase.instance.client;

  // Profile form
  final _profileFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();

  // Password form
  final _passwordFormKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  AdminModel? _admin;
  File? _selectedImage;
  bool _isLoading = true;
  bool _isSavingProfile = false;
  bool _isSavingPassword = false;
  bool _currentPassVisible = false;
  bool _newPassVisible = false;
  bool _confirmPassVisible = false;

  @override
  void initState() {
    super.initState();
    _loadAdmin();
  }

  // Load current admin data
  Future<void> _loadAdmin() async {
    final admin = await _authService.getCurrentAdmin();
    setState(() {
      _admin = admin;
      _nameController.text = admin?.fullName ?? '';
      _usernameController.text = admin?.username ?? '';
      _isLoading = false;
    });
  }

  // Pick profile image
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  // Save profile info
  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;
    setState(() => _isSavingProfile = true);

    // Upload new image if selected
    String? imageUrl = _admin?.profileImageUrl;
    if (_selectedImage != null) {
      imageUrl = await _storageService.uploadAdminImage(
        _selectedImage!,
        _admin!.id,
      );
    }

    // Update admin in database
    await _supabase
        .from('admins')
        .update({
          'full_name': _nameController.text.trim(),
          'username': _usernameController.text.trim(),
          'profile_image_url': imageUrl,
        })
        .eq('id', _admin!.id);

    await _loadAdmin();
    setState(() => _isSavingProfile = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  // Change password
  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() => _isSavingPassword = true);

    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: _newPasswordController.text),
      );

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to change password')),
        );
      }
    }

    setState(() => _isSavingPassword = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
          _buildNavItem(Icons.people, 'Doctors', '/doctors', false),
          _buildNavItem(Icons.person, 'My Profile', '/profile', true),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextButton.icon(
              onPressed: () async {
                await _authService.logout();
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'My Profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Info Card
              Expanded(child: _buildProfileCard()),
              const SizedBox(width: 24),
              // Change Password Card
              Expanded(child: _buildPasswordCard()),
            ],
          ),
        ],
      ),
    );
  }

  // Profile Info Card
  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Form(
        key: _profileFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),

            // Profile Image
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : (_admin?.profileImageUrl != null
                                    ? NetworkImage(_admin!.profileImageUrl!)
                                    : null)
                                as ImageProvider?,
                      child:
                          (_selectedImage == null &&
                              _admin?.profileImageUrl == null)
                          ? Text(
                              _admin?.fullName.substring(0, 1).toUpperCase() ??
                                  'A',
                              style: const TextStyle(
                                fontSize: 32,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Email (read only)
            const Text('Email', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                _admin?.email ?? '',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),

            const SizedBox(height: 16),

            // Full Name
            const Text(
              'Full Name',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              validator: Validators.validateName,
              decoration: const InputDecoration(hintText: 'Your full name'),
            ),

            const SizedBox(height: 16),

            // Username
            const Text(
              'Username',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _usernameController,
              validator: (value) =>
                  Validators.validateRequired(value, 'Username'),
              decoration: const InputDecoration(hintText: 'Your username'),
            ),

            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSavingProfile ? null : _saveProfile,
                child: _isSavingProfile
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Change Password Card
  Widget _buildPasswordCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Form(
        key: _passwordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Change Password',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),

            // Current Password
            const Text(
              'Current Password',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _currentPasswordController,
              obscureText: !_currentPassVisible,
              validator: (value) =>
                  Validators.validateRequired(value, 'Current password'),
              decoration: InputDecoration(
                hintText: 'Enter current password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _currentPassVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () => setState(
                    () => _currentPassVisible = !_currentPassVisible,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // New Password
            const Text(
              'New Password',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _newPasswordController,
              obscureText: !_newPassVisible,
              validator: Validators.validatePassword,
              decoration: InputDecoration(
                hintText: 'Enter new password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _newPassVisible ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _newPassVisible = !_newPassVisible),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Confirm Password
            const Text(
              'Confirm Password',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: !_confirmPassVisible,
              validator: (value) => Validators.validateConfirmPassword(
                value,
                _newPasswordController.text,
              ),
              decoration: InputDecoration(
                hintText: 'Confirm new password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _confirmPassVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () => setState(
                    () => _confirmPassVisible = !_confirmPassVisible,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Change Password Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSavingPassword ? null : _changePassword,
                child: _isSavingPassword
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Change Password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
