import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/app_localizations.dart';

class TimerTickerWidget extends StatelessWidget {
  final Duration activeStreak;
  final String currentLanguage;
  final bool isDark;

  const TimerTickerWidget({
    super.key,
    required this.activeStreak,
    required this.currentLanguage,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final days = activeStreak.inDays;
    final hours = activeStreak.inHours % 24;
    final minutes = activeStreak.inMinutes % 60;
    final seconds = activeStreak.inSeconds % 60;

    final primaryColor = AppColors.primary(isDark);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Days Huge Ticker Number
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            days.toString(),
            style: TextStyle(
              fontSize: 84,
              fontWeight: FontWeight.w900,
              fontFamily: 'Courier',
              letterSpacing: -2,
              color: primaryColor,
              shadows: [
                Shadow(
                  color: primaryColor.withValues(alpha: isDark ? 0.4 : 0.15),
                  blurRadius: 20,
                )
              ],
            ),
          ),
        ),

        // Subtitle badge
        Container(
          margin: const EdgeInsets.only(top: 2, bottom: 18),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            AppLocalizations.tr('daysWithoutIncident', lang: currentLanguage),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: primaryColor,
            ),
          ),
        ),

        // Hours : Minutes : Seconds sub-ticker
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141416) : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border(isDark),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSubUnit(hours.toString().padLeft(2, '0'), AppLocalizations.tr('hours', lang: currentLanguage), isDark),
              _buildDivider(isDark),
              _buildSubUnit(minutes.toString().padLeft(2, '0'), AppLocalizations.tr('minutes', lang: currentLanguage), isDark),
              _buildDivider(isDark),
              _buildSubUnit(seconds.toString().padLeft(2, '0'), AppLocalizations.tr('seconds', lang: currentLanguage), isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubUnit(String value, String label, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            fontFamily: 'Courier',
            color: AppColors.textPrimary(isDark),
          ),
        ),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary(isDark),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Text(
      ":",
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: AppColors.textSecondary(isDark).withValues(alpha: 0.5),
      ),
    );
  }
}
