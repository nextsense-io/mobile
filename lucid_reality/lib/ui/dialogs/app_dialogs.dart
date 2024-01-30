import 'package:disable_battery_optimization/disable_battery_optimization.dart';
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

  Future<bool> showConfirmationDialogWithResult({
    required String title,
    required String message,
    Function()? onContinue,
    Function()? onCancel,
  }) async {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("Cancel", style: Theme.of(this).textTheme.bodyMedium),
      onPressed: () {
        Navigator.pop(this, false);
        onCancel?.call();
      },
    );
    Widget continueButton = TextButton(
      child: Text("Continue", style: Theme.of(this).textTheme.bodyMedium),
      onPressed: () {
        Navigator.pop(this, true);
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
    return await showDialog(
      context: this,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Future<BatteryOptimizationState> isBatteryOptimizationDisabled() async {
    final bool isBatteryOptimizationDisabled =
        await DisableBatteryOptimization.isBatteryOptimizationDisabled ?? true;
    if (isBatteryOptimizationDisabled) {
      return Future.value(BatteryOptimizationState.isDisabled);
    } else {
      var onContinue = await showConfirmationDialogWithResult(
          title: 'Your device has additional battery optimization',
          message:
              "Follow these steps to disable optimizations and enable scheduled notifications for this app.");
      if (onContinue) {
        await DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
      }
      return Future.value(BatteryOptimizationState.isInProgress);
    }
  }
}

enum BatteryOptimizationState { isDisabled, isInProgress, isCompleted, unknown }
