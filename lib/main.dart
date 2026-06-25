import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/interest_picker_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/saved/saved_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load .env before anything else so API keys are available app-wide.
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if user is already logged in
    final currentUser = FirebaseAuth.instance.currentUser;
    final Widget initialScreen =
        currentUser != null ? const HomeScreen() : const LoginScreen();

    return MaterialApp(
      title: 'EdTech App',
      debugShowCheckedModeBanner: false,
      home: initialScreen,
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/onboarding': (context) => const InterestPickerScreen(),
        '/search': (context) => const SearchScreen(),
        '/saved': (context) => const SavedScreen(),
      },
    );
  }
}
