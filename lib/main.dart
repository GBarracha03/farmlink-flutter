import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projeto/src/auth/authentication_page.dart';
import 'package:projeto/src/home/home_menu.dart';
import 'package:projeto/src/notifications/notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().initNotification();
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
      print('\n\n\n');
      print(user);

      if (user == null) {
        _navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthenticationPage()),
        );
      } else {
        _navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(builder: (_) => HomeMenu(userId: user.uid)),
        );
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      theme: ThemeData(
        primaryColor: const Color(0xFF2A815E),
        primarySwatch: Colors.green,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final user = snapshot.data;

          if (user == null) {
            return const AuthenticationPage();
          } else {
            return HomeMenu(userId: user.uid);
          }
        },
      ),
    );
  }
}
