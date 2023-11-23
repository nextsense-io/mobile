String humanizeDuration(Duration duration) {
    if (duration.inHours == 0 && duration.inMinutes == 0)
      return '${duration.inSeconds} sec.';

    if (duration.inHours == 0)
      return '${duration.inMinutes} min.';

    var s = '${duration.inHours} hr.';
    if (duration.inMinutes % 60 != 0)
      s += '${duration.inMinutes} min.';
    return s;
}