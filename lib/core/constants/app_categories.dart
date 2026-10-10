import 'package:flutter/material.dart';

class AppCategoryInfo {
  final String key;
  final String nameTr;
  final String nameEn;
  final String defaultEmoji;
  final List<Color> gradientColors;
  final Color solidColor;

  const AppCategoryInfo({
    required this.key,
    required this.nameTr,
    required this.nameEn,
    required this.defaultEmoji,
    required this.gradientColors,
    required this.solidColor,
  });

  String getName(String lang) => lang == 'tr' ? nameTr : nameEn;
}

class AppCategories {
  static const List<AppCategoryInfo> all = [
    AppCategoryInfo(
      key: 'clumsy',
      nameTr: 'Kaza / Sakarlık',
      nameEn: 'Clumsiness',
      defaultEmoji: '🩹',
      gradientColors: [Color(0xFFFF5252), Color(0xFFFF7A00)],
      solidColor: Color(0xFFFF5252),
    ),
    AppCategoryInfo(
      key: 'meeting',
      nameTr: 'Geç Kalma',
      nameEn: 'Being Late',
      defaultEmoji: '⏰',
      gradientColors: [Color(0xFFFFB300), Color(0xFFFF6D00)],
      solidColor: Color(0xFFFFB300),
    ),
    AppCategoryInfo(
      key: 'diet',
      nameTr: 'Diyet / Kaçamak',
      nameEn: 'Diet Cheat',
      defaultEmoji: '🍔',
      gradientColors: [Color(0xFF00E676), Color(0xFF00B0FF)],
      solidColor: Color(0xFF00E676),
    ),
    AppCategoryInfo(
      key: 'relationship',
      nameTr: 'Eski Sevgili / Drama',
      nameEn: 'Ex / Drama',
      defaultEmoji: '💔',
      gradientColors: [Color(0xFFFF4081), Color(0xFF7C4DFF)],
      solidColor: Color(0xFFFF4081),
    ),
    AppCategoryInfo(
      key: 'habit',
      nameTr: 'Alışkanlık / Sigara',
      nameEn: 'Habit / Smoke',
      defaultEmoji: '🚭',
      gradientColors: [Color(0xFF78909C), Color(0xFF37474F)],
      solidColor: Color(0xFF78909C),
    ),
    AppCategoryInfo(
      key: 'code',
      nameTr: 'Kodlama / Bug',
      nameEn: 'Coding Bug',
      defaultEmoji: '💻',
      gradientColors: [Color(0xFF2979FF), Color(0xFF651FFF)],
      solidColor: Color(0xFF2979FF),
    ),
    AppCategoryInfo(
      key: 'custom',
      nameTr: 'Özel / Diğer',
      nameEn: 'Custom / Other',
      defaultEmoji: '📝',
      gradientColors: [Color(0xFFAB47BC), Color(0xFF4A148C)],
      solidColor: Color(0xFFAB47BC),
    ),
  ];

  static AppCategoryInfo getByKey(String key) {
    return all.firstWhere(
      (c) => c.key.toLowerCase() == key.toLowerCase(),
      orElse: () => all.last,
    );
  }

  static List<Color> getGradient(String key) => getByKey(key).gradientColors;
  static Color getColor(String key) => getByKey(key).solidColor;
  static String getLabel(String key, String lang) => getByKey(key).getName(lang);
}
