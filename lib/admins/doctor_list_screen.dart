// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// import 'package:medichain/data/services/auth_service.dart';
// import '../../core/constants/app_constants.dart';
// import '../../data/services/doctor_service.dart';
// import '../../data/models/doctor_model.dart';

// class DoctorListScreen extends StatefulWidget {
//   const DoctorListScreen({super.key});

//   @override
//   State<DoctorListScreen> createState() => _DoctorListScreenState();
// }

// class _DoctorListScreenState extends State<DoctorListScreen> {
//   final _doctorService = DoctorService();
//   final _searchController = TextEditingController();

//   List<DoctorModel> _doctors = [];
//   List<DoctorModel> _filteredDoctors = [];
//   bool _isLoading = true;
//   String _selectedDepartment = 'All';

//   @override
//   void initState() {
//     super.initState();
//     _loadDoctors();
//   }

//   Future<void> _loadDoctors() async {
//     final doctors = await _doctorService.getAllDoctors();
//     setState(() {
//       _doctors = doctors;
//       _filteredDoctors = doctors;
//       _isLoading = false;
//     });
//   }

//   void _searchDoctors(String query) {
//     setState(() {
//       _filteredDoctors = _doctors.where((doctor) {
//         final matchesName = doctor.fullName.toLowerCase().contains(
//           query.toLowerCase(),
//         );
//         final matchesId =
//             doctor.doctorId?.toLowerCase().contains(query.toLowerCase()) ??
//             false;
//         final matchesDept =
//             _selectedDepartment == 'All' ||
//             doctor.department == _selectedDepartment;
//         return (matchesName || matchesId) && matchesDept;
//       }).toList();
//     });
//   }

//   void _filterByDepartment(String department) {
//     setState(() {
//       _selectedDepartment = department;
//       _searchDoctors(_searchController.text);
//     });
//   }

//   Future<void> _toggleStatus(DoctorModel doctor) async {
//     await _doctorService.toggleDoctorStatus(doctor.id!, !doctor.accountStatus);
//     _loadDoctors();
//   }

//   Future<void> _confirmDelete(DoctorModel doctor) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: const Text(
//           'Delete Doctor',
//           style: TextStyle(fontWeight: FontWeight.w700),
//         ),
//         content: Text(
//           'Are you sure you want to delete ${doctor.fullName}? This action cannot be undone.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: AppColors.redMid,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       await _doctorService.deleteDoctor(doctor.id!, doctor.fullName);
//       _loadDoctors();
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Doctor deleted successfully')),
//         );
//       }
//     }
//   }

//   Future<void> _showPasswordResetDialog(DoctorModel doctor) async {
//     final passwordController = TextEditingController();
//     final formKey = GlobalKey<FormState>();
//     bool isVisible = false;

//     await showDialog(
//       context: context,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setDialogState) => AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           title: Text(
//             'Reset Password\n${doctor.fullName}',
//             style: const TextStyle(fontWeight: FontWeight.w700),
//           ),
//           content: Form(
//             key: formKey,
//             child: TextFormField(
//               controller: passwordController,
//               obscureText: !isVisible,
//               validator: (value) {
//                 if (value == null || value.isEmpty)
//                   return 'Password is required';
//                 if (value.length < 8) return 'Minimum 8 characters';
//                 return null;
//               },
//               decoration: InputDecoration(
//                 labelText: 'New Password',
//                 suffixIcon: IconButton(
//                   icon: Icon(
//                     isVisible ? Icons.visibility_off : Icons.visibility,
//                   ),
//                   onPressed: () => setDialogState(() => isVisible = !isVisible),
//                 ),
//               ),
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancel'),
//             ),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppColors.primary,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               onPressed: () async {
//                 if (formKey.currentState!.validate()) {
//                   await _doctorService.resetDoctorPassword(
//                     doctor.email,
//                     passwordController.text,
//                   );
//                   if (mounted) {
//                     Navigator.pop(context);
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(
//                         content: Text('Password reset successfully'),
//                       ),
//                     );
//                   }
//                 }
//               },
//               child: const Text('Reset'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showDoctorActions(DoctorModel doctor) {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       builder: (context) => SafeArea(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 40,
//               height: 4,
//               margin: const EdgeInsets.symmetric(vertical: 12),
//               decoration: BoxDecoration(
//                 color: Colors.grey[300],
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//               child: Row(
//                 children: [
//                   Container(
//                     width: 46,
//                     height: 46,
//                     decoration: BoxDecoration(
//                       color: doctor.accountStatus
//                           ? AppColors.primaryLight
//                           : AppColors.redLight,
//                       borderRadius: BorderRadius.circular(14),
//                     ),
//                     child: Center(
//                       child: Text(
//                         doctor.fullName.substring(0, 2).toUpperCase(),
//                         style: TextStyle(
//                           fontWeight: FontWeight.w800,
//                           fontSize: 13,
//                           color: doctor.accountStatus
//                               ? AppColors.primaryText
//                               : AppColors.redText,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           doctor.fullName,
//                           style: const TextStyle(
//                             fontWeight: FontWeight.w700,
//                             fontSize: 15,
//                           ),
//                         ),
//                         Text(
//                           doctor.department,
//                           style: const TextStyle(
//                             color: AppColors.textSecondary,
//                             fontSize: 13,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const Divider(height: 1),
//             ListTile(
//               leading: Container(
//                 width: 36,
//                 height: 36,
//                 decoration: BoxDecoration(
//                   color: AppColors.blueLight,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: const Icon(
//                   Icons.edit_outlined,
//                   color: AppColors.blueText,
//                   size: 18,
//                 ),
//               ),
//               title: const Text(
//                 'Edit Doctor',
//                 style: TextStyle(fontWeight: FontWeight.w600),
//               ),
//               onTap: () async {
//                 Navigator.pop(context);
//                 await context.push('/doctors/edit', extra: doctor);
//                 _loadDoctors();
//               },
//             ),
//             ListTile(
//               leading: Container(
//                 width: 36,
//                 height: 36,
//                 decoration: BoxDecoration(
//                   color: AppColors.amberLight,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: const Icon(
//                   Icons.key_outlined,
//                   color: AppColors.amberText,
//                   size: 18,
//                 ),
//               ),
//               title: const Text(
//                 'Reset Password',
//                 style: TextStyle(fontWeight: FontWeight.w600),
//               ),
//               onTap: () {
//                 Navigator.pop(context);
//                 _showPasswordResetDialog(doctor);
//               },
//             ),
//             ListTile(
//               leading: Container(
//                 width: 36,
//                 height: 36,
//                 decoration: BoxDecoration(
//                   color: doctor.accountStatus
//                       ? AppColors.redLight
//                       : AppColors.primaryLight,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Icon(
//                   doctor.accountStatus
//                       ? Icons.block_outlined
//                       : Icons.check_circle_outline,
//                   color: doctor.accountStatus
//                       ? AppColors.redText
//                       : AppColors.primaryText,
//                   size: 18,
//                 ),
//               ),
//               title: Text(
//                 doctor.accountStatus ? 'Deactivate' : 'Activate',
//                 style: const TextStyle(fontWeight: FontWeight.w600),
//               ),
//               onTap: () {
//                 Navigator.pop(context);
//                 _toggleStatus(doctor);
//               },
//             ),
//             ListTile(
//               leading: Container(
//                 width: 36,
//                 height: 36,
//                 decoration: BoxDecoration(
//                   color: AppColors.redLight,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: const Icon(
//                   Icons.delete_outline,
//                   color: AppColors.redText,
//                   size: 18,
//                 ),
//               ),
//               title: const Text(
//                 'Delete Doctor',
//                 style: TextStyle(
//                   fontWeight: FontWeight.w600,
//                   color: AppColors.redText,
//                 ),
//               ),
//               onTap: () {
//                 Navigator.pop(context);
//                 _confirmDelete(doctor);
//               },
//             ),
//             const SizedBox(height: 8),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       body: _isLoading
//           ? const Center(
//               child: CircularProgressIndicator(color: AppColors.primary),
//             )
//           : CustomScrollView(
//               slivers: [
//                 SliverToBoxAdapter(child: _buildHeader()),
//                 SliverToBoxAdapter(
//                   child: Container(
//                     color: Colors.white,
//                     padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
//                     child: Column(
//                       children: [
//                         Container(
//                           decoration: BoxDecoration(
//                             color: AppColors.background,
//                             borderRadius: BorderRadius.circular(14),
//                             border: Border.all(
//                               color: AppColors.borderMid,
//                               width: 1.5,
//                             ),
//                           ),
//                           child: TextField(
//                             controller: _searchController,
//                             onChanged: _searchDoctors,
//                             decoration: const InputDecoration(
//                               hintText: 'Search by name or ID...',
//                               prefixIcon: Icon(
//                                 Icons.search,
//                                 color: AppColors.textTertiary,
//                                 size: 18,
//                               ),
//                               border: InputBorder.none,
//                               enabledBorder: InputBorder.none,
//                               focusedBorder: InputBorder.none,
//                               contentPadding: EdgeInsets.symmetric(
//                                 vertical: 12,
//                               ),
//                               fillColor: Colors.transparent,
//                               filled: true,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         SizedBox(
//                           height: 36,
//                           child: ListView(
//                             scrollDirection: Axis.horizontal,
//                             children: ['All', ...AppStrings.departments]
//                                 .map(
//                                   (dept) => Padding(
//                                     padding: const EdgeInsets.only(right: 8),
//                                     child: GestureDetector(
//                                       onTap: () => _filterByDepartment(dept),
//                                       child: Container(
//                                         padding: const EdgeInsets.symmetric(
//                                           horizontal: 14,
//                                           vertical: 6,
//                                         ),
//                                         decoration: BoxDecoration(
//                                           color: _selectedDepartment == dept
//                                               ? AppColors.primary
//                                               : AppColors.background,
//                                           borderRadius: BorderRadius.circular(
//                                             20,
//                                           ),
//                                           border: Border.all(
//                                             color: _selectedDepartment == dept
//                                                 ? AppColors.primary
//                                                 : AppColors.borderMid,
//                                             width: 1.5,
//                                           ),
//                                         ),
//                                         child: Text(
//                                           dept,
//                                           style: TextStyle(
//                                             fontSize: 12,
//                                             fontWeight: FontWeight.w600,
//                                             color: _selectedDepartment == dept
//                                                 ? Colors.white
//                                                 : AppColors.textSecondary,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 )
//                                 .toList(),
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                       ],
//                     ),
//                   ),
//                 ),
//                 SliverPadding(
//                   padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
//                   sliver: SliverToBoxAdapter(
//                     child: Text(
//                       '${_filteredDoctors.length} doctors found',
//                       style: const TextStyle(
//                         color: AppColors.textTertiary,
//                         fontSize: 12,
//                       ),
//                     ),
//                   ),
//                 ),
//                 _filteredDoctors.isEmpty
//                     ? const SliverToBoxAdapter(
//                         child: Padding(
//                           padding: EdgeInsets.all(40),
//                           child: Center(
//                             child: Text(
//                               'No doctors found',
//                               style: TextStyle(color: AppColors.textTertiary),
//                             ),
//                           ),
//                         ),
//                       )
//                     : SliverPadding(
//                         padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
//                         sliver: SliverList(
//                           delegate: SliverChildBuilderDelegate(
//                             (context, index) =>
//                                 _buildDoctorCard(_filteredDoctors[index]),
//                             childCount: _filteredDoctors.length,
//                           ),
//                         ),
//                       ),
//               ],
//             ),
//       //bottomNavigationBar: _buildBottomNav(context, 1),
//     );
//   }

//   Widget _buildHeader() {
//     return Container(
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [AppColors.primary, AppColors.primaryDark],
//         ),
//       ),
//       child: SafeArea(
//         bottom: false,
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Manage',
//                     style: TextStyle(color: Colors.white60, fontSize: 12),
//                   ),
//                   const Text(
//                     'Doctors',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 22,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                 ],
//               ),
//               GestureDetector(
//                 onTap: () async {
//                   await context.push('/doctors/add');
//                   _loadDoctors();
//                 },
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 10,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withValues(alpha: 0.2),
//                     borderRadius: BorderRadius.circular(14),
//                     border: Border.all(
//                       color: Colors.white.withValues(alpha: 0.2),
//                     ),
//                   ),
//                   child: const Text(
//                     '+ Add',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.w600,
//                       fontSize: 13,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildDoctorCard(DoctorModel doctor) {
//     final initials = doctor.fullName
//         .split(' ')
//         .take(2)
//         .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
//         .join();

//     return Container(
//       margin: const EdgeInsets.only(bottom: 10),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(color: AppColors.border, width: 1.5),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.03),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 46,
//             height: 46,
//             decoration: BoxDecoration(
//               color: doctor.accountStatus
//                   ? AppColors.primaryLight
//                   : AppColors.redLight,
//               borderRadius: BorderRadius.circular(15),
//               image: doctor.profileImageUrl != null
//                   ? DecorationImage(
//                       image: NetworkImage(doctor.profileImageUrl!),
//                       fit: BoxFit.cover,
//                     )
//                   : null,
//             ),
//             child: doctor.profileImageUrl == null
//                 ? Center(
//                     child: Text(
//                       initials,
//                       style: TextStyle(
//                         fontWeight: FontWeight.w800,
//                         fontSize: 13,
//                         color: doctor.accountStatus
//                             ? AppColors.primaryText
//                             : AppColors.redText,
//                       ),
//                     ),
//                   )
//                 : null,
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   doctor.fullName,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w700,
//                     color: AppColors.textPrimary,
//                   ),
//                 ),
//                 Text(
//                   doctor.department,
//                   style: const TextStyle(
//                     fontSize: 12,
//                     color: AppColors.textSecondary,
//                   ),
//                 ),
//                 const SizedBox(height: 6),
//                 Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 8,
//                         vertical: 2,
//                       ),
//                       decoration: BoxDecoration(
//                         color: AppColors.primaryLight,
//                         borderRadius: BorderRadius.circular(6),
//                       ),
//                       child: Text(
//                         doctor.doctorId ?? '-',
//                         style: const TextStyle(
//                           fontSize: 11,
//                           color: AppColors.primaryMid,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       '৳${doctor.consultationFee.toInt()}',
//                       style: const TextStyle(
//                         fontSize: 11,
//                         color: AppColors.textSecondary,
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 8,
//                         vertical: 2,
//                       ),
//                       decoration: BoxDecoration(
//                         color: doctor.accountStatus
//                             ? AppColors.primaryLight
//                             : AppColors.redLight,
//                         borderRadius: BorderRadius.circular(6),
//                       ),
//                       child: Text(
//                         doctor.accountStatus ? 'Active' : 'Inactive',
//                         style: TextStyle(
//                           fontSize: 11,
//                           fontWeight: FontWeight.w700,
//                           color: doctor.accountStatus
//                               ? AppColors.primaryText
//                               : AppColors.redText,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           GestureDetector(
//             onTap: () => _showDoctorActions(doctor),
//             child: const Icon(Icons.more_horiz, color: Color(0xFFD1D5DB)),
//           ),
//         ],
//       ),
//     );
//   }
// }

// Widget _buildBottomNav(BuildContext context, int currentIndex) {
//   return Container(
//     decoration: const BoxDecoration(
//       color: Colors.white,
//       border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
//     ),
//     child: SafeArea(
//       top: false,
//       child: BottomNavigationBar(
//         currentIndex: currentIndex,
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         selectedItemColor: AppColors.primary,
//         unselectedItemColor: AppColors.textTertiary,
//         selectedLabelStyle: const TextStyle(
//           fontSize: 10,
//           fontWeight: FontWeight.w700,
//         ),
//         unselectedLabelStyle: const TextStyle(
//           fontSize: 10,
//           fontWeight: FontWeight.w700,
//         ),
//         onTap: (index) {
//           if (index == 0) context.go('/dashboard');
//           if (index == 1) context.go('/doctors');
//           if (index == 2) context.go('/profile');
//         },
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home_outlined),
//             activeIcon: Icon(Icons.home),
//             label: 'Home',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.people_outline),
//             activeIcon: Icon(Icons.people),
//             label: 'Doctors',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.settings_outlined),
//             activeIcon: Icon(Icons.settings),
//             label: 'Profile',
//           ),
//         ],
//       ),
//     ),
//   );
// }

// // Widget _buildBottomNav(BuildContext context, int currentIndex) {
// //   return Container(
// //     decoration: const BoxDecoration(
// //       color: Colors.white,
// //       border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
// //     ),
// //     child: SafeArea(
// //       top: false,
// //       child: BottomNavigationBar(
// //         currentIndex: currentIndex,
// //         backgroundColor: Colors.transparent,
// //         elevation: 0,
// //         selectedItemColor: AppColors.primary,
// //         unselectedItemColor: AppColors.textTertiary,
// //         selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
// //         unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
// //         onTap: (index) {
// //           if (index == 0) context.go('/dashboard');
// //           if (index == 1) context.go('/doctors');
// //           if (index == 2) context.go('/admin-blog');
// //           if (index == 3) context.go('/profile');
// //         },
// //         items: const [
// //           BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
// //           BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Doctors'),
// //           BottomNavigationBarItem(icon: Icon(Icons.forum_outlined), activeIcon: Icon(Icons.forum), label: 'Admin Blog'),
// //           BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
// //         ],
// //       ),
// //     ),
// //   );
// // }
