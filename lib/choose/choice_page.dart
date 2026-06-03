import 'package:flutter/material.dart';
import 'package:medichain/presentation/screens/auth/login_screen.dart';
import 'hover_card.dart';
import 'package:medichain/patient/login_page.dart';

class ChoicePage extends StatelessWidget {
  const ChoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Role'),
        centerTitle: true,
        elevation: 20,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // Doctor Card
            HoverCard(
              title: 'Doctor',
              icon: Icons.medical_services,
              onTap: () {},
            ),

            const SizedBox(height: 20),

            // Patient Card
            HoverCard(
              title: 'Patient',
              icon: Icons.person,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PatientLoginScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Admin Card
            HoverCard(
              title: 'Admin',
              icon: Icons.admin_panel_settings,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
  