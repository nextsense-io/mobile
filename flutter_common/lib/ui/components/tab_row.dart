import 'package:flutter/material.dart';

class TabRow extends StatelessWidget {

  final Text tabHeader;
  final Text content;

  const TabRow({super.key, this.tabHeader = const Text("\u2022", style: TextStyle(fontSize: 30)),
    required this.content});

  @override
  Widget build(BuildContext context) {
    return
      Row(
          children:[
            tabHeader,
            const SizedBox(width: 10), //space between bullet and text
            Expanded(child: content), //text
          ]
      );
  }
}