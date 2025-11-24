import 'package:automate/providers/main_screen_provider.dart';
import 'package:automate/providers/reminder_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenido, ${user?.displayName ?? user?.email ?? 'Usuario'}!',
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Text(
                "Aquí está el resumen de tu vehículo.",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        
        // Warnings Section
        const _WarningsSection(),
        
        const SizedBox(height: 24),

        // Navigation Cards
        _DashboardCard(
          icon: LucideIcons.car,
          title: 'Guantera Digital',
          subtitle: 'Gestiona tus vehículos y documentos',
          onTap: () {
            print('[HomeScreen] Digital Glovebox card tapped!');
            context.read<MainScreenProvider>().setIndex(1);
          },
        ),
        const SizedBox(height: 12),
        _DashboardCard(
          icon: LucideIcons.bell,
          title: 'Recordatorios',
          subtitle: 'Ver próximos vencimientos',
          onTap: () {
            print('[HomeScreen] Reminders card tapped!');
            context.read<MainScreenProvider>().setIndex(2);
          },
        ),
        const SizedBox(height: 12),
        _DashboardCard(
          icon: LucideIcons.map,
          title: 'Reporte Pre-Viaje',
          subtitle: 'Planifica tu próximo viaje',
          onTap: () {
            print('[HomeScreen] Pre-Trip Report card tapped!');
            context.read<MainScreenProvider>().setIndex(3);
          },
        ),
      ],
    );
  }
}

class _WarningsSection extends StatelessWidget {
  const _WarningsSection();

  @override
  Widget build(BuildContext context) {
    final reminderProvider = context.watch<ReminderProvider>();
    final warnings = reminderProvider.warnings;

    if (reminderProvider.isLoading && warnings.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(8.0),
        child: CircularProgressIndicator(),
      ));
    }

    if (warnings.isEmpty) {
      // Puedes mostrar una tarjeta de "todo en orden" si lo prefieres
      return const SizedBox.shrink(); 
    }

    final overdueCount = reminderProvider.overdueReminders.length;
    final dueSoonCount = reminderProvider.dueSoonReminders.length;
    final isUrgent = overdueCount > 0;

    final cardColor = isUrgent ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1);
    final iconColor = isUrgent ? Colors.red[800] : Colors.orange[800];
    final borderColor = isUrgent ? Colors.red.withOpacity(0.3) : Colors.orange.withOpacity(0.3);
    final mostUrgentWarning = warnings.first;

    String title = isUrgent ? '$overdueCount Recordatorio(s) Vencido(s)' : '$dueSoonCount Recordatorio(s) Próximo(s)';
    if (overdueCount > 0 && dueSoonCount > 0) {
      title = '$overdueCount vencido(s), $dueSoonCount próximo(s)';
    }

    return Card(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: iconColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: iconColor)),
                  const SizedBox(height: 4),
                  Text(
                    'Más urgente: ${mostUrgentWarning.title} (${timeago.format(mostUrgentWarning.dueDate, locale: 'es')})',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: iconColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 1,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primary.withOpacity(0.1),
                foregroundColor: colorScheme.primary,
                child: Icon(icon),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}