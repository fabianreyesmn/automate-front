import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/reminder.dart'; // Import the actual Reminder model
import '../providers/auth_provider.dart';
import '../services/reminder_service.dart'; // Import the ReminderService

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  late Future<List<Reminder>> _remindersFuture;

  @override
  void initState() {
    super.initState();
    _remindersFuture = _fetchReminders();
  }

  Future<List<Reminder>> _fetchReminders() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = await authProvider.user?.getIdToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }
    return ReminderService.getReminders(token);
  }

  void _refreshReminders() {
    setState(() {
      _remindersFuture = _fetchReminders();
    });
  }

  Future<void> _addReminder() async {
    // TODO: Implement a form/dialog for adding a new reminder
    // For now, just refresh to simulate addition
    _refreshReminders();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Recordatorios"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Reminder>>(
              future: _remindersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error al cargar recordatorios: ${snapshot.error}"),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      "No tienes recordatorios todavía.\n¡Añade uno para empezar!",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }

                final reminders = snapshot.data!;
                // Sort reminders by date
                reminders.sort((a, b) => a.dueDate.compareTo(b.dueDate));

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: reminders.length,
                  itemBuilder: (context, index) {
                    final reminder = reminders[index];
                    return ReminderCard(reminder: reminder, onRefresh: _refreshReminders);
                  },
                );
              },
            ),
          ),
          // Notification Settings - Keep for now, but might move or integrate differently
          Card(
            elevation: 0,
            color: Colors.grey[100],
            margin: const EdgeInsets.all(16.0),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push('/add-reminder');
          if (result == true) {
            _refreshReminders();
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Añadir Recordatorio',
      ),
    );
  }
}

class ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onRefresh; // Callback to refresh the list
  const ReminderCard({super.key, required this.reminder, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dueDate = reminder.dueDate;
    final daysLeft = DateTime(dueDate.year, dueDate.month, dueDate.day)
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
    final status = _getStatusStyles(daysLeft);
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(reminder.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      if (reminder.notes != null && reminder.notes!.isNotEmpty)
                        Text(reminder.notes!, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                    ],
                  ),
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
              'Fecha: ${reminder.dueDate.toLocal().toString().split(' ')[0]}',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            // TODO: Add actions for edit/delete/mark complete
          ],
        ),
      ),
    );
  }

  ({IconData icon, Color borderColor, Color textColor, String text}) _getStatusStyles(int daysLeft) {
    if (daysLeft <= 0) {
      return (icon: LucideIcons.alertCircle, borderColor: Colors.red.shade400, textColor: Colors.red.shade700, text: 'Vencido');
    }
    if (daysLeft <= 30) {
      return (icon: LucideIcons.alertTriangle, borderColor: Colors.orange.shade400, textColor: Colors.orange.shade700, text: '$daysLeft días restantes');
    }
    return (icon: LucideIcons.checkCircle, borderColor: Colors.green.shade400, textColor: Colors.green.shade700, text: 'Faltan $daysLeft días');
  }
}
