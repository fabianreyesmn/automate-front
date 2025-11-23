import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/reminder.dart';

class ReminderService {
  static final String _baseUrl = dotenv.env['BACKEND_URL']!;

  static Future<List<Reminder>> getReminders(String token, {String? vehicleId}) async {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    String url = '$_baseUrl/api/reminders';
    if (vehicleId != null) {
      url += '?vehicleId=$vehicleId';
    }

    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['reminders'];
      return data.map((json) => Reminder.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load reminders: ${response.body}');
    }
  }

  static Future<Reminder> createReminder(String token, Reminder reminder) async {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/api/reminders'),
      headers: headers,
      body: jsonEncode({
        'vehicle_id': reminder.vehicleId,
        'title': reminder.title,
        'notes': reminder.notes,
        'due_date': reminder.dueDate.toIso8601String(),
        'is_completed': reminder.isCompleted,
      }),
    );

    if (response.statusCode == 200) {
      return Reminder.fromJson(json.decode(response.body)['reminder']);
    } else {
      throw Exception('Failed to create reminder: ${response.body}');
    }
  }

  static Future<Reminder> updateReminder(String token, Reminder reminder) async {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.put(
      Uri.parse('$_baseUrl/api/reminders/${reminder.id}'),
      headers: headers,
      body: jsonEncode({
        'vehicle_id': reminder.vehicleId,
        'title': reminder.title,
        'notes': reminder.notes,
        'due_date': reminder.dueDate.toIso8601String(),
        'is_completed': reminder.isCompleted,
      }),
    );

    if (response.statusCode == 200) {
      return Reminder.fromJson(json.decode(response.body)['reminder']);
    } else {
      throw Exception('Failed to update reminder: ${response.body}');
    }
  }

  static Future<void> deleteReminder(String token, String reminderId) async {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.delete(
      Uri.parse('$_baseUrl/api/reminders/$reminderId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete reminder: ${response.body}');
    }
  }
}
