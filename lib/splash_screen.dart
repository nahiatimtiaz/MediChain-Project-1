import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medichain/patient/home_page.dart';
import 'package:medichain/patient/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _fadeController.forward();
    });
  }
  Future<void> _checkExistingSession() async {
  // 1. Wait a moment for your splash logo animation to display nicely (e.g., 2 seconds)
  await Future.delayed(const Duration(seconds: 2));

  if (!mounted) return;

  // 2. Grab the current active session from Supabase
  final session = Supabase.instance.client.auth.currentSession;

  // 3. Smart routing decision based on login state
  if (session != null) {
    // 🎉 User is already logged in! Route them straight to the HomePage dashboard
    // Navigator.pushReplacement(
    //   context,
    //   MaterialPageRoute(builder: (context) => const HomePage()),
    // );
    context.go('/patient-home-page');
  } else {

    context.go('/patient-login');
  }
}
  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
            
            Center(
  child: Image.asset(
    'assets/animations/Sceneg.gif', // Uses the stable GIF asset format
    width: 400,
    height: 400,
    fit: BoxFit.contain, // Keeps your logo proportioned perfectly without distortion
  ),
),
              
              const SizedBox(height: 24),
              
              // Fading Text Elements
              // FadeTransition(
              //   opacity: _fadeAnimation,
              //   child: const Column(
              //     children: [
              //       Text(
              //         'MediChain',
              //         style: TextStyle(
              //           fontSize: 32,
              //           fontWeight: FontWeight.bold,
              //           color: Color(0xFF1E293B),
              //           letterSpacing: 0.5,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              
              const Spacer(),
              
              // Fading Get Started Button
              FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: ElevatedButton(
                    onPressed: () => context.go('/entry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
