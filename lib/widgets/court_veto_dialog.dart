import 'dart:async';
import 'package:flutter/material.dart';
import '../models/reset_proposal.dart';
import '../services/sound_service.dart';

class CourtVetoDialog extends StatefulWidget {
  final ResetProposal proposal;
  final String currentLanguage;
  final bool isDark;
  final Function(bool isYes) onVote;
  final VoidCallback onVerdictApproved;
  final VoidCallback onVerdictVetoed;

  const CourtVetoDialog({
    super.key,
    required this.proposal,
    required this.currentLanguage,
    required this.isDark,
    required this.onVote,
    required this.onVerdictApproved,
    required this.onVerdictVetoed,
  });

  @override
  State<CourtVetoDialog> createState() => _CourtVetoDialogState();
}

class _CourtVetoDialogState extends State<CourtVetoDialog> {
  late Timer _timer;
  int _secondsRemaining = 60;
  bool? _myVote;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.proposal.expiresAt.difference(DateTime.now()).inSeconds.clamp(0, 60);

    SoundService.play(SoundEffect.sadTrombone);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      final diff = widget.proposal.expiresAt.difference(DateTime.now()).inSeconds;
      if (diff <= 0) {
        t.cancel();
        _finalizeVerdict();
      } else {
        setState(() {
          _secondsRemaining = diff;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _castVote(bool isYes) {
    if (_myVote != null) return;
    SoundService.play(SoundEffect.click);
    setState(() {
      _myVote = isYes;
    });
    widget.onVote(isYes);
  }

  void _finalizeVerdict() {
    final yes = widget.proposal.yesVotes;
    final no = widget.proposal.noVotes;

    if (yes >= no) {
      widget.onVerdictApproved();
    } else {
      widget.onVerdictVetoed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final yes = widget.proposal.yesVotes + (_myVote == true ? 1 : 0);
    final no = widget.proposal.noVotes + (_myVote == false ? 1 : 0);
    final total = yes + no;

    final double yesRatio = total == 0 ? 0.5 : yes / total;
    final double progress = _secondsRemaining / 60.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: isDark ? const Color(0xFF1E1E22) : const Color(0xFFFAF6F0),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gavel Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Text("⚖️", style: TextStyle(fontSize: 26)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.currentLanguage == 'tr' ? "GRUP MAHKEMESİ" : "GROUP COURT",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "$_secondsRemaining sn",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress Countdown Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress < 0.25 ? Colors.redAccent : const Color(0xFFFF2D55),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Accusation Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C1E24) : const Color(0xFFFDEEF2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFF2D55).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.currentLanguage == 'tr'
                        ? "🚨 ${widget.proposal.proposerName} itiraz başlattı:"
                        : "🚨 ${widget.proposal.proposerName} submitted a case:",
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB57C8A)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "\"${widget.proposal.allegedReason}\"",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF2C2526),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.currentLanguage == 'tr'
                        ? "${widget.proposal.targetName} gerçekten sayacı sıfırladı mı?"
                        : "Did ${widget.proposal.targetName} really reset the counter?",
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Live Vote Ratio Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("✅ $yes Suçlu", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                Text("❌ $no Masum", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: [
                    Expanded(
                      flex: (yesRatio * 100).toInt(),
                      child: Container(color: Colors.green.shade600),
                    ),
                    Expanded(
                      flex: ((1 - yesRatio) * 100).toInt(),
                      child: Container(color: Colors.red.shade400),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Vote Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _myVote == true ? Colors.green.shade800 : Colors.green.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _myVote != null ? null : () => _castVote(true),
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: Text(
                      widget.currentLanguage == 'tr' ? "Doğru Bozdu" : "Guilty",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _myVote == false ? Colors.red.shade900 : Colors.red.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _myVote != null ? null : () => _castVote(false),
                    icon: const Icon(Icons.cancel_rounded, size: 16),
                    label: Text(
                      widget.currentLanguage == 'tr' ? "Yalan / Masum" : "Innocent",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
