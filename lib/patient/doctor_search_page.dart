import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'package:medichain/data/models/doctor_model.dart';


class DoctorSearchPage extends StatefulWidget {
  const DoctorSearchPage({super.key});

  @override
  State<DoctorSearchPage> createState() => _DoctorSearchPageState();
}

class _DoctorSearchPageState extends State<DoctorSearchPage> {
  final supabase = Supabase.instance.client;

  List<DoctorModel> doctors = [];
  List<DoctorModel> filteredDoctors = [];
  bool isLoading = true;

  final searchController = TextEditingController();

  // Filter States
  double? maxConsultationFee;
  String? selectedDayFilter;

  final List<String> weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  List<Map<String, dynamic>> generateTimeSlots({
    required String startTimeStr,
    required String endTimeStr,
    required int durationMinutes,
    required DateTime? selectedDate, // 👈 Pass the chosen date here
  }) {
    List<Map<String, dynamic>> slots = [];

    int parseTimeToMinutes(String? timeStr) {
      // Return a default of 0 (or 540 for 9:00 AM) if the input is empty or null
      if (timeStr == null ||
          timeStr.toLowerCase() == 'empty' ||
          timeStr.trim().isEmpty) {
        return 540; // Default: 9:00 AM in minutes
      }

      try {
        final cleanStr = timeStr.trim().toLowerCase();
        int hour = 0;
        int minute = 0;

        if (cleanStr.contains('am') || cleanStr.contains('pm')) {
          // Remove all non-numeric characters except ':' for parsing
          final timePart = cleanStr.replaceAll(RegExp(r'[^0-9:]'), '').trim();
          final parts = timePart.split(':');

          hour = int.parse(parts[0]);
          minute = parts.length > 1 ? int.parse(parts[1]) : 0;

          if (cleanStr.contains('pm') && hour != 12) hour += 12;
          if (cleanStr.contains('am') && hour == 12) hour = 0;
        } else {
          final parts = cleanStr.split(':');
          hour = int.parse(parts[0]);
          minute = parts.length > 1 ? int.parse(parts[1]) : 0;
        }

        return (hour * 60) + minute;
      } catch (e) {
        // If any parsing error occurs, return default 9:00 AM
        return 540;
      }
    }

    String formatMinutesToTime(int totalMinutes) {
      int hour = totalMinutes ~/ 60;
      int minute = totalMinutes % 60;
      String period = hour >= 12 ? 'PM' : 'AM';
      int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return "${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period";
    }

    int startMinutes = parseTimeToMinutes(startTimeStr);
    final int endMinutes = parseTimeToMinutes(endTimeStr);

    // Check if the selected date is today
    bool isToday = false;
    int currentMinutesSinceMidnight = 0;

    if (selectedDate != null) {
      final now = DateTime.now();
      if (selectedDate.year == now.year &&
          selectedDate.month == now.month &&
          selectedDate.day == now.day) {
        isToday = true;
        currentMinutesSinceMidnight = (now.hour * 60) + now.minute;
      }
    }

    while (startMinutes + durationMinutes <= endMinutes) {
      int slotEndMinutes = startMinutes + durationMinutes;

      String slotStartStr = formatMinutesToTime(startMinutes);
      String slotEndStr = formatMinutesToTime(slotEndMinutes);
      String slotString = "$slotStartStr - $slotEndStr";

      // A slot has passed if it's today AND the slot's start time is earlier than right now
      bool hasPassed = isToday && (startMinutes <= currentMinutesSinceMidnight);

      slots.add({'slotText': slotString, 'hasPassed': hasPassed});

      startMinutes = slotEndMinutes + 1;
    }

    return slots;
  }

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

      // Map incoming database JSON arrays straight into typed DoctorModel instances
      final List<DoctorModel> loadedDoctors = (response as List)
          .map((json) => DoctorModel.fromJson(json))
          .toList();

      setState(() {
        doctors = loadedDoctors;
        filteredDoctors = loadedDoctors;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("DOCTOR FETCH ERROR: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // Real-time query matrix utilizing the strictly typed model fields
  void filterDisplay() {
    final query = searchController.text.toLowerCase();

    final results = doctors.where((doctor) {
      final name = doctor.fullName.toLowerCase();
      final department = doctor.department.toLowerCase();
      final fee = doctor.consultationFee;

      final availableDays = doctor.availableDays
          .map((e) => e.toLowerCase())
          .toList();

      // Check Matchers
      final matchesSearch = name.contains(query) || department.contains(query);
      final matchesFee =
          maxConsultationFee == null || fee <= maxConsultationFee!;
      final matchesDay =
          selectedDayFilter == null ||
          availableDays.any(
            (day) => day.contains(selectedDayFilter!.toLowerCase()),
          );

      return matchesSearch && matchesFee && matchesDay;
    }).toList();

    setState(() {
      filteredDoctors = results;
    });
  }

  String formatDays(List<String> days) {
    if (days.isEmpty) return 'Not Specified';
    return days.join(", ");
  }

  Widget detailText(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text("$title$value", style: const TextStyle(fontSize: 14)),
    );
  }

  // --- BOOKING BOTTOM SHEET PIPELINE WITH DYNAMIC SLOT GENERATION ---
  void _showBookingSheet(DoctorModel doctor) {
    DateTime? chosenDate;
    String? chosenSlot;
    bool isCheckingSlots = false;
    bool isSubmitting = false;
    List<String> disabledSlots = [];

    // // Trigger dynamic slot collection matrix parsing from DoctorModel directly
    // final List<Map<String, dynamic>> computedDoctorSlots = doctor.generateTimeSlots(
    //   startTimeStr: doctor.startTime ?? "15:00",
    //   endTimeStr: doctor.endTime ?? "18:00",
    //   durationMinutes: doctor.slotDuration ?? 15,
    //   selectedDate: chosenDate, // 👈 This will be updated dynamically when the user picks a date
    // );

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
                chosenSlot = null; // Reset slot choice on date change
              });

              try {
                final formattedDateStr =
                    "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

                // Fetch existing appointments matching doctor UUID string
                final existingBookings = await supabase
                    .from('appointments')
                    .select('time_slot')
                    .eq('doctor_id', doctor.id ?? '')
                    .eq('appointment_date', formattedDateStr);

                if (existingBookings != null &&
                    (existingBookings as List).isNotEmpty) {
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
                if (currentUserUID == null)
                  throw "User authentication not found.";

                final dateStr =
                    "${chosenDate!.year}-${chosenDate!.month.toString().padLeft(2, '0')}-${chosenDate!.day.toString().padLeft(2, '0')}";

                // 1. Count existing entries on that date to determine the serial number
                final countResponse = await supabase
                    .from('appointments')
                    .select('id')
                    .eq('doctor_id', doctor.id ?? '')
                    .eq('appointment_date', dateStr);

                final int nextSerialNumber = (countResponse as List).length + 1;

                // 2. Generate unique tracking identifier string
                final randomNum = Random().nextInt(90000) + 10000;
                final generatedAppId = "MC-$randomNum";

                // 3. Insert data record maps cleanly into Supabase architecture
                await supabase.from('appointments').insert({
                  'appointment_id': generatedAppId,
                  'doctor_id': doctor.id,
                  'patient_id': currentUserUID,
                  'appointment_date': dateStr,
                  'time_slot': chosenSlot,
                  'serial_number': nextSerialNumber,
                  'status': 'Pending',
                });

                if (!context.mounted) return;
                Navigator.pop(context); // Close sheet
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Success! Appt ID: $generatedAppId, Serial: #$nextSerialNumber",
                    ),
                    backgroundColor: const Color.fromARGB(255, 129, 179, 240),
                  ),
                );
              } catch (e) {
                debugPrint("BOOKING SUBMISSION ERROR: $e");

                String errorMsg = e.toString();
                if (errorMsg.contains('unique_doctor_date_slot')) {
                  errorMsg =
                      "This exact slot was just reserved. Please pick another timing.";
                }

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Booking failed: $errorMsg"),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                setSheetState(() {
                  isSubmitting = false;
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Book Appointment",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  Text(
                    "with ${doctor.fullName}",
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                  ),
                  const Divider(height: 25),

                  // Date Picker Section
                  const Text(
                    "Select Date",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    tileColor: Colors.blue.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: const Icon(
                      Icons.calendar_month,
                      color: Colors.blue,
                    ),
                    title: Text(
                      chosenDate == null
                          ? "Choose a Date"
                          : "${chosenDate!.day}/${chosenDate!.month}/${chosenDate!.year}",
                    ),
                    trailing: const Icon(Icons.arrow_drop_down),
                    onTap: () async {
                      // 1. Map integers to weekday strings
                      final List<String> indexToDayMap = [
                        '',
                        'Monday',
                        'Tuesday',
                        'Wednesday',
                        'Thursday',
                        'Friday',
                        'Saturday',
                        'Sunday',
                      ];

                      // Helper to check if a specific date is allowed by this doctor
                      bool isDayAvailable(DateTime date) {
                        String currentGridDay = indexToDayMap[date.weekday];
                        return doctor.availableDays.any(
                          (day) =>
                              day.trim().toLowerCase() ==
                              currentGridDay.toLowerCase(),
                        );
                      }

                      // 2. Find the closest valid initial date starting from today
                      DateTime calculatedInitialDate = DateTime.now();
                      bool foundValidDate = false;

                      // Search up to 30 days ahead for the first day this doctor actually works
                      for (int i = 0; i < 30; i++) {
                        DateTime checkDate = DateTime.now().add(
                          Duration(days: i),
                        );
                        if (isDayAvailable(checkDate)) {
                          calculatedInitialDate = checkDate;
                          foundValidDate = true;
                          break;
                        }
                      }

                      // Fallback: If doctor has no valid days configured, don't open the picker
                      if (!foundValidDate) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "This doctor has no active working days scheduled.",
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      // 3. Now safely open the picker with a guaranteed valid initialDate
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate:
                            calculatedInitialDate, // 👈 Safe initial position
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                        selectableDayPredicate: (DateTime date) {
                          return isDayAvailable(date);
                        },
                      );

                      if (picked != null) {
                        setSheetState(() {
                          chosenDate = picked;
                        });
                        await checkSlotAvailability(picked);
                      }
                    },
                  ),
                  const SizedBox(height: 15),

                  // Dynamic Slot Chip Grid Generation
                  // Dynamic Slot Chip Grid Generation
                  if (chosenDate != null) ...[
                    const Text(
                      "Select Time Slot",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (isCheckingSlots)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    // Quick safety check if doctor data isn't missing
                    else
                      () {
                        // Generate the slots on the fly using the doctor data properties
                        final List<Map<String, dynamic>> computedDoctorSlots =
                            generateTimeSlots(
                              startTimeStr: doctor.startTime ?? "15:00",
                              endTimeStr: doctor.endTime ?? "18:00",
                              durationMinutes: doctor.slotDuration ?? 15,
                              selectedDate:
                                  chosenDate, // 👈 Passing the active date
                            );

                        if (computedDoctorSlots.isEmpty) {
                          return const Text(
                            "No operational times available for this selection setup.",
                            style: TextStyle(color: Colors.red),
                          );
                        }

                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: computedDoctorSlots.map<Widget>((slotData) {
                            final String slot = slotData['slotText'];
                            final bool hasPassed =
                                slotData['hasPassed'] ?? false;
                            final bool isBooked = disabledSlots.contains(slot);
                            final bool isUnavailable = isBooked || hasPassed;
                            final bool isSelected = chosenSlot == slot;

                            return ChoiceChip(
                              label: Text(slot),
                              selected: isSelected,
                              selectedColor: Colors.blue,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (isUnavailable
                                          ? Colors.grey
                                          : Colors.black),
                              ),
                              backgroundColor: isUnavailable
                                  ? Colors.grey.shade200
                                  : Colors.blue.shade50,
                              disabledColor: Colors.grey.shade200,
                              // If it's booked or passed, set onSelected to null to completely disable it
                              onSelected: isUnavailable
                                  ? null
                                  : (selected) {
                                      setSheetState(() {
                                        chosenSlot = selected ? slot : null;
                                      });
                                    },
                            );
                          }).toList(),
                        );
                      }(),
                  ],

                  const SizedBox(height: 25),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          (chosenDate == null ||
                              chosenSlot == null ||
                              isSubmitting)
                          ? null
                          : confirmBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Confirm & Reserve Slot",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

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
                  const Text(
                    "Max Consultation Fee (BDT):",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: maxConsultationFee ?? 5000,
                    min: 200,
                    max: 5000,
                    divisions: 24,
                    label: maxConsultationFee?.round().toString() ?? "Any",
                    onChanged: (val) {
                      setDialogState(() {
                        maxConsultationFee = val;
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Available Day:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<String>(
                    value: selectedDayFilter,
                    isExpanded: true,
                    hint: const Text("Select Day"),
                    items: weekDays
                        .map(
                          (day) =>
                              DropdownMenuItem(value: day, child: Text(day)),
                        )
                        .toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedDayFilter = val;
                      });
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
                ),
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
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            onChanged: (_) => filterDisplay(),
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 30,
                                            backgroundColor:
                                                Colors.blue.shade100,
                                            backgroundImage:
                                                doctor.profileImageUrl != null
                                                ? NetworkImage(
                                                    doctor.profileImageUrl!,
                                                  )
                                                : null,
                                            child:
                                                doctor.profileImageUrl == null
                                                ? const Icon(
                                                    Icons.person,
                                                    size: 30,
                                                    color: Colors.blue,
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  doctor.fullName,
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  doctor.department,
                                                  style: TextStyle(
                                                    color: Colors.grey.shade700,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      detailText(
                                        "Qualifications: ",
                                        doctor.qualifications ?? 'N/A',
                                      ),
                                      detailText(
                                        "Consultation Fee: ",
                                        "${doctor.consultationFee.toStringAsFixed(0)} BDT",
                                      ),
                                      detailText(
                                        "Available Days: ",
                                        formatDays(doctor.availableDays),
                                      ),
                                      detailText(
                                      "Chamber start-end time: ",
                                      "${doctor.startTime ?? 'N/A'} - ${doctor.endTime ?? 'N/A'}",
                                      ),
                                      detailText(
                                        "Slot Duration: ",
                                        "${doctor.slotDuration} Minutes",
                                      ),
                                      detailText(
                                        "Phone: ",
                                        doctor.phone ?? 'N/A',
                                      ),
                                      detailText("Email: ", doctor.email),
                                      const Divider(height: 30),

                                      SizedBox(
                                        width: double.infinity,
                                        height: 45,
                                        child: ElevatedButton.icon(
                                          onPressed: () =>
                                              _showBookingSheet(doctor),
                                          icon: const Icon(Icons.edit_calendar),
                                          label: const Text(
                                            "Book Appointment",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.blue.shade700,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
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
                  ],
                ),
              ),
      ),
    );
  }
}


// class DoctorSearchPage extends StatefulWidget {
//   const DoctorSearchPage({super.key});

//   @override
//   State<DoctorSearchPage> createState() => _DoctorSearchPageState();
// }

// class _DoctorSearchPageState extends State<DoctorSearchPage> {
//   List<Map<String, dynamic>> generateTimeSlots({
//     int parseTimeToMinutes(String? timeStr){
//       int minute = 0;

//       if(cleanStr.contains('am')||cleanStr.contains('pm')){
//         final timePart = cleanStr.replaceAll(RegExp(r'[^0-9:]'), '').trim();
//         final parts = timePart.split(':');

//         hour = int.parse(parts[0]);
//         minute = parts.length >1? int.parse(parts[1]) : 0;

//         if (cleanstr.contains('pm') && hour != 12) hour += 12;
//         if (cleanStr.contains('am') && hour == 12) hour = 0;
//       } else {
//         final parts = cleanStr.split(':');
//         hour = int.parse(parts[0]);
//         minute = parts.length >1? int.parse(parts[1]) : 0; 
//       }
//       return (jpur*60) + minute;
//     } catch(e){
//       return 540;
//     }
//   }

//   )
//   final supabase = Supabase.instance.client;

//   List<DoctorModel> doctors = [];
//   List<DoctorModel> filteredDoctors = [];
//   bool isLoading = true;

//   final searchController = TextEditingController();

//   // Filter States
//   double? maxConsultationFee;
//   String? selectedDayFilter;

//   final List<String> weekDays = [
//     'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
//   ];

//   List<Map<String, dynamic>> generateTimeSlots({
//   required String startTimeStr,
//   required String endTimeStr,
//   required int durationMinutes,
//   required DateTime? selectedDate, // 👈 Pass the chosen date here
// }) {
//   List<Map<String, dynamic>> slots = [];

//   int parseTimeToMinutes(String timeStr) {
//     final cleanStr = timeStr.trim().toLowerCase();
//     int hour = 0;
//     int minute = 0;

//     final normalizedStr = cleanStr.trim().toLowerCase();

//     if (cleanStr.contains('am') || cleanStr.contains('pm')) {
//       final parts = cleanStr.replaceAll(RegExp(r'[am|pm]'), '').trim().split(':');
//       hour = int.parse(parts[0]);
//       minute = int.parse(parts[1]);
//       if (cleanStr.contains('pm') && hour != 12) hour += 12;
//       if (cleanStr.contains('am') && hour == 12) hour = 0;
//     } else {
//       final parts = cleanStr.split(':');
//       hour = int.parse(parts[0]);
//       minute = int.parse(parts[1]);
//     }
//     return (hour * 60) + minute;
//   }

//   String formatMinutesToTime(int totalMinutes) {
//     int hour = totalMinutes ~/ 60;
//     int minute = totalMinutes % 60;
//     String period = hour >= 12 ? 'PM' : 'AM';
//     int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
//     return "${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period";
//   }

//   int startMinutes = parseTimeToMinutes(startTimeStr);
//   final int endMinutes = parseTimeToMinutes(endTimeStr);

//   // Check if the selected date is today
//   bool isToday = false;
//   int currentMinutesSinceMidnight = 0;
  
//   if (selectedDate != null) {
//     final now = DateTime.now();
//     if (selectedDate.year == now.year && 
//         selectedDate.month == now.month && 
//         selectedDate.day == now.day) {
//       isToday = true;
//       currentMinutesSinceMidnight = (now.hour * 60) + now.minute;
//     }
//   }

//   while (startMinutes + durationMinutes <= endMinutes) {
//     int slotEndMinutes = startMinutes + durationMinutes;
    
//     String slotStartStr = formatMinutesToTime(startMinutes);
//     String slotEndStr = formatMinutesToTime(slotEndMinutes);
//     String slotString = "$slotStartStr - $slotEndStr";

//     // A slot has passed if it's today AND the slot's start time is earlier than right now
//     bool hasPassed = isToday && (startMinutes <= currentMinutesSinceMidnight);

//     slots.add({
//       'slotText': slotString,
//       'hasPassed': hasPassed,
//     });

//     startMinutes = slotEndMinutes + 1; 
//   }

//   return slots;
// }

//   @override
//   void initState() {
//     super.initState();
//     fetchDoctors();
//   }

//   @override
//   void dispose() {
//     searchController.dispose();
//     super.dispose();
//   }

//   Future<void> fetchDoctors() async {
//     try {
//       final response = await supabase.from('doctors').select();
      
//       // Map incoming database JSON arrays straight into typed DoctorModel instances
//       final List<DoctorModel> loadedDoctors = (response as List)
//           .map((json) => DoctorModel.fromJson(json))
//           .toList();

//       setState(() {
//         doctors = loadedDoctors;
//         filteredDoctors = loadedDoctors;
//         isLoading = false;
//       });
//     } catch (e) {
//       debugPrint("DOCTOR FETCH ERROR: $e");
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   // Real-time query matrix utilizing the strictly typed model fields
//   void filterDisplay() {
//     final query = searchController.text.toLowerCase();

//     final results = doctors.where((doctor) {
//       final name = doctor.fullName.toLowerCase();
//       final department = doctor.department.toLowerCase();
//       final fee = doctor.consultationFee;
      
//       final availableDays = doctor.availableDays.map((e) => e.toLowerCase()).toList();

//       // Check Matchers
//       final matchesSearch = name.contains(query) || department.contains(query);
//       final matchesFee = maxConsultationFee == null || fee <= maxConsultationFee!;
//       final matchesDay = selectedDayFilter == null || 
//           availableDays.any((day) => day.contains(selectedDayFilter!.toLowerCase()));

//       return matchesSearch && matchesFee && matchesDay;
//     }).toList();

//     setState(() {
//       filteredDoctors = results;
//     });
//   }

//   String formatDays(List<String> days) {
//     if (days.isEmpty) return 'Not Specified';
//     return days.join(", ");
//   }

//   Widget detailText(String title, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(top: 6),
//       child: Text(
//         "$title$value",
//         style: const TextStyle(fontSize: 14),
//       ),
//     );
//   }

//   // --- BOOKING BOTTOM SHEET PIPELINE WITH DYNAMIC SLOT GENERATION ---
//   void _showBookingSheet(DoctorModel doctor) {
//     DateTime? chosenDate;
//     String? chosenSlot;
//     bool isCheckingSlots = false;
//     bool isSubmitting = false;
//     List<String> disabledSlots = [];

//     // // Trigger dynamic slot collection matrix parsing from DoctorModel directly
//     // final List<Map<String, dynamic>> computedDoctorSlots = doctor.generateTimeSlots(
//     //   startTimeStr: doctor.startTime ?? "15:00",
//     //   endTimeStr: doctor.endTime ?? "18:00",
//     //   durationMinutes: doctor.slotDuration ?? 15,
//     //   selectedDate: chosenDate, // 👈 This will be updated dynamically when the user picks a date
//     // );

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (BuildContext context, StateSetter setSheetState) {
            
//             // Function to query already booked slots for that doctor on a selected date
//             Future<void> checkSlotAvailability(DateTime date) async {
//               setSheetState(() {
//                 isCheckingSlots = true;
//                 chosenSlot = null; // Reset slot choice on date change
//               });

//               try {
//                 final formattedDateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                
//                 // Fetch existing appointments matching doctor UUID string
//                 final existingBookings = await supabase
//                     .from('appointments')
//                     .select('time_slot')
//                     .eq('doctor_id', doctor.id ?? '')
//                     .eq('appointment_date', formattedDateStr);

//                 if (existingBookings != null && (existingBookings as List).isNotEmpty) {
//                   disabledSlots = (existingBookings as List)
//                       .map((booking) => booking['time_slot'].toString())
//                       .toList();
//                 } else {
//                   disabledSlots = [];
//                 }
//               } catch (e) {
//                 debugPrint("SLOT CHECK ERROR: $e");
//               }

//               setSheetState(() {
//                 isCheckingSlots = false;
//               });
//             }

//             // Function execution to save record to Supabase appointments table
//             Future<void> confirmBooking() async {
//               if (chosenDate == null || chosenSlot == null) return;

//               setSheetState(() {
//                 isSubmitting = true;
//               });

//               try {
//                 final currentUserUID = supabase.auth.currentUser?.id;
//                 if (currentUserUID == null) throw "User authentication not found.";

//                 final dateStr = "${chosenDate!.year}-${chosenDate!.month.toString().padLeft(2, '0')}-${chosenDate!.day.toString().padLeft(2, '0')}";

//                 // 1. Count existing entries on that date to determine the serial number
//                 final countResponse = await supabase
//                     .from('appointments')
//                     .select('id')
//                     .eq('doctor_id', doctor.id ?? '')
//                     .eq('appointment_date', dateStr);

//                 final int nextSerialNumber = (countResponse as List).length + 1;

//                 // 2. Generate unique tracking identifier string
//                 final randomNum = Random().nextInt(90000) + 10000;
//                 final generatedAppId = "MC-$randomNum";

//                 // 3. Insert data record maps cleanly into Supabase architecture
//                 await supabase.from('appointments').insert({
//                   'appointment_id': generatedAppId,
//                   'doctor_id': doctor.id,
//                   'patient_id': currentUserUID, 
//                   'appointment_date': dateStr,
//                   'time_slot': chosenSlot,
//                   'serial_number': nextSerialNumber,
//                   'status': 'Pending',
//                 });

//                 if (!context.mounted) return;
//                 Navigator.pop(context); // Close sheet
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text("Success! Appt ID: $generatedAppId, Serial: #$nextSerialNumber"),
//                     backgroundColor: const Color.fromARGB(255, 129, 179, 240),
//                   ),
//                 );
//               } catch (e) {
//                 debugPrint("BOOKING SUBMISSION ERROR: $e");
                
//                 String errorMsg = e.toString();
//                 if (errorMsg.contains('unique_doctor_date_slot')) {
//                   errorMsg = "This exact slot was just reserved. Please pick another timing.";
//                 }

//                 if (!context.mounted) return;
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(content: Text("Booking failed: $errorMsg"), backgroundColor: Colors.red),
//                 );
//               } finally {
//                 setSheetState(() {
//                   isSubmitting = false;
//                 });
//               }
//             }

//             return Padding(
//               padding: EdgeInsets.only(
//                 top: 20, left: 20, right: 20,
//                 bottom: MediaQuery.of(context).viewInsets.bottom + 20,
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Center(
//                     child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
//                   ),
//                   const SizedBox(height: 15),
//                   Text("Book Appointment", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
//                   Text("with Dr. ${doctor.fullName}", style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
//                   const Divider(height: 25),

//                   // Date Picker Section
//                   const Text("Select Date", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                   const SizedBox(height: 8),
//                   ListTile(
//                     tileColor: Colors.blue.shade50,
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                     leading: const Icon(Icons.calendar_month, color: Colors.blue),
//                     title: Text(chosenDate == null 
//                         ? "Choose a Date" 
//                         : "${chosenDate!.day}/${chosenDate!.month}/${chosenDate!.year}"),
//                     trailing: const Icon(Icons.arrow_drop_down),
//                     onTap: () async {
//   // 1. Map integers to weekday strings
//   final List<String> indexToDayMap = [
//     '', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
//   ];

//   // Helper to check if a specific date is allowed by this doctor
//   bool isDayAvailable(DateTime date) {
//     String currentGridDay = indexToDayMap[date.weekday];
//     return doctor.availableDays.any(
//       (day) => day.trim().toLowerCase() == currentGridDay.toLowerCase()
//     );
//   }

//   // 2. Find the closest valid initial date starting from today
//   DateTime calculatedInitialDate = DateTime.now();
//   bool foundValidDate = false;

//   // Search up to 30 days ahead for the first day this doctor actually works
//   for (int i = 0; i < 30; i++) {
//     DateTime checkDate = DateTime.now().add(Duration(days: i));
//     if (isDayAvailable(checkDate)) {
//       calculatedInitialDate = checkDate;
//       foundValidDate = true;
//       break;
//     }
//   }

//   // Fallback: If doctor has no valid days configured, don't open the picker
//   if (!foundValidDate) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text("This doctor has no active working days scheduled."),
//         backgroundColor: Colors.orange,
//       ),
//     );
//     return;
//   }

//   // 3. Now safely open the picker with a guaranteed valid initialDate
//   final DateTime? picked = await showDatePicker(
//     context: context,
//     initialDate: calculatedInitialDate, // 👈 Safe initial position
//     firstDate: DateTime.now(),
//     lastDate: DateTime.now().add(const Duration(days: 30)),
//     selectableDayPredicate: (DateTime date) {
//       return isDayAvailable(date);
//     },
//   );
  
//   if (picked != null) {
//     setSheetState(() { chosenDate = picked; });
//     await checkSlotAvailability(picked);
//   }
// },
//                   ),
//                   const SizedBox(height: 15),

//                   // Dynamic Slot Chip Grid Generation 
//                   // Dynamic Slot Chip Grid Generation 
// if (chosenDate != null) ...[
//   const Text("Select Time Slot", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//   const SizedBox(height: 8),
//   if (isCheckingSlots)
//     const Center(child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator()))
//     // Quick safety check if doctor data isn't missing
//   else () {
//     // Generate the slots on the fly using the doctor data properties
//     final List<Map<String, dynamic>> computedDoctorSlots = generateTimeSlots(
//         startTimeStr: doctor.startTime ?? "15:00",
//         endTimeStr: doctor.endTime ?? "18:00",
//         durationMinutes: doctor.slotDuration ?? 15,
//         selectedDate: chosenDate, // 👈 Passing the active date
//       );

//     if (computedDoctorSlots.isEmpty) {
//       return const Text("No operational times available for this selection setup.", style: TextStyle(color: Colors.red));
//     }

//     return Wrap(
//       spacing: 10,
//       runSpacing: 10,
//       children: computedDoctorSlots.map<Widget>((slotData) {
//         final String slot = slotData['slotText'];
//         final bool hasPassed = slotData['hasPassed'] ?? false;
//         final bool isBooked = disabledSlots.contains(slot);
//         final bool isUnavailable = isBooked || hasPassed;
//         final bool isSelected = chosenSlot == slot;

//         return ChoiceChip(
//             label: Text(slot),
//             selected: isSelected,
//             selectedColor: Colors.blue,
//             labelStyle: TextStyle(
//               color: isSelected ? Colors.white : (isUnavailable ? Colors.grey : Colors.black)
//             ),
//             backgroundColor: isUnavailable ? Colors.grey.shade200 : Colors.blue.shade50,
//             disabledColor: Colors.grey.shade200,
//             // If it's booked or passed, set onSelected to null to completely disable it
//             onSelected: isUnavailable ? null : (selected) {
//               setSheetState(() {
//                 chosenSlot = selected ? slot : null;
//               });
//             },
//           );
//       }).toList(),
//     );
//   }(),
// ],
                  
//                   const SizedBox(height: 25),
                  
//                   // Submit Button
//                   SizedBox(
//                     width: double.infinity,
//                     height: 50,
//                     child: ElevatedButton(
//                       onPressed: (chosenDate == null || chosenSlot == null || isSubmitting) ? null : confirmBooking,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.blue.shade800,
//                         foregroundColor: Colors.white,
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                       ),
//                       child: isSubmitting 
//                           ? const CircularProgressIndicator(color: Colors.white)
//                           : const Text("Confirm & Reserve Slot", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                     ),
//                   )
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   void _showFilterDialog() {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setDialogState) {
//             return AlertDialog(
//               title: const Text("Filter Criteria"),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text("Max Consultation Fee (BDT):", style: TextStyle(fontWeight: FontWeight.bold)),
//                   Slider(
//                     value: maxConsultationFee ?? 5000,
//                     min: 200,
//                     max: 5000,
//                     divisions: 24,
//                     label: maxConsultationFee?.round().toString() ?? "Any",
//                     onChanged: (val) {
//                       setDialogState(() { maxConsultationFee = val; });
//                     },
//                   ),
//                   const SizedBox(height: 15),
//                   const Text("Available Day:", style: TextStyle(fontWeight: FontWeight.bold)),
//                   DropdownButton<String>(
//                     value: selectedDayFilter,
//                     isExpanded: true,
//                     hint: const Text("Select Day"),
//                     items: weekDays.map((day) => DropdownMenuItem(value: day, child: Text(day))).toList(),
//                     onChanged: (val) {
//                       setDialogState(() { selectedDayFilter = val; });
//                     },
//                   ),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () {
//                     setState(() {
//                       maxConsultationFee = null;
//                       selectedDayFilter = null;
//                     });
//                     filterDisplay();
//                     Navigator.pop(context);
//                   },
//                   child: const Text("Clear All"),
//                 ),
//                 ElevatedButton(
//                   onPressed: () {
//                     filterDisplay(); 
//                     Navigator.pop(context);
//                   },
//                   child: const Text("Apply Filters"),
//                 )
//               ],
//             );
//           },
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F9FF),
//       body: SafeArea(
//         child: isLoading
//             ? const Center(child: CircularProgressIndicator())
//             : Padding(
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   children: [
//                     Row(
//                       children: [
//                         Expanded(
//                           child: TextField(
//                             controller: searchController,
//                             onChanged: (_) => filterDisplay(), 
//                             decoration: InputDecoration(
//                               hintText: "Search doctor or department",
//                               prefixIcon: const Icon(Icons.search),
//                               filled: true,
//                               fillColor: Colors.white,
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(16),
//                                 borderSide: BorderSide.none,
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         IconButton(
//                           icon: Icon(Icons.tune, color: Colors.blue.shade800),
//                           style: IconButton.styleFrom(
//                             backgroundColor: Colors.white,
//                             padding: const EdgeInsets.all(14),
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                           ),
//                           onPressed: _showFilterDialog,
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 20),

//                     // Main Doctors Feed List
//                     Expanded(
//                       child: filteredDoctors.isEmpty
//                           ? const Center(child: Text("No doctors found"))
//                           : ListView.builder(
//                               itemCount: filteredDoctors.length,
//                               itemBuilder: (context, index) {
//                                 final doctor = filteredDoctors[index];

//                                 return Container(
//                                   margin: const EdgeInsets.only(bottom: 18),
//                                   padding: const EdgeInsets.all(18),
//                                   decoration: BoxDecoration(
//                                     color: Colors.white,
//                                     borderRadius: BorderRadius.circular(20),
//                                     boxShadow: [
//                                       BoxShadow(
//                                         color: Colors.grey.withOpacity(0.08),
//                                         blurRadius: 10,
//                                       ),
//                                     ],
//                                   ),
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Row(
//                                         children: [
//                                           CircleAvatar(
//                                             radius: 30,
//                                             backgroundColor: Colors.blue.shade100,
//                                             backgroundImage: doctor.profileImageUrl != null
//                                                 ? NetworkImage(doctor.profileImageUrl!)
//                                                 : null,
//                                             child: doctor.profileImageUrl == null
//                                                 ? const Icon(Icons.person, size: 30, color: Colors.blue)
//                                                 : null,
//                                           ),
//                                           const SizedBox(width: 16),
//                                           Expanded(
//                                             child: Column(
//                                               crossAxisAlignment: CrossAxisAlignment.start,
//                                               children: [
//                                                 Text(
//                                                   doctor.fullName,
//                                                   style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                                                 ),
//                                                 const SizedBox(height: 4),
//                                                 Text(
//                                                   doctor.department,
//                                                   style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
//                                                 ),
//                                               ],
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                       const SizedBox(height: 16),
//                                       detailText("Qualifications: ", doctor.qualifications ?? 'N/A'),
//                                       detailText("Consultation Fee: ", "${doctor.consultationFee.toStringAsFixed(0)} BDT"),
//                                       detailText("Available Days: ", formatDays(doctor.availableDays)),
//                                       detailText("Slot Duration: ", "${doctor.slotDuration} Minutes"),
//                                       detailText("Phone: ", doctor.phone ?? 'N/A'),
//                                       detailText("Email: ", doctor.email),
//                                       const Divider(height: 30),
                                      
//                                       SizedBox(
//                                         width: double.infinity,
//                                         height: 45,
//                                         child: ElevatedButton.icon(
//                                           onPressed: () => _showBookingSheet(doctor),
//                                           icon: const Icon(Icons.edit_calendar),
//                                           label: const Text("Book Appointment", style: TextStyle(fontWeight: FontWeight.bold)),
//                                           style: ElevatedButton.styleFrom(
//                                             backgroundColor: Colors.blue.shade700,
//                                             foregroundColor: Colors.white,
//                                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 );
//                               },
//                             ),
//                     ),
//                   ],
//                 ),
//               ),
//       ),
//     );
//   }
// }
