import 'package:flutter/material.dart';
import 'package:nextsense_trial_ui/ui/components/content_text.dart';

/* A widget to add drop-down view in app. */
class DropDownMenu extends StatelessWidget {
  final String title;
  final dynamic value;
  final List<dynamic> possibleValues;
  final ValueChanged<dynamic>? onChanged;
  final bool labelAbove;

  DropDownMenu({required this.title, required this.value, required this.possibleValues,
      this.onChanged, this.labelAbove = true});

  Widget _dropDownContainer(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(top: 0, left: 8, bottom: 0),
      child: DropdownButtonHideUnderline(
        child: DropdownButton(
          isExpanded: true,
          value: value,
          dropdownColor: Colors.white,
          items: possibleValues.map((dynamic value) {
            return new DropdownMenuItem<dynamic>(
              value: value,
              child: ContentText(text: value.toString()),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (labelAbove) {
      return Container(
        margin: EdgeInsets.only(bottom: 0, left: 8, right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ContentText(text: title),
            Padding(padding: EdgeInsets.only(top: 0)),
            _dropDownContainer(context)
          ],
        ),
      );
    } else {
      return Container(
        margin: EdgeInsets.only(bottom: 0, left: 8, right: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          // mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(flex: 50, child: ContentText(text: title)),
            Expanded(flex: 50, child: _dropDownContainer(context))
          ],
        ),
      );
    }
  }
}
