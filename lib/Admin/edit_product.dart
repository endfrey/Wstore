// lib/Admin/edit_product.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wstore/widget/support_widget.dart';

class EditProduct extends StatefulWidget {
  final String productId;
  const EditProduct({Key? key, required this.productId}) : super(key: key);

  @override
  State<EditProduct> createState() => _EditProductState();
}

class _EditProductState extends State<EditProduct> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  bool loading = true;
  bool saving = false;

  // product fields
  TextEditingController? nameController;
  TextEditingController? priceController;
  TextEditingController? detailController;
  List<String> images = [];
  List<Map<String, dynamic>> variants = []; // each: {'color': '', 'stock': 0}

  // controllers for variant editing
  List<TextEditingController> variantColorControllers = [];
  List<TextEditingController> variantStockControllers = [];

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() => loading = true);
    final doc =
        await _firestore.collection('Products').doc(widget.productId).get();
    if (!doc.exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ไม่พบสินค้า"), backgroundColor: Colors.red),
        );
        Navigator.pop(context);
      }
      return;
    }
    final data = doc.data()!;
    nameController = TextEditingController(text: data['Name'] ?? '');
    priceController = TextEditingController(text: (data['Price'] ?? '').toString());
    detailController = TextEditingController(text: data['Detail'] ?? '');
    images = (data['images'] is List)
        ? List<String>.from(data['images'])
        : (data['Image'] != null ? [data['Image'].toString()] : []);
    final rawVariants = (data['variants'] is List) ? List.from(data['variants']) : [];
    variants = rawVariants
        .map((e) => {
              'color': e['color'] ?? '',
              'stock': (e['stock'] is int) ? e['stock'] : int.tryParse("${e['stock']}") ?? 0
            })
        .toList();

    variantColorControllers =
        variants.map((v) => TextEditingController(text: v['color'] ?? '')).toList();
    variantStockControllers =
        variants.map((v) => TextEditingController(text: (v['stock'] ?? 0).toString())).toList();

    setState(() => loading = false);
  }

  Future<void> _pickAndUploadImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked == null) return;
    final file = File(picked.path);

    final fileName = DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
    final ref = _storage.ref().child('products/${widget.productId}/$fileName');

    final uploadTask = await ref.putFile(file);
    final url = await uploadTask.ref.getDownloadURL();

    images.add(url);
    setState(() {});
  }

  Future<void> _deleteImageAt(int idx) async {
    final url = images[idx];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("ลบรูปภาพ"),
        content: const Text("ต้องการลบรูปภาพนี้หรือไม่?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("ยกเลิก")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("ลบ")),
        ],
      ),
    );
    if (confirm != true) return;

    // ลบจาก storage (ถ้าเป็น URL ของ storage)
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {
      // ไม่บังคับว่าต้องลบได้เสมอ
    }

    images.removeAt(idx);
    setState(() {});
  }

  void _addVariantRow() {
    variantColorControllers.add(TextEditingController());
    variantStockControllers.add(TextEditingController(text: '0'));
    setState(() {});
  }

  void _removeVariantRow(int idx) {
    if (variantColorControllers.length <= 1) return;
    variantColorControllers[idx].dispose();
    variantStockControllers[idx].dispose();
    variantColorControllers.removeAt(idx);
    variantStockControllers.removeAt(idx);
    setState(() {});
  }

  Future<void> _saveProduct() async {
    if (nameController == null || priceController == null || detailController == null) return;

    final name = nameController!.text.trim();
    final price = priceController!.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("กรุณากรอกชื่อสินค้า"), backgroundColor: Colors.red));
      return;
    }

    setState(() => saving = true);

    // prepare variants
    final List<Map<String, dynamic>> newVariants = [];
    for (int i = 0; i < variantColorControllers.length; i++) {
      final c = variantColorControllers[i].text.trim();
      final s = int.tryParse(variantStockControllers[i].text.trim()) ?? 0;
      if (c.isNotEmpty) newVariants.add({'color': c, 'stock': s});
    }

    final payload = {
      'Name': name,
      'UpdatedName': name.toUpperCase(),
      'Price': price,
      'Detail': detailController!.text.trim(),
      'images': images,
      'variants': newVariants,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await _firestore.collection('Products').doc(widget.productId).update(payload);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("บันทึกสำเร็จ"), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("เกิดข้อผิดพลาด: $e"), backgroundColor: Colors.red));
    }

    setState(() => saving = false);
  }

  @override
  void dispose() {
    nameController?.dispose();
    priceController?.dispose();
    detailController?.dispose();
    for (var c in variantColorControllers) c.dispose();
    for (var c in variantStockControllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF46C5D3),
        elevation: 0,
        title: Text(
          loading ? "กำลังโหลด..." : (nameController?.text ?? "Edit Product"),
          style: AppWidget.boldTextStyle().copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: saving ? null : _saveProduct,
          )
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // images section
                  const Text("รูปสินค้า", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length + 1,
                      itemBuilder: (context, i) {
                        if (i == images.length) {
                          // add button
                          return GestureDetector(
                            onTap: _pickAndUploadImage,
                            child: Container(
                              width: 110,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4)
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.add_a_photo, color: Color(0xFF0284C7)),
                                  SizedBox(height: 6),
                                  Text("เพิ่มรูป", style: TextStyle(color: Colors.black54))
                                ],
                              ),
                            ),
                          );
                        }

                        final url = images[i];
                        return Stack(
                          children: [
                            Container(
                              width: 110,
                              margin: const EdgeInsets.only(right: 12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(url, height: 110, width: 110, fit: BoxFit.cover),
                              ),
                            ),
                            Positioned(
                              right: 6,
                              top: 6,
                              child: InkWell(
                                onTap: () => _deleteImageAt(i),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),

                  // name
                  const Text("ชื่อสินค้า", style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(controller: nameController, decoration: const InputDecoration(border: OutlineInputBorder())),
                  const SizedBox(height: 12),

                  // price
                  const Text("ราคา", style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),

                  // detail
                  const Text("รายละเอียด", style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: detailController,
                    maxLines: 4,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),

                  // variants
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Variants (สี + สต็อก)", style: TextStyle(fontWeight: FontWeight.w600)),
                      TextButton.icon(
                        onPressed: _addVariantRow,
                        icon: const Icon(Icons.add),
                        label: const Text("เพิ่มสี"),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: List.generate(variantColorControllers.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: variantColorControllers[i],
                                decoration: const InputDecoration(
                                  labelText: "สี",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: variantStockControllers[i],
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: "สต็อก",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _removeVariantRow(i),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.remove_circle, color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: saving ? null : _saveProduct,
                      icon: saving ? const SizedBox.shrink() : const Icon(Icons.save),
                      label: saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text("บันทึกสินค้า"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF46C5D3),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}
