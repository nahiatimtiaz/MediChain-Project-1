import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_model.dart';

class AuthService {
 
  final _supabase = Supabase.instance.client;

  Future<AdminModel?> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) return null;

      final adminData = await _supabase
          .from('admins')
          .select()
          .eq('id', response.user!.id)
          .single();

      
      await _supabase
          .from('admins')
          .update({'last_login': DateTime.now().toIso8601String()})
          .eq('id', response.user!.id);

      return AdminModel.fromJson(adminData);
    } catch (e) {
      return null;
    }
  }

 
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }


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

  bool isLoggedIn() {
    return _supabase.auth.currentUser != null;
  }
}
