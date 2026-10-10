import 'package:flutter_test/flutter_test.dart';
import 'package:sifirlandi/services/gemini_service.dart';

void main() {
  group('SmartRoastEngine (GeminiService) Tests', () {
    test('Generates fast food / night eating contextual roast when note mentions çiğ köfte', () async {
      final roast = await GeminiService.generateRoast(
        name: 'Ahmet',
        category: 'diet',
        elapsedTimeFormatted: '5 gün',
        counterTitle: 'Diyet',
        note: 'Gece 3 te çiğ köfte yedim',
        lang: 'tr',
      );

      expect(roast.isNotEmpty, true);
      // Roast should have dynamic comedic flair
      expect(roast.length > 20, true);
    });

    test('Generates relationship / ex roast when note mentions ex', () async {
      final roast = await GeminiService.generateRoast(
        name: 'Mehmet',
        category: 'relationship',
        elapsedTimeFormatted: '10 gün',
        counterTitle: 'Gurur',
        note: 'Eski sevgilime yazdım mesaj attım',
        lang: 'tr',
      );

      expect(roast.isNotEmpty, true);
      expect(roast.contains('Mehmet') || roast.length > 20, true);
    });

    test('Generates dynamic fallback roast for custom obscure notes', () async {
      final roast = await GeminiService.generateRoast(
        name: 'Ali',
        category: 'custom',
        elapsedTimeFormatted: '2 gün',
        counterTitle: 'Çalışma',
        note: 'Kedim klavyeme bastı',
        lang: 'tr',
      );

      expect(roast.isNotEmpty, true);
      expect(roast.length > 15, true);
    });
  });
}
