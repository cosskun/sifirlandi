import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sifirlandi/widgets/common/stat_card_widget.dart';

void main() {
  testWidgets('StatCardWidget renders title, value and icon correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatCardWidget(
            icon: Icons.trending_up,
            title: 'Toplam Rekor',
            value: '14 gün',
            color: Colors.orange,
            isDark: false,
          ),
        ),
      ),
    );

    expect(find.text('Toplam Rekor'), findsOneWidget);
    expect(find.text('14 gün'), findsOneWidget);
    expect(find.byIcon(Icons.trending_up), findsOneWidget);
  });
}
