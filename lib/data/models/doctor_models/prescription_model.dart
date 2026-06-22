class PrescriptionModel {
  final String? id;
  final String doctorId;
  final String patientId;
  final String? appointmentId;
  final String? diagnosis;
  final List<Map<String, dynamic>> medicines;
  final String? notes;
  final DateTime? followUpDate;
  final DateTime? createdAt;


  final String? doctorName;

  PrescriptionModel({
    this.id,
    required this.doctorId,
    required this.patientId,
    this.appointmentId,
    this.diagnosis,
    required this.medicines,
    this.notes,
    this.followUpDate,
    this.createdAt,
    this.doctorName,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      id: json['id'],
      doctorId: json['doctor_id'],
      patientId: json['patient_id'],
      appointmentId: json['appointment_id'],
      diagnosis: json['diagnosis'],
      medicines: List<Map<String, dynamic>>.from(json['medicines'] ?? []),
      notes: json['notes'],
      followUpDate: json['follow_up_date'] != null
          ? DateTime.parse(json['follow_up_date'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      doctorName: json['doctors']?['full_name'],
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'doctor_id': doctorId,
      'patient_id': patientId,
      'appointment_id': appointmentId,
      'diagnosis': diagnosis,
      'medicines': medicines,
      'notes': notes,
      'follow_up_date': followUpDate?.toIso8601String().split('T')[0],
    };
  }
}
