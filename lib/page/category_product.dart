// lib/page/category_product.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wstore/page/product_detail.dart';

class CategoryProduct extends StatelessWidget {
  final String category;
  const CategoryProduct({Key? key, required this.category}) : super(key: key);

  Widget buildProductCard(BuildContext context, Map<String, dynamic> p, String id) {
    // ✅ ดึงรูปหลายรูป (images) จาก Firestore
    final List<String> images =
        (p['images'] != null && p['images'] is List)
            ? List<String>.from(p['images'])
            : (p['Image'] != null ? [p['Image']] : []);

    final variants = (p['variants'] is List)
        ? List<Map<String, dynamic>>.from(p['variants'])
        : null;

    final firstImg = images.isNotEmpty ? images[0] : "";
    final name = p['Name'] ?? '';
    final price = p['Price']?.toString() ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetail(
              image: firstImg,
              name: name,
              price: price,
              detail: p['Detail'] ?? '',
              productId: id,
              storeId: p['storeId'],
              variants: variants,
            ),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: (firstImg.startsWith('http')
                  ? Image.network(firstImg,
                      height: 120, width: double.infinity, fit: BoxFit.cover)
                  : Image.asset(
                      firstImg.isNotEmpty
                          ? firstImg
                          : 'assets/images/placeholder.png',
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                price.isNotEmpty ? '฿$price' : '฿0',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coll = FirebaseFirestore.instance.collection(category);

    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: StreamBuilder<QuerySnapshot>(
        stream: coll.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty)
            return Center(child: Text('ไม่มีสินค้าหมวด $category'));

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: docs.length,
            itemBuilder: (context, idx) {
              final d = docs[idx];
              final data = d.data() as Map<String, dynamic>;
              return buildProductCard(context, data, d.id);
            },
          );
        },
      ),
    );
  }
}
