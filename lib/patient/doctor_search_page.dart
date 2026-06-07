
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math'; // Used to generate unique appointment IDs

class DoctorSearchPage extends StatefulWidget {
  const DoctorSearchPage({super.key});

  @override
  State<DoctorSearchPage> createState() => _DoctorSearchPageState();
}

class _DoctorSearchPageState extends State<DoctorSearchPage> {
  final supabase = Supabase.instance.client;

  List<dynamic> doctors = [];
  List<dynamic> filteredDoctors = [];
  bool isLoading = true;

  final searchController = TextEditingController();

  // Filter States
  double? maxConsultationFee;
  String? selectedDayFilter;

  // List of days for the filter dropdown
  final List<String> weekDays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    fetchDoctors();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchDoctors() async {
    try {
      final response = await supabase.from('doctors').select();
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

  // Real-time search with auto-recommendation filtering + sidebar criteria
  void filterDisplay() {
    final query = searchController.text.toLowerCase();

    final results = doctors.where((doctor) {
      final name = doctor['full_name']?.toString().toLowerCase() ?? '';
      final department = doctor['department']?.toString().toLowerCase() ?? '';
      
      // Extract numeric fee safely
      final fee = double.tryParse(doctor['consultation_fee']?.toString() ?? '0') ?? 0.0;
      
      // Extract available days list or string safely
      final dynamic daysData = doctor['available_days'];
      List<String> availableDays = [];
      if (daysData is List) {
        availableDays = daysData.map((e) => e.toString().toLowerCase()).toList();
      } else if (daysData is String) {
        availableDays = [daysData.toLowerCase()];
      }

      // Check Matchers
      final matchesSearch = name.contains(query) || department.contains(query);
      final matchesFee = maxConsultationFee == null || fee <= maxConsultationFee!;
      final matchesDay = selectedDayFilter == null || 
          availableDays.any((day) => day.contains(selectedDayFilter!.toLowerCase()));

      return matchesSearch && matchesFee && matchesDay;
    }).toList();

    setState(() {
      filteredDoctors = results;
    });
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

  Widget detailText(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        "$title$value",
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  // --- BOOKING BOTTOM SHEET PIPELINE ---
  void _showBookingSheet(Map<String, dynamic> doctor) {
    // Local tracking states for the sheet choices
    DateTime? chosenDate;
    String? chosenSlot;
    bool isCheckingSlots = false;
    bool isSubmitting = false;
    List<String> disabledSlots = [];

    // Safely parse doctor available elements
    final List<dynamic> doctorSlots = doctor['time_slots'] is List 
        ? doctor['time_slots'] 
        : [doctor['time_slots']?.toString() ?? ''];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            
            // Function to query already booked slots for that doctor on a selected date
            Future<void> checkSlotAvailability(DateTime date) async {
              setSheetState(() {
                isCheckingSlots = true;
                chosenSlot = null; // reset slot choice on date change
              });

              try {
                final formattedDateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                
                // Fetch existing appointments matching doctor and date
                final existingBookings = await supabase
                    .from('appointments')
                    .select('time_slot')
                    .eq('doctor_id', doctor['id'])
                    .eq('appointment_date', formattedDateStr);

                if (existingBookings != null && (existingBookings as List).isNotEmpty) {
                  disabledSlots = (existingBookings as List)
                      .map((booking) => booking['time_slot'].toString())
                      .toList();
                } else {
                  disabledSlots = [];
                }
              } catch (e) {
                debugPrint("SLOT CHECK ERROR: $e");
              }

              setSheetState(() {
                isCheckingSlots = false;
              });
            }

            // Function execution to save record to Supabase appointments table
            Future<void> confirmBooking() async {
              if (chosenDate == null || chosenSlot == null) return;

              setSheetState(() {
                isSubmitting = true;
              });

              try {
                final currentUserUID = supabase.auth.currentUser?.id;
                if (currentUserUID == null) throw "User authentication not found.";

                final dateStr = "${chosenDate!.year}-${chosenDate!.month.toString().padLeft(2, '0')}-${chosenDate!.day.toString().padLeft(2, '0')}";

                // 1. Count existing entries on that date to determine the serial number
                final countResponse = await supabase
                    .from('appointments')
                    .select('id')
                    .eq('doctor_id', doctor['id'])
                    .eq('appointment_date', dateStr);

                final int nextSerialNumber = (countResponse as List).length + 1;

                // 2. Generate a customized unique appointment ID prefixed for MediChain
                final randomNum = Random().nextInt(90000) + 10000;
                final generatedAppId = "MC-$randomNum";

                // 3. Insert into 'appointments' table
                await supabase.from('appointments').insert({
                  'appointment_id': generatedAppId,
                  'doctor_id': doctor['id'],
                  'patient_id': currentUserUID, // Links directly to the authenticated uuid schema mapping
                  'appointment_date': dateStr,
                  'time_slot': chosenSlot,
                  'serial_number': nextSerialNumber,
                  'status': 'Pending',
                });

                if (!context.mounted) return;
                Navigator.pop(context); // Close sheet
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Success! Appt ID: $generatedAppId, Serial: #$nextSerialNumber"),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                debugPrint("BOOKING SUBMISSION ERROR: $e");
                
                String errorMsg = e.toString();
                // Graceful messaging override if a unique constraint triggers for parallel submissions
                if (errorMsg.contains('unique_doctor_date_slot')) {
                  errorMsg = "This exact slot was just reserved. Please pick another timing.";
                }

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Booking failed: $errorMsg"), backgroundColor: Colors.red),
                );
              } finally {
                setSheetState(() {
                  isSubmitting = false;
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                top: 20, left: 20, right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                  ),
                  const SizedBox(height: 15),
                  Text("Book Appointment", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                  Text("with Dr. ${doctor['full_name']}", style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
                  const Divider(height: 25),

                  // Date Picker Section
                  const Text("Select Date", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ListTile(
                    tileColor: Colors.blue.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: const Icon(Icons.calendar_month, color: Colors.blue),
                    title: Text(chosenDate == null 
                        ? "Choose a Date" 
                        : "${chosenDate!.day}/${chosenDate!.month}/${chosenDate!.year}"),
                    trailing: const Icon(Icons.arrow_drop_down),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setSheetState(() { chosenDate = picked; });
                        await checkSlotAvailability(picked);
                      }
                    },
                  ),
                  const SizedBox(height: 15),

                  // Slot Selection Section
                  if (chosenDate != null) ...[
                    const Text("Select Time Slot (First-Come, First-Served)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (isCheckingSlots)
                      const Center(child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator()))
                    else
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: doctorSlots.map<Widget>((slot) {
                          final bool isBooked = disabledSlots.contains(slot.toString());
                          final bool isSelected = chosenSlot == slot.toString();

                          return ChoiceChip(
                            label: Text(slot.toString()),
                            selected: isSelected,
                            selectedColor: Colors.blue,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : (isBooked ? Colors.grey : Colors.black)
                            ),
                            backgroundColor: isBooked ? Colors.grey.shade200 : Colors.blue.shade50,
                            disabledColor: Colors.grey.shade200,
                            onSelected: isBooked ? null : (selected) {
                              setSheetState(() {
                                chosenSlot = selected ? slot.toString() : null;
                              });
                            },
                          );
                        }).toList(),
                      ),
                  ],
                  
                  const SizedBox(height: 25),
                  
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (chosenDate == null || chosenSlot == null || isSubmitting) ? null : confirmBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: isSubmitting 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Confirm & Reserve Slot", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Filter Dialog pass logic configurations
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Filter Criteria"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Max Consultation Fee (BDT):", style: TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: maxConsultationFee ?? 5000,
                    min: 200,
                    max: 5000,
                    divisions: 24,
                    label: maxConsultationFee?.round().toString() ?? "Any",
                    onChanged: (val) {
                      setDialogState(() { maxConsultationFee = val; });
                    },
                  ),
                  const SizedBox(height: 15),
                  const Text("Available Day:", style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: selectedDayFilter,
                    isExpanded: true,
                    hint: const Text("Select Day"),
                    items: weekDays.map((day) => DropdownMenuItem(value: day, child: Text(day))).toList(),
                    onChanged: (val) {
                      setDialogState(() { selectedDayFilter = val; });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      maxConsultationFee = null;
                      selectedDayFilter = null;
                    });
                    filterDisplay();
                    Navigator.pop(context);
                  },
                  child: const Text("Clear All"),
                ),
                ElevatedButton(
                  onPressed: () {
                    filterDisplay(); 
                    Navigator.pop(context);
                  },
                  child: const Text("Apply Filters"),
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Search Bar and Filters Inline layout Row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            onChanged: (_) => filterDisplay(), // Instant live recommendation feed updates
                            decoration: InputDecoration(
                              hintText: "Search doctor or department",
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: Icon(Icons.tune, color: Colors.blue.shade800),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.all(14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _showFilterDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Main Doctors Feed List
                    Expanded(
                      child: filteredDoctors.isEmpty
                          ? const Center(child: Text("No doctors found"))
                          : ListView.builder(
                              itemCount: filteredDoctors.length,
                              itemBuilder: (context, index) {
                                final doctor = filteredDoctors[index];

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 18),
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.08),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 30,
                                            backgroundColor: Colors.blue.shade100,
                                            backgroundImage: doctor['profile_image_url'] != null
                                                ? NetworkImage(doctor['profile_image_url'])
                                                : null,
                                            child: doctor['profile_image_url'] == null
                                                ? const Icon(Icons.person, size: 30, color: Colors.blue)
                                                : null,
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  doctor['full_name'] ?? '',
                                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  doctor['department'] ?? '',
                                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      detailText("Qualifications: ", doctor['qualifications'] ?? ''),
                                      detailText("Consultation Fee: ", "${doctor['consultation_fee']?.toString() ?? '0'} BDT"),
                                      detailText("Available Days: ", formatDays(doctor['available_days'])),
                                      detailText("Time Slots: ", formatTimeSlots(doctor['time_slots'])),
                                      detailText("Phone: ", doctor['phone'] ?? ''),
                                      detailText("Email: ", doctor['email'] ?? ''),
                                      const Divider(height: 30),
                                      
                                      // Interactive Book Button Action element
                                      SizedBox(
                                        width: double.infinity,
                                        height: 45,
                                        child: ElevatedButton.icon(
                                          onPressed: () => _showBookingSheet(doctor),
                                          icon: const Icon(Icons.edit_calendar),
                                          label: const Text("Book Appointment", style: TextStyle(fontWeight: FontWeight.bold)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue.shade700,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        ),
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

// appointments
// id uuid
// appointment_id text
// doctor_id uuid
// patient_id uuid
// appointment_date date
// time_slot text
// serial_number int4
// status text
// created_at timestamp

// doctors
// id uuid
// doctor_id text
// full_name text
// department text
// qualifications text
// consultation_fee numeric
// available_days text[] 
// time_slots jsonb
// slot_duration int4
// profile_image_url text
// email text
// phone text
// account_status bool
// created_at timestamptz
// updated_at timestamptz

