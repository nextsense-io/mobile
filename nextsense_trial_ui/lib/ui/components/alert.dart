import 'package:flutter/material.dart';

class SimpleAlertDialog extends StatelessWidget {
  final String title;
  final String content;
  final String buttonText;
  final bool popNavigator;

  SimpleAlertDialog({required this.title, required this.content,
      this.buttonText = 'ok', this.popNavigator = false});

  @override
  Widget build(BuildContext context) {
    Widget okButton = TextButton(
      child: Text(buttonText),
      onPressed: () {
        Navigator.pop(context);
        if (popNavigator) {
          Navigator.pop(context);
        }
      },
    );
    return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          okButton,
        ]
    );
  }
}