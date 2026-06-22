import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/doctor_models/appointment_model.dart';

class ScheduleService {
  final _supabase = Supabase.instance.client;

  Future<List<AppointmentModel>> getAppointmentsByDate(
    String doctorId,
    DateTime date,
  ) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await _supabase
          .from('appointments')
          .select('*, patients(full_name, phone, patient_id)')
          .eq('doctor_id', doctorId)
          .eq('appointment_date', dateStr)
          .order('serial_number');

      return (response as List)
          .map((json) => AppointmentModel.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<DateTime>> getAppointmentDates(String doctorId) async {
    try {
      final response = await _supabase
          .from('appointments')
          .select('appointment_date')
          .eq('doctor_id', doctorId)
          .neq('status', 'Cancelled');

      return (response as List)
          .map((json) => DateTime.parse(json['appointment_date']))
          .toSet()
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> updateAppointmentStatus(
    String appointmentId,
    String status,
  ) async {
    try {
      await _supabase
          .from('appointments')
          .update({'status': status})
          .eq('id', appointmentId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<int> getDailyPatientCount(String doctorId, DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await _supabase
          .from('appointments')
          .select()
          .eq('doctor_id', doctorId)
          .eq('appointment_date', dateStr)
          .neq('status', 'Cancelled');

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  Future<bool> blockDate(String doctorId, DateTime date, String reason) async {
    try {
      await _supabase.from('doctor_blocked_dates').insert({
        'doctor_id': doctorId,
        'blocked_date': date.toIso8601String().split('T')[0],
        'reason': reason,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<DateTime>> getBlockedDates(String doctorId) async {
    try {
      final response = await _supabase
          .from('doctor_blocked_dates')
          .select('blocked_date')
          .eq('doctor_id', doctorId);

      return (response as List)
          .map((json) => DateTime.parse(json['blocked_date']))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> unblockDate(String doctorId, DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      await _supabase
          .from('doctor_blocked_dates')
          .delete()
          .eq('doctor_id', doctorId)
          .eq('blocked_date', dateStr);
      return true;
    } catch (e) {
      return false;
    }
  }
}
