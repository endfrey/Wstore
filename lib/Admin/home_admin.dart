import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wstore/Admin/product_list.dart';
import 'package:wstore/Admin/sales_analytics.dart';
import 'package:wstore/Admin/add_product.dart';
import 'package:wstore/Admin/all_orders.dart';
import 'package:wstore/Chat/chat_list_page.dart';
import 'package:wstore/page/login.dart';
import 'package:wstore/widget/support_widget.dart';

class HomeAdmin extends StatefulWidget {
  const HomeAdmin({super.key});

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  String storeName = "WStore"; 
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadStoreData();
  }

  Future<void> loadStoreData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("store")
          .doc("main_store")
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          storeName = data['name'] ?? "WStore";
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // ✅ Popup ยืนยันการออกจากระบบ
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          "ออกจากระบบ",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบแอดมิน?"),
        actions: [
          TextButton(
            child: const Text("ยกเลิก"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("ออกจากระบบ", style: TextStyle(color: Colors.white)),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LogIn()),
                (_) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB2EBF2), Color(0xFF4DD0E1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),

                      // ✅ โลโก้ร้าน
                      Center(
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.white,
                          backgroundImage: const AssetImage(
                            "assets/images/w.jpg",
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ✅ ชื่อร้าน
                      Text(
                        storeName,
                        style: AppWidget.boldTextStyle().copyWith(
                          fontSize: 24,
                          color: const Color(0xFF01579B),
                        ),
                      ),

                      const SizedBox(height: 4),
                      const Text(
                        "Admin Dashboard",
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),

                      const SizedBox(height: 24),

                      // ✅ เมนูหลัก
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 20,
                          childAspectRatio: 1,
                          children: [
                            dashboardCard(
                              icon: Icons.add_box_outlined,
                              label: "เพิ่มสินค้า",
                              color: const Color(0xFF00BCD4),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AddProduct(),

                                  ),
                                );
                              },
                            ),
                            dashboardCard(
                              icon: Icons.inventory_2_outlined,
                              label: "สต็อกสินค้า",
                              color: const Color(0xFF0097A7),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AdminStockPage(),
                                  ),
                                );
                              },
                            ),
                            dashboardCard(
                              icon: Icons.shopping_cart_outlined,
                              label: "ออเดอร์ทั้งหมด",
                              color: const Color(0xFF00838F),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AllOrders(),
                                  ),
                                );
                              },
                            ),
                            
                            dashboardCard(
                              icon: Icons.chat_bubble_outline,
                              label: "แชทกับลูกค้า",
                              color: const Color(0xFF26A69A),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ChatListPage(),
                                  ),
                                );
                              },
                            ),
                            dashboardCard(
                              icon: Icons.analytics_outlined,
                              label: "สถิติการขาย",
                              color: const Color(0xFF00ACC1),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SalesAnalyticsPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // ✅ ปุ่ม LOG OUT แบบพรีเมียม
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _confirmLogout,
                          icon: const Icon(Icons.logout, color: Colors.white),
                          label: const Text(
                            "ออกจากระบบ",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 4,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                      Text(
                        "WStore • Admin Panel",
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget dashboardCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppWidget.boldTextStyle().copyWith(
                fontSize: 16,
                color: const Color(0xFF01579B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
