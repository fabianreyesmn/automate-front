import 'package:flutter/foundation.dart';

class Reminder {
  final String id;
  final String userId;
  final String? vehicleId; // Optional, a reminder can be general
  final String title;
  final String? notes; // Changed from description
  final DateTime dueDate; // Changed from date
  final bool isCompleted;
  final DateTime createdAt;

  Reminder({
    required this.id,
    required this.userId,
    this.vehicleId,
    required this.title,
    this.notes, // Changed from description
    required this.dueDate, // Changed from date
    this.isCompleted = false,
    required this.createdAt,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      userId: json['user_id'],
      vehicleId: json['vehicle_id'],
      title: json['title'],
      notes: json['notes'], // Changed from description
      dueDate: DateTime.parse(json['due_date']), // Changed from date
      isCompleted: json['is_completed'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'vehicle_id': vehicleId,
      'title': title,
      'notes': notes, // Changed from description
      'due_date': dueDate.toIso8601String(), // Changed from date
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Reminder copyWith({
    String? id,
    String? userId,
    String? vehicleId,
    String? title,
    String? notes, // Changed from description
    DateTime? dueDate, // Changed from date
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vehicleId: vehicleId ?? this.vehicleId,
      title: title ?? this.title,
      notes: notes ?? this.notes, // Changed from description
      dueDate: dueDate ?? this.dueDate, // Changed from date
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
