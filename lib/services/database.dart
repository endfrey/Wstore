// lib/services/database.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMethods {
  // ---------------------------
  // Store
  // ---------------------------
  Future<DocumentSnapshot> getStoreInfo(String storeId) async {
    return await FirebaseFirestore.instance
        .collection("store")
        .doc(storeId)
        .get();
  }

  Future<void> updateStoreInfo(
    String storeId,
    Map<String, dynamic> storeData,
  ) async {
    return await FirebaseFirestore.instance
        .collection("store")
        .doc(storeId)
        .set(storeData, SetOptions(merge: true));
  }

  // ---------------------------
  // Chat Rooms
  // ---------------------------
  Future<void> createChatRoom(
    Map<String, dynamic> chatRoomData,
    String chatRoomId,
  ) async {
    return await FirebaseFirestore.instance
        .collection("chatRooms")
        .doc(chatRoomId)
        .set(chatRoomData, SetOptions(merge: true));
  }

  Future<Stream<QuerySnapshot>> getChatRooms(String userId) async {
    return FirebaseFirestore.instance
        .collection("chatRooms")
        .where("users", arrayContains: userId)
        .snapshots();
  }

  // ---------------------------
  // Users
  // ---------------------------
  Future addUserDetails(Map<String, dynamic> userInfoMap, String id) async {
    return await FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .set(userInfoMap);
  }

  // ---------------------------
  // Products
  // ---------------------------
  Future addAllProducts(Map<String, dynamic> userInfoMap) async {
    return await FirebaseFirestore.instance
        .collection("Products")
        .add(userInfoMap);
  }

  Future<List<Map<String, dynamic>>> getProductsByStore(String storeId) async {
    final snap = await FirebaseFirestore.instance
        .collection('Products')
        .where('storeId', isEqualTo: storeId)
        .get();

    return snap.docs.map((d) => d.data()).toList();
  }

  Future addProduct(
    Map<String, dynamic> userInfoMap,
    String categoryname,
  ) async {
    return await FirebaseFirestore.instance
        .collection(categoryname)
        .add(userInfoMap);
  }

  // ---------------------------
  // Orders
  // ---------------------------

  /// ✅ Admin เปลี่ยนสถานะเป็น Delivered
  updateStatus(String id) async {
    return await FirebaseFirestore.instance.collection("Orders").doc(id).update(
      {"Status": "Delivered", "deliveredAt": FieldValue.serverTimestamp()},
    );
  }

  /// ✅ ลูกค้าดึงออเดอร์ของตัวเอง
  Future<Stream<QuerySnapshot>> getOrders(String email) async {
    return FirebaseFirestore.instance
        .collection("Orders")
        .where("Email", isEqualTo: email)
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  /// ✅ Admin ดึงออเดอร์ทั้งหมด (ไม่กรองสถานะ)
  Future<Stream<QuerySnapshot>> allOrder() async {
    return FirebaseFirestore.instance
        .collection("Orders")
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  Future orderDetails(Map<String, dynamic> userInfoMap) async {
    return await FirebaseFirestore.instance
        .collection("Orders")
        .add(userInfoMap);
  }

  // ================================================================
  // ✅ FIXED VERSION: decrementStock + salesCount (transaction safe)
  // ================================================================
  Future<bool> decrementStock(String? productId, String? color, int qty) async {
    if (productId == null) return false;

    final docRef = FirebaseFirestore.instance
        .collection('Products')
        .doc(productId);

    try {
      await FirebaseFirestore.instance.runTransaction((txn) async {
        final snap = await txn.get(docRef);
        if (!snap.exists) throw Exception("Product not found");

        final data = snap.data() as Map<String, dynamic>;

        List variants = List<Map<String, dynamic>>.from(data['variants'] ?? []);
        bool reduced = false;

        // ✅ CASE 1 — มี variants
        if (variants.isNotEmpty) {
          if (color == null) throw Exception("Color required");

          bool found = false;

          for (int i = 0; i < variants.length; i++) {
            final vColor = variants[i]['color']?.toString() ?? "";
            if (vColor.toLowerCase() == color.toLowerCase()) {
              found = true;

              int stock = int.tryParse("${variants[i]['stock']}") ?? 0;
              if (stock < qty) throw Exception("Insufficient stock");

              final newStock = stock - qty;
              if (newStock <= 0) {
                variants.removeAt(i);
              } else {
                variants[i]['stock'] = newStock;
              }

              reduced = true;
              break;
            }
          }

          if (!found) throw Exception("Variant not found");

          txn.update(docRef, {"variants": variants});
        }
        // ✅ CASE 2 — ไม่มี variants แต่มี stock
        else if (data.containsKey("stock")) {
          int stock = int.tryParse("${data['stock']}") ?? 0;
          if (stock < qty) throw Exception("Insufficient stock");

          txn.update(docRef, {"stock": stock - qty});
          reduced = true;
        }
        // ✅ CASE 3 — ไม่มี stock ใด ๆ
        else {
          reduced = true;
        }

        // ✅ เพิ่มยอดขาย
        final oldSales = int.tryParse("${data['salesCount'] ?? 0}") ?? 0;
        txn.update(docRef, {"salesCount": oldSales + qty});
      });

      return true;
    } catch (e) {
      print("ERROR decrementStock(): $e");
      return false;
    }
  }

  // ---------------------------
  // Search
  // ---------------------------
  Future<QuerySnapshot> search(String updatename) async {
    return await FirebaseFirestore.instance
        .collection("Products")
        .where("SearchKey", isEqualTo: updatename.substring(0, 1).toUpperCase())
        .get();
  }

  // --------------------------------------------------------------
  // ✅ สร้าง Pending Order ก่อนชำระเงิน
  // --------------------------------------------------------------
  Future<String?> createPendingOrder(Map<String, dynamic> orderData) async {
    try {
      orderData['Status'] = "Pending";
      orderData['createdAt'] = FieldValue.serverTimestamp();
      orderData['orderDate'] = FieldValue.serverTimestamp();

      final doc = await FirebaseFirestore.instance
          .collection("Orders")
          .add(orderData);

      return doc.id;
    } catch (e) {
      print("createPendingOrder error: $e");
      return null;
    }
  }

  // --------------------------------------------------------------
  // ✅ ชำระเงินสำเร็จ → เปลี่ยนสถานะเป็น Shipping
  // --------------------------------------------------------------
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
}
