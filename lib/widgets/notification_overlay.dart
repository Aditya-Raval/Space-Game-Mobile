import 'package:flutter/material.dart';
import 'dart:async';

class NotificationOverlay extends StatefulWidget {
  const NotificationOverlay({super.key});

  @override
  State<NotificationOverlay> createState() => NotificationOverlayState();
}

class NotificationOverlayState extends State<NotificationOverlay> {
  final List<NotificationItem> _notifications = [];

  void showNotification(String text, Color color) {
    final notification = NotificationItem(
      text: text,
      color: color,
      id: DateTime.now().millisecondsSinceEpoch,
    );

    setState(() {
      _notifications.add(notification);
    });

    Timer(const Duration(seconds: 3), () {
      setState(() {
        _notifications.removeWhere((n) => n.id == notification.id);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      right: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _notifications.map((notification) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: notification.color, width: 1),
            ),
            child: Text(
              notification.text,
              style: TextStyle(
                color: notification.color,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class NotificationItem {
  final String text;
  final Color color;
  final int id;

  NotificationItem({
    required this.text,
    required this.color,
    required this.id,
  });
}