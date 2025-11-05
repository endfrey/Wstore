import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:wstore/Admin/add_product.dart';
import 'package:wstore/Admin/admin_login.dart';
import 'package:wstore/Admin/all_orders.dart';
import 'package:wstore/Admin/home_admin.dart';
import 'package:wstore/page/Order.dart';
import 'package:wstore/page/bottomnav.dart';
import 'package:wstore/page/category_product.dart';
import 'package:wstore/page/homepage.dart';
import 'package:wstore/page/login.dart';
import 'package:wstore/page/product_detail.dart';
import 'package:wstore/page/profile.dart';
import 'package:wstore/page/signup.dart';

import 'package:wstore/services/constant.dart';
import 'package:wstore/services/store_setup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey = publishableKey;
  await Firebase.initializeApp();

  // ✅ Init store data
  await StoreSetup.initializeStoreData();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WStore',
      theme: ThemeData(primarySwatch: Colors.green),

      // ✅ เข้าหน้าโฮมปกติ (มี BottomNav และ Chat อยู่แล้ว)
      home: const HomeAdmin(),
    );
  }
}
