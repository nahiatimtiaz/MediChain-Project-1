import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_model.dart';

class AuthService {
  // Supabase client instance
  final _supabase = Supabase.instance.client;

  // Login with email and password
  Future<AdminModel?> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) return null;

      // Get admin data from admins table
      final adminData = await _supabase
          .from('admins')
          .select()
          .eq('id', response.user!.id)
          .single();

      // Update last login time
      await _supabase
          .from('admins')
          .update({'last_login': DateTime.now().toIso8601String()})
          .eq('id', response.user!.id);

      return AdminModel.fromJson(adminData);
    } catch (e) {
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // Get current logged in admin
  Future<AdminModel?> getCurrentAdmin() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final adminData = await _supabase
          .from('admins')
          .select()
          .eq('id', user.id)
          .single();

      return AdminModel.fromJson(adminData);
    } catch (e) {
      return null;
    }
  }

  // Check if admin is logged in
  bool isLoggedIn() {
    return _supabase.auth.currentUser != null;
  }
}
