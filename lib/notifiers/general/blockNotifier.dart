import 'package:flutter/material.dart';

class BlockNotifier extends ChangeNotifier {
  final String id;
  bool _init;
  Offset _position;
  String _name;
  String _department;

  BlockNotifier({
    required this.id,
    required Offset position,
    bool init = false,
    String name = '',
    String department = '',
  }) : _position = position,
       _name = name,
       _department = department,
       _init = init;

  Offset get position => _position;
  String get name => _name;
  String get department => _department;
  bool get isInitialized => _init;

  void updatePosition(Offset newPosition) {
    _position = newPosition;
    notifyListeners();
  }

  void updatePositionAndInit(Offset newPosition) {
    _position = newPosition;
    _init = true;
    notifyListeners();
  }

  void updateName(String newName) {
    _name = newName;
    notifyListeners();
  }

  void updateDepartment(String newDepartment) {
    _department = newDepartment;
    notifyListeners();
  }

  void markAsInitialized() {
    _init = true;
    notifyListeners();
  }
}
