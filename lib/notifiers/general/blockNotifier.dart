import 'package:flutter/material.dart';

class BlockNotifier extends ChangeNotifier {
  final String id;
  Offset _position;
  String _name;
  String _department;
  
  BlockNotifier({
    required this.id,
    required Offset position,
    String name = '',
    String department = '',
  }) : _position = position,
       _name = name,
       _department = department;
  
  Offset get position => _position;
  String get name => _name;
  String get department => _department;
  
  void updatePosition(Offset newPosition) {
    _position = newPosition;
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
}