import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/doctor_models/prescription_model.dart';
import '../../models/doctor_models/patient_model.dart';
import '../../models/doctor_models/medical_report_model.dart';

class PrescriptionService {
  final _supabase = Supabase.instance.client;

  // Search patient by patient ID
  Future<PatientModel?> searchPatientById(String patientId) async {
    try {
      final response = await _supabase
          .from('patients')
          .select()
          .eq('patient_id', patientId)
          .single();

      return PatientModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Get all prescriptions for a patient
  Future<List<PrescriptionModel>> getPatientPrescriptions(
    String patientId,
  ) async {
    try {
      final response = await _supabase
          .from('prescriptions')
          .select('*, doctors(full_name)')
          .eq('patient_id', patientId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PrescriptionModel.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Add new prescription
  Future<bool> addPrescription(PrescriptionModel prescription) async {
    try {
      await _supabase.from('prescriptions').insert(prescription.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get all medical reports for a patient
  Future<List<MedicalReportModel>> getPatientReports(String patientId) async {
    try {
      final response = await _supabase
          .from('medical_reports')
          .select()
          .eq('patient_id', patientId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => MedicalReportModel.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Upload medical report file
  Future<bool> uploadReport(
    String patientId,
    String doctorId,
    File file,
    String reportName,
  ) async {
    try {
      final fileName =
          '${patientId}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // Upload file to Supabase storage
      await _supabase.storage
          .from('medical-reports')
          .upload('reports/$fileName', file);

      // Get file URL
      final fileUrl = _supabase.storage
          .from('medical-reports')
          .getPublicUrl('reports/$fileName');

      // Save report info in database
      await _supabase.from('medical_reports').insert({
        'patient_id': patientId,
        'doctor_id': doctorId,
        'report_name': reportName,
        'report_url': fileUrl,
        'report_type': 'PDF',
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // Get patient allergy info
  Future<String?> getPatientAllergies(String patientId) async {
    try {
      final response = await _supabase
          .from('patients')
          .select('allergies')
          .eq('id', patientId)
          .single();

      return response['allergies'];
    } catch (e) {
      return null;
    }
  }
}
