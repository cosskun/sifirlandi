import 'package:flutter_test/flutter_test.dart';
import 'package:sifirlandi/services/invite_service.dart';

void main() {
  group('InviteService Tests', () {
    test('generateInviteLink creates expected URL format with room code', () {
      final url = InviteService.generateInviteLink('A8B2C4');
      expect(url, 'https://sifirlandi.web.app/?join=A8B2C4');
    });

    test('generateShareMessage generates rich Turkish share text', () {
      final msg = InviteService.generateShareMessage(
        counterTitle: 'Diyet Bozmama',
        roomCode: 'X9Y8Z7',
        lang: 'tr',
      );
      expect(msg.contains('Diyet Bozmama'), true);
      expect(msg.contains('X9Y8Z7'), true);
      expect(msg.contains('https://sifirlandi.web.app/?join=X9Y8Z7'), true);
    });
  });
}
