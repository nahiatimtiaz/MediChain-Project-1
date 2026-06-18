import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
//import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_constants.dart';
import '../data/services/doctor_services/doctor_auth_service.dart';
import '../data/services/doctor_services/schedule_service.dart';
import '../data/models/doctor_models/appointment_model.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _authService = DoctorAuthService();
  final _scheduleService = ScheduleService();

  Map<String, dynamic>? _doctor;
  DateTime _selectedDay = DateTime.now();
  List<AppointmentModel> _appointments = [];
  List<DateTime> _appointmentDates = [];
  bool _isLoading = true;
  int _dailyCount = 0;

  // Mini calendar days strip
  late List<DateTime> _weekDays;

  @override
  void initState() {
    super.initState();
    _buildWeekDays();
    _loadData();
  }

  void _buildWeekDays() {
    final now = _selectedDay;
    final monday = now.subtract(Duration(days: now.weekday - 1));
    _weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  Future<void> _loadData() async {
    final doctor = await _authService.getCurrentDoctor();
    if (doctor == null) {
      if (mounted) context.go('/doctor-login');
      return;
    }

    final dates = await _scheduleService.getAppointmentDates(doctor['id']);
    final appointments = await _scheduleService.getAppointmentsByDate(
      doctor['id'],
      _selectedDay,
    );
    final count = await _scheduleService.getDailyPatientCount(
      doctor['id'],
      _selectedDay,
    );

    setState(() {
      _doctor = doctor;
      _appointmentDates = dates;
      _appointments = appointments;
      _dailyCount = count;
      _isLoading = false;
    });
  }

  Future<void> _loadAppointmentsForDate(DateTime date) async {
    if (_doctor == null) return;
    final appointments = await _scheduleService.getAppointmentsByDate(
      _doctor!['id'],
      date,
    );
    final count = await _scheduleService.getDailyPatientCount(
      _doctor!['id'],
      date,
    );
    setState(() {
      _appointments = appointments;
      _dailyCount = count;
    });
  }

  Future<void> _updateStatus(AppointmentModel apt, String status) async {
    await _scheduleService.updateAppointmentStatus(apt.id!, status);
    _loadAppointmentsForDate(_selectedDay);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.bluePrimary))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'APPOINTMENTS · ${DateFormat('MMM d').format(_selectedDay).toUpperCase()}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._appointments.map((apt) => _buildAppointmentCard(apt)),
                        if (_appointments.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.border, width: 1.5),
                            ),
                            child: const Center(
                              child: Text(
                                'No appointments for this date',
                                style: TextStyle(color: AppColors.textTertiary),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.bluePrimary, AppColors.blueDark],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Schedule',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      Text(
                        DateFormat('EEEE, MMM d').format(_selectedDay),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _weekDays.map((day) {
                  final isSelected = DateUtils.isSameDay(_selectedDay, day);
                  final hasAppt = _appointmentDates.any((d) => DateUtils.isSameDay(d, day));
                  final dayName = DateFormat('EEE').format(day).substring(0, 2).toUpperCase();
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedDay = day);
                        _loadAppointmentsForDate(day);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? Colors.white.withOpacity(0.4)
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              dayName,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              day.day.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: hasAppt
                                    ? const Color(0xFF4ADE80)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStatChip('$_dailyCount/50', 'Total', Colors.white.withOpacity(0.2)),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    _appointments.where((a) => a.status == 'Pending').length.toString(),
                    'Pending',
                    const Color(0x4DEAB308),
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    _appointments.where((a) => a.status == 'Completed').length.toString(),
                    'Done',
                    const Color(0x4022C55E),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String value, String label, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildAppointmentCard(AppointmentModel apt) {
    final isCompleted = apt.status == 'Completed';
    final isPending = apt.status == 'Pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.blueLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    '#${apt.serialNumber}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.blueText,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      apt.patientName ?? 'Unknown Patient',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${apt.patientUniqueId ?? '-'} · ${apt.timeSlot}${apt.patientPhone != null ? ' · ${apt.patientPhone}' : ''}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.primaryLight : AppColors.amberLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  apt.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isCompleted ? AppColors.primaryText : AppColors.amberText,
                  ),
                ),
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFF4F6FB)),
                ),
              ),
              child: Row(
                children: [
                  // 1. Complete Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _updateStatus(apt, 'Completed'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            '✓ Complete',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 2. Add Prescription Shortcut (Fixed Syntax, Colors & Model Mapping)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.push(
                        '/doctor-prescription',
                        extra: {
                          'doctor_id': _doctor?['id'],
                          'patient_id': apt.patientId,      // Modified from map syntax to model getters
                          'appointment_id': apt.id,         // Modified from map syntax to model getters
                        },
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: AppColors.bluePrimary,     // Switched text contrast base safely to dark blue primary
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: Color.fromARGB(255, 153, 32, 32), size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Prescribe',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 3. Cancel Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _updateStatus(apt, 'Cancelled'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: AppColors.redLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            '✕ Cancel',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.redText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}