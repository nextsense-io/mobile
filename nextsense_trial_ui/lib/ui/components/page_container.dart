/* A widget that contains the page content with standard margins. */
import 'package:flutter/widgets.dart';

class PageContainer extends StatelessWidget {
  final Widget child;

  PageContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        top: 20,
        right: 20,
        left: 20,
        bottom: 20,
      ),
      child: child,
    );
  }
}