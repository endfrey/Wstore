import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:wstore/services/constant.dart';
import 'package:wstore/services/database.dart';
import 'package:wstore/services/shared_pref.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  String? userId;
  Stream<QuerySnapshot>? cartStream;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    userId = await SharedPreferenceHelper().getUserID();
    cartStream = await DatabaseMethods().getCart(userId!);
    setState(() {});
  }

  int _totalPrice(List<QueryDocumentSnapshot> docs) {
    int total = 0;
    for (var d in docs) {
      final data = d.data() as Map<String, dynamic>;
      int price = (data["price"] ?? 0).toInt();
      int qty = (data["qty"] ?? 1).toInt();
      total += price * qty;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF38BDF8),
        centerTitle: true,
        title: const Text(
          "My Cart",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: cartStream == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder(
              stream: cartStream,
              builder: (context, AsyncSnapshot<QuerySnapshot> snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 90, color: Colors.blue.shade300),
                        const SizedBox(height: 10),
                        Text(
                          "ตะกร้าว่างเปล่า",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.blueGrey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        itemBuilder: (_, i) => _cartItemCard(
                          docs[i].id,
                          docs[i].data() as Map<String, dynamic>,
                        ),
                      ),
                    ),
                    _bottomCheckoutBox(docs),
                  ],
                );
              },
            ),
    );
  }

  Widget _bottomCheckoutBox(List<QueryDocumentSnapshot> docs) {
    final total = _totalPrice(docs);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "รวมทั้งหมด: ฿$total",
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () => payCart(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding:
                  const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("ชำระเงิน",
                style: TextStyle(color: Colors.white, fontSize: 16)),
          )
        ],
      ),
    );
  }

  Widget _cartItemCard(String itemId, Map<String, dynamic> data) {
    final qty = (data["qty"] ?? 1).toInt();
    final price = (data["price"] ?? 0).toInt();
    final color = data["color"];
    final image = data["image"];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              image ?? "",
              width: 70,
              height: 70,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data["name"] ?? "",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (color != null) Text("สี: $color"),
                Text("฿$price",
                    style: const TextStyle(
                        color: Color(0xFF0284C7),
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: qty > 1
                        ? () {
                            DatabaseMethods().updateCartQty(
                              userId!,
                              itemId,
                              qty - 1,
                            );
                          }
                        : null,
                  ),
                  Text("$qty"),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      DatabaseMethods().updateCartQty(
                        userId!,
                        itemId,
                        qty + 1,
                      );
                    },
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  DatabaseMethods().removeFromCart(userId!, itemId);
                },
                child: const Icon(Icons.delete, color: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ Stripe Checkout
  Future<void> payCart() async {
    if (cartStream == null || userId == null) return;

    final snap = await FirebaseFirestore.instance
        .collection("Cart")
        .doc(userId)
        .collection("items")
        .get();

    if (snap.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ไม่มีสินค้าในตะกร้า")),
      );
      return;
    }

    final total = _totalPrice(snap.docs);
    final amountInCents = (total * 100).toString();

    try {
      final intent = await _createPaymentIntent(amountInCents, "THB");

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: "WStore",
          paymentIntentClientSecret: intent["client_secret"],
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      for (var doc in snap.docs) {
        final item = doc.data() as Map<String, dynamic>;

        await DatabaseMethods().createPendingOrder({
          "Product": item["name"],
          "ProductId": item["productId"],
          "StoreId": item["storeId"],
          "ProductImage": item["image"],
          "Email": await SharedPreferenceHelper().getUserEmail(),
          "Price": item["price"].toString(),
          "Quantity": item["qty"],
          "Color": item["color"],
          "Status": "Delivered",
          "createdAt": FieldValue.serverTimestamp(),
        });

        await DatabaseMethods().decrementStock(
          item["productId"],
          item["color"],
          item["qty"],
        );
      }

      await DatabaseMethods().clearCart(userId!);

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
              Text("ชำระเงินสำเร็จ",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาด: $e")),
      );
    }
  }

  Future<Map<String, dynamic>> _createPaymentIntent(
      String amount, String currency) async {
    try {
      final response = await http.post(
        Uri.parse("https://api.stripe.com/v1/payment_intents"),
        headers: {
          "Authorization": "Bearer $secretKey",
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          "amount": amount,
          "currency": currency,
          "payment_method_types[]": "card",
        },
      );

      return jsonDecode(response.body);
    } catch (err) {
      throw Exception("Stripe error: $err");
    }
  }
}
