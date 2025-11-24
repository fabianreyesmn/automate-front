import 'package:flutter/material.dart';

class MainScreenProvider with ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void setIndex(int index) {
    print('[MainScreenProvider] setIndex called with: $index');
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
      print('[MainScreenProvider] Index changed to $_selectedIndex and listeners notified.');
    } else {
      print('[MainScreenProvider] Index is already $_selectedIndex. No change.');
    }
  }
}
