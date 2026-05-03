import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/doctor_model.dart';
import '../../../data/services/doctor_service.dart';
import '../../../data/services/storage_service.dart';

class AddEditDoctorScreen extends StatefulWidget {
  final DoctorModel? doctor; // null = Add, not null = Edit

  const AddEditDoctorScreen({super.key, this.doctor});

  @override
  State<AddEditDoctorScreen> createState() => _AddEditDoctorScreenState();
}

class _AddEditDoctorScreenState extends State<AddEditDoctorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _doctorService = DoctorService();
  final _storageService = StorageService();

  // Text Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _qualificationsController = TextEditingController();
  final _feeController = TextEditingController();
  final _passwordController = TextEditingController();

  // Form State
  String _selectedDepartment = AppStrings.departments[0];
  int _selectedSlotDuration = 30;
  List<String> _selectedDays = [];
  File? _selectedImage;
  String? _existingImageUrl;
  bool _isLoading = false;
  bool _passwordVisible = false;

  // Check if editing or adding
  bool get _isEditing => widget.doctor != null;

  @override
  void initState() {
    super.initState();
    // If editing, fill form with existing data
    if (_isEditing) {
      _nameController.text = widget.doctor!.fullName;
      _emailController.text = widget.doctor!.email;
      _phoneController.text = widget.doctor!.phone ?? '';
      _qualificationsController.text = widget.doctor!.qualifications ?? '';
      _feeController.text = widget.doctor!.consultationFee.toString();
      _selectedDepartment = widget.doctor!.department;
      _selectedSlotDuration = widget.doctor!.slotDuration;
      _selectedDays = List.from(widget.doctor!.availableDays);
      _existingImageUrl = widget.doctor!.profileImageUrl;
    }
  }

  // Pick image from gallery
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

  // Save doctor
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one available day'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Upload image if selected
    String? imageUrl = _existingImageUrl;
    if (_selectedImage != null) {
      imageUrl = await _storageService.uploadDoctorImage(
        _selectedImage!,
        _emailController.text.trim(),
      );
    }

    // Build doctor model
    final doctor = DoctorModel(
      id: widget.doctor?.id,
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      qualifications: _qualificationsController.text.trim(),
      consultationFee: double.parse(_feeController.text),
      department: _selectedDepartment,
      slotDuration: _selectedSlotDuration,
      availableDays: _selectedDays,
      timeSlots: [],
      profileImageUrl: imageUrl,
      accountStatus: true,
    );

    bool success;
    if (_isEditing) {
      success = await _doctorService.updateDoctor(widget.doctor!.id!, doctor);
    } else {
      success = await _doctorService.addDoctor(
        doctor,
        _passwordController.text,
      );
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Doctor updated successfully'
                  : 'Doctor added successfully',
            ),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Try again.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _qualificationsController.dispose();
    _feeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Doctor' : 'Add Doctor'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Basic Information'),
                    const SizedBox(height: 16),

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
                                  : (_existingImageUrl != null
                                            ? NetworkImage(_existingImageUrl!)
                                            : null)
                                        as ImageProvider?,
                              child:
                                  (_selectedImage == null &&
                                      _existingImageUrl == null)
                                  ? const Icon(Icons.person, size: 50)
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

                    const SizedBox(height: 20),

                    // Full Name
                    _buildLabel('Full Name *'),
                    TextFormField(
                      controller: _nameController,
                      validator: Validators.validateName,
                      decoration: const InputDecoration(
                        hintText: 'Dr. Full Name',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email
                    _buildLabel('Email *'),
                    TextFormField(
                      controller: _emailController,
                      validator: Validators.validateEmail,
                      enabled: !_isEditing, // Cannot change email when editing
                      decoration: const InputDecoration(
                        hintText: 'doctor@email.com',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Phone
                    _buildLabel('Phone (Optional)'),
                    TextFormField(
                      controller: _phoneController,
                      validator: Validators.validatePhone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: '01XXXXXXXXX',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Qualifications
                    _buildLabel('Qualifications'),
                    TextFormField(
                      controller: _qualificationsController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'MBBS, MD, etc.',
                      ),
                    ),

                    // Password (only for Add)
                    if (!_isEditing) ...[
                      const SizedBox(height: 16),
                      _buildLabel('Password *'),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_passwordVisible,
                        validator: Validators.validatePassword,
                        decoration: InputDecoration(
                          hintText: 'Set login password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setState(
                              () => _passwordVisible = !_passwordVisible,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 24),

              // Right Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Schedule & Department'),
                    const SizedBox(height: 16),

                    // Department
                    _buildLabel('Department *'),
                    DropdownButtonFormField<String>(
                      value: _selectedDepartment,
                      items: AppStrings.departments
                          .map(
                            (dept) => DropdownMenuItem(
                              value: dept,
                              child: Text(dept),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedDepartment = value!),
                      decoration: const InputDecoration(
                        hintText: 'Select department',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Consultation Fee
                    _buildLabel('Consultation Fee (৳) *'),
                    TextFormField(
                      controller: _feeController,
                      validator: Validators.validateFee,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'e.g. 500'),
                    ),
                    const SizedBox(height: 16),

                    // Slot Duration
                    _buildLabel('Slot Duration *'),
                    DropdownButtonFormField<int>(
                      value: _selectedSlotDuration,
                      items: [15, 20, 30, 45, 60]
                          .map(
                            (min) => DropdownMenuItem(
                              value: min,
                              child: Text('$min minutes'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedSlotDuration = value!),
                      decoration: const InputDecoration(
                        hintText: 'Select slot duration',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Available Days
                    _buildLabel('Available Days *'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppStrings.weekDays.map((day) {
                        final isSelected = _selectedDays.contains(day);
                        return FilterChip(
                          label: Text(day.substring(0, 3)),
                          selected: isSelected,
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          checkmarkColor: AppColors.primary,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedDays.add(day);
                              } else {
                                _selectedDays.remove(day);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSave,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(_isEditing ? 'Update Doctor' : 'Add Doctor'),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Cancel Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Section Title
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  // Field Label
  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
