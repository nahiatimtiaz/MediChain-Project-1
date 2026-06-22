
class AdminModel {
  final String id;
  final String fullName;
  final String username;
  final String email;
  final String? profileImageUrl;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  AdminModel({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    this.profileImageUrl,
    this.createdAt,
    this.lastLogin,
  });


  factory AdminModel.fromJson(Map<String, dynamic> json) {
    return AdminModel(
      id: json['id'],
      fullName: json['full_name'],
      username: json['username'],
      email: json['email'],
      profileImageUrl: json['profile_image_url'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'username': username,
      'email': email,
      'profile_image_url': profileImageUrl,
    };
  }
}
