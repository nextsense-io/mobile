import 'package:flutter/material.dart';

extension AppDialogs on BuildContext {
  showConfirmationDialog({
    required String title,
    required String message,
    Function()? onContinue,
    Function()? onCancel,
  }) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("Cancel", style: Theme.of(this).textTheme.bodyMedium),
      onPressed: () {
        Navigator.pop(this);
        onCancel?.call();
      },
    );
    Widget continueButton = TextButton(
      child: Text("Continue", style: Theme.of(this).textTheme.bodyMedium),
      onPressed: () {
        Navigator.pop(this);
        onContinue?.call();
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(title, style: Theme.of(this).textTheme.bodyLarge),
      content: Text(message, style: Theme.of(this).textTheme.bodyMedium),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: this,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
