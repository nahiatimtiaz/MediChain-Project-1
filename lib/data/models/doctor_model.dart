class DoctorModel {
  final String? id;
  final String? doctorId;
  final String fullName;
  final String department;
  final String? qualifications;
  final double consultationFee;
  final List<String> availableDays;
  final String? startTime;
  final String? endTime;
  final int slotDuration;
  final int maxPatientsPerDay;
  final String? profileImageUrl;
  final String email;
  final String? phone;
  final bool accountStatus;
  final DateTime? createdAt;
  final String? chamberStartTime;
 final String? chamberEndTime;

  DoctorModel({
    this.id,
    this.doctorId,
    required this.fullName,
    required this.department,
    this.qualifications,
    required this.consultationFee,
    required this.availableDays,
    this.startTime,
    this.endTime,
    required this.slotDuration,
    this.maxPatientsPerDay = 50,
    this.profileImageUrl,
    required this.email,
    this.phone,
    this.accountStatus = true,
    this.createdAt,
    this.chamberStartTime,
    this.chamberEndTime,
  });

  // Convert Supabase JSON to DoctorModel
  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['id'],
      doctorId: json['doctor_id'],
      fullName: json['full_name'] ?? '',
      department: json['department'] ?? '',
      qualifications: json['qualifications'],
      consultationFee: (json['consultation_fee'] as num?)?.toDouble() ?? 0.0,
      availableDays: List<String>.from(json['available_days'] ?? []),
      startTime: json['start_time'],
      endTime: json['end_time'],
      slotDuration: json['slot_duration'] ?? 15,
      maxPatientsPerDay: json['max_patients_per_day'] ?? 50,
      profileImageUrl: json['profile_image_url'],
      email: json['email'] ?? '',
      phone: json['phone'],
      accountStatus: json['account_status'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  // Convert DoctorModel to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'department': department,
      'qualifications': qualifications,
      'consultation_fee': consultationFee,
      'available_days': availableDays,
      'start_time': startTime,
      'end_time': endTime,
      'slot_duration': slotDuration,
      'max_patients_per_day': maxPatientsPerDay,
      'profile_image_url': profileImageUrl,
      'email': email,
      'phone': phone,
      'account_status': accountStatus,
    };
  }
}
