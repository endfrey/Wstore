// lib/page/product_detail.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wstore/services/database.dart';
import 'package:wstore/services/shared_pref.dart';

class ProductDetail extends StatefulWidget {
  final String image, name, price, detail;
  final String? productId;
  final String? storeId;
  final List<Map<String, dynamic>>? variants;

  const ProductDetail({
    required this.image,
    required this.name,
    required this.price,
    required this.detail,
    this.productId,
    this.storeId,
    this.variants,
    Key? key,
  }) : super(key: key);

  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  String? userId, userEmail, userName, userImage;
  String? selectedColor;
  int quantity = 1;

  List<String> imageList = [];
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    loadUser();
    _loadImages();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSelectFirstColor();
    });
  }

  Future<void> loadUser() async {
    userId = await SharedPreferenceHelper().getUserID();
    userName = await SharedPreferenceHelper().getUserName();
    userEmail = await SharedPreferenceHelper().getUserEmail();
    userImage = await SharedPreferenceHelper().getUserImage();
    setState(() {});
  }

  Future<void> _loadImages() async {
    if (widget.productId == null) {
      imageList = [widget.image];
      setState(() {});
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection("Products")
        .doc(widget.productId)
        .get();

    if (doc.exists && doc.data()!["images"] != null) {
      imageList = List<String>.from(doc["images"]);
    } else {
      imageList = [widget.image];
    }

    setState(() {});
  }

  void _autoSelectFirstColor() {
    if (widget.variants == null || widget.variants!.isEmpty) return;

    for (final v in widget.variants!) {
      final stock = int.tryParse("${v['stock']}") ?? 0;
      if (stock > 0) {
        selectedColor = v["color"].toString();
        quantity = 1;
        setState(() {});
        break;
      }
    }
  }

  int _unitPrice() => int.tryParse(widget.price) ?? 0;

  int _totalPrice() => _unitPrice() * quantity;

  int _selectedStockLocal() {
    if (widget.variants == null || widget.variants!.isEmpty) return 999999;

    if (selectedColor == null) return 0;

    final match = widget.variants!.firstWhere(
      (e) => e["color"].toString() == selectedColor,
      orElse: () => {"stock": 0},
    );

    return int.tryParse("${match["stock"]}") ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final heroTag = widget.productId ?? widget.image;
    final localMax = _selectedStockLocal();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      body: SafeArea(
        child: Column(
          children: [
            _backButton(),
            _productImages(heroTag),
            Expanded(child: _detailSection(localMax)),
          ],
        ),
      ),
    );
  }

  Widget _backButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.blue.shade100.withOpacity(0.5),
                    blurRadius: 8)
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: Color(0xFF0C4A6E), size: 20),
          ),
        ),
      ]),
    );
  }

  Widget _productImages(String heroTag) {
    return Hero(
      tag: heroTag,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade100.withOpacity(0.4),
              blurRadius: 15,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              PageView.builder(
                itemCount: imageList.length,
                onPageChanged: (i) {
                  setState(() => _currentImageIndex = i);
                },
                itemBuilder: (context, i) {
                  return Image.network(
                    imageList[i],
                    fit: BoxFit.contain,
                  );
                },
              ),
              if (imageList.length > 1)
                Positioned(
                  bottom: 12,
                  child: Row(
                    children: List.generate(
                      imageList.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _currentImageIndex == i ? 12 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _currentImageIndex == i
                              ? Colors.white
                              : Colors.white54,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailSection(int localMax) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titlePrice(),
          const SizedBox(height: 15),
          _details(),
          const SizedBox(height: 15),
          if (widget.variants != null && widget.variants!.isNotEmpty)
            _colorSelector(),
          const SizedBox(height: 10),
          _quantitySelector(localMax),
          const Spacer(),
          _addToCartButton(),
        ],
      ),
    );
  }

  Widget _titlePrice() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(widget.name,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0C4A6E))),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("฿${widget.price}",
                style: const TextStyle(
                  color: Color(0xFF0284C7),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 5),
            Text("รวม: ฿${_totalPrice()}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0369A1),
                )),
          ],
        )
      ],
    );
  }

  Widget _details() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Details",
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF0C4A6E),
              fontWeight: FontWeight.w600,
            )),
        const SizedBox(height: 6),
        Text(widget.detail,
            style: const TextStyle(fontSize: 15, color: Colors.black54)),
      ],
    );
  }

  Widget _colorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("สี",
            style: TextStyle(
                fontSize: 16,
                color: Color(0xFF0C4A6E),
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: widget.variants!
              .map((v) {
                final c = v["color"].toString();
                final s = int.tryParse("${v["stock"]}") ?? 0;

                if (s <= 0) return const SizedBox();

                return ChoiceChip(
                  label: Text("$c ($s)"),
                  selected: selectedColor == c,
                  onSelected: (_) {
                    setState(() {
                      selectedColor = c;
                      quantity = 1;
                    });
                  },
                );
              })
              .whereType<Widget>()
              .toList(),
        ),
      ],
    );
  }

  Widget _quantitySelector(int localMax) {
    return Row(
      children: [
        const Text("จำนวน:",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(width: 15),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed:
                    quantity > 1 ? () => setState(() => quantity--) : null,
              ),
              Text("$quantity", style: const TextStyle(fontSize: 16)),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  if (quantity < localMax) {
                    setState(() => quantity++);
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text("คงเหลือ: $localMax",
            style: TextStyle(
              fontSize: 14,
              color: localMax <= 0 ? Colors.red : Colors.green,
            )),
      ],
    );
  }

  // ✅ ✅ NEW BUTTON: Add To Cart
  Widget _addToCartButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          "Add to Cart",
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white),
        ),
        onPressed: () async {
          if (widget.variants != null &&
              widget.variants!.isNotEmpty &&
              selectedColor == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("กรุณาเลือกสีสินค้า")),
            );
            return;
          }

          await DatabaseMethods().addToCart(userId!, {
            "productId": widget.productId,
            "name": widget.name,
            "image": widget.image,
            "price": _unitPrice(),
            "qty": quantity,
            "color": selectedColor,
            "addedAt": FieldValue.serverTimestamp(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("เพิ่มลงตะกร้าสำเร็จ ✅"),
              duration: Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }
}
