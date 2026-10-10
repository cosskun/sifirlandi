import 'package:flutter_test/flutter_test.dart';
import 'package:sifirlandi/services/milestone_service.dart';

void main() {
  group('MilestoneService Tests', () {
    test('Calculates 0 unlocked badges for brand new counter', () {
      final unlocked = MilestoneService.getUnlockedBadges(Duration.zero);
      expect(unlocked.isEmpty, true);
    });

    test('Unlocks 1-day badge after 24 hours', () {
      final unlocked = MilestoneService.getUnlockedBadges(const Duration(days: 1, hours: 2));
      expect(unlocked.length, 1);
      expect(unlocked.first.id, 'm1');
    });

    test('Unlocks multiple badges as streak grows to 10 days', () {
      final unlocked = MilestoneService.getUnlockedBadges(const Duration(days: 10));
      expect(unlocked.length, 3); // 1-day, 3-day, 7-day
    });

    test('Returns correct next milestone and progress percentage', () {
      final next = MilestoneService.getNextMilestone(const Duration(days: 5));
      expect(next?.id, 'm7'); // Next target is 7 days

      final progress = MilestoneService.calculateProgress(const Duration(days: 5));
      expect(progress > 0.0 && progress < 1.0, true);
    });
  });
}
