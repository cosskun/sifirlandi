import 'package:flutter_test/flutter_test.dart';
import 'package:sifirlandi/services/penalty_service.dart';

void main() {
  group('PenaltyService Tests', () {
    test('Default penalties list is populated and contains valid entries', () {
      final list = PenaltyService.defaultPenalties;
      expect(list.isNotEmpty, true);
      expect(list.length >= 10, true);
      for (var p in list) {
        expect(p.title.isNotEmpty, true);
        expect(p.emoji.isNotEmpty, true);
        expect(p.description.isNotEmpty, true);
      }
    });

    test('getRandomPenalty returns a valid item from list', () {
      final list = PenaltyService.defaultPenalties;
      final selected = PenaltyService.getRandomPenalty(list);
      expect(list.contains(selected), true);
    });
  });
}
