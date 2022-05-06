import 'package:flutter/material.dart';

class WaitWidget extends StatelessWidget {
  final Widget message;
  final bool textVisible;

  const WaitWidget({required this.message, this.textVisible = true});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Visibility(
            visible: textVisible,
            child: message,),
          SizedBox(
            height: 20,
          ),
          Container(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }
}