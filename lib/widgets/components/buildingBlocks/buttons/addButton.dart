import 'package:flutter/material.dart';

class AddButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const AddButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(Icons.add),
      style: IconButton.styleFrom(
        elevation: 4,
        shadowColor: Colors.black26,
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.black26),
      ),
    );
  }
}
