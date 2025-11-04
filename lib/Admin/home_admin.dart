import 'package:flutter/material.dart';
import 'package:wstore/Admin/add_product.dart';
import 'package:wstore/Admin/all_orders.dart';
import 'package:wstore/widget/support_widget.dart';

class HomeAdmin extends StatefulWidget {
  const HomeAdmin({super.key});

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  final Color seaBlue = const Color(0xFF1FB5FF);
  final Color aquaBlue = const Color(0xFF00C2D1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  body: Container(
    width: double.infinity,      // ✅ เต็มความกว้าง
    height: double.infinity,     // ✅ เต็มความสูง
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF7AD7F0),
          Color(0xFF46C5D3),
        ],
      ),
    ),
    child: SafeArea(             // ✅ ป้องกันล้ำขอบจอ
      child: Column(
        children: [
          SizedBox(height: 40),
          Text(
            "Home Admin",
            style: AppWidget.boldTextStyle().copyWith(
              fontSize: 28,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 60),
          menuButton(
            icon: Icons.add,
            text: "Add Product",
            onTap: () {
              Navigator.push(context,
                MaterialPageRoute(builder: (context) => AddProduct()));
            },
          ),
          SizedBox(height: 80),
          menuButton(
            icon: Icons.shopping_cart_outlined,
            text: "All Orders",
            onTap: () {
              Navigator.push(context,
                MaterialPageRoute(builder: (context) => AllOrders()));
            },
          ),
        ],
      ),
    ),
  ),
);

  }

  // ✅ Widget ปุ่มเมนูสไตล์น้ำทะเล
  Widget menuButton({required IconData icon, required String text, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          width: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                offset: Offset(0, 3),
                blurRadius: 6,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: const Color(0xFF00B4D8), // ✅ ไอคอนสีฟ้าน้ำทะเล
              ),
              const SizedBox(width: 20),
              Text(
                text,
                style: AppWidget.boldTextStyle().copyWith(
                  fontSize: 20,
                  color: Color(0xFF0077B6), // ฟ้าน้ำทะเลเข้ม
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
