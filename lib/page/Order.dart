// lib/page/order.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wstore/services/database.dart';
import 'package:wstore/services/shared_pref.dart';
import 'package:intl/intl.dart';

class Order extends StatefulWidget {
  const Order({super.key});

  @override
  State<Order> createState() => _OrderState();
}

class _OrderState extends State<Order> {
  String? email;
  Stream? orderStream;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  loadData() async {
    email = await SharedPreferenceHelper().getUserEmail();
    orderStream = await DatabaseMethods().getOrders(email!);
    setState(() {});
  }

  String formatDate(Timestamp? ts) {
    if (ts == null) return "-";
    final date = ts.toDate();
    return DateFormat("dd MMM yyyy • HH:mm").format(date);
  }

  // ✅ สถานะแบบ professional
  Widget buildStatusBadge(String? status) {
    status = status ?? "Pending";

    Color bg;
    Color text;
    IconData icon;

    switch (status) {
      case "Delivered":
        bg = Colors.green.shade100;
        text = Colors.green.shade700;
        icon = Icons.check_circle;
        break;

      case "Shipping":
        bg = Colors.orange.shade100;
        text = Colors.orange.shade700;
        icon = Icons.local_shipping;
        break;

      case "Cancelled":
        bg = Colors.red.shade100;
        text = Colors.red.shade700;
        icon = Icons.cancel;
        break;

      case "Refunded":
        bg = Colors.purple.shade100;
        text = Colors.purple.shade700;
        icon = Icons.cached;
        break;

      default:
        bg = Colors.blue.shade100;
        text = Colors.blue.shade700;
        icon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: text),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: text,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Card ดีไซน์ใหม่
  Widget orderCard(DocumentSnapshot ds) {
    final data = ds.data() as Map<String, dynamic>;

    final String name = data["Product"] ?? "ไม่พบชื่อสินค้า";
    final String price = data["Price"]?.toString() ?? "0";
    final String image = data["ProductImage"] ?? "";
    final Timestamp? orderDate = data["OrderDate"];
    final String status = data["Status"] ?? "Pending";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // ✅ รูปสินค้า
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: image.isNotEmpty
                ? Image.network(
                    image,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 150,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child:
                        const Icon(Icons.image_not_supported, size: 40),
                  ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ ชื่อสินค้า
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0C4A6E),
                  ),
                ),

                const SizedBox(height: 6),

                // ✅ ราคา
                Text(
                  "฿$price",
                  style: const TextStyle(
                    color: Color(0xFF0284C7),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                // ✅ วันที่
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: Color(0xFF38BDF8), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      formatDate(orderDate),
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ✅ สถานะ
                buildStatusBadge(status),

                const SizedBox(height: 16),

                // ✅ ปุ่มชุดล่าง (2 ปุ่ม)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF38BDF8)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          // TODO: ไปหน้า product detail
                        },
                        child: const Text(
                          "ดูรายละเอียด",
                          style: TextStyle(
                              color: Color(0xFF0284C7),
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF38BDF8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          // TODO: chat กับร้าน
                        },
                        child: const Text(
                          "ติดต่อร้าน",
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget orderList() {
    return StreamBuilder(
      stream: orderStream,
      builder: (context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
          );
        }

        final docs = snapshot.data.docs;

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_toggle_off,
                    size: 90, color: Colors.blue.shade200),
                const SizedBox(height: 10),
                Text(
                  "ยังไม่มีออเดอร์",
                  style: TextStyle(
                      fontSize: 18, color: Colors.blueGrey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: docs.length,
          itemBuilder: (context, i) => orderCard(docs[i]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF38BDF8),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "My Orders",
          style: TextStyle(
              fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: orderList(),
      ),
    );
  }
}
