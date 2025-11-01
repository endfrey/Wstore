import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wstore/Admin/add_product.dart';

class DatabaseMethods {
  Future addUserDetails(Map<String, dynamic> userInfoMap, String id) async {
    return await FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .set(userInfoMap);
  }

  Future addAllProducts(Map<String, dynamic> userInfoMap) async {
    return await FirebaseFirestore.instance
        .collection("Products")
        .add(userInfoMap);
  }

  Future addProduct(
    Map<String, dynamic> userInfoMap,
    String categoryname,
  ) async {
    return await FirebaseFirestore.instance
        .collection(categoryname)
        .add(userInfoMap);
  }

  updateStatus(String id) async {
    return await FirebaseFirestore.instance.collection("Orders").doc(id).update(
      {"Status": "Delivered"},
    );
  }

  Future<Stream<QuerySnapshot>> getProducts(String category) async {
    return await FirebaseFirestore.instance.collection(category).snapshots();
  }

  Future<Stream<QuerySnapshot>> allOrder() async {
    return await FirebaseFirestore.instance
        .collection("Orders")
        .where("Status", isEqualTo: "On the way")
        .snapshots();
  }

  Future<Stream<QuerySnapshot>> getOrders(String email) async {
    return await FirebaseFirestore.instance
        .collection("Orders")
        .where("Email", isEqualTo: email)
        .snapshots();
  }

  Future orderDetails(Map<String, dynamic> userInfoMap) async {
    return await FirebaseFirestore.instance
        .collection("Orders")
        .add(userInfoMap);
  }

  Future<QuerySnapshot> search(String updatename)async {
    return await FirebaseFirestore.instance.collection("Products").where("SearchKey",isEqualTo: updatename.substring(0,1).toUpperCase()).get();
  }
}
