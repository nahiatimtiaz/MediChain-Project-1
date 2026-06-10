import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medichain/patient/patient_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medichain/blog/blog.dart';
import 'package:medichain/patient/patient_history.dart';
import 'doctor_search_page.dart';
import 'package:medichain/services/notification.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;

  int _selectedIndex = 0;
  bool isLoading = true;

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController bloodGroupController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController allergiesController = TextEditingController();
  final TextEditingController patientIdController = TextEditingController();

  String patientId = '';
  String welcomeName = '';

  final String userId = Supabase.instance.client.auth.currentUser?.id ?? '';
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    fetchPatientData();
  }

  @override
  void dispose() {
    // FIX: Safely remove active overlay dropdown elements to prevent screen ghosting
    _closeNotificationOverlay();
    
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    dobController.dispose();
    genderController.dispose();
    bloodGroupController.dispose();
    addressController.dispose();
    allergiesController.dispose();
    patientIdController.dispose();
    super.dispose();
  }

  void _closeNotificationOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  Future<void> fetchPatientData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('patients')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      // FIX: Guard against async unmounting drops
      if (!mounted) return;

      if (response != null) {
        setState(() {
          patientId = response['patient_id'] ?? '';
          welcomeName = response['full_name'] ?? '';

          patientIdController.text = patientId;
          fullNameController.text = response['full_name'] ?? '';
          emailController.text = response['email'] ?? '';
          phoneController.text = response['phone'] ?? '';
          dobController.text = response['date_of_birth'] ?? '';
          genderController.text = response['gender'] ?? '';
          bloodGroupController.text = response['blood_group'] ?? '';
          addressController.text = response['address'] ?? '';
          allergiesController.text = response['allergies'] ?? '';

          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> savePatientData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase.from('patients').upsert({
        'id': user.id,
        'patient_id': patientId,
        'full_name': fullNameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'date_of_birth': dobController.text.trim(),
        'gender': genderController.text.trim(),
        'blood_group': bloodGroupController.text.trim(),
        'address': addressController.text.trim(),
        'allergies': allergiesController.text.trim(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient information saved successfully'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        style: TextStyle(color: enabled ? Colors.black87 : Colors.black54),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blueAccent.shade100, size: 22),
          labelStyle: const TextStyle(color: Colors.black54, fontSize: 14),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.blue, width: 1.5),
          ),
        ),
      ),
    );
  }

  Future<void> cancelAppointment(String appointmentDbId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Cancel Appointment"),
          content: const Text("Are you sure you want to cancel this appointment?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("No"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Yes, Cancel", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await supabase.from('appointments').delete().eq('id', appointmentDbId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Appointment cancelled successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to cancel appointment: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget buildAppointmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Appointments',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey.shade900,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 230,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: supabase
                .from('appointments')
                .stream(primaryKey: ['id'])
                .eq('patient_id', userId)
                .order('appointment_date', ascending: true),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF03489D)),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading appointments: ${snapshot.error}',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                );
              }

              final appointments = snapshot.data ?? [];

              if (appointments.isEmpty) {
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    color: Colors.white,
                  ),
                  child: const Center(
                    child: Text(
                      'No upcoming appointments found.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  final appt = appointments[index];
                  return AppointmentCard(
                    appt: appt,
                    supabase: supabase,
                    onCancel: (id) => cancelAppointment(id),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildHomePage() {
    final currentDate = DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back,', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                const SizedBox(height: 2),
                Text(
                  welcomeName.isNotEmpty ? welcomeName : 'Patient',
                  style: const TextStyle(fontSize: 24, color: Color(0xFF03489D), fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ID: $patientId',
                        style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.calendar_month, size: 16, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(currentDate, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          buildAppointmentsSection(),
          const SizedBox(height: 20),
          Text(
            'Your Demographics & Medical Records',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade900),
          ),
          const SizedBox(height: 12),
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Colors.grey.shade100),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  buildTextField(label: 'Patient Identification Number', controller: patientIdController, icon: Icons.fingerprint, enabled: false),
                  buildTextField(label: 'Full Name', controller: fullNameController, icon: Icons.person_outline),
                  buildTextField(label: 'Email Address', controller: emailController, icon: Icons.mail_outline),
                  buildTextField(label: 'Phone Contact', controller: phoneController, icon: Icons.phone_android),
                  buildTextField(label: 'Date of Birth', controller: dobController, icon: Icons.cake_outlined),
                  buildTextField(label: 'Gender Identity', controller: genderController, icon: Icons.wc_outlined),
                  buildTextField(label: 'Blood Profile', controller: bloodGroupController, icon: Icons.bloodtype_outlined),
                  buildTextField(label: 'Residential Address', controller: addressController, icon: Icons.home_outlined, maxLines: 2),
                  buildTextField(label: 'Known Pathological Allergies', controller: allergiesController, icon: Icons.warning_amber_rounded, maxLines: 2),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: savePatientData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF03489D),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Save Profiles Changes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
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

  void showNotificationsDropdown(BuildContext context) {
    _closeNotificationOverlay(); // Guard against doubling elements

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: kToolbarHeight + MediaQuery.of(context).padding.top - 10,
        right: 16,
        child: Material(
          elevation: 12,
          shadowColor: Colors.black12,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 330,
            height: 400,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: NotificationService.stream(userId),
              builder: (context, snapshot) {
                final notifications = snapshot.data ?? [];
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                          onPressed: _closeNotificationOverlay,
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: notifications.isEmpty
                          ? const Center(child: Text("No notifications yet", style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                              itemCount: notifications.length,
                              itemBuilder: (context, index) {
                                final n = notifications[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(n['title'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                  subtitle: Text(n['message'] ?? '', style: const TextStyle(fontSize: 12)),
                                  leading: CircleAvatar(
                                    backgroundColor: n['is_read'] ? Colors.grey.shade100 : Colors.blue.shade50,
                                    child: Icon(
                                      n['is_read'] ? Icons.notifications_none : Icons.notifications_active,
                                      color: n['is_read'] ? Colors.grey : Colors.blue,
                                      size: 20,
                                    ),
                                  ),
                                  onTap: () async {
                                    await NotificationService.markAsRead(n['id']);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      buildHomePage(),
      const DoctorSearchPage(),
      const PatientHistoryPage(),
      const CommunityPage(),
      const PatientProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF03489D),
        elevation: 0,
        title: const Text('MediChain', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        actions: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: NotificationService.stream(userId),
            builder: (context, snapshot) {
              final notifications = snapshot.data ?? [];
              final unread = notifications.where((n) => n['is_read'] == false).length;

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 26),
                    onPressed: () => showNotificationsDropdown(context),
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 8,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          unread.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading ? const Center(child: CircularProgressIndicator(color: Color(0xFF03489D))) : pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            _closeNotificationOverlay(); // Close notification panel when shifting view index pages
            setState(() => _selectedIndex = index);
          },
          selectedItemColor: const Color(0xFF03489D),
          unselectedItemColor: Colors.grey.shade400,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 15,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.person_search_outlined), label: 'Doctors'),
            BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.forum_outlined), label: 'Community'),
            BottomNavigationBarItem(icon: Icon(Icons.account_circle_outlined), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// FIX: Isolated State component to avoid multi-stream Future builder flickering loops
class AppointmentCard extends StatefulWidget {
  final Map<String, dynamic> appt;
  final SupabaseClient supabase;
  final Function(String) onCancel;

  const AppointmentCard({
    super.key,
    required this.appt,
    required this.supabase,
    required this.onCancel,
  });

  @override
  State<AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<AppointmentCard> {
  Future<PostgrestMap?>? _doctorFuture;

  @override
  void initState() {
    super.initState();
    final String doctorId = widget.appt['doctor_id']?.toString() ?? '';
    if (doctorId.isNotEmpty) {
      _doctorFuture = widget.supabase.from('doctors').select().eq('id', doctorId).maybeSingle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final String apptId = widget.appt['appointment_id'] ?? widget.appt['id']?.toString() ?? 'N/A';
    final String date = widget.appt['appointment_date'] ?? widget.appt['date'] ?? 'TBD';
    final String time = widget.appt['time_slot'] ?? 'TBD';
    final String appointmentDbId = widget.appt['id']?.toString() ?? '';
    final String status = widget.appt['status'] ?? 'Scheduled';

    return Container(
      width: MediaQuery.of(context).size.width * 0.78,
      margin: const EdgeInsets.only(right: 16, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blueAccent.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FutureBuilder<PostgrestMap?>(
            future: _doctorFuture,
            builder: (context, docSnapshot) {
              String doctorName = 'Loading Specialist...';
              String specialty = 'Medical Department';

              if (docSnapshot.connectionState == ConnectionState.done && docSnapshot.hasData) {
                final docData = docSnapshot.data;
                if (docData != null) {
                  doctorName = docData['full_name'] ?? 'Physician';
                  specialty = docData['department'] ?? 'General Medicine';
                }
              } else if (docSnapshot.hasError) {
                doctorName = 'Verified Professional';
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.medical_services, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctorName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          specialty,
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(status, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'APT ID: $apptId',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(date, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(time, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 2),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.cancel_outlined, color: Colors.white),
                  label: const Text("Cancel Appointment", style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white)),
                  onPressed: () => widget.onCancel(appointmentDbId),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}