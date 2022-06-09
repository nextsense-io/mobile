import 'package:flutter/material.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';

class AddFloatingButton extends StatelessWidget {

  final VoidCallback onPressed;

  AddFloatingButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(onPressed: onPressed,
        backgroundColor: NextSenseColors.red,
        child: Icon(Icons.add, size: 40, color: Colors.white));
  }
}