import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sifirlandi/main.dart';
import 'package:sifirlandi/models/counter_profile.dart';
import 'package:sifirlandi/models/reset_entry.dart';
import 'package:sifirlandi/models/public_counter.dart';
import 'package:sifirlandi/models/counter_comment.dart';
import 'package:sifirlandi/screens/profile_detail_screen.dart';
import 'package:sifirlandi/screens/public_counter_detail_screen.dart';
import 'package:sifirlandi/screens/widget_studio_screen.dart';
import 'package:sifirlandi/widgets/penalty_wheel_dialog.dart';
import 'package:sifirlandi/widgets/court_veto_dialog.dart';
import 'package:sifirlandi/widgets/milestone_certificate_dialog.dart';
import 'package:sifirlandi/models/milestone_badge.dart';
import 'package:sifirlandi/models/reset_proposal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleResets = [
    ResetEntry(
      id: 'res_1',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      note: 'Yine geç kaldı',
      roastMessage: 'Saatler sana işlemiyor galiba! ⏰',
      durationSincePrevious: const Duration(days: 2),
    ),
    ResetEntry(
      id: 'res_2',
      timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
      note: 'Diyette tatlı yedi',
      roastMessage: 'Pazartesi başlanan diyet salı bitti 🍩',
      durationSincePrevious: Duration.zero,
    ),
  ];

  final sampleProfile = CounterProfile(
    id: 'test_prof_1',
    name: 'Can',
    title: 'Buluşmaya Zamanında Gelme',
    category: 'meeting',
    avatarEmoji: '⏰',
    longestStreakSeconds: 172800, // 2 days
    resets: sampleResets,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'sifirlandi_is_premium': false,
      'sifirlandi_theme_mode': 'light',
      'shared_user_display_name': 'TestKullanici',
    });
  });

  group('1. HomeScreen Tests - Tabs, Dialogs and Navigation', () {
    testWidgets('Renders HomeScreen with tabs and creates new profile via FAB modal', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Check title and Private tab
      expect(find.text('SIFIRLANDI!'), findsOneWidget);
      expect(find.text('Bireysel'), findsOneWidget);
      expect(find.text('Ortak'), findsOneWidget);
      expect(find.text('Keşfet 🌍'), findsOneWidget);

      // Open Add Profile FAB Modal
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);
      await tester.tap(fab);
      await tester.pumpAndSettle();

      // Add profile modal should be open
      expect(find.text('Yeni Sayaç Oluştur'), findsOneWidget);
      expect(find.text('Oluştur'), findsOneWidget);

      // Type name and title
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));
      await tester.enterText(textFields.first, 'Burak');
      await tester.enterText(textFields.last, 'Sigarayı Bırakma');
      await tester.pumpAndSettle();

      // Tap Create
      await tester.tap(find.text('Oluştur'));
      await tester.pumpAndSettle();

      // Verify new profile card appears in grid
      expect(find.text('Burak'), findsOneWidget);
      expect(find.text('Sigarayı Bırakma'), findsOneWidget);
    });

    testWidgets('Quick reset dialog opens, submits note, and displays roast dialog', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Ensure profile exists
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.first, 'Selin');
      await tester.enterText(textFields.last, 'Diyeti Bozma');
      await tester.tap(find.text('Oluştur'));
      await tester.pumpAndSettle();

      // Tap Quick Reset (rotate_left_rounded) on card
      final quickResetBtn = find.byIcon(Icons.rotate_left_rounded);
      expect(quickResetBtn, findsWidgets);
      await tester.tap(quickResetBtn.first);
      await tester.pumpAndSettle();

      // Check Quick Reset dialog
      expect(find.text('Hızlı Sıfırla'), findsOneWidget);
      final noteField = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));
      await tester.enterText(noteField, 'Çikolata yedi');
      await tester.pumpAndSettle();

      // Tap Sıfırla
      final resetConfirmBtn = find.widgetWithText(ElevatedButton, 'Sıfırla!');
      expect(resetConfirmBtn, findsOneWidget);
      await tester.tap(resetConfirmBtn);
      await tester.pumpAndSettle();

      // Check Roast dialog opens
      expect(find.text('EYVAH! SIFIRLANDI!'), findsOneWidget);
      expect(find.text('Kapat'), findsOneWidget);
      await tester.tap(find.text('Kapat'));
      await tester.pumpAndSettle();
    });

    testWidgets('Switches tabs between Private, Shared, and Explore cleanly', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Tap Shared Tab
      await tester.tap(find.text('Ortak'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Katıl'), findsOneWidget);

      // Tap Katıl
      await tester.tap(find.text('Katıl'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Ortak Sayaca Katıl'), findsOneWidget);
      await tester.tap(find.text('İptal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Tap Explore Tab
      await tester.tap(find.text('Keşfet 🌍'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Trend & Popüler Sayaçlar'), findsOneWidget);
    });

    testWidgets('AppBar popup menu opens Edit Nickname and Premium Shop dialogs', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Open PopupMenuButton
      final popupBtn = find.byType(PopupMenuButton<String>);
      expect(popupBtn, findsOneWidget);
      await tester.tap(popupBtn);
      await tester.pumpAndSettle();

      // Tap Edit Nickname
      expect(find.text('Rumuz Değiştir'), findsOneWidget);
      await tester.tap(find.text('Rumuz Değiştir'));
      await tester.pumpAndSettle();

      expect(find.text('Profil İsmi Düzenle'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'EfsaneKullanici');
      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();

      // Open PopupMenuButton again for Premium Shop
      await tester.tap(popupBtn);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Premium Mağaza'));
      await tester.pumpAndSettle();

      expect(find.text('SIFIRLANDI! PREMIUM 👑'), findsOneWidget);
      expect(find.text('🚫 Tüm Reklamları Kaldır'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
    });
  });

  group('2. ProfileDetailScreen Tests - Ticker, Stats, Badges, Wheel, Court', () {
    testWidgets('Renders ProfileDetailScreen and all subcomponents without overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileDetailScreen(
            profile: sampleProfile,
            currentLanguage: 'tr',
            isPremium: true,
            themeMode: 'light',
            onProfileUpdated: (_) {},
            onProfileDeleted: (_) {},
            onPremiumStatusChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Profile details
      expect(find.text('CAN'), findsOneWidget);
      expect(find.text('Buluşmaya Zamanında Gelme'), findsOneWidget);
      expect(find.text('TOPLAM SIFIRLAMA'), findsOneWidget);
      expect(find.text('BAŞARI ROZETLERİ'), findsOneWidget);
      expect(find.text('Ceza Çarkı 🎯'), findsOneWidget);
      expect(find.text('SIFIRLA! 🚨'), findsOneWidget);
      expect(find.text('Paylaş 📸'), findsOneWidget);
      expect(find.text('Widget Ekle 📱'), findsOneWidget);
    });

    testWidgets('Opens PenaltyWheelDialog and spins wheel', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PenaltyWheelDialog(
              targetName: 'Can',
              currentLanguage: 'tr',
              isDark: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CEZA & GÖREV ÇARKI'), findsOneWidget);
      expect(find.text('ÇARKI ÇEVİR! 🎯'), findsOneWidget);

      // Tap spin button
      await tester.tap(find.text('ÇARKI ÇEVİR! 🎯'));
      await tester.pump(); // animation start

      // Advance animation through completion
      await tester.pump(const Duration(milliseconds: 4000));
      await tester.pumpAndSettle();

      // Should show winner penalty card
      expect(find.text('Gruba Gönder'), findsOneWidget);
    });

    testWidgets('Opens CourtVetoDialog and casts vote without assertion error', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final proposal = ResetProposal(
        id: 'prop_test',
        counterId: 'c_1',
        proposerName: 'Mehmet',
        targetName: 'Ahmet',
        allegedReason: 'Buluşmaya 45 dakika geç geldi!',
        votes: {'u1': true, 'u2': true, 'u3': true}, // tests 100% yes ratio edge case (flex > 0 safety)
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(seconds: 45)),
      );

      bool votedYes = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CourtVetoDialog(
              proposal: proposal,
              currentLanguage: 'tr',
              isDark: false,
              onVote: (isYes) {
                votedYes = isYes;
              },
              onVerdictApproved: () {},
              onVerdictVetoed: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('GRUP MAHKEMESİ'), findsOneWidget);
      expect(find.text('Doğru Bozdu'), findsOneWidget);
      expect(find.text('Yalan / Masum'), findsOneWidget);

      // Tap "Doğru Bozdu"
      await tester.tap(find.text('Doğru Bozdu'));
      await tester.pumpAndSettle();

      expect(votedYes, isTrue);
    });

    testWidgets('Opens MilestoneCertificateDialog and renders badge trophy', (WidgetTester tester) async {
      final badge = MilestoneBadge(
        id: 'week_1',
        title: 'Çelik İrade',
        description: '1 Hafta Boyunca Sıfırlanmadı!',
        targetDays: 7,
        iconEmoji: '🥈',
        tier: 'silver',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MilestoneCertificateDialog(
              badge: badge,
              userName: 'Can',
              counterTitle: 'Sigarayı Bırakma',
              currentLanguage: 'tr',
              isDark: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('YENİ ROZET AÇILDI! 🎉'), findsOneWidget);
      expect(find.text('Çelik İrade'), findsOneWidget);
      expect(find.text('Kapat'), findsOneWidget);
    });
  });

  group('3. PublicCounterDetailScreen & Community Interactions', () {
    testWidgets('Renders PublicCounterDetailScreen and allows liking & commenting', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final counter = PublicCounter(
        id: 'trend_1',
        title: 'İstanbul Trafiğinde Kaza Olmayan Süre',
        description: 'Trafik akıcı ilerliyor',
        category: 'traffic',
        locationTag: 'İstanbul / E-5',
        avatarEmoji: '🚗',
        lastResetTime: DateTime.now().subtract(const Duration(hours: 3)),
        resetCount: 42,
        likesCount: 15,
        recentComments: [
          CounterComment(
            id: 'comm_1',
            counterId: 'trend_1',
            authorName: 'Sürücü34',
            content: 'Köprü çıkışı kilitlendi yine',
            reactionEmoji: '🚗',
            timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PublicCounterDetailScreen(
            counter: counter,
            currentLanguage: 'tr',
            isPremium: false,
            themeMode: 'light',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TREND SAYAÇ'), findsOneWidget);
      expect(find.text('İstanbul Trafiğinde Kaza Olmayan Süre'), findsOneWidget);
      expect(find.text('CANLI TOPLULUK AKIŞI'), findsOneWidget);
      expect(find.text('Köprü çıkışı kilitlendi yine'), findsOneWidget);

      // Tap Like Icon
      final likeIcon = find.byIcon(Icons.favorite);
      expect(likeIcon, findsOneWidget);
      await tester.tap(likeIcon);
      await tester.pumpAndSettle();

      // Enter comment
      final commentField = find.byType(TextField);
      await tester.enterText(commentField, 'Mecidiyeköy açık');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();
    });
  });

  group('4. WidgetStudioScreen Tests - Themes & Dropdowns', () {
    testWidgets('Renders WidgetStudioScreen and handles theme switching cleanly', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: WidgetStudioScreen(
            profiles: [sampleProfile],
            currentLanguage: 'tr',
            isDark: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ana Ekran Widget Stüdyosu 🧩'), findsOneWidget);
      expect(find.text('⚡ Cyber Neon'), findsOneWidget);
      expect(find.text('🖤 Obsidian'), findsOneWidget);
      expect(find.text('🍷 Bordo'), findsOneWidget);

      // Switch theme to Obsidian
      await tester.tap(find.text('🖤 Obsidian'));
      await tester.pumpAndSettle();

      // Tap Save Widget button
      final saveBtn = find.text("WIDGET'I KAYDET & ETKİNLEŞTİR");
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();
    });

    testWidgets('Renders WidgetStudioScreen even with empty profiles list without crashing', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: WidgetStudioScreen(
            profiles: [],
            currentLanguage: 'tr',
            isDark: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should render dummy profile without DropdownButton assertion crash
      expect(find.text('Ana Ekran Widget Stüdyosu 🧩'), findsOneWidget);
      expect(find.text('Diyeti Bozmama'), findsWidgets);
    });
  });

  group('5. Ultra-Compact Screen (320x568 iPhone SE) Overflow Verification', () {
    testWidgets('HomeScreen and ProfileDetailScreen render on 320x568 with zero RenderFlex overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320 * 2, 568 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MyApp());
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileDetailScreen(
            profile: sampleProfile,
            currentLanguage: 'tr',
            isPremium: false,
            themeMode: 'light',
            onProfileUpdated: (_) {},
            onProfileDeleted: (_) {},
            onPremiumStatusChanged: (_) {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });
  });
}
