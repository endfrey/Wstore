import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ✅ ดึงข้อมูลผู้ใช้
  Future<String> getUserName(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data()?['name'] ?? 'ผู้ใช้';
  }

  Future<String?> getUserImage(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data()?['image'];
  }

  // ✅ ดึงข้อมูลร้าน (ระบบร้านเดียว)
  Future<String> getStoreName() async {
    final doc = await _firestore.collection('store').doc('main_store').get();
    return doc.data()?['name'] ?? 'ร้านค้า';
  }

  Future<String?> getStoreImage() async {
    final doc = await _firestore.collection('store').doc('main_store').get();
    return doc.data()?['image'];
  }

  // ✅ Stream: แสดงข้อความในห้องนั้น
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // ✅ stream: ห้องแชทของผู้ใช้ (ลูกค้า)
  Stream<DocumentSnapshot> getUserChat(String userId) {
    return _firestore.collection('chats').doc(userId).snapshots();
  }

  // ✅ stream: สำหรับแอดมิน (ดูแชททั้งหมด)
  Stream<QuerySnapshot> getAllChats() {
    return _firestore
        .collection('chats')
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  // ✅ สร้างห้องแชทลูกค้า (ถ้ายังไม่มี)
  Future<void> createChatRoomForUser(String userId) async {
    final chatRef = _firestore.collection('chats').doc(userId);

    if (!(await chatRef.get()).exists) {
      await chatRef.set({
        'chatId': userId,
        'users': [userId, 'admin'],
        'userName': await getUserName(userId),
        'userImage': await getUserImage(userId),
        'storeName': await getStoreName(),
        'storeImage': await getStoreImage(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCountForAdmin': 0,
        'unreadCountForUser': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await chatRef.set({
        'storeName': await getStoreName(),
        'storeImage': await getStoreImage(),
      }, SetOptions(merge: true));
    }
  }

  // ✅ ส่งข้อความ
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    String? text,
    String? imageUrl,
  }) async {
    final msg = {
      'senderId': senderId,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
    };

    // ✅ add message
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(msg);

    // ✅ update room
    await _firestore.collection('chats').doc(chatId).set({
      'lastMessage': text ?? (imageUrl != null ? '[รูปภาพ]' : ''),
      'lastMessageTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),

      /// ✅ เพิ่ม unreadCount เฉพาะ "อีกฝั่ง"
      if (senderId == "admin")
        'unreadCountForUser': FieldValue.increment(1)
      else
        'unreadCountForAdmin': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  // ✅ อัปโหลดรูปภาพ
  Future<String?> uploadImage(File image, String chatId) async {
    try {
      final ref = _storage
          .ref()
          .child('chat_images/$chatId/${DateTime.now().millisecondsSinceEpoch}.jpg');

      final task = await ref.putFile(image);
      return await task.ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  // ✅ mark as read → admin / user
  Future<void> markAsRead(String chatId, {required bool forAdmin}) async {
    await _firestore.collection('chats').doc(chatId).update({
      forAdmin ? 'unreadCountForAdmin' : 'unreadCountForUser': 0,
    });
  }
}
