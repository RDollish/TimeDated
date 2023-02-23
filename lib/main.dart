import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'reminder_form.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_screen.dart';

void main() async {
  // Initialize Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      return MaterialApp(
        title: 'TimeDated',
        theme: ThemeData(
          primarySwatch: Colors.pink,
        ),
        home: const MyHomePage(title: 'TimeDated'),
      );
    } else {
      return MaterialApp(
        title: 'TimeDated',
        theme: ThemeData(
          primarySwatch: Colors.pink,
        ),
        home: const LoginScreen(),
      );
    }
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReminderFormPage(),
                  ),
                );
              },
              child: const Text('Add Reminder'),
            ),
          ],
        ),
      ),
    );
  }
}
