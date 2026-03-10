import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'title': title, 'body': body,
    'timestamp': timestamp.toIso8601String(), 'isRead': isRead,
  };

  factory NotificationItem.fromMap(Map<String, dynamic> map) => NotificationItem(
    id: map['id'], title: map['title'], body: map['body'],
    timestamp: DateTime.parse(map['timestamp']), isRead: map['isRead'] ?? false,
  );
}

class NotificationProvider with ChangeNotifier {
  List<NotificationItem> _items = [];
  List<NotificationItem> get items => _items;

  NotificationProvider() { loadNotifications(); }

  Future<void> addNotification(String title, String body) async {
    final newItem = NotificationItem(
      id: DateTime.now().toString(), title: title, body: body, timestamp: DateTime.now(),
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
  // Inside NotificationProvider class
  void clearAll() {
    _items.clear();
    notifyListeners();
    saveNotifications();
  }
}