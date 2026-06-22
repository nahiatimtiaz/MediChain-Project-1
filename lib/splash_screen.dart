import 'package:flutter/material.dart'; 
import 'package:go_router/go_router.dart'; 
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
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      final userId = session.user.id;

      try {
        final patientCheck = await Supabase.instance.client
            .from('patients') 
            .select('id')
            .eq('id', userId)
            .maybeSingle();   

        if (patientCheck != null) {
          context.go('/patient-home-page');
          return; 
        }

        final doctorCheck = await Supabase.instance.client
            .from('doctors')  
            .select('id')
            .eq('id', userId)
            .maybeSingle();

        if (doctorCheck != null) {
          context.go('/doctor-home-page');
          return; 
        }

       
        final adminCheck = await Supabase.instance.client
            .from('admins')   
            .select('id')
            .eq('id', userId)
            .maybeSingle();

        if (adminCheck != null) {
          context.go('/admin-home-page');
          return; 
        }

       
        context.go('/patient-login');

      } catch (e) {
        context.go('/patient-login');
      }
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
                  'assets/animations/Sceneg.gif', 
                  width: 400,
                  height: 400,
                  fit: BoxFit.contain, 
                ),
              ),
              
              const SizedBox(height: 24),
              
              const Spacer(),
              
              FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: ElevatedButton(
                    onPressed: _checkExistingSession,
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
                        Spacer(), 
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
