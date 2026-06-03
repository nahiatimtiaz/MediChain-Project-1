class AppointmentModel {
  final String? id;
  final String? appointmentId;
  final String doctorId;
  final String patientId;
  final DateTime appointmentDate;
  final String timeSlot;
  final int serialNumber;
  final String status;
  final DateTime? createdAt;

  // Patient info joined from patients table
  final String? patientName;
  final String? patientPhone;
  final String? patientUniqueId;

  AppointmentModel({
    this.id,
    this.appointmentId,
    required this.doctorId,
    required this.patientId,
    required this.appointmentDate,
    required this.timeSlot,
    required this.serialNumber,
    this.status = 'Pending',
    this.createdAt,
    this.patientName,
    this.patientPhone,
    this.patientUniqueId,
  });

  // Convert Supabase JSON to AppointmentModel
  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'],
      appointmentId: json['appointment_id'],
      doctorId: json['doctor_id'],
      patientId: json['patient_id'],
      appointmentDate: DateTime.parse(json['appointment_date']),
      timeSlot: json['time_slot'],
      serialNumber: json['serial_number'],
      status: json['status'] ?? 'Pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      patientName: json['patients']?['full_name'],
      patientPhone: json['patients']?['phone'],
      patientUniqueId: json['patients']?['patient_id'],
    );
  }

  // Convert AppointmentModel to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'doctor_id': doctorId,
      'patient_id': patientId,
      'appointment_date': appointmentDate.toIso8601String().split('T')[0],
      'time_slot': timeSlot,
      'serial_number': serialNumber,
      'status': status,
    };
  }
}
