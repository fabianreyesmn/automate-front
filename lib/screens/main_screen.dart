import 'package:automate/providers/main_screen_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'home_screen.dart';
import 'digital_glovebox_screen.dart';
import 'reminders_screen.dart';
import 'pre_trip_report_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    DigitalGloveboxScreen(),
    RemindersScreen(),
    PreTripReportScreen(),
  ];

  static const List<String> _titles = <String>[
    'Dashboard',
    'Guantera Digital',
    'Recordatorios',
    'Reporte Pre-Viaje',
  ];

  @override
  Widget build(BuildContext context) {
    final screenProvider = context.watch<MainScreenProvider>();
    final selectedIndex = screenProvider.selectedIndex;
    print('[MainScreen] Build method running with index: $selectedIndex');

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: _widgetOptions.elementAt(selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.layoutDashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.car),
            label: 'Guantera',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.bell),
            label: 'Recordatorios',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.map),
            label: 'Pre-Viaje',
          ),
        ],
        currentIndex: selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: (index) => context.read<MainScreenProvider>().setIndex(index),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
