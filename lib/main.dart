import 'package:flutter/material.dart';
import 'package:green_object/ui/home_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:green_object/utils/high_score_store.dart';
import 'package:green_object/utils/ad_manager.dart';

// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // await Firebase.initializeApp();

  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  // FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // PlatformDispatcher.instance.onError = (error, stack) {
  //   FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  //   return true;
  // };

  await HighScoreStore.init();
  await AdManager.instance.init();

  runApp(const MultiGameApp());
}

class MultiGameApp extends StatelessWidget {
  const MultiGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini Games Collection',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1a1a2e),
        textTheme: GoogleFonts.pressStart2pTextTheme(),
        // Ensure default text color is white for dark theme if needed, but pressStart2pTextTheme handles it mostly
      ),
      home: const HomeScreen(),
    );
  }
}
