import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences
import '../models/reminder.dart';
import '../providers/auth_provider.dart';
import '../services/reminder_service.dart';
import '../services/notification_service.dart'; // Import NotificationService

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  late Future<List<Reminder>> _remindersFuture;
  bool _notificationsEnabled = false; // State for notification toggle

  @override
  void initState() {
    super.initState();
    _remindersFuture = _fetchReminders();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? false;
    });
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
    _remindersFuture.then((_) {
      _scheduleAllRemindersNotifications();
    });
  }

  Future<void> _scheduleAllRemindersNotifications() async {
    if (!_notificationsEnabled) {
      NotificationService().cancelAllNotifications(); // Cancel all if disabled
      return;
    }

    final reminders = await _remindersFuture;
    for (var reminder in reminders) {
      // Schedule notification for 7 days before.
      // The notification ID should be unique per reminder and per 'daysBefore' setting.
      // Using a combination of reminder ID hash and daysBefore to create a unique ID.
      // Ensure reminder.id is not null and is unique.
      if (reminder.id != null) {
        NotificationService().scheduleNotification(reminder, 7, reminder.id.hashCode + 7);
      }
    }
  }

  Future<void> _addReminder() async {
    final result = await context.push('/add-reminder');
    if (result == true) {
      _refreshReminders();
    }
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
          // Notification Settings
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
                  SwitchListTile(
                    title: const Text('Enable Reminder Notifications'),
                    value: _notificationsEnabled,
                    onChanged: (bool value) async {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('notificationsEnabled', value);

                      if (value) {
                        // Request permissions when enabling notifications
                        final granted = await NotificationService().requestPermissions();
                        if (granted == true) {
                          // If granted, schedule notifications for existing reminders
                          _scheduleAllRemindersNotifications();
                        } else {
                          // If not granted, maybe show a message to the user
                          debugPrint('Notification permissions not granted.');
                          // Optionally, revert the switch if permissions are not granted
                          setState(() {
                            _notificationsEnabled = false;
                          });
                          await prefs.setBool('notificationsEnabled', false);
                        }
                      } else {
                        // If disabling, cancel all scheduled notifications
                        NotificationService().cancelAllNotifications();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 80), // Add space for the FloatingActionButton
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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    // Show confirmation dialog
                    final bool confirmDelete = await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Confirmar Eliminación'),
                          content: const Text('¿Estás seguro de que quieres eliminar este recordatorio?'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Eliminar'),
                            ),
                          ],
                        );
                      },
                    ) ?? false;

                    if (confirmDelete) {
                      try {
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        final token = await authProvider.user?.getIdToken();
                        if (token == null) throw Exception('Not authenticated');

                        await ReminderService.deleteReminder(token, reminder.id);
                        NotificationService().cancelNotification(reminder.id.hashCode + 7); // Cancel associated notification
                        onRefresh(); // Refresh the list after deletion
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Recordatorio eliminado con éxito!')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error al eliminar recordatorio: $e')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
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
