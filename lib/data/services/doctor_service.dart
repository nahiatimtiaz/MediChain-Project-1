import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/doctor_model.dart';

class DoctorService {
  // Supabase client instance
  final _supabase = Supabase.instance.client;

  // Get all doctors from database
  Future<List<DoctorModel>> getAllDoctors() async {
    try {
      final response = await _supabase
          .from('doctors')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => DoctorModel.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Add new doctor
  Future<bool> addDoctor(DoctorModel doctor, String password) async {
    try {
      // Create doctor auth account in Supabase
      final authResponse = await _supabase.auth.admin.createUser(
        AdminUserAttributes(
          email: doctor.email,
          password: password,
          emailConfirm: true,
        ),
      );

      if (authResponse.user == null) return false;

      // Save doctor data in doctors table
      await _supabase.from('doctors').insert(doctor.toJson());

      // Log this action in audit_logs
      await _logAction(
        'ADD_DOCTOR',
        doctor.email,
        'Added new doctor: ${doctor.fullName}',
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  // Update existing doctor info
  Future<bool> updateDoctor(String doctorId, DoctorModel doctor) async {
    try {
      await _supabase
          .from('doctors')
          .update(doctor.toJson())
          .eq('id', doctorId);

      // Log this action
      await _logAction(
        'UPDATE_DOCTOR',
        doctor.doctorId ?? '',
        'Updated doctor: ${doctor.fullName}',
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  // Delete doctor
  Future<bool> deleteDoctor(String doctorId, String doctorName) async {
    try {
      await _supabase.from('doctors').delete().eq('id', doctorId);

      // Log this action
      await _logAction(
        'DELETE_DOCTOR',
        doctorId,
        'Deleted doctor: $doctorName',
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  // Toggle doctor active/inactive status
  Future<bool> toggleDoctorStatus(String doctorId, bool newStatus) async {
    try {
      await _supabase
          .from('doctors')
          .update({'account_status': newStatus})
          .eq('id', doctorId);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Reset doctor password
  Future<bool> resetDoctorPassword(String email, String newPassword) async {
    try {
      await _supabase.rpc(
        'admin_set_doctor_password',
        params: {'doctor_email': email, 'new_password': newPassword},
      );

      // Log this action
      await _logAction('RESET_PASSWORD', email, 'Password reset for: $email');

      return true;
    } catch (e) {
      return false;
    }
  }

  // Search doctors by name, department or doctor ID
  Future<List<DoctorModel>> searchDoctors(String query) async {
    try {
      final response = await _supabase
          .from('doctors')
          .select()
          .or(
            'full_name.ilike.%$query%,department.ilike.%$query%,doctor_id.ilike.%$query%',
          );

      return (response as List)
          .map((json) => DoctorModel.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Filter doctors by department
  Future<List<DoctorModel>> filterByDepartment(String department) async {
    try {
      final response = await _supabase
          .from('doctors')
          .select()
          .eq('department', department);

      return (response as List)
          .map((json) => DoctorModel.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Save action to audit_logs table
  Future<void> _logAction(
    String actionType,
    String targetId,
    String description,
  ) async {
    try {
      final adminId = Supabase.instance.client.auth.currentUser?.id;
      await _supabase.from('audit_logs').insert({
        'admin_id': adminId,
        'action_type': actionType,
        'target_doctor_id': targetId,
        'description': description,
      });
    } catch (e) {
      // Log error silently
    }
  }
}
