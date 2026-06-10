import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/doctor_services/doctor_auth_service.dart';
import '../../data/services/doctor_services/prescription_service.dart';
import '../../data/models/doctor_models/patient_model.dart';

class PatientSearchScreen extends StatefulWidget {
  const PatientSearchScreen({super.key});

  @override
  State<PatientSearchScreen> createState() => _PatientSearchScreenState();
}

class _PatientSearchScreenState extends State<PatientSearchScreen> {
  final _authService = DoctorAuthService();
  final _prescriptionService = PrescriptionService();
  final _searchController = TextEditingController();

  PatientModel? _foundPatient;
  bool _isSearching = false;
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final doctor = await _authService.getCurrentDoctor();
    if (doctor == null) {
      if (mounted) context.go('/doctor-login');
    }
  }

  Future<void> _searchPatient() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _foundPatient = null;
      _notFound = false;
    });

    final patient = await _prescriptionService.searchPatientById(
      _searchController.text.trim().toUpperCase(),
    );

    setState(() {
      _foundPatient = patient;
      _notFound = patient == null;
      _isSearching = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Patient History'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search by Patient ID',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),

            // Search box
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. PAT-0001',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onFieldSubmitted: (_) => _searchPatient(),
                    textInputAction: TextInputAction.search,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSearching ? null : _searchPatient,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(80, 52),
                  ),
                  child: _isSearching
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Search'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Not found
            if (_notFound)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No patient found with ID: ${_searchController.text}',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),

            // Patient card
            if (_foundPatient != null) _buildPatientCard(_foundPatient!),
          ],
        ),
      ),
      // bottomNavigationBar: BottomNavigationBar(
      //   currentIndex: 1,
      //   selectedItemColor: AppColors.primary,
      //   onTap: (index) {
      //     if (index == 0) context.go('/doctor-schedule');
      //     if (index == 2) context.go('/doctor-notifications');
      //     if (index == 3) context.go('/doctor-profile');
      //   },
      //   items: const [
      //     BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Schedule'),
      //     BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Patients'),
      //     BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
      //     BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      //   ],
      // ),
    );
  }

  Widget _buildPatientCard(PatientModel patient) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + basic info
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: patient.profileImageUrl != null
                    ? NetworkImage(patient.profileImageUrl!)
                    : null,
                child: patient.profileImageUrl == null
                    ? Text(
                        patient.fullName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 20),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'ID: ${patient.patientId}',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),

          // Details
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (patient.phone != null)
                _infoChip(Icons.phone, patient.phone!),
              if (patient.gender != null)
                _infoChip(Icons.person, patient.gender!),
              if (patient.bloodGroup != null)
                _infoChip(Icons.water_drop, patient.bloodGroup!),
            ],
          ),

          // Allergy warning
          if (patient.allergies != null && patient.allergies!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: AppColors.warning, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Allergies: ${patient.allergies}',
                      style: TextStyle(color: AppColors.warning, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: () =>
                context.go('/doctor-patient-detail', extra: patient.id),
            icon: const Icon(Icons.history),
            label: const Text('View History & Add Prescription'),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }
}