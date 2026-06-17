import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../../data/models/doctor_model.dart';
import '../../data/services/doctor_service.dart';
import '../../data/services/storage_service.dart';

class AddEditDoctorScreen extends StatefulWidget {
  final DoctorModel? doctor;

  const AddEditDoctorScreen({super.key, this.doctor});

  @override
  State<AddEditDoctorScreen> createState() => _AddEditDoctorScreenState();
}

class _AddEditDoctorScreenState extends State<AddEditDoctorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _doctorService = DoctorService();
  final _storageService = StorageService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _qualificationsController = TextEditingController();
  final _feeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  String _selectedDepartment = AppStrings.departments[0];
  int _selectedSlotDuration = 30;
  List<String> _selectedDays = [];
  File? _selectedImage;
  String? _existingImageUrl;
  bool _isLoading = false;
  bool _passwordVisible = false;

  String _formatTime(TimeOfDay? time) {
  if (time == null) return '';
  final String hour = time.hour.toString().padLeft(2, '0');
  final String minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

  // New states for dynamic time slot partitioning
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool get _isEditing => widget.doctor != null;

 @override
void initState() {
  super.initState();
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

    // 👇 ADD THIS TO PARSE DB STRINGS INTO THE TIME WIDGET STATES:
    if (widget.doctor!.startTime != null && widget.doctor!.startTime!.isNotEmpty) {
      final parts = widget.doctor!.startTime!.split(':');
      _startTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1].substring(0, 2)));
    }
    if (widget.doctor!.endTime != null && widget.doctor!.endTime!.isNotEmpty) {
      final parts = widget.doctor!.endTime!.split(':');
      _endTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1].substring(0, 2)));
    }
  }
}

  // Helper method to parse String (e.g., "03:00 PM") to TimeOfDay
  TimeOfDay _parseTimeOfDay(String? timeStr) {
    // Handle null, empty, or placeholder 'EMPTY' values by returning a default time
    if (timeStr == null ||
        timeStr.toLowerCase() == 'empty' ||
        timeStr.trim().isEmpty) {
      return const TimeOfDay(hour: 9, minute: 0);
    }

    try {
      // Normalize string and extract hour and minute parts
      final normalized = timeStr.toLowerCase().trim();
      final parts = normalized.split(':');

      int hour = int.parse(parts[0]);
      int minute = int.parse(
        parts[1].split(' ')[0].replaceAll(RegExp(r'[^0-9]'), ''),
      );

      // Adjust hour based on AM/PM indicator
      if (normalized.contains('pm') && hour < 12) hour += 12;
      if (normalized.contains('am') && hour == 12) hour = 0;

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      // Return default time if parsing fails due to unexpected format
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  // Updated Time Picker for Start Time
  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 15, minute: 0),
    );
    if (picked != null && mounted) {
      setState(() => _startTime = picked);
    }
  }

  // Updated Time Picker for End Time
  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? const TimeOfDay(hour: 19, minute: 0),
    );
    if (picked != null && mounted) {
      setState(() => _endTime = picked);
    }
  }

  // --- Pick Image ---
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (picked != null) {
      final file = File(picked.path);
      final extension = picked.path.split('.').last.toLowerCase();
      if (extension != 'jpg' && extension != 'jpeg' && extension != 'png') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Only JPEG and PNG images are allowed'),
            ),
          );
        }
        return;
      }
      final fileSizeInMB = await file.length() / (1024 * 1024);
      if (fileSizeInMB > 2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image size must be less than 2MB')),
          );
        }
        return;
      }
      setState(() => _selectedImage = file);
    }
  }

  // --- Save / Update ---
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation for Time and Days
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both Chamber Start and End times'),
        ),
      );
      return;
    }

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one available day'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    String? imageUrl = _existingImageUrl;
    if (_selectedImage != null) {
      imageUrl = await _storageService.uploadDoctorImage(
        _selectedImage!,
        _emailController.text.trim(),
      );
    }

    final String customDoctorId = _isEditing
        ? (widget.doctor!.doctorId ?? '')
        : 'DOC-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    // Creating the DoctorModel with corrected time fields
    final doctor = DoctorModel(
  id: widget.doctor?.id,
  doctorId: customDoctorId,
  fullName: _nameController.text.trim(),
  email: _emailController.text.trim(),
  phone: _phoneController.text.trim(),
  qualifications: _qualificationsController.text.trim(),
  consultationFee: double.parse(_feeController.text),
  department: _selectedDepartment,
  slotDuration: _selectedSlotDuration,
  availableDays: _selectedDays,
  
  // 👇 CHANGE THESE TWO LINES TO USE THE HELPER FUNCTION:
  startTime: _formatTime(_startTime),
  endTime: _formatTime(_endTime),
  
  maxPatientsPerDay: widget.doctor?.maxPatientsPerDay ?? 50,
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
        context.go('/doctors');
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
    _startTimeController.dispose();
    _endTimeController.dispose();
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/doctors'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Profile Image ---
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
                          padding: const EdgeInsets.all(6),
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
              _buildSectionHeader('Basic Information'),
              const SizedBox(height: 12),

              _buildLabel('Full Name *'),
              TextFormField(
                controller: _nameController,
                validator: Validators.validateName,
                decoration: const InputDecoration(hintText: 'Dr. Full Name'),
              ),
              const SizedBox(height: 16),

              _buildLabel('Email *'),
              TextFormField(
                controller: _emailController,
                validator: Validators.validateEmail,
                enabled: !_isEditing,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'doctor@email.com'),
              ),
              const SizedBox(height: 16),

              _buildLabel('Phone (Optional)'),
              TextFormField(
                controller: _phoneController,
                validator: Validators.validatePhone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: '01XXXXXXXXX'),
              ),
              const SizedBox(height: 16),

              _buildLabel('Qualifications'),
              TextFormField(
                controller: _qualificationsController,
                maxLines: 2,
                decoration: const InputDecoration(hintText: 'MBBS, MD, etc.'),
              ),

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
                      onPressed: () =>
                          setState(() => _passwordVisible = !_passwordVisible),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              _buildSectionHeader('Schedule & Department'),
              const SizedBox(height: 12),

              _buildLabel('Department *'),
              DropdownButtonFormField<String>(
                value: _selectedDepartment,
                items: AppStrings.departments
                    .map(
                      (dept) =>
                          DropdownMenuItem(value: dept, child: Text(dept)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedDepartment = value!),
                decoration: const InputDecoration(
                  hintText: 'Select department',
                ),
              ),
              const SizedBox(height: 16),

              // // --- Start & End Time ---
              // Row(
              //   children: [
              //     Expanded(
              //       child: Column(
              //         crossAxisAlignment: CrossAxisAlignment.start,
              //         children: [
              //           _buildLabel('Start Time *'),
              //           TextFormField(
              //             controller: _startTimeController,
              //             readOnly: true,
              //             onTap: () =>
              //                 _selectTime(context, _startTimeController),
              //             validator: (v) =>
              //                 v == null || v.isEmpty ? 'Required' : null,
              //             decoration: const InputDecoration(
              //               hintText: '03:00 PM',
              //               suffixIcon: Icon(Icons.access_time),
              //             ),
              //           ),
              //         ],
              //       ),
              //     ),
              //     const SizedBox(width: 16),
              //     Expanded(
              //       child: Column(
              //         crossAxisAlignment: CrossAxisAlignment.start,
              //         children: [
              //           _buildLabel('End Time *'),
              //           TextFormField(
              //             controller: _endTimeController,
              //             readOnly: true,
              //             onTap: () => _selectTime(context, _endTimeController),
              //             validator: (v) =>
              //                 v == null || v.isEmpty ? 'Required' : null,
              //             decoration: const InputDecoration(
              //               hintText: '07:00 PM',
              //               suffixIcon: Icon(Icons.access_time),
              //             ),
              //           ),
              //         ],
              //       ),
              //     ),
              //   ],
              // ),
              const SizedBox(height: 16),

              _buildLabel('Consultation Fee (৳) *'),
              TextFormField(
                controller: _feeController,
                validator: Validators.validateFee,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'e.g. 500'),
              ),
              const SizedBox(height: 16),

              // --- DYNAMIC START TIME & END TIME PICKER ROW ---
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Chamber Starts *'),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.access_time),
                          label: Text(
                            _startTime == null
                                ? 'Select Start'
                                : _startTime!.format(context),
                          ),
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: const TimeOfDay(hour: 15, minute: 0),
                            );
                            if (time != null) setState(() => _startTime = time);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Chamber Ends *'),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.access_time),
                          label: Text(
                            _endTime == null
                                ? 'Select End'
                                : _endTime!.format(context),
                          ),
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: const TimeOfDay(hour: 19, minute: 0),
                            );
                            if (time != null) setState(() => _endTime = time);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildLabel('Slot Duration *'),
              DropdownButtonFormField<int>(
                value: _selectedSlotDuration,
                items: const [15, 20, 30, 45, 60]
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

              _buildLabel('Available Days *'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppStrings.weekDays.map((day) {
                  final isSelected = _selectedDays.contains(day);
                  return FilterChip(
                    label: Text(
                      day.substring(0, 3),
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary.withAlpha(38),
                    backgroundColor: Colors.white,
                    checkmarkColor: AppColors.primary,
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
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

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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

              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => context.go('/doctors'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
