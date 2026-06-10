import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/services/doctor_services/doctor_auth_service.dart';
import '../../../../data/services/doctor_services/prescription_service.dart';
import '../../../../data/models/doctor_models/prescription_model.dart';
import '../../../../data/models/doctor_models/medical_report_model.dart';
import '../../../../data/models/doctor_models/patient_model.dart';

class PatientDetailScreen extends StatefulWidget {
  final String patientId;

  const PatientDetailScreen({super.key, required this.patientId});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  final _authService = DoctorAuthService();
  final _prescriptionService = PrescriptionService();

  Map<String, dynamic>? _doctor;
  PatientModel? _patient;
  List<PrescriptionModel> _prescriptions = [];
  List<MedicalReportModel> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final doctor = await _authService.getCurrentDoctor();
    if (doctor == null) {
      if (mounted) context.go('/doctor-login');
      return;
    }

    // Load patient, prescriptions and reports
    final prescriptions = await _prescriptionService.getPatientPrescriptions(
      widget.patientId,
    );
    final reports = await _prescriptionService.getPatientReports(
      widget.patientId,
    );

    setState(() {
      _doctor = doctor;
      _prescriptions = prescriptions;
      _reports = reports;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Patient History'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // Add prescription button
          TextButton.icon(
            onPressed: () => context.go(
              '/doctor-prescription',
              extra: {
                'doctor_id': _doctor?['id'],
                'patient_id': widget.patientId,
              },
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Add Prescription',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prescriptions Section
                  _buildSectionTitle('Prescriptions', _prescriptions.length),
                  const SizedBox(height: 16),

                  _prescriptions.isEmpty
                      ? _buildEmptyCard('No prescriptions found')
                      : Column(
                          children: _prescriptions
                              .map((p) => _buildPrescriptionCard(p))
                              .toList(),
                        ),

                  const SizedBox(height: 24),

                  // Reports Section
                  _buildSectionTitle('Medical Reports', _reports.length),
                  const SizedBox(height: 16),

                  _reports.isEmpty
                      ? _buildEmptyCard('No reports found')
                      : Column(
                          children: _reports
                              .map((r) => _buildReportCard(r))
                              .toList(),
                        ),
                ],
              ),
            ),
    );
  }

  // Section title with count badge
  Widget _buildSectionTitle(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ],
    );
  }

  // Prescription card
  Widget _buildPrescriptionCard(PrescriptionModel prescription) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                prescription.diagnosis ?? 'No diagnosis',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                prescription.createdAt != null
                    ? DateFormat('MMM d, yyyy').format(prescription.createdAt!)
                    : '',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Doctor name
          Text(
            'Dr. ${prescription.doctorName ?? 'Unknown'}',
            style: TextStyle(color: AppColors.primary, fontSize: 13),
          ),

          const SizedBox(height: 12),

          // Medicines
          if (prescription.medicines.isNotEmpty) ...[
            const Text(
              'Medicines:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            ...prescription.medicines.map(
              (med) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.medication, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(med['name'] ?? ''),
                    const SizedBox(width: 8),
                    Text(
                      med['dosage'] ?? '',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Notes
          if (prescription.notes != null) ...[
            const SizedBox(height: 8),
            Text(
              'Notes: ${prescription.notes}',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],

          // Follow up date
          if (prescription.followUpDate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.event, size: 16, color: AppColors.warning),
                const SizedBox(width: 6),
                Text(
                  'Follow up: ${DateFormat('MMM d, yyyy').format(prescription.followUpDate!)}',
                  style: TextStyle(color: AppColors.warning),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Report card
  Widget _buildReportCard(MedicalReportModel report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.description, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.reportName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  report.createdAt != null
                      ? DateFormat('MMM d, yyyy').format(report.createdAt!)
                      : '',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // View report button
          IconButton(
            icon: Icon(Icons.open_in_new, color: AppColors.primary),
            onPressed: () {
              // Open report URL
            },
          ),
        ],
      ),
    );
  }

  // Empty state card
  Widget _buildEmptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(message, style: TextStyle(color: AppColors.textSecondary)),
      ),
    );
  }
}
