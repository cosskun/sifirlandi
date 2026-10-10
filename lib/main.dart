import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_config.dart';
import 'services/firebase_service.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Suppress yellow-black zebra stripe overflow warnings across all devices
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return const SizedBox.shrink();
  };
  
  if (FirebaseConfig.isValid) {
    try {
      await Firebase.initializeApp(
        options: FirebaseConfig.currentPlatform,
      );
    } catch (e) {
      debugPrint("Firebase Initialization Error: $e");
    }
  }
  
  await FirebaseService.initializeAuth();
  
  runApp(const MyApp());
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sıfırlandı!',
      debugShowCheckedModeBanner: false,
      scrollBehavior: MyCustomScrollBehavior(),
      
      // Setup localization for Turkish dates (intl package support)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
      ],
      
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF800020), // Burgundy
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF800020),
          primary: const Color(0xFF800020),
          secondary: const Color(0xFFB57C8A),
          surface: const Color(0xFFFAF6F0),
        ),
        scaffoldBackgroundColor: const Color(0xFFFAF6F0),
        
        // Font customization using google_fonts
        textTheme: GoogleFonts.outfitTextTheme(const TextTheme(
          displayLarge: TextStyle(color: Color(0xFF2C2526), fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: Color(0xFF4A3E3F)),
          bodyMedium: TextStyle(color: Color(0xFF4A3E3F)),
        )),
        
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFFFAF6F0),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
