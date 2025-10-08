import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:wstore/page/Order.dart';
import 'package:wstore/page/homepage.dart';
import 'package:wstore/page/profile.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  late List<Widget> pages;

  late Home HomePage;
  late Profile ProfilePage;
  late Order OrderPage;
  int currentTabIndex = 0;

  @override
  void initState() {
    HomePage = Home();
    ProfilePage = Profile();
    OrderPage = Order();
    pages = [HomePage, OrderPage, ProfilePage];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CurvedNavigationBar(
        height: 65,
        backgroundColor: Color(0xfff2f2f2),
        color: Colors.black,
        animationDuration: Duration(milliseconds: 500),
        onTap: (int index) {
          setState(() {
            currentTabIndex = index;
          });
        },
        items: [
          Icon(Icons.home_outlined, color: Colors.white),
          Icon(Icons.shopping_cart_outlined, color: Colors.white),
          Icon(Icons.person_outline, color: Colors.white),
        ],
      ),
      body: pages[currentTabIndex],
    );
  }
}
