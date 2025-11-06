import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wstore/services/database.dart';
import 'package:intl/intl.dart';

class AllOrders extends StatefulWidget {
  const AllOrders({super.key});

  @override
  State<AllOrders> createState() => _AllOrdersState();
}

class _AllOrdersState extends State<AllOrders> {
  Stream<QuerySnapshot>? orderStream;

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  loadOrders() async {
    orderStream = await DatabaseMethods().allOrder();
    setState(() {});
  }

  String formatDate(Timestamp? ts) {
    if (ts == null) return "-";
    return DateFormat("dd MMM yyyy • HH:mm").format(ts.toDate());
  }

  Future<bool> showConfirmDialog() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ยืนยันสถานะ"),
        content: const Text("ต้องการทำออเดอร์นี้เป็น “Delivered” ไหม?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("ยกเลิก"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("ยืนยัน"),
          ),
        ],
      ),
    );
  }

  // ✅ Badge
  Widget buildStatusBadge(String? status) {
    status ??= "Pending";

    Map<String, dynamic> map = {
      "Delivered": {
        "bg": Colors.green.shade100,
        "text": Colors.green.shade700,
        "icon": Icons.check_circle,
      },
      "Shipping": {
        "bg": Colors.orange.shade100,
        "text": Colors.orange.shade700,
        "icon": Icons.local_shipping,
      },
      "Cancelled": {
        "bg": Colors.red.shade100,
        "text": Colors.red.shade700,
        "icon": Icons.cancel,
      },
      "Refunded": {
        "bg": Colors.purple.shade100,
        "text": Colors.purple.shade700,
        "icon": Icons.cached,
      },
    };

    final cfg =
        map[status] ??
        {
          "bg": Colors.blue.shade100,
          "text": Colors.blue.shade700,
          "icon": Icons.pending,
        };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cfg["bg"],
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(cfg["icon"], size: 14, color: cfg["text"]),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: cfg["text"],
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ การ์ดออเดอร์ แสดงราคา x จำนวน อย่างถูกต้อง
  Widget orderCard(DocumentSnapshot ds) {
    final data = ds.data() as Map<String, dynamic>;

    String name = data["Product"] ?? data["productName"] ?? "ไม่พบชื่อสินค้า";

    // ✅ ราคา / ชิ้น
    double price = ((data["Price"] ?? data["price"] ?? 0) as num).toDouble();

    // ✅ จำนวน
    int qty = ((data["quantity"] ?? data["qty"] ?? 1) as num).toInt();

    // ✅ ราคารวม
    double total = price * qty;

    String image = data["ProductImage"] ?? data["image"] ?? "";
    String email = data["Email"] ?? data["userEmail"] ?? "";
    String status = data["Status"] ?? data["status"] ?? "Pending";

    Timestamp? orderDate =
        data["OrderDate"] ?? data["orderDate"] ?? data["date"];

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
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported, size: 40),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

                // ✅ ราคา x จำนวน = รวม
                Text(
                  "฿${price.toStringAsFixed(0)}  x  $qty  =  ฿${total.toStringAsFixed(0)}",
                  style: const TextStyle(
                    color: Color(0xFF0284C7),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    const Icon(
                      Icons.email_outlined,
                      size: 18,
                      color: Color(0xFF38BDF8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      email,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: Color(0xFF38BDF8),
                    ),
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
                buildStatusBadge(status),
                const SizedBox(height: 16),

                if (status != "Delivered")
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        bool ok = await showConfirmDialog();
                        if (ok) {
                          await DatabaseMethods().updateStatus(ds.id);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF38BDF8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "ทำรายการเสร็จสิ้น",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildOrders() {
    return StreamBuilder(
      stream: orderStream,
      builder: (context, AsyncSnapshot snap) {
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final docs = snap.data.docs;

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              "ยังไม่มีออเดอร์",
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (_, i) => orderCard(docs[i]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7AD7F0),
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      "All Orders",
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: buildOrders(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
