import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

final supabase = Supabase.instance.client;

class NotificationService {
  static Stream<List<Map<String, dynamic>>> stream(String userId) {
    return supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  static Future<void> markAsRead(String id) async {
    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id);
  }

  static Future<List<Map<String, dynamic>>> fetchAll(String userId) async {
    final res = await supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }
}

class NotificationsPage extends StatelessWidget {
  final String userId;

  const NotificationsPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: NotificationService.stream(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];

              return ListTile(
                leading: Icon(
                  n['is_read']
                      ? Icons.notifications_none
                      : Icons.notifications_active,
                ),
                title: Text(n['title']),
                subtitle: Text(n['message']),
                onTap: () {
                  NotificationService.markAsRead(n['id']);
                },
              );
            },
          );
        },
      ),
    );
  }
}