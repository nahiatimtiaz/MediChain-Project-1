// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class NotificationService {
//   final _supabase = Supabase.instance.client;
//   final _localNotifications = FlutterLocalNotificationsPlugin();

//   // Initialize local notifications
//   Future<void> initialize() async {
//     const androidSettings = AndroidInitializationSettings(
//       '@mipmap/ic_launcher',
//     );
//     const initSettings = InitializationSettings(android: androidSettings);
//     await _localNotifications.initialize(initSettings);
//   }

//   // Show local notification
//   Future<void> showNotification(String title, String message) async {
//     const androidDetails = AndroidNotificationDetails(
//       'medichain_channel',
//       'MediChain Notifications',
//       importance: Importance.high,
//       priority: Priority.high,
//     );
//     const details = NotificationDetails(android: androidDetails);
//     await _localNotifications.show(0, title, message, details);
//   }

//   // Get all notifications for current doctor
//   Future<List<Map<String, dynamic>>> getNotifications(String doctorId) async {
//     try {
//       final response = await _supabase
//           .from('notifications')
//           .select()
//           .eq('user_id', doctorId)
//           .eq('user_type', 'doctor')
//           .order('created_at', ascending: false)
//           .limit(20);

//       return List<Map<String, dynamic>>.from(response);
//     } catch (e) {
//       return [];
//     }
//   }

//   // Mark notification as read
//   Future<void> markAsRead(String notificationId) async {
//     try {
//       await _supabase
//           .from('notifications')
//           .update({'is_read': true})
//           .eq('id', notificationId);
//     } catch (e) {
//       return;
//     }
//   }

//   // Get unread notification count
//   Future<int> getUnreadCount(String doctorId) async {
//     try {
//       final response = await _supabase
//           .from('notifications')
//           .select()
//           .eq('user_id', doctorId)
//           .eq('user_type', 'doctor')
//           .eq('is_read', false);

//       return (response as List).length;
//     } catch (e) {
//       return 0;
//     }
//   }
// }
