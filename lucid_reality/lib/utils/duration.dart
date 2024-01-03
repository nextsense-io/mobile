String humanizeDuration(Duration duration) {
  if (duration.inHours == 0 && duration.inMinutes == 0) return '${duration.inSeconds} sec.';

  if (duration.inHours == 0) return '${duration.inMinutes} min.';

  var s = '${duration.inHours} hr.';
  if (duration.inMinutes % 60 != 0) s += '${duration.inMinutes} min.';
  return s;
}

String formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');

  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

  if (duration.inHours > 0) {
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  } else {
    return '$twoDigitMinutes:$twoDigitSeconds';
  }
}
