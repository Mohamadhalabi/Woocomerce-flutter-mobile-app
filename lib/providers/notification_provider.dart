import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final int? productId; // ✅ Added
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.productId, // ✅ Added
    this.isRead = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'body': body,
    'timestamp': timestamp.toIso8601String(),
    'productId': productId, // ✅ Added
    'isRead': isRead,
  };

  factory NotificationItem.fromMap(Map<String, dynamic> map) => NotificationItem(
    id: map['id'],
    title: map['title'],
    body: map['body'],
    timestamp: DateTime.parse(map['timestamp']),
    productId: map['productId'], // ✅ Added
    isRead: map['isRead'] ?? false,
  );
}

class NotificationProvider with ChangeNotifier {
  List<NotificationItem> _items = [];
  List<NotificationItem> get items => _items;

  NotificationProvider() { loadNotifications(); }

  // ✅ Updated to accept optional productId
  Future<void> addNotification(String title, String body, {int? productId}) async {
    final newItem = NotificationItem(
      id: DateTime.now().toString(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
      productId: productId, // ✅ Passed to model
    );
    _items.insert(0, newItem);
    notifyListeners();
    await saveNotifications();
  }

  void markAsRead(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index].isRead = true;
      notifyListeners();
      saveNotifications();
    }
  }

  void deleteNotification(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
    saveNotifications();
  }

  Future<void> saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_items.map((i) => i.toMap()).toList());
    await prefs.setString('notification_history', data);
  }

  Future<void> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('notification_history');
    if (data != null) {
      _items = (jsonDecode(data) as List).map((i) => NotificationItem.fromMap(i)).toList();
      notifyListeners();
    }
  }

  void clearAll() {
    _items.clear();
    notifyListeners();
    saveNotifications();
  }
}