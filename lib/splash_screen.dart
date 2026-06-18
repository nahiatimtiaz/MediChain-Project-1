import 'package:flutter/material.dart'; //material design library- scaffold, colors, elevated button etc
import 'package:go_router/go_router.dart'; //imports go router package
import 'package:supabase_flutter/supabase_flutter.dart'; // imports supabase for authentication states 

class SplashScreen extends StatefulWidget { //defines splash screen as stateful widget, stateful is needed as the screen manages an animation controller that changes over time
  const SplashScreen({super.key});
  /*
  class: Defines a new blueprint (object pattern) in Dart.

  SplashScreen: The custom name given to this specific screen.

 extends: Inherits functionality from a parent class.

StatefulWidget: A widget that holds state that can change during the 
widget's lifetime. Because this page handles dynamic changes 
(an animation fading in, a changing timer), it must be a StatefulWidget.

const: Tells Flutter that this widget is an immutable constant. This 
optimizes memory because Flutter won't rebuild the configuration object 
if nothing changes.

SplashScreen: The constructor function for this class.

{super.key}: A named argument that forwards a unique identifier (key) to 
the parent StatefulWidget constructor (super). Flutter uses keys to 
track widgets in its element tree.
  */

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

  @override: An annotation indicating that this method replaces a method inherited from StatefulWidget.

State<SplashScreen>: The data type this method must return. It expects a state object linked specifically to SplashScreen.

createState(): The method Flutter calls behind the scenes to create the backend logic holder for this widget.

=>: The arrow syntax shorthand for { return _SplashScreenState(); }.

_SplashScreenState(): Instantiates the companion state class below. The leading underscore (_) marks this class as private, meaning it can only be used inside this specific file.
  */
}


class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
 
  /* 
  SingleTickerProviderStateMixin: This is a "mixin" that provides a Ticker (a clock that ticks on every frame). It tells the app to sync the animation 
  frame rate with the device's display refresh rate.
  extends State<SplashScreen>: Inherits all the tools required to 
  update the UI (like setState and build). It links this class 
  specifically to the SplashScreen widget configuration.

 with: Applies a mixin. A mixin allows you to inject functionality
 from another class without using standard parent-child inheritance.

 SingleTickerProviderStateMixin: A mixin that supplies a single Ticker (a clock utility). The ticker tells your app to tick on every single frame, allowing the animation controller 
 to match the device's refresh rate (e.g., 60Hz or 120Hz) precisely.
  */
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  /*
   late: Promises Dart's type system that these variables will be initialized later (inside initState) before anyone tries to read them.
AnimationController: A built-in Flutter controller that drives an animation (stops it, loops it, tracks elapsed time).
Animation<double>: A value tracker that interpolates decimal numbers (from 0.0 to 1.0) as time goes on. The FadeTransition widget uses these numbers to change opacity.
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

/*
void: Means this function doesn't return any data.
initState(): A lifecycle method that runs exactly once when this widget enters the memory tree.
super.initState(): Calls the parent State class's initialization logic first to make sure everything initializes safely.
vsync: this: Links the clock (Ticker) from our SingleTickerProviderStateMixin to the controller. This prevents the animation from running and wasting resources when the phone screen is off or backgrounded.
duration: ...: Configures the total runtime of the animation to last 800 milliseconds.
Tween<double>: Stands for "be-tween". It maps the animation timeline to human numbers. It starts at 0.0 (invisible) and ends at 1.0 (fully visible).
.animate(): Chains a curve onto the timeline.
CurvedAnimation: Applies non-linear mathematical styling to the animation pace.
Curves.easeIn: Ensures the animation starts slow and accelerates (instead of moving at a rigid, robotic linear speed).
Future.delayed: Asynchronously schedules an action to happen after a brief window of time.
const Duration(milliseconds: 400): The delay time (400ms) before the button begins to fade in.
if (mounted): A boolean flag check. If the user leaves the screen before 400 milliseconds pass, mounted becomes false. This safeguard ensures your code doesn't try to animate a widget that no longer exists in memory.
_fadeController.forward(): Triggers the animation to play moving forward (from 0 to 1).
Future<void>: Indicates this function is asynchronous (returns a promise that completes later).
async: Enables the use of asynchronous code behaviors inside this method.
if (!mounted) return;: If the widget is detached from the UI tree, stop executing immediately to prevent crash errors.
final: Variables declared with final can only be set once.
Supabase.instance.client.auth.currentSession: Reaches out to the globally initialized Supabase setup, dives into its auth engine, and checks if an encrypted access token (session) is saved on the device.
if (session != null): If a session is not null, it means a user logged in previously.
context.go(...): GoRouter's method that instantly jumps to a specific path route, swapping out the splash screen completely
dispose(): Runs when this widget is removed permanently from the app structure.
_fadeController.dispose(): Crucial. Turns off the ticker clock loop. If forgotten, this causes memory leaks, silently draining user batteries in the background.
super.dispose(): Lets the parent class complete its final clean-up routines.
Widget: The return structural type. Everything you view visually on a Flutter layout is a Widget.
build(BuildContext context): The core UI method called every time something needs to draw onto the screen. context is a tracking locator showing exactly where this widget sits in the app's structural tree.
Scaffold: The baseline layout canvas for Material Design. It manages app-bars, bottom menus, and structural backgrounds.
SafeArea: An architectural wrapper that cushions your design from camera notches, status lines, and bottom navigation handles on iOS/Android.
Padding: Generates blank cushion space around widgets.
EdgeInsets.symmetric(horizontal: 24.0): Applies exactly 24 units of layout padding on both the left and right sides.
Column: A structural layout tool that displays its structural children in a vertical stack (top to bottom).
mainAxisAlignment: MainAxisAlignment.center: Instructs the Column layout engine to aim for center distribution vertically.
children: [...]: An array list containing all child elements residing inside the Column
Spacer(): An elastic invisible widget that expands to consume all empty space available. Having spacers on both sides centers your items dynamically.
Center: Forces its target child into the layout center.
Image.asset(...): Pulls and decodes a static asset image/GIF included in your local project bundle files.
fit: BoxFit.contain: Tells the system to scale the image as large as possible within the 400x400 box boundaries without cropping it or breaking its original shape proportions.
FadeTransition: A specialized internal rendering widget that reads an animation value and directly transforms its child’s screen opacity accordingly.
opacity: _fadeAnimation: Links up our double tween values (from 0.0 smoothly to 1.0) directly into the fade renderer.
onPressed: _checkExistingSession: Registers the execution event trigger. When a user taps this button, it executes the Supabase routing evaluation function defined earlier. Notice no () are written here; we are passing a reference to the function so it runs on click, rather than executing it immediately during build time.
styleFrom: Helper configurator for styling a Material elevated button.
Color(0xFF2563EB): A standard Hex color value defining a distinct royal blue button shade.
double.infinity: Tells the layout engine to span the full width of its parent layout limits.
BorderRadius.circular(16): Softens and curves the button edges with a 16-pixel radius.
elevation: 0: flattens the layout button flat, stripping out the default Material drop shadow effect.
Row: Arranges its interior contents on a horizontal row axis (left to right).
Text('Get Started'): Draws the text characters directly to the viewport canvas.
Spacer(): In this context, it pushes the Text cleanly to the left and pushes the icon over to the extreme right edge of the button layout.
Icon(Icons.arrow_forward_rounded): Draws a Material design directional arrow system icon.
*/