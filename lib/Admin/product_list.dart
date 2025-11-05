import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wstore/Admin/edit_product.dart';
import 'package:wstore/widget/support_widget.dart';

class AdminStockPage extends StatefulWidget {
  const AdminStockPage({Key? key}) : super(key: key);

  @override
  State<AdminStockPage> createState() => _AdminStockPageState();
}

class _AdminStockPageState extends State<AdminStockPage> {
  final String storeId = "main_store";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9F8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF46C5D3),
        elevation: 0,
        title: Text(
          "จัดการสินค้า",
          style: AppWidget.boldTextStyle().copyWith(
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: "เพิ่มสินค้าใหม่",
          )
        ],
      ),

      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("Products")
              .where("storeId", isEqualTo: storeId)
              .orderBy("createdAt", descending: true)
              .snapshots(),

          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snap.hasError) {
              return Center(
                child: Text(
                  "❌ เกิดข้อผิดพลาด: ${snap.error}",
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final docs = snap.data?.docs ?? [];

            if (docs.isEmpty) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined,
                      size: 90, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    "ยังไม่มีสินค้า",
                    style: AppWidget.semiBoldTextStyle()
                        .copyWith(fontSize: 18, color: Colors.black54),
                  ),
                ],
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                // ✅ ปรับอัตราส่วนตามหน้าจอ ป้องกัน Overflow
                double itemHeight = (constraints.maxHeight / 2.3);
                double itemWidth = constraints.maxWidth / 2;

                return Padding(
                  padding: const EdgeInsets.all(14),
                  child: GridView.builder(
                    itemCount: docs.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: itemWidth / itemHeight,
                    ),

                    itemBuilder: (context, idx) {
                      final d = docs[idx];
                      final data = d.data() as Map<String, dynamic>;

                      final images = (data['images'] is List)
                          ? List<String>.from(data['images'])
                          : (data['Image'] != null ? [data['Image']] : []);

                      final title = data['UpdatedName'] ?? data['Name'] ?? '';
                      final price = data['Price']?.toString() ?? '0';

                      int totalStock = 0;
                      if (data["variants"] is List) {
                        for (var v in data["variants"]) {
                          totalStock += (v["stock"] ?? 0) as int;
                        }
                      }

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProduct(productId: d.id),
                            ),
                          );
                        },

                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.shade100.withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(20)),
                                child: images.isNotEmpty
                                    ? Image.network(
                                        images.first,
                                        height: 120,          // ✅ ลดเพื่อไม่ให้ล้น
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        height: 120,
                                        color: Colors.grey.shade200,
                                        child: const Icon(
                                          Icons.image_not_supported,
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                                      ),
                              ),

                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Color(0xFF083344),
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    Text(
                                      "฿$price",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0284C7),
                                        fontSize: 16,
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    Text(
                                      "สต็อก: $totalStock",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    SizedBox(
                                      width: double.infinity,
                                      height: 34,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF46C5D3),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          elevation: 0,
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => EditProduct(
                                                  productId: d.id),
                                            ),
                                          );
                                        },
                                        child: const Text(
                                          "แก้ไขสินค้า",
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
