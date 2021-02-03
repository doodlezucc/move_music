Duration parseIsoDuration(String iso) {
  int part(String id) {
    final regex = RegExp(r'[0-9]');

    var start = iso.indexOf(id);
    if (start < 0) return 0;

    var p = iso.substring(start - 2);
    if (regex.hasMatch(p[0])) {
      // part is two-digit number
      return int.parse(p.substring(0, 2));
    }
    return int.parse(p[1]);
  }

  return Duration(hours: part('H'), minutes: part('M'), seconds: part('S'));
}

String durationString(Duration d) {
  var out =
      (d.inSeconds % Duration.secondsPerMinute).toString().padLeft(2, '0');
  var min = d.inMinutes % Duration.minutesPerHour;
  if (d.inHours > 0) {
    out = '${d.inHours}:' + min.toString().padLeft(2, '0') + ':$out';
  } else {
    out = '$min:$out';
  }
  return out;
}

String plural(int value) => value != 1 ? 's' : '';

String durationSpelledOut(int sec) {
  var out = (sec % 60).toString() + ' second' + plural(sec);
  if (sec < 60) return out;

  var min = (sec / 60).floor() % Duration.minutesPerHour;
  out = min.toString() + ' minute' + plural(min) + ' and ' + out;
  if (sec < 60 * 60) return out;

  var h = (sec / 60 / 60).floor();

  return '$h hour${plural(h)}, $out';
}
