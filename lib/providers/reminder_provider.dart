import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/reminder.dart';

enum ReminderStatus { overdue, dueSoon, safe }

class ReminderProvider with ChangeNotifier {
  User? _currentUser;
  List<Reminder> _reminders = [];
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  List<Reminder> get reminders => _reminders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void updateUser(User? user) {
    if (user != _currentUser) {
      _currentUser = user;
      if (user != null) {
        fetchReminders();
      } else {
        _reminders = [];
        notifyListeners();
      }
    }
  }

  // Getter para las advertencias (vencidos y próximos a vencer)
  List<Reminder> get warnings {
    final now = DateTime.now();
    return _reminders.where((r) {
      if (r.isCompleted) return false;
      final status = getReminderStatus(r, now);
      return status == ReminderStatus.overdue || status == ReminderStatus.dueSoon;
    }).toList()..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  List<Reminder> get overdueReminders => warnings.where((r) => getReminderStatus(r) == ReminderStatus.overdue).toList();
  List<Reminder> get dueSoonReminders => warnings.where((r) => getReminderStatus(r) == ReminderStatus.dueSoon).toList();

  ReminderStatus getReminderStatus(Reminder reminder, [DateTime? now]) {
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    final dueDate = DateUtils.dateOnly(reminder.dueDate);

    if (dueDate.isBefore(today)) {
      return ReminderStatus.overdue;
    }
    if (dueDate.isBefore(today.add(const Duration(days: 7)))) {
      return ReminderStatus.dueSoon;
    }
    return ReminderStatus.safe;
  }

  Future<void> fetchReminders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await user.getIdToken();
      final backendUrl = dotenv.env['BACKEND_URL'];
      final url = Uri.parse('$backendUrl/api/reminders');

      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> reminderList = data['reminders'];
        _reminders = reminderList.map((json) => Reminder.fromJson(json)).toList();
      } else {
        _errorMessage = 'Failed to load reminders.';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
