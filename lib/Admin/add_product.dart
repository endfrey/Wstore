// lib/Admin/add_product.dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:random_string/random_string.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wstore/widget/support_widget.dart';

class AddProduct extends StatefulWidget {
  const AddProduct({super.key});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  final ImagePicker _picker = ImagePicker();

  List<File> selectedImages = [];

  final TextEditingController namecontroller = TextEditingController();
  final TextEditingController pricecontroller = TextEditingController();
  final TextEditingController detailcontroller = TextEditingController();

  final String storeId = "main_store";

  String? value;
  final List<String> categoryitem = ['Watch', 'Laptop', 'TV', 'Headphone'];

  List<Map<String, TextEditingController>> variantControllers = [];

  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    _addVariant();
  }

  // ✅ เลือกรูปหลายรูป
  Future<void> pickImages() async {
    try {
      final List<XFile>? images = await _picker.pickMultiImage(imageQuality: 80);
      if (images != null && images.isNotEmpty) {
        setState(() {
          selectedImages.addAll(images.map((img) => File(img.path)));
        });
      }
    } catch (e) {
      _err("ไม่สามารถเลือกภาพได้: $e");
    }
  }

  // ✅ เพิ่ม Variant
  void _addVariant() {
    setState(() {
      variantControllers.add({
        'color': TextEditingController(),
        'stock': TextEditingController(text: '0'),
      });
    });
  }

  void _removeVariant(int index) {
    if (variantControllers.length <= 1) return;
    setState(() {
      variantControllers[index]['color']?.dispose();
      variantControllers[index]['stock']?.dispose();
      variantControllers.removeAt(index);
    });
  }

  void _resetForm() {
    setState(() {
      selectedImages.clear();
      namecontroller.clear();
      pricecontroller.clear();
      detailcontroller.clear();
      value = null;

      for (var v in variantControllers) {
        v['color']?.dispose();
        v['stock']?.dispose();
      }
      variantControllers.clear();
      _addVariant();
    });
  }

  // ✅ parse ราคา → double
  double? _parsePrice() {
    final raw = pricecontroller.text.trim();
    if (raw.isEmpty) return null;

    return double.tryParse(raw.replaceAll(',', ''))?.toDouble();
  }

  // ✅ อัปโหลดสินค้า + แก้ปัญหาราคาเป็น 0
  Future<void> uploadItem() async {
    if (isUploading) return;

    if (selectedImages.isEmpty) {
      _err("กรุณาเลือกรูปสินค้าอย่างน้อย 1 รูป");
      return;
    }
    if (namecontroller.text.trim().isEmpty) {
      _err("กรุณากรอกชื่อสินค้า");
      return;
    }

    final parsedPrice = _parsePrice();
    if (parsedPrice == null || parsedPrice <= 0) {
      _err("กรุณากรอกราคาเป็นตัวเลขที่ถูกต้อง");
      return;
    }

    if (value == null) {
      _err("กรุณาเลือกหมวดหมู่สินค้า");
      return;
    }

    setState(() => isUploading = true);

    final productId = randomAlphaNumeric(14);
    final List<String> imageUrls = [];

    try {
      // ✅ Upload รูปทีละรูป
      for (int i = 0; i < selectedImages.length; i++) {
        final file = selectedImages[i];
        final ext = file.path.split('.').last;
        final ref = FirebaseStorage.instance.ref().child("products/$productId\_$i.$ext");

        final snapshot = await ref.putFile(file);
        final downloadURL = await snapshot.ref.getDownloadURL();
        imageUrls.add(downloadURL);
      }

      // ✅ prepare variants
      final List<Map<String, dynamic>> variants = variantControllers.map((vc) {
        final color = vc['color']?.text.trim() ?? "";
        final rawStock = vc['stock']?.text.trim() ?? "0";
        final stock = int.tryParse(rawStock) ?? 0;

        return {"color": color, "stock": stock};
      }).where((v) => (v["color"] as String).isNotEmpty).toList();

      final String searchKey = namecontroller.text.trim().isNotEmpty
          ? namecontroller.text.trim()[0].toUpperCase()
          : "";

      final Map<String, dynamic> data = {
        "productId": productId,
        "Name": namecontroller.text.trim(),
        "Image": imageUrls.isNotEmpty ? imageUrls.first : "",
        "images": imageUrls,

        // ✅ IMPORTANT — PRICE เป็น double 100%
        "Price": parsedPrice.toDouble(),    

        "Detail": detailcontroller.text.trim(),
        "SearchKey": searchKey,
        "UpdatedName": namecontroller.text.trim().toUpperCase(),
        "storeId": storeId,
        "variants": variants,
        "salesCount": 0,
        "createdAt": FieldValue.serverTimestamp(),
      };

      // ✅ Save to category
      await FirebaseFirestore.instance.collection(value!).doc(productId).set(data);

      // ✅ Save to Products
      await FirebaseFirestore.instance.collection("Products").doc(productId).set(data);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("✅ เพิ่มสินค้าสำเร็จ!", style: TextStyle(fontSize: 16)),
        ),
      );

      _resetForm();
      Navigator.pop(context);

    } catch (e) {
      _err("เกิดข้อผิดพลาดขณะอัปโหลด: $e");
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  void _err(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.red, content: Text(msg)),
    );
  }

  @override
  void dispose() {
    namecontroller.dispose();
    pricecontroller.dispose();
    detailcontroller.dispose();
    for (var v in variantControllers) {
      v['color']?.dispose();
      v['stock']?.dispose();
    }
    super.dispose();
  }

  Widget buildLabel(String text) {
    return Text(
      text,
      style: AppWidget.semiBoldTextStyle().copyWith(color: Colors.white, fontSize: 17),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(border: InputBorder.none, hintText: hint),
      ),
    );
  }

  Widget buildBoxField(TextEditingController ct, String hint, {bool number = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: ct,
        keyboardType: number ? TextInputType.number : null,
        decoration: InputDecoration(border: InputBorder.none, hintText: hint),
      ),
    );
  }

  Widget buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          items: categoryitem.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item, style: AppWidget.semiBoldTextStyle()),
            );
          }).toList(),
          onChanged: (newValue) => setState(() => value = newValue),
          value: value,
          hint: const Text("เลือกหมวดหมู่"),
        ),
      ),
    );
  }

  Widget _buildImagePreviewGrid() {
    if (selectedImages.isEmpty) return const SizedBox.shrink();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: selectedImages.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                selectedImages[index],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Positioned(
              right: -6,
              top: -6,
              child: IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red, size: 22),
                onPressed: () => setState(() => selectedImages.removeAt(index)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7AD7F0), Color(0xFF46C5D3)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white, size: 26),
                        ),
                        const Spacer(),
                        Text(
                          "Add Product",
                          style: AppWidget.boldTextStyle()
                              .copyWith(fontSize: 26, color: Colors.white),
                        ),
                        const Spacer(),
                      ],
                    ),

                    const SizedBox(height: 28),

                    buildLabel("Upload Product Images"),
                    const SizedBox(height: 12),

                    GestureDetector(
                      onTap: pickImages,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
                          ],
                        ),
                        child: Column(
                          children: const [
                            Icon(Icons.add_photo_alternate, size: 50, color: Color(0xFF0096C7)),
                            SizedBox(height: 8),
                            Text("Tap to select multiple images",
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    _buildImagePreviewGrid(),

                    const SizedBox(height: 20),

                    buildLabel("Product Name"),
                    const SizedBox(height: 8),
                    buildTextField(controller: namecontroller, hint: "ชื่อสินค้า"),

                    const SizedBox(height: 20),

                    buildLabel("Product Price"),
                    const SizedBox(height: 8),
                    buildTextField(
                      controller: pricecontroller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      hint: "ราคาสินค้า 199 หรือ 1299.50",
                    ),

                    const SizedBox(height: 20),

                    buildLabel("Product Detail"),
                    const SizedBox(height: 8),
                    buildTextField(
                        controller: detailcontroller,
                        maxLines: 6,
                        hint: "รายละเอียดสินค้า"),

                    const SizedBox(height: 20),

                    buildLabel("Product Category"),
                    const SizedBox(height: 8),
                    buildDropdown(),

                    const SizedBox(height: 25),

                    buildLabel("Variants (Color + Stock)"),
                    const SizedBox(height: 10),

                    Column(
                      children: List.generate(variantControllers.length, (index) {
                        final controllers = variantControllers[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Expanded(flex: 2,
                                  child: buildBoxField(
                                      controllers['color']!, "Color")),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: buildBoxField(
                                      controllers['stock']!, "Stock",
                                      number: true)),
                              const SizedBox(width: 10),
                              IconButton(
                                onPressed: () => _removeVariant(index),
                                icon: const Icon(Icons.remove_circle,
                                    color: Colors.red),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),

                    TextButton.icon(
                      onPressed: _addVariant,
                      icon: const Icon(Icons.add),
                      label: const Text("Add Variant"),
                    ),

                    const SizedBox(height: 20),

                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0096C7),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: isUploading ? null : uploadItem,
                        child: SizedBox(
                          height: 24,
                          child: Center(
                            child: isUploading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text(
                                    "Add Product",
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.white),
                                  ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),

          if (isUploading)
            Positioned.fill(
              child: Container(
                color: Colors.black38,
                child: const Center(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(),
                          ),
                          SizedBox(width: 16),
                          Text("Uploading...", style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
