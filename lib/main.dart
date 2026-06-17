import 'package:flutter/material.dart'; //design package that gives access to UI widgets, themes and design elements such as StatelessWidget, Material app and colors 
import 'package:supabase_flutter/supabase_flutter.dart'; // imports the Supabase backend service
import 'core/constants/supabase_config.dart'; //custom imports, holds 
import 'core/theme/app_theme.dart'; //Contains your custom colors, fonts, and styling definitions.
import 'routes/app_router.dart'; //handles the app's navigation 

//why did u use app router instead of navigator.push?

void main() async { // starting point of the flutter application. 
//async -> tells Dart that asynchronous operations such as fetching data or initializing services will happen inside the function
// it allows us to use await keyword
  WidgetsFlutterBinding.ensureInitialized();
// the line above Interacts with the Flutter engine. It ensures that the Flutter widget framework is fully booted up and ready to go before executing any asynchronous code.
//without this the app will crash 
  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const MyApp()); //starts the actual UI rendering, 
  // the const is sued as it optimizes performance by telling flutter that this widget instance will
  //never change, preventing unnecessary redraws. Without const: Flutter is forced to create a brand-new instance of MyApp in memory at runtime (while the app is actively running) right when the main() function executes.
}

class MyApp extends StatelessWidget { //myapp widget
// statelessWidget means its configuration wont dynamically change its own state during its lifecycle 
  const MyApp({super.key});
  //superkey forwards a unique identifier key to the parent statelesswidget class which helps flutter track and manage the widget tree


  @override
  // overrides flutter's built in build method. 
  Widget build(BuildContext context) {
    return MaterialApp.router( // creates the foundational wrapper for the app, specifically configured to use a Router instead of traditional navigaiton
      title: 'Healthcare Admin', // sets the application title 
      debugShowCheckedModeBanner: false, // removes the debug banner
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router, // this passes the actual routing map to the app. 
      // this tells flutter exactly which page to show when the app boots up and how to navigate between screens. 
    );
  }
}
