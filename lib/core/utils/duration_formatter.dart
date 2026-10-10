class DurationFormatter {
  /// Formats duration into full localized text, e.g. "4 gün 12 saat 30 dakika 15 saniye"
  static String formatFull(Duration d, {String lang = 'tr'}) {
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;

    final isTr = lang == 'tr';
    final parts = <String>[];

    if (days > 0) parts.add("$days ${isTr ? 'gün' : 'days'}");
    if (hours > 0) parts.add("$hours ${isTr ? 'saat' : 'hours'}");
    if (minutes > 0) parts.add("$minutes ${isTr ? 'dakika' : 'minutes'}");
    parts.add("$seconds ${isTr ? 'saniye' : 'seconds'}");

    return parts.join(' ');
  }

  /// Formats duration into compact ticker text, e.g. "4g 12s 30d 15sn"
  static String formatCompact(Duration d, {String lang = 'tr'}) {
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;

    final isTr = lang == 'tr';
    final dUnit = isTr ? 'g' : 'd';
    final hUnit = isTr ? 's' : 'h';
    final mUnit = isTr ? 'd' : 'm';
    final sUnit = isTr ? 'sn' : 's';

    return "${days}$dUnit ${hours}$hUnit ${minutes}$mUnit ${seconds}$sUnit";
  }

  /// Formats average streak or frequency text, e.g. "3.5 gün" or "12 saat"
  static String formatAverage(Duration d, {String lang = 'tr'}) {
    final isTr = lang == 'tr';
    if (d.inDays > 0) {
      final days = (d.inHours / 24.0).toStringAsFixed(1);
      return "$days ${isTr ? 'gün' : 'days'}";
    } else if (d.inHours > 0) {
      return "${d.inHours} ${isTr ? 'saat' : 'hours'}";
    } else if (d.inMinutes > 0) {
      return "${d.inMinutes} ${isTr ? 'dk' : 'min'}";
    } else {
      return "${d.inSeconds} ${isTr ? 'sn' : 'sec'}";
    }
  }
}
