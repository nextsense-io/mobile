import 'package:flutter/material.dart';
import 'package:nextsense_trial_ui/domain/timed_entry.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:flutter_common/ui/components/rounded_background.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';
import 'package:nextsense_trial_ui/utils/date_utils.dart';

class TimedEntryCard extends StatelessWidget {
  final TimedEntry timedEntry;
  final Function(BuildContext, dynamic) onTap;
  final DateTime dateTime;

  TimedEntryCard(TimedEntry timedEntry, Function(BuildContext, dynamic) onTap) :
        this.timedEntry = timedEntry, this.dateTime = timedEntry.dateTime, this.onTap = onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 80,
        child: Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            child: InkWell(
              onTap: () => onTap(context, timedEntry),
              child: RoundedBackground(child: Align(alignment: Alignment.centerLeft,
                  child: MediumText(text: dateTime.humanized, color: NextSenseColors.darkBlue))),
            )));
  }
}