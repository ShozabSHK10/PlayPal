import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:playpal/pages/auth_page.dart';
import 'package:playpal/pages/splash_screen.dart';
import 'core/theme/app_theme.dart';

// User pages
import 'package:playpal/pages/select_location_page.dart';
import 'package:playpal/pages/home_page.dart';
import 'package:playpal/pages/setting_page.dart';
import 'package:playpal/pages/user_profile.dart';
import 'package:playpal/pages/group_chat.dart';
import 'package:playpal/pages/create_match_page.dart';
import 'package:playpal/pages/bookings_page.dart';
import 'package:playpal/pages/match_details_screen.dart';
import 'package:playpal/pages/discover_players_page.dart';
import 'package:playpal/pages/user_announcement_page.dart';
import 'package:playpal/pages/view_user_profile_page.dart';
import 'package:playpal/pages/join_match_screen.dart';
import 'package:playpal/pages/verify_email_page.dart';

// Admin pages

/// Must be a top-level function
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('🔔 Handling background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ensure Firebase is initialized before proceeding
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Firebase App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );

  // Firebase Messaging Setup
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      print('Foreground message: ${message.notification!.title}');
    }
  });

  // Request for Notification Permission
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  print('User granted permission: ${settings.authorizationStatus}');

  // Run the App
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthPage(),
      builder: (context, child) {
        return Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) => child!,
            ),
          ],
        );
      },
      // Define routes for navigation
      routes: {
        '/home': (context) => HomePage(),
        '/splash': (context) => SplashScreen(),
        '/settings': (context) => SettingsPage(),
        '/profile': (context) => ProfilePage(),
        '/groupChat': (context) => ChatsPage(),
        '/createMatch': (context) => CreateMatchPage(),
        '/myBookings': (context) => BookingsPage(),
        '/selectLocation': (context) => SelectLocationScreen(),
        '/verifyEmail': (context) => VerifyEmailPage(),
        '/matchDetails': (context) {
          final matchId = ModalRoute.of(context)!.settings.arguments as String;
          return MatchDetailsScreen(matchId: matchId);
        },
        '/announcements': (context) => const UserAnnouncementsPage(),
        '/discoverPlayers': (context) => const DiscoverPlayersPage(),
        '/viewUserProfile': (context) {
          final userId = ModalRoute.of(context)!.settings.arguments as String;
          return ViewUserProfilePage(userId: userId);
        },
        '/joinMatch': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return JoinMatchScreen(
            matchId: args['matchId'] as String,
            maxPlayers: args['maxPlayers'] as int,
            members: args['members'] as List,
          );
        },
      },
    );
  }
}
