class MedicalReportModel {
  final String? id;
  final String patientId;
  final String? doctorId;
  final String reportName;
  final String reportUrl;
  final String? reportType;
  final DateTime? createdAt;

  MedicalReportModel({
    this.id,
    required this.patientId,
    this.doctorId,
    required this.reportName,
    required this.reportUrl,
    this.reportType,
    this.createdAt,
  });

  factory MedicalReportModel.fromJson(Map<String, dynamic> json) {
    return MedicalReportModel(
      id: json['id'],
      patientId: json['patient_id'],
      doctorId: json['doctor_id'],
      reportName: json['report_name'],
      reportUrl: json['report_url'],
      reportType: json['report_type'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'doctor_id': doctorId,
      'report_name': reportName,
      'report_url': reportUrl,
      'report_type': reportType,
    };
  }
}
