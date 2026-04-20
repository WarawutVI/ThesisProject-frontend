import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final user =FirebaseAuth.instance.currentUser;
  void sigout()async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: Center(
        child: Text('Welcome to ${user!.email}'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:(()=> sigout()),
        child: const Icon(Icons.logout),
      ),
    );
  }
}