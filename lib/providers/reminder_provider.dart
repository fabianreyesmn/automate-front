import 'package:automate/services/reminder_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  List<Reminder> get warnings {
    final now = DateTime.now();
    final result = _reminders.where((r) {
      if (r.isCompleted) return false;
      final status = getReminderStatus(r, now);
      return status == ReminderStatus.overdue || status == ReminderStatus.dueSoon;
    }).toList()..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return result;
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
    if (_currentUser == null) {
      print('[ReminderProvider] fetchReminders called, but user is null.');
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _currentUser!.getIdToken();
      if (token == null) {
        throw Exception('Authentication token was null.');
      }
      // Usar el ReminderService para obtener los datos
      _reminders = await ReminderService.getReminders(token);
      print('[ReminderProvider] Fetch successful via ReminderService. Loaded ${_reminders.length} reminders.');

    } catch (e) {
      _errorMessage = 'An error occurred: $e';
      print('[ReminderProvider] Fetch error via ReminderService: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
