import 'package:cloud_firestore/cloud_firestore.dart';

class StoreSetup {
  static Future<void> initializeStoreData() async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final String storeId = 'main_store'; // Main store ID

    // Check if store data exists
    DocumentSnapshot storeDoc = await _firestore
        .collection('store')
        .doc(storeId)
        .get();

    if (!storeDoc.exists) {
      // Initialize store data
      await _firestore.collection('store').doc(storeId).set({
        'name': 'WStore',
        'description':
            'ยินดีต้อนรับสู่ WStore ร้านค้าออนไลน์ที่มีสินค้าคุณภาพดี ราคาเป็นมิตร พร้อมบริการหลังการขายที่ประทับใจ',
        'logo': 'https://via.placeholder.com/200',
        'contact': 'โทร: 02-XXX-XXXX\nEmail: contact@wstore.com\nLine: @wstore',
        'address': '123 ถนนสุขุมวิท แขวงคลองเตย เขตคลองเตย กรุงเทพฯ 10110',
        // Use a simple open/closed status instead of detailed per-day hours
        'isOpen': true,
        'socialMedia': {
          'facebook': 'facebook.com/wstore',
          'instagram': '@wstore',
          'line': '@wstore',
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Store data initialized successfully');
    }
  }
}
