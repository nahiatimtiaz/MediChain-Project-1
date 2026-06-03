import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorSearchPage extends StatefulWidget {
  const DoctorSearchPage({super.key});

  @override
  State<DoctorSearchPage> createState() =>
      _DoctorSearchPageState();
}

class _DoctorSearchPageState
    extends State<DoctorSearchPage> {
  final supabase = Supabase.instance.client;

  List<dynamic> doctors = [];
  List<dynamic> filteredDoctors = [];

  bool isLoading = true;

  final searchController = TextEditingController();

 int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    fetchDoctors();
  }

  Future<void> fetchDoctors() async {
    try {
      final response = await supabase
          .from('doctors')
          .select();

      setState(() {
        doctors = response;
        filteredDoctors = response;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("DOCTOR FETCH ERROR: $e");

      setState(() {
        isLoading = false;
      });
    }
  }

  void searchDoctors(String query) {
    final results = doctors.where((doctor) {
      final name =
          doctor['full_name']
                  ?.toString()
                  .toLowerCase() ??
              '';

      final department =
          doctor['department']
                  ?.toString()
                  .toLowerCase() ??
              '';

      return name.contains(query.toLowerCase()) ||
          department.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredDoctors = results;
    });
  }

  void onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pop(context);
    }
  }

  String formatDays(dynamic days) {
    if (days == null) return '';

    if (days is List) {
      return days.join(", ");
    }

    return days.toString();
  }

  String formatTimeSlots(dynamic slots) {
    if (slots == null) return '';

    if (slots is List) {
      return slots.join(", ");
    }

    return slots.toString();
  }

  Widget detailText(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        "$title$value",
        style: const TextStyle(
          fontSize: 14,
        ),
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  return Container(
    color: const Color(0xFFF5F9FF),

    child: SafeArea(
      child: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                children: [
                  TextField(
                    controller: searchController,

                    onChanged: searchDoctors,

                    decoration: InputDecoration(
                      hintText:
                          "Search doctor or department",

                      prefixIcon: const Icon(
                        Icons.search,
                      ),

                      filled: true,

                      fillColor: Colors.white,

                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),

                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Expanded(
                    child: filteredDoctors.isEmpty
                        ? const Center(
                            child: Text(
                              "No doctors found",
                            ),
                          )
                        : ListView.builder(
                            itemCount:
                                filteredDoctors.length,

                            itemBuilder:
                                (context, index) {
                              final doctor =
                                  filteredDoctors[
                                      index];

                              return Container(
                                margin:
                                    const EdgeInsets.only(
                                  bottom: 18,
                                ),

                                padding:
                                    const EdgeInsets.all(
                                  18,
                                ),

                                decoration: BoxDecoration(
                                  color: Colors.white,

                                  borderRadius:
                                      BorderRadius.circular(
                                    20,
                                  ),

                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey
                                          .withOpacity(
                                        0.08,
                                      ),

                                      blurRadius: 10,
                                    ),
                                  ],
                                ),

                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,

                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 30,

                                          backgroundColor:
                                              Colors.blue
                                                  .shade100,

                                          backgroundImage:
                                              doctor['profile_image_url'] !=
                                                      null
                                                  ? NetworkImage(
                                                      doctor[
                                                          'profile_image_url'],
                                                    )
                                                  : null,

                                          child:
                                              doctor['profile_image_url'] ==
                                                      null
                                                  ? const Icon(
                                                      Icons
                                                          .person,

                                                      size:
                                                          30,

                                                      color:
                                                          Colors
                                                              .blue,
                                                    )
                                                  : null,
                                        ),

                                        const SizedBox(
                                          width: 16,
                                        ),

                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .start,

                                            children: [
                                              Text(
                                                doctor['full_name'] ??
                                                    '',

                                                style:
                                                    const TextStyle(
                                                  fontSize:
                                                      20,

                                                  fontWeight:
                                                      FontWeight
                                                          .bold,
                                                ),
                                              ),

                                              const SizedBox(
                                                height: 4,
                                              ),

                                              Text(
                                                doctor['department'] ??
                                                    '',

                                                style:
                                                    TextStyle(
                                                  color: Colors
                                                      .grey
                                                      .shade700,

                                                  fontSize:
                                                      15,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(
                                      height: 16,
                                    ),

                                    detailText(
                                      "Qualifications: ",
                                      doctor['qualifications'] ??
                                          '',
                                    ),

                                    detailText(
                                      "Consultation Fee: ",
                                      doctor['consultation_fee']
                                              ?.toString() ??
                                          '',
                                    ),

                                    detailText(
                                      "Available Days: ",
                                      formatDays(
                                        doctor[
                                            'available_days'],
                                      ),
                                    ),

                                    detailText(
                                      "Time Slots: ",
                                      formatTimeSlots(
                                        doctor[
                                            'time_slots'],
                                      ),
                                    ),

                                    detailText(
                                      "Phone: ",
                                      doctor['phone'] ??
                                          '',
                                    ),

                                    detailText(
                                      "Email: ",
                                      doctor['email'] ??
                                          '',
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    ),
  );
}
}