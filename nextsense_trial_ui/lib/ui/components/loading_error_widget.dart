import 'package:flutter/material.dart';
import 'package:nextsense_trial_ui/ui/components/nextsense_button.dart';

class LoadingErrorWidget extends StatelessWidget {

  final String msg;
  final VoidCallback onTap;

  LoadingErrorWidget(this.msg, {required this.onTap});

  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Container(
        height: 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                child: Text(msg, textAlign: TextAlign.center)
            ),
            SizedBox(height: 30,),
            NextsenseButton.primary("Refresh", onPressed: onTap)
          ],
        ),
      ),
    );
  }
}