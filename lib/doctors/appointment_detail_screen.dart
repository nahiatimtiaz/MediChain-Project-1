import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../admin/app_constants.dart';
import 'appointment_model.dart';
import 'schedule_service.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final AppointmentModel appointment;

  const AppointmentDetailScreen({super.key, required this.appointment});

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  final _scheduleService = ScheduleService();
  bool _isUpdating = false;

  Future<void> _updateStatus(String status) async {
    setState(() => _isUpdating = true);
    await _scheduleService.updateAppointmentStatus(
      widget.appointment.id!,
      status,
    );
    setState(() => _isUpdating = false);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Status updated to $status')));
      Navigator.pop(context, true);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return AppColors.success;
      case 'Cancelled':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final apt = widget.appointment;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Appointment Detail'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appointment Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Appointment #${apt.appointmentId}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(apt.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(apt.status).withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          apt.status,
                          style: TextStyle(
                            color: _getStatusColor(apt.status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 24),

                  _buildInfoRow(
                    Icons.format_list_numbered,
                    'Serial Number',
                    '#${apt.serialNumber}',
                  ),
                  _buildInfoRow(
                    Icons.person,
                    'Patient Name',
                    apt.patientName ?? 'Unknown',
                  ),
                  _buildInfoRow(
                    Icons.badge,
                    'Patient ID',
                    apt.patientUniqueId ?? '-',
                  ),
                  if (apt.patientPhone != null)
                    _buildInfoRow(Icons.phone, 'Phone', apt.patientPhone!),
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Date',
                    DateFormat(
                      'EEEE, MMMM d, yyyy',
                    ).format(apt.appointmentDate),
                  ),
                  _buildInfoRow(Icons.access_time, 'Time Slot', apt.timeSlot),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Status Update Buttons
            if (apt.status == 'Pending') ...[
              Text(
                'Update Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isUpdating
                          ? null
                          : () => _updateStatus('Completed'),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Mark Completed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isUpdating
                          ? null
                          : () => _updateStatus('Cancelled'),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // View Patient History
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    context.go('/doctor-patient-detail', extra: apt.patientId),
                icon: const Icon(Icons.history),
                label: const Text('View Patient History'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
              ),
            ),

            const SizedBox(height: 12),

            // Add Prescription
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go(
                  '/doctor-prescription',
                  extra: {
                    'doctor_id': apt.doctorId,
                    'patient_id': apt.patientId,
                    'appointment_id': apt.id,
                  },
                ),
                icon: const Icon(Icons.note_add),
                label: const Text('Add Prescription'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 48)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
