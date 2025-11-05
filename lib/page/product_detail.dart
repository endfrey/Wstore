// lib/page/product_detail.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:wstore/services/constant.dart';
import 'package:wstore/services/database.dart';
import 'package:wstore/services/shared_pref.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  String? userName, userEmail, userImage;
  Map<String, dynamic>? paymentIntent;
  String? selectedColor;
  int quantity = 1;
  bool processing = false;

  // ✅ MULTIPLE IMAGES SUPPORT
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

  // ✅ โหลดรูปสินค้าจาก Firestore
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
      final imgs = List<String>.from(doc["images"]);
      imageList = imgs;
    } else {
      imageList = [widget.image];
    }

    if (mounted) setState(() {});
  }

  Future<void> loadUser() async {
    userName = await SharedPreferenceHelper().getUserName();
    userEmail = await SharedPreferenceHelper().getUserEmail();
    userImage = await SharedPreferenceHelper().getUserImage();

    if (mounted) setState(() {});
  }

  void _autoSelectFirstColor() {
    if (widget.variants == null || widget.variants!.isEmpty) return;

    for (final v in widget.variants!) {
      final stock = int.tryParse("${v['stock']}") ?? 0;
      if (stock > 0) {
        selectedColor = v["color"]?.toString();
        quantity = 1;
        setState(() {});
        break;
      }
    }
  }

  int _unitPrice() {
    return int.tryParse(widget.price) ??
        double.tryParse(widget.price)?.round() ??
        0;
  }

  int _totalPrice() => _unitPrice() * quantity;

  int _selectedStockLocal() {
    if (widget.variants == null || widget.variants!.isEmpty) return 999999;

    if (selectedColor == null) {
      final stocks = widget.variants!
          .map((e) => int.tryParse("${e['stock']}") ?? 0)
          .toList();
      return stocks.isEmpty ? 0 : stocks.reduce((a, b) => a > b ? a : b);
    }

    final match = widget.variants!.firstWhere(
      (e) => (e["color"] ?? "").toString() == selectedColor,
      orElse: () => {"stock": 0},
    );

    return int.tryParse("${match["stock"]}") ?? 0;
  }

  bool get _allOutOfStock {
    if (widget.variants == null || widget.variants!.isNotEmpty == false)
      return false;

    return widget.variants!
        .every((v) => (int.tryParse("${v['stock']}") ?? 0) <= 0);
  }

  // ----------------------- UI -----------------------

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
            _productImage(heroTag),
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

  // ✅ MULTIPLE IMAGES CAROUSEL
  Widget _productImage(String heroTag) {
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
                itemCount: imageList.isEmpty ? 1 : imageList.length,
                onPageChanged: (i) {
                  setState(() => _currentImageIndex = i);
                },
                itemBuilder: (context, i) {
                  final img =
                      imageList.isEmpty ? widget.image : imageList[i];

                  return Image.network(img, fit: BoxFit.contain);
                },
              ),

              // ✅ Indicator
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
        boxShadow: [
          BoxShadow(color: Color(0xFFE0F2FE), blurRadius: 20, offset: Offset(0, -2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titlePrice(),
          const SizedBox(height: 15),
          _detailsText(),
          const SizedBox(height: 15),
          if (widget.variants != null && widget.variants!.isNotEmpty)
            _colorSelector(),
          const SizedBox(height: 10),
          _quantitySelector(localMax),
          const Spacer(),
          _buyNowButton(),
          const SizedBox(height: 10),
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
                    fontSize: 18,
                    color: Color(0xFF0284C7),
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text("รวม: ฿${_totalPrice()}",
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0369A1))),
          ],
        )
      ],
    );
  }

  Widget _detailsText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Details",
            style: TextStyle(
                fontSize: 18,
                color: Color(0xFF0C4A6E),
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(widget.detail,
            style: const TextStyle(
                fontSize: 15, color: Colors.black54, height: 1.4)),
      ],
    );
  }

  Widget _colorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("สีที่เลือก",
            style: TextStyle(
                fontSize: 16,
                color: Color(0xFF0C4A6E),
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: widget.variants!
              .where((v) => (int.tryParse("${v['stock']}") ?? 0) > 0)
              .map((v) {
            final c = v["color"].toString();
            final s = int.tryParse("${v['stock']}") ?? 0;

            return ChoiceChip(
              label: Text("$c ($s)"),
              selected: selectedColor == c,
              onSelected: (sel) {
                setState(() {
                  selectedColor = sel ? c : null;
                  if (quantity > s) quantity = s;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _quantitySelector(int localMax) {
    return Row(
      children: [
        const Text("จำนวน:",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(width: 12),
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
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("ถึงจำนวนสูงสุดในสต็อกแล้ว")),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (widget.variants != null && widget.variants!.isNotEmpty)
          Text("คงเหลือ: $localMax",
              style: TextStyle(
                  color: localMax <= 0 ? Colors.red : Colors.green,
                  fontSize: 14)),
      ],
    );
  }

  // ✅ BUY NOW (unchanged)
  Widget _buyNowButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF38BDF8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: processing
            ? const CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2)
            : const Text("Buy Now",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
        onPressed: processing || _allOutOfStock
            ? null
            : () async {
                if (widget.variants != null &&
                    widget.variants!.isNotEmpty &&
                    selectedColor == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("กรุณาเลือกสีสินค้า")),
                  );
                  return;
                }

                await _processOrder();
              },
      ),
    );
  }

  // ------------------- ORDER FLOW (unchanged) -------------------

  Future<void> _processOrder() async {
    setState(() => processing = true);

    final orderId = await DatabaseMethods().createPendingOrder({
      'Product': widget.name,
      'Price': _totalPrice().toString(),
      'Name': userName,
      'Email': userEmail,
      'Image': userImage,
      'ProductImage': widget.image,
      'Status': 'pending',
      'Color': selectedColor,
      'Quantity': quantity,
      'ProductId': widget.productId,
      'StoreId': widget.storeId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (orderId == null) {
      setState(() => processing = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("สร้างคำสั่งซื้อไม่สำเร็จ")));
      return;
    }

    try {
      paymentIntent =
          await createPaymentIntent(_totalPrice().toString(), 'USD');

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent?['client_secret'],
          merchantDisplayName: 'WStore',
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      final ok = await DatabaseMethods().decrementStock(
        widget.productId,
        selectedColor,
        quantity,
      );

      if (!ok) {
        await FirebaseFirestore.instance
            .collection("Orders")
            .doc(orderId)
            .update({'Status': 'error'});
        setState(() => processing = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("สต็อกไม่พอ / มีข้อผิดพลาด")));
        return;
      }

      await FirebaseFirestore.instance
          .collection("Orders")
          .doc(orderId)
          .update({'Status': 'Delivered'});

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.check_circle, color: Colors.green, size: 48),
                SizedBox(height: 12),
                Text("Payment Successful",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      }
    } on StripeException {
      await FirebaseFirestore.instance
          .collection("Orders")
          .doc(orderId)
          .update({'Status': 'cancelled'});

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Payment cancelled")));
    } catch (e) {
      await FirebaseFirestore.instance
          .collection("Orders")
          .doc(orderId)
          .update({'Status': 'error'});

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Payment error: $e")));
    }

    setState(() => processing = false);
  }

  // ------------------- STRIPE -------------------

  Future<Map<String, dynamic>?> createPaymentIntent(
      String amount, String currency) async {
    try {
      final body = {
        'amount': _toCents(amount),
        'currency': currency,
        'payment_method_types[]': 'card',
      };

      final response = await http.post(
        Uri.parse("https://api.stripe.com/v1/payment_intents"),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      return jsonDecode(response.body);
    } catch (err) {
      print("Stripe error: $err");
      return null;
    }
  }

  String _toCents(String amount) {
    final a = int.tryParse(amount) ?? 0;
    return (a * 100).toString();
  }
}
