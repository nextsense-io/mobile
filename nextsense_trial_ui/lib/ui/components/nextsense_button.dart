import 'package:flutter/material.dart';

class NextsenseButton extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  Color? borderColor;
  VoidCallback? onPressed;
  bool isBusy = false;

  NextsenseButton.primary(this.text, {this.onPressed})
      : backgroundColor = Colors.deepPurple,
        textColor = Colors.white;

  NextsenseButton.secondary(this.text, {this.onPressed})
      : backgroundColor = Colors.white,
        textColor = Colors.deepPurple, borderColor = Colors.deepPurple;

  NextsenseButton(this.text,
      {required this.backgroundColor,
      required this.textColor,
      this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 1.0, bottom: 10.0),
      child: TextButton(
          child: _child(),
          style: ButtonStyle(
              padding:
                  MaterialStateProperty.all<EdgeInsets>(EdgeInsets.all(10)),
              foregroundColor: MaterialStateProperty.all<Color>(textColor),
              backgroundColor:
                  MaterialStateProperty.all<Color>(backgroundColor),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                      side: borderColor != null
                          ? BorderSide(color: borderColor!)
                          : BorderSide.none))),
          onPressed: onPressed),
    );
  }

  Widget _child() {
    if (isBusy) {
      return SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.0,
          ));
    }

    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
