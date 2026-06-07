import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';

class AdminActivitiesScreen extends StatefulWidget {
  const AdminActivitiesScreen({super.key});

  @override
  State<AdminActivitiesScreen> createState() => _AdminActivitiesScreenState();
}

class _AdminActivitiesScreenState extends State<AdminActivitiesScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _allActivities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

  Future<void> _fetchActivities() async {
    try {
      final response = await _supabase
          .from('audit_logs')
          .select()
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _allActivities = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('FETCH ALL ACTIVITIES ERROR: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  IconData _getActivityIcon(String actionType) {
    switch (actionType) {
      case 'ADD_DOCTOR':
        return Icons.person_add_outlined;
      case 'UPDATE_DOCTOR':
        return Icons.edit_outlined;
      case 'DELETE_DOCTOR':
        return Icons.block_outlined;
      case 'RESET_PASSWORD':
        return Icons.key_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _getActivityBg(String actionType) {
    switch (actionType) {
      case 'ADD_DOCTOR':
        return AppColors.primaryLight;
      case 'UPDATE_DOCTOR':
        return AppColors.blueLight;
      case 'DELETE_DOCTOR':
        return AppColors.redLight;
      case 'RESET_PASSWORD':
        return AppColors.amberLight;
      default:
        return AppColors.grayLight;
    }
  }

  Color _getActivityColor(String actionType) {
    switch (actionType) {
      case 'ADD_DOCTOR':
        return AppColors.primaryText;
      case 'UPDATE_DOCTOR':
        return AppColors.blueText;
      case 'DELETE_DOCTOR':
        return AppColors.redText;
      case 'RESET_PASSWORD':
        return AppColors.amberText;
      default:
        return AppColors.grayText;
    }
  }

  String _formatDateTime(String createdAt) {
    if (createdAt.isEmpty) return '';
    try {
      final date = DateTime.parse(createdAt).toLocal();
      return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text(
          'Audit History Log',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _fetchActivities,
              color: AppColors.primary,
              child: _allActivities.isEmpty
                  ? const Center(
                      child: Text(
                        'No record history entries found',
                        style: TextStyle(color: AppColors.textTertiary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      itemCount: _allActivities.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final activity = _allActivities[index];
                        final actionType = activity['action_type'] ?? '';
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.border,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _getActivityBg(actionType),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getActivityIcon(actionType),
                                  color: _getActivityColor(actionType),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      activity['description'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Action Type: $actionType',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: _getActivityColor(actionType),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatDateTime(
                                        activity['created_at'] ?? '',
                                      ),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
