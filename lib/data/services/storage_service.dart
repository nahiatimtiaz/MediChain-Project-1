import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final _supabase = Supabase.instance.client;

  Future<String?> uploadDoctorImage(File imageFile, String doctorEmail) async {
    try {
      final fileName =
          '${doctorEmail}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'doctors/$fileName';

      await _supabase.storage.from('doctor-images').upload(filePath, imageFile);

      final imageUrl = _supabase.storage
          .from('doctor-images')
          .getPublicUrl(filePath);
      return imageUrl;
    } catch (e) {
      return null;
    }
  }

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

  Future<String?> uploadPatientImage(File imageFile, String userId) async {
    try {

      final fileName =
          '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'patients/$fileName';

      await _supabase.storage.from('patient-images').upload(filePath, imageFile);

      final imageUrl = _supabase.storage
          .from('patient-images')
          .getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteImage(String bucket, String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final filePath = pathSegments
          .sublist(pathSegments.indexOf(bucket) + 1)
          .join('/');

      await _supabase.storage.from(bucket).remove([filePath]);
    } catch (e) {
    
    }
  }
}