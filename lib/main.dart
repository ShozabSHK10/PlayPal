import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:playpal/features/auth/auth_page.dart';
import 'package:playpal/features/home/splash_screen.dart';
import 'core/utils/theme/app_theme.dart';

// User pages
import 'package:playpal/features/home/select_location_page.dart';
import 'package:playpal/features/home/home_page.dart';
import 'package:playpal/features/settings/setting_page.dart';
import 'package:playpal/features/users/user_profile.dart';
import 'package:playpal/features/chats/group_chat.dart';
import 'package:playpal/features/matches/create_match_page.dart';
import 'package:playpal/features/home/bookings_page.dart';
import 'package:playpal/features/matches/match_details_screen.dart';
import 'package:playpal/features/users/discover_players_page.dart';
import 'package:playpal/features/home/user_announcement_page.dart';
import 'package:playpal/features/users/view_user_profile_page.dart';
import 'package:playpal/features/matches/join_match_screen.dart';
import 'package:playpal/features/auth/verify_email_page.dart';

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
