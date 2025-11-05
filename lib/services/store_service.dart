import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get store information
  Future<DocumentSnapshot> getStoreInfo() async {
    return await _firestore.collection('store').doc('info').get();
  }

  // Update store information
  Future<void> updateStoreInfo(Map<String, dynamic> storeData) async {
    await _firestore
        .collection('store')
        .doc('info')
        .set(storeData, SetOptions(merge: true));
  }

  // Get store working hours
  Future<DocumentSnapshot> getStoreHours() async {
    return await _firestore.collection('store').doc('hours').get();
  }

  // Update store working hours
  Future<void> updateStoreHours(Map<String, dynamic> hoursData) async {
    await _firestore.collection('store').doc('hours').set(hoursData);
  }

  // Check if store is currently open
  Future<bool> isStoreOpen() async {
    try {
      DocumentSnapshot hours = await getStoreHours();
      if (!hours.exists) return false;

      Map<String, dynamic> data = hours.data() as Map<String, dynamic>;
      DateTime now = DateTime.now();
      String today = _getDayOfWeek(now.weekday);

      if (!data.containsKey(today)) return false;

      Map<String, dynamic> todayHours = data[today];
      if (!todayHours['isOpen']) return false;

      TimeOfDay openTime = _parseTime(todayHours['open']);
      TimeOfDay closeTime = _parseTime(todayHours['close']);
      TimeOfDay currentTime = TimeOfDay.now();

      return _isTimeBetween(currentTime, openTime, closeTime);
    } catch (e) {
      print('Error checking store hours: \$e');
      return false;
    }
  }

  String _getDayOfWeek(int day) {
    switch (day) {
      case 1:
        return 'monday';
      case 2:
        return 'tuesday';
      case 3:
        return 'wednesday';
      case 4:
        return 'thursday';
      case 5:
        return 'friday';
      case 6:
        return 'saturday';
      case 7:
        return 'sunday';
      default:
        return 'monday';
    }
  }

  TimeOfDay _parseTime(String time) {
    List<String> parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  bool _isTimeBetween(TimeOfDay time, TimeOfDay start, TimeOfDay end) {
    int now = time.hour * 60 + time.minute;
    int open = start.hour * 60 + start.minute;
    int close = end.hour * 60 + end.minute;

    if (close < open) {
      // Handles cases crossing midnight
      return now >= open || now <= close;
    }
    return now >= open && now <= close;
  }
}
