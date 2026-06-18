// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:intl/intl.dart';
// import '../../core/constants/app_constants.dart';
// import '../../data/services/doctor_services/doctor_auth_service.dart';
// import '../../data/services/doctor_services/notification_service.dart';

// class NotificationScreen extends StatefulWidget {
//   const NotificationScreen({super.key});

//   @override
//   State<NotificationScreen> createState() => _NotificationScreenState();
// }

// class _NotificationScreenState extends State<NotificationScreen> {
//   final _authService = DoctorAuthService();
//   final _notificationService = NotificationService();

//   List<Map<String, dynamic>> _notifications = [];
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//   }

//   Future<void> _loadData() async {
//     final doctor = await _authService.getCurrentDoctor();
//     if (doctor == null) {
//       if (mounted) context.go('/doctor-login');
//       return;
//     }

//     final notifications = await _notificationService.getNotifications(doctor['id']);

//     setState(() {
//       _notifications = notifications;
//       _isLoading = false;
//     });
//   }

//   Future<void> _markAsRead(String id) async {
//     await _notificationService.markAsRead(id);
//     _loadData();
//   }

//   Future<void> _markAllAsRead() async {
//     for (final n in _notifications) {
//       if (n['is_read'] == false) {
//         await _notificationService.markAsRead(n['id']);
//       }
//     }
//     _loadData();
//   }

//   String _timeAgo(String createdAt) {
//     final date = DateTime.parse(createdAt).toLocal();
//     final diff = DateTime.now().difference(date);
//     if (diff.inMinutes < 1) return 'Just now';
//     if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
//     if (diff.inHours < 24) return '${diff.inHours} hours ago';
//     return DateFormat('MMM d, yyyy').format(date);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final unreadCount = _notifications.where((n) => n['is_read'] == false).length;

//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         backgroundColor: AppColors.primary,
//         foregroundColor: Colors.white,
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text('Notifications'),
//             if (unreadCount > 0)
//               Text(
//                 '$unreadCount unread',
//                 style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
//               ),
//           ],
//         ),
//         actions: [
//           if (unreadCount > 0)
//             TextButton(
//               onPressed: _markAllAsRead,
//               child: const Text(
//                 'Mark all read',
//                 style: TextStyle(color: Colors.white, fontSize: 13),
//               ),
//             ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _notifications.isEmpty
//               ? Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(Icons.notifications_none,
//                           size: 64, color: AppColors.textSecondary),
//                       const SizedBox(height: 16),
//                       Text(
//                         'No notifications',
//                         style: TextStyle(
//                           color: AppColors.textSecondary,
//                           fontSize: 16,
//                         ),
//                       ),
//                     ],
//                   ),
//                 )
//               : RefreshIndicator(
//                   onRefresh: _loadData,
//                   child: ListView.separated(
//                     padding: const EdgeInsets.all(16),
//                     itemCount: _notifications.length,
//                     separatorBuilder: (_, __) => const SizedBox(height: 8),
//                     itemBuilder: (context, index) {
//                       final notification = _notifications[index];
//                       final isUnread = notification['is_read'] == false;

//                       return Container(
//                         decoration: BoxDecoration(
//                           color: isUnread
//                               ? AppColors.primary.withValues(alpha: 0.05)
//                               : Colors.white,
//                           borderRadius: BorderRadius.circular(12),
//                           border: isUnread
//                               ? Border.all(
//                                   color: AppColors.primary.withValues(alpha: 0.2))
//                               : null,
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withValues(alpha: 0.04),
//                               blurRadius: 6,
//                             ),
//                           ],
//                         ),
//                         child: ListTile(
//                           contentPadding: const EdgeInsets.all(12),
//                           leading: Container(
//                             padding: const EdgeInsets.all(8),
//                             decoration: BoxDecoration(
//                               color: AppColors.primary.withValues(alpha: 0.1),
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: Icon(Icons.notifications,
//                                 color: AppColors.primary, size: 20),
//                           ),
//                           title: Text(
//                             notification['title'] ?? '',
//                             style: TextStyle(
//                               fontWeight: isUnread
//                                   ? FontWeight.bold
//                                   : FontWeight.normal,
//                               fontSize: 14,
//                             ),
//                           ),
//                           subtitle: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const SizedBox(height: 4),
//                               Text(
//                                 notification['message'] ?? '',
//                                 style: const TextStyle(fontSize: 13),
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 _timeAgo(notification['created_at']),
//                                 style: TextStyle(
//                                   color: AppColors.textSecondary,
//                                   fontSize: 12,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           trailing: isUnread
//                               ? IconButton(
//                                   icon: Icon(Icons.check_circle_outline,
//                                       color: AppColors.success),
//                                   onPressed: () =>
//                                       _markAsRead(notification['id']),
//                                 )
//                               : null,
//                           isThreeLine: true,
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: 2,
//         selectedItemColor: AppColors.primary,
//         onTap: (index) {
//           if (index == 0) context.go('/doctor-schedule');
//           if (index == 1) context.go('/doctor-patients');
//           if (index == 3) context.go('/doctor-profile');
//         },
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Schedule'),
//           BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Patients'),
//           BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
//           BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
//         ],
//       ),
//     );
//   }
// }