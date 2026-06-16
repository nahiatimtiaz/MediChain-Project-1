import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/validators.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/storage_service.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  final _authService = AuthService();
  final _storageService = StorageService();
  final _supabase = Supabase.instance.client;

  final _profileFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  final _passwordFormKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Map<String, dynamic>? _patientData;
  File? _selectedImage;
  bool _isLoading = true;
  bool _isSavingProfile = false;
  bool _isImageDeleted = false;
  bool _isSavingPassword = false;
  bool _currentPassVisible = false;
  bool _newPassVisible = false;
  bool _confirmPassVisible = false;

  @override
  void initState() {
    super.initState();
    _loadPatientProfile();
  }

  Future<void> _loadPatientProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final data = await _supabase
            .from('patients')
            .select()
            .eq('id', user.id)
            .single();

        setState(() {
          _patientData = data;
          _nameController.text = data['full_name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load profile data'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showImageSourceOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final hasImage = _selectedImage != null || 
            (_patientData?['profile_image_url'] != null && !_isImageDeleted);

        return SafeArea(
          child: Wrap(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Profile Photo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Upload from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                  setState(() => _isImageDeleted = false);
                },
              ),
              if (hasImage)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Remove Current Photo', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage = null;
                      _isImageDeleted = true;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _isImageDeleted = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;
    setState(() => _isSavingProfile = true);

    try {
      final userId = _supabase.auth.currentUser!.id;
      String? imageUrl = _patientData?['profile_image_url'];

      if (_isImageDeleted) {
        imageUrl = null;
      } else if (_selectedImage != null) {
        imageUrl = await _storageService.uploadPatientImage(
          _selectedImage!,
          userId,
        );
      }

      await _supabase
          .from('patients')
          .update({
            'full_name': _nameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'profile_image_url': imageUrl,
          })
          .eq('id', userId);

      setState(() {
        _selectedImage = null;
        _isImageDeleted = false;
      });

      await _loadPatientProfile();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save profile changes'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSavingProfile = false);
    }
  }

Future<void> _changePassword() async {
  if (!_passwordFormKey.currentState!.validate()) return;
  setState(() => _isSavingPassword = true);

  try {
    final email = _supabase.auth.currentUser?.email;
    
    if (email == null) {
      throw Exception("User email not found.");
    }

    // Step 1: Verify the current password by attempting a silent re-login check
    await _supabase.auth.signInWithPassword(
      email: email,
      password: _currentPasswordController.text.trim(),
    );

    // Step 2: If the sign-in doesn't throw an error, it means the current password is correct.
    // Proceed to update the password safely.
    await _supabase.auth.updateUser(
      UserAttributes(password: _newPasswordController.text.trim()),
    );

    // Clear forms cleanly on success
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully')),
      );
    }
  } on AuthException catch (authError) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          // Handle wrong password/credentials error explicitly
          content: Text(authError.message.contains('invalid') || authError.message.contains('credentials')
              ? 'Incorrect current password. Please try again.'
              : authError.message), 
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to change password'), backgroundColor: Colors.red),
      );
    }
  } finally {
    setState(() => _isSavingPassword = false);
  }
}

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], 
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _buildProfileCard(),
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
    );
  }

  Widget _buildHeader() {
    final fullName = _patientData?['full_name'] ?? 'Patient';
    final patientId = _patientData?['patient_id'] ?? 'PAT------';
    
    final initials = fullName.split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    ImageProvider? avatarImage;
    if (!_isImageDeleted) {
      if (_selectedImage != null && _selectedImage!.path.isNotEmpty) {
        avatarImage = FileImage(File(_selectedImage!.path));
      } else if (_patientData?['profile_image_url'] != null && 
                 _patientData?['profile_image_url'].toString().trim().isNotEmpty == true) {
        avatarImage = NetworkImage(_patientData?['profile_image_url']);
      }
    }

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.fromARGB(255, 114, 169, 213), Color.fromARGB(255, 166, 202, 219)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            children: [
              GestureDetector(
                onTap: () => _showImageSourceOptions(context),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          backgroundImage: avatarImage,
                          child: avatarImage == null
                              ? Text(
                                  initials.isEmpty ? 'P' : initials,
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 4,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.edit, size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ID: $patientId',
                style: const TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
      ),
      child: Form(
        key: _profileFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EDIT PERSONAL INFO',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey[600],
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Full Name',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              validator: Validators.validateName,
              decoration: const InputDecoration(hintText: 'Your full name'),
            ),
            const SizedBox(height: 12),
            Text(
              'Phone Number',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              validator: (v) => Validators.validateRequired(v, 'Phone Number'),
              decoration: const InputDecoration(hintText: 'Your phone number'),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSavingProfile ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSavingProfile
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
      ),
      child: Form(
        key: _passwordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SECURITY & PASSWORD',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey[600],
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 14),
            _buildPasswordField(
              'Current Password', 
              _currentPasswordController, 
              _currentPassVisible, 
              () => setState(() => _currentPassVisible = !_currentPassVisible),
              validator: (v) => Validators.validateRequired(v, 'Current Password'),
            ),
            const SizedBox(height: 12),
            _buildPasswordField(
              'New Password', 
              _newPasswordController, 
              _newPassVisible, 
              () => setState(() => _newPassVisible = !_newPassVisible),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'New password is required';
                if (v.length < 8) return 'Password must be at least 8 characters long';
                
                // 🔥 ENHANCED REGEX PATTERN: Requires 1 Uppercase, 1 Lowercase, 1 Number, allows special characters
                final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$');
                if (!passwordRegex.hasMatch(v)) {
                  return 'Must include uppercase, lowercase, and a number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildPasswordField(
              'Confirm New Password', 
              _confirmPasswordController, 
              _confirmPassVisible, 
              () => setState(() => _confirmPassVisible = !_confirmPassVisible),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please confirm your new password';
                if (v != _newPasswordController.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSavingPassword ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSavingPassword
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
    );
  }

  Widget _buildPasswordField(
    String label, 
    TextEditingController controller, 
    bool visible, 
    VoidCallback toggle, 
    {required FormFieldValidator<String> validator}
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: !visible,
          validator: validator,
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: Icon(Icons.lock_outline, size: 18, color: Colors.grey[400]),
            suffixIcon: IconButton(
              icon: Icon(
                visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 18,
                color: Colors.grey[400],
              ),
              onPressed: toggle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          await _authService.logout();
          if (mounted) context.go('/patient-login');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFEBEE), 
          foregroundColor: const Color(0xFFC62828), 
          side: const BorderSide(color: Color(0xFFFFEBEE), width: 2),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Sign Out Account',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}