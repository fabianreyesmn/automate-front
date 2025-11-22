import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

// --- Mock Data based on the React component ---
enum DocumentType { insurance, registration }

class Reminder {
  final String id;
  final String documentId;
  final DocumentType documentType;
  final String vehicleModel;
  final int daysUntilExpiry;
  final DateTime expiryDate;

  Reminder({
    required this.id,
    required this.documentId,
    required this.documentType,
    required this.vehicleModel,
    required this.daysUntilExpiry,
    required this.expiryDate,
  });

  String get documentTypeAsString {
    return documentType.toString().split('.').last.capitalize();
  }
}

final List<Reminder> mockReminders = [
  Reminder(id: 'r1', documentId: 'd1', documentType: DocumentType.insurance, vehicleModel: 'Camry', daysUntilExpiry: 25, expiryDate: DateTime(2024, 12, 31)),
  Reminder(id: 'r2', documentId: 'd3', documentType: DocumentType.insurance, vehicleModel: 'CR-V', daysUntilExpiry: 45, expiryDate: DateTime(2025, 1, 20)),
  Reminder(id: 'r3', documentId: 'd2', documentType: DocumentType.registration, vehicleModel: 'Camry', daysUntilExpiry: 160, expiryDate: DateTime(2025, 5, 15)),
];
// --- End Mock Data ---

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sortedReminders = [...mockReminders]..sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));
    final theme = Theme.of(context);

    return ListView(
      children: [
        Text('Upcoming Expirations', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        ...sortedReminders.map((reminder) => ReminderCard(reminder: reminder)),
        
        const SizedBox(height: 24),

        // Notification Settings
        Card(
          elevation: 0,
          color: Colors.grey[100],
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notification Settings', style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                const Text('Get notified before your documents expire.'),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('30 days before'),
                  value: true,
                  onChanged: (val) {},
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('15 days before'),
                  value: true,
                  onChanged: (val) {},
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('7 days before'),
                  value: false,
                  onChanged: (val) {},
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}

class ReminderCard extends StatelessWidget {
  final Reminder reminder;
  const ReminderCard({super.key, required this.reminder});

  @override
  Widget build(BuildContext context) {
    final status = _getStatusStyles(reminder.daysUntilExpiry);
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: status.borderColor, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reminder.documentTypeAsString, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text(reminder.vehicleModel, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                  ],
                ),
                Row(
                  children: [
                    Text(status.text, style: theme.textTheme.bodyMedium?.copyWith(color: status.textColor, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Icon(status.icon, color: status.textColor),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Expires on: ${reminder.expiryDate.toLocal().toString().split(' ')[0]}',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  ({IconData icon, Color borderColor, Color textColor, String text}) _getStatusStyles(int daysLeft) {
    if (daysLeft <= 30) {
      return (icon: LucideIcons.alertTriangle, borderColor: Colors.red.shade400, textColor: Colors.red.shade700, text: '$daysLeft days left');
    }
    if (daysLeft <= 60) {
      return (icon: LucideIcons.bell, borderColor: Colors.orange.shade400, textColor: Colors.orange.shade700, text: '$daysLeft days left');
    }
    return (icon: LucideIcons.checkCircle, borderColor: Colors.green.shade400, textColor: Colors.green.shade700, text: 'Expires in $daysLeft days');
  }
}

extension StringExtension on String {
    String capitalize() {
      return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
    }
}