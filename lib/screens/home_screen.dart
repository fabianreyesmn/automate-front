import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${user?.displayName ?? user?.email ?? 'User'}!',
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Text(
                "Here's your vehicle summary.",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        
        // Heads up/Alert card
        Card(
          color: Colors.yellow[100],
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.yellow[700]!, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Icon(LucideIcons.alertTriangle, color: Colors.yellow[800]),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Heads up!', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('You have 2 documents expiring soon.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),

        // Navigation Cards
        _DashboardCard(
          icon: LucideIcons.car,
          title: 'Digital Glovebox',
          subtitle: 'Manage your vehicles & documents',
          onTap: () {
            // This could navigate or switch tabs
          },
        ),
        const SizedBox(height: 12),
        _DashboardCard(
          icon: LucideIcons.bell,
          title: 'Reminders',
          subtitle: 'View upcoming expirations',
          onTap: () {
            // This could navigate or switch tabs
          },
        ),
        const SizedBox(height: 12),
        _DashboardCard(
          icon: LucideIcons.map,
          title: 'Pre-Trip Report',
          subtitle: 'Plan your next journey',
          onTap: () {
            // This could navigate or switch tabs
          },
        ),
      ],
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
            ],
          ),
        ),
      ),
    );
  }
}