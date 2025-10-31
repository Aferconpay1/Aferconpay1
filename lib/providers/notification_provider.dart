import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class NotificationProvider with ChangeNotifier {
  final FirestoreService _firestoreService;
  bool _hasUnreadNotifications = false;

  NotificationProvider(this._firestoreService) {
    _listenToNotifications();
  }

  bool get hasUnreadNotifications => _hasUnreadNotifications;

  void _listenToNotifications() {
    _firestoreService.notificationsStream.listen((QuerySnapshot snapshot) {
      final hasUnread = snapshot.docs.any((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        // Check if data is not null and if 'isRead' is explicitly false
        return data != null && data.containsKey('isRead') && data['isRead'] == false;
      });

      if (hasUnread != _hasUnreadNotifications) {
        _hasUnreadNotifications = hasUnread;
        notifyListeners();
      }
    });
  }

  Future<void> markAllAsRead() async {
    if (!_hasUnreadNotifications) return; // No need to run if everything is read

    final QuerySnapshot snapshot = await _firestoreService.notificationsStream.first;
    final batch = FirebaseFirestore.instance.batch();

    for (var doc in snapshot.docs) {
       final data = doc.data() as Map<String, dynamic>?;
       if (data != null && data.containsKey('isRead') && data['isRead'] == false) {
         batch.update(doc.reference, {'isRead': true});
       }
    }

    await batch.commit();
    _hasUnreadNotifications = false;
    notifyListeners();
  }
}
