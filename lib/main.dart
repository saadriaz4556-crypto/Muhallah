import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Local screens
import 'package:muhallah/screens/smart_search_screen.dart';
import 'screens/help_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/forgot_password.dart';
import 'screens/registration_screen.dart';
import 'screens/features_screen/panic_buttom.dart';
import 'screens/features_screen/quick_report.dart';
import 'screens/features_screen/announcements.dart';
import 'screens/features_screen/lostfound.dart';
import 'screens/features_screen/localservices.dart';
import 'screens/features_screen/add_local_service_screen.dart';
import 'screens/features_screen/marriage_event.dart';
import 'screens/features_screen/invitation_card.dart';
import 'screens/features_screen/jobs.dart';
import 'screens/features_screen/poll_voting.dart';
import 'screens/features_screen/event_donation.dart';

import 'firebase_options.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:get/get.dart';
import 'package:muhallah/features/bill_reminder/models/bill_model.dart';
import 'package:muhallah/features/bill_reminder/services/notification_service.dart';
import 'package:muhallah/features/bill_reminder/screens/bill_list_screen.dart';
import 'package:muhallah/services/fcm_token_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize FCM Token handler
    FcmTokenService.instance.initialize();
    
    // Initialize Hive
    await Hive.initFlutter();
    Hive.registerAdapter(BillModelAdapter());
    
    // Initialize Notifications
    await NotificationService.initializeNotifications();
    
    print('✅ Firebase & Services initialized successfully');
  } catch (e, st) {
    print('❌ Initialization failed: $e\n$st');
  }
  runApp(const MyApp());
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (snapshot.hasData) {
          print('User is logged in: ${snapshot.data!.uid}');
          return const HomeScreeen();
        } else {
          print('No user is logged in.');
        }
        return const LoginScreen();
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Digital Muhallah',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF252A34),
        fontFamily: 'Montserrat',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF252A34),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF08D9D6)),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFEAEAEA)),
          bodyMedium: TextStyle(color: Color(0xFFEAEAEA)),
          titleLarge: TextStyle(color: Color(0xFFEAEAEA)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF252A34),
          selectedItemColor: Color(0xFF08D9D6),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: const HomeScreeen(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/registration_screen': (context) => const RegistrationFlow(),
        '/forgot_password': (context) => const ForgotPasswordFlow(),
        '/home': (context) => const HomeScreeen(),
        '/panic_button': (context) => const PanicApp(),
        '/quick_report': (context) => const QuickReportApp(),
        '/announcements': (context) => const AnnouncementApp(),
        '/lostfound': (context) => const LostFoundApp(),
        '/merriage_event': (context) => const MarriageEventsScreen(),
        '/invitation_card': (context) => const InvitationCardScreen(),
        '/localservices': (context) => const LocalServicesScreen(),
        '/add_service': (context) => const AddLocalServiceScreen(),
        '/bill_remminder': (context) => BillListScreen(),
        '/jobs': (context) => const JobsApp(),
        '/poll_voting': (context) => const PollsVotingApp(),
        '/event_donation': (context) => const EventsDonationsApp(),
        '/smart_search': (context) => const SmartSearchScreen(),
        '/smart-search': (context) => const SmartSearchScreen(),
        '/help': (context) => const HelpScreen(),
      },
    );
  }
}
