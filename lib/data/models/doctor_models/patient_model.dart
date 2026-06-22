class PatientModel {
  final String? id;
  final String? patientId;
  final String fullName;
  final String email;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? bloodGroup;
  final String? address;
  final String? allergies;
  final String? profileImageUrl;
  final DateTime? createdAt;

  PatientModel({
    this.id,
    this.patientId,
    required this.fullName,
    required this.email,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.bloodGroup,
    this.address,
    this.allergies,
    this.profileImageUrl,
    this.createdAt,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'],
      patientId: json['patient_id'],
      fullName: json['full_name'],
      email: json['email'],
      phone: json['phone'],
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'])
          : null,
      gender: json['gender'],
      bloodGroup: json['blood_group'],
      address: json['address'],
      allergies: json['allergies'],
      profileImageUrl: json['profile_image_url'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'blood_group': bloodGroup,
      'address': address,
      'allergies': allergies,
      'profile_image_url': profileImageUrl,
    };
  }
}
