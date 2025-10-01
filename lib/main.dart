import 'package:flutter/material.dart';
import 'package:wstore/page/homepage.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Micro-Commerce App',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: Home(), //
    );
  }
}
