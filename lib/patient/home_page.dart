import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  String patientId = '';
  String welcomeName = '';

  final String userId =
      Supabase.instance.client.auth.currentUser?.id ?? '';

  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    fetchPatientData();
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

      if (response != null) {
        setState(() {
          patientId = response['patient_id'] ?? '';
          welcomeName = response['full_name'] ?? '';

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
      setState(() => isLoading = false);
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient information saved')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget buildTextField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget buildHomePage() {
    final currentDate =
        DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, $welcomeName',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Patient ID: $patientId',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            currentDate,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  buildTextField(
                    label: 'Patient ID',
                    controller: TextEditingController(text: patientId),
                    enabled: false,
                  ),
                  buildTextField(label: 'Full Name', controller: fullNameController),
                  buildTextField(label: 'Email', controller: emailController),
                  buildTextField(label: 'Phone', controller: phoneController),
                  buildTextField(label: 'Date of Birth', controller: dobController),
                  buildTextField(label: 'Gender', controller: genderController),
                  buildTextField(label: 'Blood Group', controller: bloodGroupController),
                  buildTextField(label: 'Address', controller: addressController, maxLines: 2),
                  buildTextField(label: 'Allergies', controller: allergiesController, maxLines: 2),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: savePatientData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Save Information',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  void showNotificationsDropdown(BuildContext context) {
    final overlay = Overlay.of(context);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 80,
        right: 10,
        child: Material(
          elevation: 10,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 320,
            height: 400,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: NotificationService.stream(userId),
              builder: (context, snapshot) {
                final notifications = snapshot.data ?? [];

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Notifications",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _overlayEntry?.remove();
                            _overlayEntry = null;
                          },
                        ),
                      ],
                    ),
                    const Divider(),

                    Expanded(
                      child: ListView.builder(
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final n = notifications[index];

                          return ListTile(
                            title: Text(n['title'] ?? ''),
                            subtitle: Text(n['message'] ?? ''),
                            leading: Icon(
                              n['is_read']
                                  ? Icons.notifications_none
                                  : Icons.notifications_active,
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
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Medichain',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),

        actions: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: NotificationService.stream(userId),
            builder: (context, snapshot) {
              final notifications = snapshot.data ?? [];

              final unread = notifications
                  .where((n) => n['is_read'] == false)
                  .length;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none, color: Colors.black),
                    onPressed: () {
                      showNotificationsDropdown(context);
                    },
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unread.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pages[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Doctors'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Community'),
        ],
      ),
    );
  }
}