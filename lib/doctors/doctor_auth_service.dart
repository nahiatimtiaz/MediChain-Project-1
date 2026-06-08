import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorAuthService {
  final _supabase = Supabase.instance.client;

  // Doctor login with email and password
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) return null;

      // Get doctor data from doctors table
      final doctorData = await _supabase
          .from('doctors')
          .select()
          .eq('email', email)
          .single();

      // Check if doctor account is active
      if (doctorData['account_status'] == false) {
        await _supabase.auth.signOut();
        return null;
      }

      return doctorData;
    } catch (e) {
      return null;
    }
  }

  // Get current logged in doctor
  Future<Map<String, dynamic>?> getCurrentDoctor() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final doctorData = await _supabase
          .from('doctors')
          .select()
          .eq('email', user.email!)
          .single();

      return doctorData;
    } catch (e) {
      return null;
    }
  }

  // Doctor logout
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // Check if doctor is logged in
  bool isLoggedIn() {
    return _supabase.auth.currentUser != null;
  }

  // Change password
  Future<bool> changePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      return true;
    } catch (e) {
      return false;
    }
  }
}
