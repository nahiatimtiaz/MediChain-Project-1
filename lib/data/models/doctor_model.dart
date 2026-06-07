// Doctor Data Model
class DoctorModel {
  final String? id;
  final String? doctorId;
  final String fullName;
  final String department;
  final String? qualifications;
  final double consultationFee;
  final List<String> availableDays;
  final List<Map<String, String>> timeSlots;
  final int slotDuration;
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
    required this.timeSlots,
    required this.slotDuration,
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
      fullName: json['full_name'],
      department: json['department'],
      qualifications: json['qualifications'],
      consultationFee: (json['consultation_fee'] as num).toDouble(),
      availableDays: List<String>.from(json['available_days'] ?? []),
      timeSlots:
          (json['time_slots'] as List<dynamic>?)
              ?.map((e) => Map<String, String>.from(e))
              .toList() ??
          [],
      slotDuration: json['slot_duration'] ?? 30,
      profileImageUrl: json['profile_image_url'],
      email: json['email'],
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
      'time_slots': timeSlots,
      'slot_duration': slotDuration,
      'profile_image_url': profileImageUrl,
      'email': email,
      'phone': phone,
      'account_status': accountStatus,
    };
  }
}
