import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/doctor_model.dart';

class DoctorService {
  final _supabase = Supabase.instance.client;

  // Get all doctors
  Future<List<DoctorModel>> getAllDoctors() async {
    try {
      final response = await _supabase
          .from('doctors')
          .select()
          .order('full_name', ascending: true);
      return (response as List)
          .map((json) => DoctorModel.fromJson(json))
          .toList();
    } catch (e) {
      print('GET ALL DOCTORS ERROR: $e');
      return [];
    }
  }

  // Add new doctor
  Future<bool> addDoctor(DoctorModel doctor, String password) async {
    try {
      print('Adding doctor: ${doctor.email}');

      final AuthResponse authResponse = await _supabase.auth.signUp(
        email: doctor.email,
        password: password,
      );

      final String? authUserId = authResponse.user?.id;

      if (authUserId != null) {
        await _supabase.from('doctors').insert({
          'id': authUserId,
          'doctor_id': doctor.doctorId,
          'full_name': doctor.fullName,
          'email': doctor.email,
          'department': doctor.department,
          'qualifications': doctor.qualifications,
          'phone': doctor.phone,
          'consultation_fee': doctor.consultationFee,
         // 'time_slots': doctor.timeSlots,
          'slot_duration': doctor.slotDuration,
          'available_days': doctor.availableDays,
          'start_time': doctor.startTime,
          'end_time': doctor.endTime,
          'max_patients_per_day': doctor.maxPatientsPerDay,
          'profile_image_url': doctor.profileImageUrl,
          'account_status': true,
        });

        await _logAction(
          'ADD_DOCTOR',
          doctor.email,
          'Added new doctor: ${doctor.fullName}',
        );

        print('Doctor added successfully');
        return true;
      }
      return false;
    } catch (e) {
      print('ADD DOCTOR ERROR: $e');
      return false;
    }
  }

  // Update existing doctor
  Future<bool> updateDoctor(String doctorId, DoctorModel doctor) async {
    try {
      await _supabase
          .from('doctors')
          .update({
            'full_name': doctor.fullName,
            'phone': doctor.phone,
            'qualifications': doctor.qualifications,
            'consultation_fee': doctor.consultationFee,
            'department': doctor.department,
            // 'time_slots': doctor.timeSlots,
            'slot_duration': doctor.slotDuration,
            'available_days': doctor.availableDays,
            'start_time': doctor.startTime,
            'end_time': doctor.endTime,
            'max_patients_per_day': doctor.maxPatientsPerDay,
            'profile_image_url': doctor.profileImageUrl,
          })
          .eq('id', doctorId);

      await _logAction(
        'UPDATE_DOCTOR',
        doctor.doctorId ?? '',
        'Updated doctor: ${doctor.fullName}',
      );

      return true;
    } catch (e) {
      print('UPDATE DOCTOR ERROR: $e');
      return false;
    }
  }

  // Delete doctor
  Future<bool> deleteDoctor(String doctorId, String doctorName) async {
    try {
      await _logAction(
        'DELETE_DOCTOR',
        doctorId,
        'Deleted doctor: $doctorName',
      );
      await _supabase.from('doctors').delete().eq('id', doctorId);
      return true;
    } catch (e) {
      print('DELETE DOCTOR ERROR: $e');
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
      print('TOGGLE STATUS ERROR: $e');
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
      await _logAction('RESET_PASSWORD', email, 'Password reset for: $email');
      return true;
    } catch (e) {
      print('RESET PASSWORD ERROR: $e');
      return false;
    }
  }

  // Search doctors
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
      print('SEARCH DOCTORS ERROR: $e');
      return [];
    }
  }

  // Filter by department
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
      print('FILTER BY DEPARTMENT ERROR: $e');
      return [];
    }
  }

  // Upload doctor profile image
  Future<String?> uploadDoctorProfileImage(
    File imageFile,
    String doctorId,
  ) async {
    try {
      final fileName = '$doctorId-${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _supabase.storage
          .from('doctor-images')
          .upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );
      final String imageUrl = _supabase.storage
          .from('doctor-images')
          .getPublicUrl(fileName);
      await _supabase
          .from('doctors')
          .update({'profile_image_url': imageUrl})
          .eq('id', doctorId);
      return imageUrl;
    } catch (e) {
      print('UPLOAD DOCTOR IMAGE ERROR: $e');
      return null;
    }
  }

  // Save action to audit_logs
  Future<void> _logAction(
    String actionType,
    String targetId,
    String description,
  ) async {
    try {
      final adminId = _supabase.auth.currentUser?.id;
      await _supabase.from('audit_logs').insert({
        'admin_id': adminId,
        'action_type': actionType,
        'target_doctor_id': targetId,
        'description': description,
      });
    } catch (e) {
      print('LOG ACTION ERROR: $e');
    }
  }
}
