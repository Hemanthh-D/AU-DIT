import 'package:flutter/foundation.dart';

enum UserRole { student, technician, admin }

class SessionProvider extends ChangeNotifier {
  UserRole? _role;
  String? _email;
  String? _studentId;
  String? _technicianId;
  bool _darkMode = false;

  UserRole? get role => _role;
  String? get email => _email;

  String get studentId => _studentId ?? 'STUDENT_123';
  String get technicianId => _technicianId ?? 'Tech 1';

  bool get isLoggedIn => _role != null;
  bool get darkMode => _darkMode;

  void setDarkMode(bool value) {
    if (_darkMode == value) return;
    _darkMode = value;
    notifyListeners();
  }

  void login({required String email}) {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return;

    _email = normalized;
    if (normalized == 'admin@campus.edu') {
      _role = UserRole.admin;
      _studentId = null;
      _technicianId = null;
    } else if (normalized == 'tech@campus.edu' || normalized == 'tech1@campus.edu') {
      _role = UserRole.technician;
      _technicianId = 'Tech 1';
      _studentId = null;
    } else if (normalized == 'tech2@campus.edu') {
      _role = UserRole.technician;
      _technicianId = 'Tech 2';
      _studentId = null;
    } else if (normalized == 'counselor@campus.edu' ||
        normalized == 'counsellor@campus.edu') {
      _role = UserRole.technician;
      _technicianId = 'Counselor';
      _studentId = null;
    } else {
      _role = UserRole.student;
      _studentId = 'STUDENT_123';
      _technicianId = null;
    }

    notifyListeners();
  }

  void logout() {
    _role = null;
    _email = null;
    _studentId = null;
    _technicianId = null;
    notifyListeners();
  }
}

