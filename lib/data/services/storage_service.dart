import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  // Supabase client instance
  final _supabase = Supabase.instance.client;

  // Upload doctor profile image
  Future<String?> uploadDoctorImage(File imageFile, String doctorEmail) async {
    try {
      // Create unique file name using email and timestamp
      final fileName =
          '${doctorEmail}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'doctors/$fileName';

      // Upload image to Supabase storage
      await _supabase.storage.from('doctor-images').upload(filePath, imageFile);

      // Get public URL of uploaded image
      final imageUrl = _supabase.storage
          .from('doctor-images')
          .getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      return null;
    }
  }

  // Upload admin profile image
  Future<String?> uploadAdminImage(File imageFile, String adminId) async {
    try {
      final fileName =
          '${adminId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'admins/$fileName';

      await _supabase.storage.from('admin-images').upload(filePath, imageFile);

      final imageUrl = _supabase.storage
          .from('admin-images')
          .getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      return null;
    }
  }

  // Delete old image from storage
  Future<void> deleteImage(String bucket, String imageUrl) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final filePath = pathSegments
          .sublist(pathSegments.indexOf(bucket) + 1)
          .join('/');

      await _supabase.storage.from(bucket).remove([filePath]);
    } catch (e) {
      // Delete error silently
    }
  }
}
