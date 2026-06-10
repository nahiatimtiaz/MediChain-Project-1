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
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      chamberStartTime: json['chamber_start_time'],
      chamberEndTime: json['chamber_end_time'],
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
      'chamber_start_time': chamberStartTime,
      'chamber_end_time': chamberEndTime,
    };
  }

  // Generates real-time time slots based on slotDuration
  List<String> generateTimeSlots() {
    // Fallback to chamber timings if normal timings aren't set
    final startStr = chamberStartTime ?? startTime;
    final endStr = chamberEndTime ?? endTime;

    if (startStr == null || endStr == null) {
      return ["09:00 AM", "11:00 AM", "04:00 PM", "07:00 PM"]; // Safety Fallbacks
    }

    try {
      List<String> slots = [];
      
      // Pure Dart helper to convert "HH:mm" or "HH:mm PM" into total minutes from midnight
      int parseToTotalMinutes(String timeStr) {
        final normalized = timeStr.toLowerCase().trim();
        
        // Split hours and minutes
        final parts = normalized.split(':');
        int hour = int.parse(parts[0]);
        
        // Extract numeric minutes (ignoring trailing spaces, AM/PM, or seconds if present)
        final minutePart = parts[1].split(' ')[0].replaceAll(RegExp(r'[^0-9]'), '');
        int minute = int.parse(minutePart);
        
        // Handle 12-hour clock AM/PM modifiers safely
        if (normalized.contains('pm') && hour < 12) hour += 12;
        if (normalized.contains('am') && hour == 12) hour = 0;
        
        return (hour * 60) + minute;
      }

      int currentMinutes = parseToTotalMinutes(startStr);
      final int endMinutes = parseToTotalMinutes(endStr);

      // Dynamic split loop execution logic
      while (currentMinutes + slotDuration <= endMinutes) {
        final int hour = currentMinutes ~/ 60;
        final int minute = currentMinutes % 60;
        
        final String period = hour >= 12 ? "PM" : "AM";
        final int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        final String displayMinute = minute.toString().padLeft(2, '0');
        
        slots.add("$displayHour:$displayMinute $period");
        currentMinutes += slotDuration;
      }
      return slots;
    } catch (e) {
      print('SLOT GENERATION PARSING ERROR: $e');
      return ["09:00 AM", "10:00 AM", "11:00 AM"]; // Fallback if format parsing encounters anomalies
    }
  }
}