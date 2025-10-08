import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:wstore/Admin/add_product.dart';
import 'package:wstore/Admin/admin_login.dart';
import 'package:wstore/page/bottomnav.dart';
import 'package:wstore/page/homepage.dart';
import 'package:wstore/page/login.dart';
import 'package:wstore/page/product_detail.dart';
import 'package:wstore/page/profile.dart';
import 'package:wstore/page/signup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Micro-Commerce App',
      theme: ThemeData(primarySwatch: Colors.green),
      home: AddProduct(),
    );
  }
}
