import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                hintText: 'Email',
              ),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Password',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loginWithEmail,
              child: const Text('Login with Email'),
            ),
            ElevatedButton(
              onPressed: _registerWithEmail,
              child: const Text('Register with Email'),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _loginWithEmail() async {
    try {
      await _auth.signInWithEmailAndPassword(
          email: _emailController.text, password: _passwordController.text);
      // User is signed in.
          Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (context) => const MyHomePage(title: '',)),
    );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        debugPrint('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        debugPrint('Wrong password provided for that user.');
      }
    }
  }

  Future<void> _registerWithEmail() async {
    try {
      await _auth.createUserWithEmailAndPassword(
          email: _emailController.text, password: _passwordController.text);

      // Insert the new user into the database
      User? user = _auth.currentUser;
      if (user != null) {
        await DatabaseHelper.instance.insertUser(
          firebaseId: user.uid,
          email: user.email ?? '',
        );
            Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (context) => const MyHomePage(title: '',)),
    );
      }
    } catch (e) {
      debugPrint('Failed to register: $e');
    }
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  DatabaseHelper._privateConstructor();

  Future<void> insertUser({
    required String firebaseId,
    required String email,
  }) async {
    // insert the user into the database
  }
}
