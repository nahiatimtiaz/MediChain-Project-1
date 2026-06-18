// import 'dart:io';
//import 'package:go_router/go_router.dart';
// import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// //import 'package:open_filex/open_filex.dart';
// import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:url_launcher/url_launcher.dart';

class PatientHistoryPage extends StatefulWidget {
  const PatientHistoryPage({super.key});

  @override
  State<PatientHistoryPage> createState() => _PatientHistoryPageState();
}

class _PatientHistoryPageState extends State<PatientHistoryPage> {
  final supabase = Supabase.instance.client;

  List prescriptions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPrescriptions();
  }

  Future<void> fetchPrescriptions() async {
    try {
      setState(() {
        isLoading = true;
      });

      final user = supabase.auth.currentUser;

      if (user == null) return;

      final response = await supabase
          .from('prescriptions')
          .select('''
            *,
            doctors (
              full_name,
              department
            )
          ''')
          .eq('patient_id', user.id)
          .order(
            'created_at',
            ascending: false,
          );

      if (mounted) {
        setState(() {
          prescriptions = response;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("FETCH PRESCRIPTIONS ERROR: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      // Handled cleanly inside the body content layout
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : prescriptions.isEmpty
                ? buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: prescriptions.length,
                    itemBuilder: (context, index) {
                      final prescription = prescriptions[index];
                      // final reports = prescription ['reports'] ?? [];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.08),
                              blurRadius: 10,
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.medical_services,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        prescription['doctors']?['full_name'] ??
                                            'Doctor',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      Text(
                                        prescription['doctors']?['department'] ?? '',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            detailRow(
                              "Date",
                              prescription['created_at'] != null
                                  ? DateFormat('dd MMM yyyy').format(
                                      DateTime.parse(prescription['created_at']),
                                    )
                                  : '',
                            ),
                            detailRow(
                            "Medicines", 
                            _formatJsonMedicines(prescription['medicines'])
                            ),
                            detailRow(
                              "Diagnosis",
                              prescription['diagnosis'] ?? '',
                            ),
                            detailRow(
                              "Notes",
                              prescription['notes'] ?? '',
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 90,
              color: Colors.blue.shade200,
            ),
            const SizedBox(height: 20),
            const Text(
              "No Medical History Yet",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Your visits, prescriptions and reports will appear here.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? "-" : value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
String _formatJsonMedicines(dynamic medicinesData) {
  if (medicinesData == null) return '-';
  
  try {
    if (medicinesData is List) {
      return medicinesData.map((med) {
        final name = med['name'] ?? 'Unknown Medicine';
        final dosage = med['dosage'] ?? med['dose'] ?? '';
        return dosage.isNotEmpty ? "$name ($dosage)" : name;
      }).join(', ');
    }
  } catch (e) {
    debugPrint("Parsing medicines JSON failed: $e");
  }
  return medicinesData.toString();
}