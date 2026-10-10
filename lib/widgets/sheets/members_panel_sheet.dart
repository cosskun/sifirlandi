import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/counter_profile.dart';
import '../../services/firebase_service.dart';
import '../../services/invite_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/app_localizations.dart';

class MembersPanelSheet extends StatefulWidget {
  final CounterProfile profile;
  final String currentLanguage;
  final bool isDark;
  final Function(CounterProfile) onProfileUpdated;

  const MembersPanelSheet({
    super.key,
    required this.profile,
    required this.currentLanguage,
    required this.isDark,
    required this.onProfileUpdated,
  });

  @override
  State<MembersPanelSheet> createState() => _MembersPanelSheetState();
}

class _MembersPanelSheetState extends State<MembersPanelSheet> {
  late CounterProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
  }

  bool get _isCreator {
    final currentUid = FirebaseService.userId;
    return _profile.creatorId == currentUid || _profile.members[currentUid] == 'admin';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final membersList = _profile.members.keys.toList();

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
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
                  widget.currentLanguage == 'tr' ? "Sayaç Üyeleri" : "Counter Members",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary(isDark),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.textPrimary(isDark)),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 12),

            // Room Code & Invite Actions Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface(isDark),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.tr('roomCode', lang: widget.currentLanguage),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _profile.roomCode ?? "",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary(isDark),
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 20),
                        tooltip: AppLocalizations.tr('copy', lang: widget.currentLanguage),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _profile.roomCode ?? ""));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(widget.currentLanguage == 'tr'
                                  ? "Davet kodu kopyalandı! 📋"
                                  : "Invite code copied! 📋"),
                              backgroundColor: AppColors.primaryBurgundy,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.whatsappGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () {
                            InviteService.shareToWhatsApp(
                              counterTitle: _profile.title,
                              roomCode: _profile.roomCode ?? '',
                              lang: widget.currentLanguage,
                            );
                          },
                          icon: const Icon(Icons.chat_rounded, size: 16),
                          label: Text(
                            AppLocalizations.tr('shareWhatsapp', lang: widget.currentLanguage),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade400),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onPressed: () {
                          InviteService.copyLink(roomCode: _profile.roomCode ?? '');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppLocalizations.tr('copyLink', lang: widget.currentLanguage)),
                              backgroundColor: AppColors.primaryBurgundy,
                            ),
                          );
                        },
                        icon: const Icon(Icons.link_rounded, size: 16),
                        label: Text(
                          AppLocalizations.tr('copyLink', lang: widget.currentLanguage),
                          style: TextStyle(fontSize: 12, color: AppColors.textPrimary(isDark)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Members List Header
            Text(
              "${membersList.length} ${widget.currentLanguage == 'tr' ? 'Üye' : 'Members'}",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary(isDark),
              ),
            ),
            const SizedBox(height: 8),

            // Members List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: membersList.length,
              separatorBuilder: (ctx, idx) => const Divider(height: 1),
              itemBuilder: (ctx, idx) {
                final uid = membersList[idx];
                final role = _profile.members[uid] ?? 'viewer';
                final name = _profile.memberNames[uid] ?? (uid == _profile.creatorId ? "Kurucu" : "Üye #$idx");
                final isCurrent = uid == FirebaseService.userId;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary(isDark).withValues(alpha: 0.15),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : "?",
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary(isDark)),
                    ),
                  ),
                  title: Text(
                    name + (isCurrent ? " (${widget.currentLanguage == 'tr' ? 'Sen' : 'You'})" : ""),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary(isDark),
                    ),
                  ),
                  subtitle: Text(
                    role == 'admin'
                        ? (widget.currentLanguage == 'tr' ? '👑 Kurucu / Yönetici' : '👑 Admin')
                        : role == 'editor'
                            ? (widget.currentLanguage == 'tr' ? '⚡ Sıfırlayabilir' : '⚡ Can Reset')
                            : (widget.currentLanguage == 'tr' ? '👁️ İzleyici' : '👁️ Viewer'),
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary(isDark)),
                  ),
                  trailing: _isCreator && !isCurrent
                      ? PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: AppColors.textSecondary(isDark)),
                          onSelected: (newRole) async {
                            if (newRole == 'remove') {
                              await FirebaseService.removeMember(_profile.roomCode!, uid);
                              final updatedMembers = Map<String, String>.from(_profile.members)..remove(uid);
                              final updatedNames = Map<String, String>.from(_profile.memberNames)..remove(uid);
                              final updated = _profile.copyWith(members: updatedMembers, memberNames: updatedNames);
                              if (mounted) {
                                setState(() => _profile = updated);
                                widget.onProfileUpdated(updated);
                              }
                            } else {
                              await FirebaseService.updateMemberRole(_profile.roomCode!, uid, newRole);
                              final updatedMembers = Map<String, String>.from(_profile.members)..[uid] = newRole;
                              final updated = _profile.copyWith(members: updatedMembers);
                              if (mounted) {
                                setState(() => _profile = updated);
                                widget.onProfileUpdated(updated);
                              }
                            }
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: 'editor',
                              child: Text(widget.currentLanguage == 'tr' ? 'Sıfırlama Yetkisi Ver' : 'Allow Reset'),
                            ),
                            PopupMenuItem(
                              value: 'viewer',
                              child: Text(widget.currentLanguage == 'tr' ? 'Sadece İzleyici Yap' : 'Make Viewer'),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'remove',
                              child: Text(
                                widget.currentLanguage == 'tr' ? 'Odadan Çıkar' : 'Remove from Room',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        )
                      : null,
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
