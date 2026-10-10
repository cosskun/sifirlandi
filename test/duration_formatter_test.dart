import 'package:flutter_test/flutter_test.dart';
import 'package:sifirlandi/core/utils/duration_formatter.dart';

void main() {
  group('DurationFormatter Tests', () {
    test('formatFull formats days, hours, minutes, seconds correctly in Turkish', () {
      final d = const Duration(days: 3, hours: 4, minutes: 15, seconds: 30);
      final result = DurationFormatter.formatFull(d, lang: 'tr');
      expect(result, '3 gün 4 saat 15 dakika 30 saniye');
    });

    test('formatFull formats days, hours, minutes, seconds correctly in English', () {
      final d = const Duration(days: 1, hours: 2, minutes: 3, seconds: 4);
      final result = DurationFormatter.formatFull(d, lang: 'en');
      expect(result, '1 days 2 hours 3 minutes 4 seconds');
    });

    test('formatCompact formats short ticker correctly', () {
      final d = const Duration(days: 5, hours: 10, minutes: 20, seconds: 45);
      final result = DurationFormatter.formatCompact(d, lang: 'tr');
      expect(result, '5g 10s 20d 45sn');
    });

    test('formatAverage formats average durations correctly', () {
      final d = const Duration(days: 4, hours: 12);
      final result = DurationFormatter.formatAverage(d, lang: 'tr');
      expect(result, '4.5 gün');
    });
  });
}
