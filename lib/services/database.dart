import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DatabaseMethods {
  // ===============================================================
  // ✅ STORE
  // ===============================================================
  Future<DocumentSnapshot> getStoreInfo(String storeId) async {
    return FirebaseFirestore.instance.collection("store").doc(storeId).get();
  }

  Future<void> updateStoreInfo(
    String storeId,
    Map<String, dynamic> data,
  ) async {
    return FirebaseFirestore.instance
        .collection("store")
        .doc(storeId)
        .set(data, SetOptions(merge: true));
  }

  // ===============================================================
  // ✅ CHAT ROOMS
  // ===============================================================
  Future<void> createChatRoom(
    Map<String, dynamic> chatRoomData,
    String id,
  ) async {
    return FirebaseFirestore.instance
        .collection("chatRooms")
        .doc(id)
        .set(chatRoomData, SetOptions(merge: true));
  }

  Future<Stream<QuerySnapshot>> getChatRooms(String userId) async {
    return FirebaseFirestore.instance
        .collection("chatRooms")
        .where("users", arrayContains: userId)
        .snapshots();
  }

  // ===============================================================
  // ✅ USERS
  // ===============================================================
  Future addUserDetails(Map<String, dynamic> userInfo, String id) async {
    return FirebaseFirestore.instance.collection("users").doc(id).set(userInfo);
  }

  // ===============================================================
  // ✅ PRODUCTS
  // ===============================================================
  Future addAllProducts(Map<String, dynamic> data) async {
    return FirebaseFirestore.instance.collection("Products").add(data);
  }

  Future<List<Map<String, dynamic>>> getProductsByStore(String storeId) async {
    final snap = await FirebaseFirestore.instance
        .collection('Products')
        .where('storeId', isEqualTo: storeId)
        .get();

    return snap.docs.map((d) => d.data()).toList();
  }

  Future addProduct(Map<String, dynamic> data, String category) async {
    return FirebaseFirestore.instance.collection(category).add(data);
  }

  Future<Stream<QuerySnapshot>> getProducts(String category) async {
    return FirebaseFirestore.instance.collection(category).snapshots();
  }

  Future<Stream<QuerySnapshot>> getAllProducts() async {
    return FirebaseFirestore.instance.collection("Products").snapshots();
  }

  // ===============================================================
  // ✅ ORDER
  // ===============================================================
  Future<Stream<QuerySnapshot>> getOrders(String email) async {
    return FirebaseFirestore.instance
        .collection("Orders")
        .where("Email", isEqualTo: email)
        .snapshots();
  }

  Future<Stream<QuerySnapshot>> allOrder() async {
    return FirebaseFirestore.instance.collection("Orders").snapshots();
  }

  updateStatus(String id) async {
    return FirebaseFirestore.instance.collection("Orders").doc(id).update({
      "Status": "Delivered",
      "deliveredAt": FieldValue.serverTimestamp(),
    });
  }

  Future<String?> createPendingOrder(Map<String, dynamic> orderData) async {
    try {
      orderData['Status'] = "Pending";
      orderData['createdAt'] = FieldValue.serverTimestamp();
      orderData['orderDate'] = FieldValue.serverTimestamp();

      final doc =
          await FirebaseFirestore.instance.collection("Orders").add(orderData);

      return doc.id;
    } catch (e) {
      print("createPendingOrder error: $e");
      return null;
    }
  }

  Future<bool> finalizeOrder(String orderId) async {
    try {
      await FirebaseFirestore.instance.collection("Orders").doc(orderId).update(
        {"Status": "Shipping", "paidAt": FieldValue.serverTimestamp()},
      );
      return true;
    } catch (e) {
      print("finalizeOrder error: $e");
      return false;
    }
  }

  // ===============================================================
  // ✅ STOCK & SALES
  // ===============================================================
  Future<bool> decrementStock(String? productId, String? color, int qty) async {
    if (productId == null) return false;

    final docRef =
        FirebaseFirestore.instance.collection('Products').doc(productId);

    try {
      await FirebaseFirestore.instance.runTransaction((txn) async {
        final snap = await txn.get(docRef);
        if (!snap.exists) throw Exception("Product not found");

        final data = snap.data() as Map<String, dynamic>;
        List variants = List<Map<String, dynamic>>.from(data['variants'] ?? []);

        if (variants.isNotEmpty) {
          if (color == null) throw Exception("Color required");

          bool found = false;
          for (int i = 0; i < variants.length; i++) {
            final vColor = variants[i]['color']?.toString() ?? "";
            if (vColor.toLowerCase() == color.toLowerCase()) {
              found = true;
              int stock = int.tryParse("${variants[i]['stock']}") ?? 0;
              if (stock < qty) throw Exception("Insufficient stock");
              int newStock = stock - qty;
              if (newStock <= 0) {
                variants.removeAt(i);
              } else {
                variants[i]['stock'] = newStock;
              }
              break;
            }
          }
          if (!found) throw Exception("Variant not found");
          txn.update(docRef, {"variants": variants});
        } else if (data.containsKey("stock")) {
          int stock = int.tryParse("${data['stock']}") ?? 0;
          if (stock < qty) throw Exception("Insufficient stock");
          txn.update(docRef, {"stock": stock - qty});
        }

        int oldSales = data["salesCount"] ?? 0;
        txn.update(docRef, {"salesCount": oldSales + qty});
      });

      return true;
    } catch (e) {
      print("decrementStock error: $e");
      return false;
    }
  }

  // ===============================================================
  // ✅ SEARCH
  // ===============================================================
  Future<QuerySnapshot> search(String name) async {
    return FirebaseFirestore.instance
        .collection("Products")
        .where("SearchKey", isEqualTo: name.substring(0, 1).toUpperCase())
        .get();
  }

  // ===============================================================
  // ✅ CART
  // ===============================================================
  Future<void> addToCart(String userId, Map<String, dynamic> item) async {
  int price = 0;
  if (item["price"] is int) {
    price = item["price"];
  } else if (item["price"] is String) {
    price = int.tryParse(item["price"]) ?? 0;
  }

  int qty = item["qty"] is int
      ? item["qty"]
      : int.tryParse(item["qty"].toString()) ?? 1;

  item["price"] = price;
  item["qty"] = qty;
  item["total"] = price * qty;
  item["addedAt"] = FieldValue.serverTimestamp(); // ✅ เพิ่มบรรทัดนี้

  await FirebaseFirestore.instance
      .collection("Cart")
      .doc(userId)
      .collection("items")
      .add(item);
}



  Future<Stream<QuerySnapshot>> getCart(String userId) async {
    return FirebaseFirestore.instance
        .collection("Cart")
        .doc(userId)
        .collection("items")
        .orderBy("addedAt", descending: false)
        .snapshots();
  }

  Future<void> removeFromCart(String userId, String itemId) async {
    await FirebaseFirestore.instance
        .collection("Cart")
        .doc(userId)
        .collection("items")
        .doc(itemId)
        .delete();
  }

  Future<void> updateCartQty(String userId, String itemId, int qty) async {
  final ref = FirebaseFirestore.instance
      .collection("Cart")
      .doc(userId)
      .collection("items")
      .doc(itemId);

  final snap = await ref.get();
  if (!snap.exists) return;

  final data = snap.data()!;
  final price = int.tryParse(data["price"].toString()) ?? 0;

  // คำนวณราคาทั้งหมดใหม่
  final total = price * qty;

  await ref.update({
    "qty": qty,
    "total": total,  // อัพเดต total ด้วยราคาที่คำนวณใหม่
  });
}


  Future<void> clearCart(String userId) async {
    final items = await FirebaseFirestore.instance
        .collection("Cart")
        .doc(userId)
        .collection("items")
        .get();

    for (var d in items.docs) {
      await d.reference.delete();
    }
  }

  // ===============================================================
  // ✅ DELETE PRODUCT WITH IMAGES (คืนค่า bool)
  // ===============================================================
  Future<bool> deleteProductWithImages(String productId) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final FirebaseStorage storage = FirebaseStorage.instance;

      final docRef = firestore.collection("Products").doc(productId);
      final productSnap = await docRef.get();

      if (!productSnap.exists) {
        print("⚠️ ไม่พบสินค้าที่ต้องการลบ");
        return false;
      }

      final data = productSnap.data() as Map<String, dynamic>;

      if (data.containsKey("image") && data["image"] != null) {
        await _deleteImageFromStorage(data["image"], storage);
      }

      if (data.containsKey("images") &&
          data["images"] is List &&
          (data["images"] as List).isNotEmpty) {
        for (var url in (data["images"] as List)) {
          await _deleteImageFromStorage(url, storage);
        }
      }

      await docRef.delete();
      print("✅ ลบสินค้าพร้อมรูปภาพสำเร็จ: $productId");
      return true;
    } catch (e) {
      print("❌ เกิดข้อผิดพลาดขณะลบสินค้า: $e");
      return false;
    }
  }

  Future<void> _deleteImageFromStorage(
      String imageUrl, FirebaseStorage storage) async {
    try {
      final ref = storage.refFromURL(imageUrl);
      await ref.delete();
      print("🗑️ ลบรูปสำเร็จ: $imageUrl");
    } catch (e) {
      print("⚠️ ลบรูปภาพไม่สำเร็จ: $e");
    }
  }
}
