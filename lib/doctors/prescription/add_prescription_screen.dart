

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/doctor_models/prescription_model.dart';
import '../../data/services/doctor_services/prescription_service.dart';

class AddPrescriptionScreen extends StatefulWidget {
  final Map<String, dynamic> extra;

  const AddPrescriptionScreen({super.key, required this.extra});

  @override
  State<AddPrescriptionScreen> createState() => _AddPrescriptionScreenState();
}

class _AddPrescriptionScreenState extends State<AddPrescriptionScreen> {
  final _prescriptionService = PrescriptionService();
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();
  final _reportNameController = TextEditingController();

  final List<Map<String, dynamic>> _medicines = [];
  DateTime? _followUpDate;
  bool _isLoading = false;
  File? _selectedReport;
  String? _patientAllergies;

  @override
  void initState() {
    super.initState();
    _loadAllergies();
  }

  Future<void> _loadAllergies() async {
    final allergies = await _prescriptionService.getPatientAllergies(
      widget.extra['patient_id'],
    );
    setState(() => _patientAllergies = allergies);
  }

  void _addMedicine() {
    setState(() {
      _medicines.add({
        'name': '',
        'dosage': '',
        'duration': '',
        'nameController': TextEditingController(),
        'dosageController': TextEditingController(),
        'durationController': TextEditingController(),
      });
    });
  }

  void _removeMedicine(int index) {
    setState(() => _medicines.removeAt(index));
  }

  Future<void> _pickReport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null) {
      setState(() => _selectedReport = File(result.files.single.path!));
    }
  }

  // Future<void> _pickFollowUpDate() async {
  //   final date = await showDatePicker(
  //     context: context,
  //     initialDate: DateTime.now().add(const Duration(days: 7)),
  //     firstDate: DateTime.now(),
  //     lastDate: DateTime.now().add(const Duration(days: 365)),
  //   );
  //   if (date != null) setState(() => _followUpDate = date);
  // }

  Future<void> _savePrescription() async {
    if (_diagnosisController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter diagnosis')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final medicines = _medicines
        .map((med) => {
              'name': med['nameController'].text,
              'dosage': med['dosageController'].text,
              'duration': med['durationController'].text,
            })
        .toList();

    final prescription = PrescriptionModel(
      doctorId: widget.extra['doctor_id'],
      patientId: widget.extra['patient_id'],
      appointmentId: widget.extra['appointment_id'],
      diagnosis: _diagnosisController.text.trim(),
      medicines: medicines,
      notes: _notesController.text.trim(),
      followUpDate: _followUpDate,
    );

    final success = await _prescriptionService.addPrescription(prescription);

    if (_selectedReport != null && _reportNameController.text.isNotEmpty) {
      await _prescriptionService.uploadReport(
        widget.extra['patient_id'],
        widget.extra['doctor_id'],
        _selectedReport!,
        _reportNameController.text.trim(),
      );
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prescription saved successfully')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save. Try again.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _notesController.dispose();
    _reportNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Prescription'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Allergy warning
            if (_patientAllergies != null && _patientAllergies!.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '⚠️ Patient Allergies: $_patientAllergies',
                        style: TextStyle(color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),

            // Diagnosis
            _buildLabel('Diagnosis *'),
            TextFormField(
              controller: _diagnosisController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Enter diagnosis...'),
            ),

            const SizedBox(height: 20),

            // Medicines
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLabel('Medicines'),
                TextButton.icon(
                  onPressed: _addMedicine,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),

            ..._medicines.asMap().entries.map((entry) {
              final index = entry.key;
              final med = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: med['nameController'],
                            decoration: const InputDecoration(
                              hintText: 'Medicine name',
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.remove_circle, color: AppColors.error),
                          onPressed: () => _removeMedicine(index),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: med['dosageController'],
                            decoration: const InputDecoration(
                              hintText: 'Dosage',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: med['durationController'],
                            decoration: const InputDecoration(
                              hintText: 'Duration',
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),

            // Notes
            _buildLabel('Notes (Optional)'),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Additional notes...'),
            ),

            const SizedBox(height: 20),

            // Follow up date
            // _buildLabel('Follow Up Date'),
            // InkWell(
            //   onTap: _pickFollowUpDate,
            //   child: Container(
            //     width: double.infinity,
            //     padding: const EdgeInsets.all(14),
            //     decoration: BoxDecoration(
            //       color: Colors.white,
            //       borderRadius: BorderRadius.circular(8),
            //       border: Border.all(color: AppColors.border),
            //     ),
            //     child: Row(
            //       children: [
            //         Icon(Icons.calendar_today,
            //             color: AppColors.textSecondary, size: 18),
            //         const SizedBox(width: 8),
            //         // Text(
            //         //   _followUpDate != null
            //         //       ? DateFormat('MMM d, yyyy').format(_followUpDate!)
            //         //       : 'Select follow up date',
            //         //   style: TextStyle(
            //         //     color: _followUpDate != null
            //         //         ? AppColors.textPrimary
            //         //         : AppColors.textSecondary,
            //         //   ),
            //         // ),
            //       ],
            //     ),
            //   ),
            // ),

            const SizedBox(height: 20),

            // Upload Report
            _buildLabel('Upload Report (Optional)'),
            TextFormField(
              controller: _reportNameController,
              decoration: const InputDecoration(hintText: 'Report name'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickReport,
              icon: const Icon(Icons.upload_file),
              label: Text(
                _selectedReport != null
                    ? 'File selected ✓'
                    : 'Choose File (PDF/Image)',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isLoading ? null : _savePrescription,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Save Prescription'),
            ),

            const SizedBox(height: 12),

            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),

            const SizedBox(height: 24),
          ],
        ),
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
