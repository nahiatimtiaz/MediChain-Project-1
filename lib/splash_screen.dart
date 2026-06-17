import 'package:flutter/material.dart'; //material design library- scaffold, colors, elevated button etc
import 'package:go_router/go_router.dart'; //imports go router package
import 'package:supabase_flutter/supabase_flutter.dart'; // imports supabase for authentication states 

class SplashScreen extends StatefulWidget { //defines splash screen as stateful widget, stateful is needed as the screen manages an animation controller that changes over time
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();//its connects a stateful widget to its corresponding state class. it is the bridge that allows a widget to dynamically change what it looks like on the screen. 
  /*
  State<SplashScreen>: This is the return type of the method. It tells Flutter: "This function is guaranteed to hand you back a State object that belongs specifically to our SplashScreen widget."

  createState(): This is a built-in Flutter framework method. Whenever you insert a StatefulWidget into the widget tree, Flutter immediately calls its createState() method to set up the widget's internal gears.

  => (Arrow Syntax): This is just a short, clean Dart shorthand for writing a one-line function that returns a value. It means the same thing as { return _SplashScreenState(); }.

 _SplashScreenState(): This instantiates (creates an instance of) your companion State class, which holds all of your splash screen's variables, background logic, timers, and the build method UI.

  By overriding createState(), you are telling Flutter: 
  "Hey, whenever you want to render this splash screen, 
  don't look at the configuration class itself. Look at this 
  attached _SplashScreenState companion class instead, because 
  that's where I'm going to manage all the data and updates!"
  */
}


class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  //SingleTickerProviderStateMixin: This is a "mixin" that provides a Ticker (a clock that ticks on every frame). It tells the app to sync the animation frame rate with the device's display refresh rate.
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  /*
  _fadeController: The brain of the animation. It manages the time, direction (forward/backward), and state of the animation.
  _fadeAnimation: The actual values (from 0.0 to 1.0) being generated to control the opacity.
  late: Tells Dart these variables will be initialized shortly in the initState method before they are ever read.
  */

  @override
  void initState() {
    super.initState();
    // this method is triggered exactly once when this screen is first loaded into memory 
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      /*
      Initializes the controller.
      vsync: this: Links the ticker provided by the mixin to prevent off-screen animations from consuming battery/CPU.
      duration: Sets the fading effect to last exactly 800 milliseconds.
      */
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

    // 1. Grab the current active session from Supabase
    final session = Supabase.instance.client.auth.currentSession;

    // 2. Smart routing decision based on login state
    if (session != null) {
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
              
              const Spacer(),
              
              // Fading Get Started Button
              FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: ElevatedButton(
                    // 🔥 Link this button directly to your smart session check method
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
                        Spacer(), // Keeps things balanced if needed or standard spacing
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