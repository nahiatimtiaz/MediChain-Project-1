import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PatientHistoryPage extends StatefulWidget {
  const PatientHistoryPage({super.key});

  @override
  State<PatientHistoryPage> createState() => _PatientHistoryPageState();
}

class _PatientHistoryPageState extends State<PatientHistoryPage> {
  final supabase = Supabase.instance.client;

  List visits = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchVisits();
  }

  Future<void> fetchVisits() async {
    try {
      setState(() {
        isLoading = true;
      });

      final user = supabase.auth.currentUser;

      if (user == null) return;

      final response = await supabase
          .from('visits')
          .select('''
            *,
            doctors (
              full_name,
              department
            ),
            reports (*)
          ''')
          .eq('patient_id', user.id)
          .order(
            'visit_date',
            ascending: false,
          );

      if (mounted) {
        setState(() {
          visits = response;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("FETCH VISITS ERROR: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> uploadReport(String visitId) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result == null) return;

      final file = File(result.files.single.path!);

      final fileName =
          "${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}";

      await supabase.storage.from('medical-reports').upload(
            fileName,
            file,
          );

      final fileUrl = supabase.storage
          .from('medical-reports')
          .getPublicUrl(fileName);

      await supabase.from('reports').insert({
        'visit_id': visitId,
        'file_url': fileUrl,
        'report_type': result.files.single.extension,
      });

      fetchVisits();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Report Uploaded"),
          ),
        );
      }
    } catch (e) {
      debugPrint("UPLOAD ERROR: $e");
    }
  }

  Future<void> openReport(String url) async {
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
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
            : visits.isEmpty
                ? buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: visits.length,
                    itemBuilder: (context, index) {
                      final visit = visits[index];
                      final reports = visit['reports'] ?? [];

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
                                        visit['doctors']?['full_name'] ??
                                            'Doctor',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      Text(
                                        visit['doctors']?['department'] ?? '',
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
                              "Visit Date",
                              visit['visit_date'] != null
                                  ? DateFormat('dd MMM yyyy').format(
                                      DateTime.parse(visit['visit_date']),
                                    )
                                  : '',
                            ),
                            detailRow(
                              "Diagnosis",
                              visit['diagnosis'] ?? '',
                            ),
                            detailRow(
                              "Notes",
                              visit['notes'] ?? '',
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              "Medical Reports",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 12),
                            reports.isEmpty
                                ? Text(
                                    "No reports uploaded",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  )
                                : Column(
                                    children: reports.map<Widget>((report) {
                                      return Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 10),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.description,
                                              color: Colors.blue,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                report['report_type'] ??
                                                    'Report',
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                openReport(report['file_url']);
                                              },
                                              child: const Text("Open"),
                                            )
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                            const SizedBox(height: 18),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  uploadReport(visit['id']);
                                },
                                icon: const Icon(Icons.upload),
                                label: const Text("Upload Report"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 12,
                                  ),
                                ),
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