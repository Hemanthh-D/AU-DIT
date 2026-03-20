import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';

class NotificationProvider extends ChangeNotifier {
  final List<AppNotification> _notifications = [];
  bool _enabled = true;

  List<AppNotification> get notifications =>
      List.unmodifiable(_notifications);
  List<AppNotification> get unread =>
      _notifications.where((n) => !n.read).toList();
  int get unreadCount => unread.length;
  bool get enabled => _enabled;

  void setEnabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
  }

  void add(AppNotification n) {
    if (!_enabled) return;
    _notifications.insert(0, n);
    notifyListeners();
  }

  void markRead(String id) {
    final i = _notifications.indexWhere((n) => n.id == id);
    if (i == -1) return;
    _notifications[i] = _notifications[i].copyWith(read: true);
    notifyListeners();
  }

  void markAllRead() {
    for (var i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].read) {
        _notifications[i] = _notifications[i].copyWith(read: true);
      }
    }
    notifyListeners();
  }

  void markTechnicianRead(String technicianId) {
    for (var i = 0; i < _notifications.length; i++) {
      if (_notifications[i].technicianId == technicianId && !_notifications[i].read) {
        _notifications[i] = _notifications[i].copyWith(read: true);
      }
    }
    notifyListeners();
  }

  void clear() {
    _notifications.clear();
    notifyListeners();
  }

  List<AppNotification> forStudent(String studentId) {
    return _notifications
        .where((n) => (n.studentId == studentId || n.studentId == null) && n.technicianId == null)
        .toList();
  }

  List<AppNotification> forTechnician(String technicianId) {
    return _notifications
        .where((n) => n.technicianId == technicianId)
        .toList();
  }

  int unreadCountForTechnician(String technicianId) {
    return forTechnician(technicianId).where((n) => !n.read).length;
  }
}
