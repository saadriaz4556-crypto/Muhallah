import 'package:flutter/material.dart';

void main() {
  runApp(const BillRemindersApp());
}
class BillRemindersApp extends StatelessWidget {
  const BillRemindersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false, // hides debug banner
      home: HelloWorldScreen(),
    );
  }
}

class HelloWorldScreen extends StatelessWidget {
  const HelloWorldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('we are still working on this screen'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'We are still working on this screen',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
