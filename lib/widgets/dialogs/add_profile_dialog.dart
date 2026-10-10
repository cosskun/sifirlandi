import 'package:flutter/material.dart';
import '../../models/counter_profile.dart';
import '../../core/constants/app_categories.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/firebase_service.dart';

class AddProfileDialog extends StatefulWidget {
  final String currentLanguage;
  final bool isDark;
  final Function(CounterProfile profile) onCreated;

  const AddProfileDialog({
    super.key,
    required this.currentLanguage,
    required this.isDark,
    required this.onCreated,
  });

  @override
  State<AddProfileDialog> createState() => _AddProfileDialogState();
}

class _AddProfileDialogState extends State<AddProfileDialog> {
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  String _selectedCategory = 'clumsy';
  String _selectedEmoji = '🩹';
  bool _isShared = false;

  final List<String> _emojis = [
    '🩹', '⏰', '🍔', '💔', '🚭', '💻', '🎮', '💸', '☕', '🚗', '🏃‍♂️', '🎯', '🥗', '🍩', '🍺', '📝'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _submit() async {
    final name = _nameController.text.trim();
    final title = _titleController.text.trim();

    if (name.isEmpty || title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.currentLanguage == 'tr' ? "Lütfen tüm alanları doldurun!" : "Please fill all fields!"),
          backgroundColor: Colors.red.shade800,
        ),
      );
      return;
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();

    if (_isShared) {
      final sharedProfile = await FirebaseService.createSharedRoom(
        name,
        title,
        _selectedCategory,
        _selectedEmoji,
      );
      widget.onCreated(sharedProfile);
    } else {
      final newProfile = CounterProfile(
        id: id,
        name: name,
        title: title,
        category: _selectedCategory,
        avatarEmoji: _selectedEmoji,
        resets: [],
      );
      widget.onCreated(newProfile);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.tr('createTitle', lang: widget.currentLanguage),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary(isDark),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.textPrimary(isDark)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Emoji Picker Strip
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _emojis.length,
                itemBuilder: (ctx, idx) {
                  final e = _emojis[idx];
                  final isSel = _selectedEmoji == e;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedEmoji = e),
                    child: Container(
                      width: 44,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.primary(isDark).withValues(alpha: 0.2) : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSel ? AppColors.primary(isDark) : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(e, style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Target Name Input
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.tr('personName', lang: widget.currentLanguage),
                hintText: "Örn: Ahmet, Diyetim, Sigara...",
                filled: true,
                fillColor: AppColors.surface(isDark),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),

            // Counter Title Input
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: AppLocalizations.tr('counterName', lang: widget.currentLanguage),
                hintText: "Örn: Sakarlık Yapmama, Sigara İçmeme...",
                filled: true,
                fillColor: AppColors.surface(isDark),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            // Category Chips
            Text(
              AppLocalizations.tr('selectCategory', lang: widget.currentLanguage),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary(isDark),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppCategories.all.map((cat) {
                final isSelected = _selectedCategory == cat.key;
                return ChoiceChip(
                  label: Text("${cat.defaultEmoji} ${cat.getName(widget.currentLanguage)}"),
                  selected: isSelected,
                  selectedColor: AppColors.primary(isDark).withValues(alpha: 0.2),
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _selectedCategory = cat.key;
                        _selectedEmoji = cat.defaultEmoji;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Shared Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                AppLocalizations.tr('isSharedCounter', lang: widget.currentLanguage),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              subtitle: Text(
                AppLocalizations.tr('isSharedSub', lang: widget.currentLanguage),
                style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary(isDark)),
              ),
              value: _isShared,
              activeThumbColor: AppColors.accentNeonCrimson,
              onChanged: (v) => setState(() => _isShared = v),
            ),
            const SizedBox(height: 16),

            // Submit Button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary(isDark),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                onPressed: _submit,
                child: Text(
                  AppLocalizations.tr('createBtn', lang: widget.currentLanguage),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
