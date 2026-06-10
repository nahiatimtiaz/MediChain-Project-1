import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';

class AdminBottomNav extends StatelessWidget {
  final Widget child;
  final int currentIndex;

  const AdminBottomNav({
    required this.child,
    required this.currentIndex,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: child, // Renders the active screen child seamlessly
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: currentIndex, // Relies completely on index handed by AppRouter
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed, // Keeps labels steady
            selectedItemColor: AppColors.bluePrimary,
            unselectedItemColor: AppColors.textTertiary,
            selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            onTap: (index) {
              switch (index) {
                case 0:
                  context.go('/dashboard');
                  break;
                case 1:
                  context.go('/doctors');
                  break;
                case 2:
                  context.go('/admin-blog');
                  break;
                case 3:
                  context.go('/profile');
                  break;
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_outlined), 
                activeIcon: Icon(Icons.home), 
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline), 
                activeIcon: Icon(Icons.people), 
                label: 'Doctors',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.forum_outlined), 
                activeIcon: Icon(Icons.forum), 
                label: 'Admin Blog',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline), 
                activeIcon: Icon(Icons.person), 
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}