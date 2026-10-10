import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/public_counter.dart';
import '../services/public_counters_service.dart';
import '../services/gemini_service.dart';
import '../services/sound_service.dart';

class PublicCounterDetailScreen extends StatefulWidget {
  final PublicCounter counter;
  final String currentLanguage;
  final bool isPremium;
  final String themeMode;

  const PublicCounterDetailScreen({
    super.key,
    required this.counter,
    required this.currentLanguage,
    required this.isPremium,
    required this.themeMode,
  });

  @override
  State<PublicCounterDetailScreen> createState() => _PublicCounterDetailScreenState();
}

class _PublicCounterDetailScreenState extends State<PublicCounterDetailScreen> {
  late PublicCounter _counter;
  Timer? _timer;
  Duration _timeElapsed = Duration.zero;
  final TextEditingController _commentController = TextEditingController();
  String _selectedReactionEmoji = '🔥';
  bool _isResetting = false;

  final List<String> _quickEmojis = ['🔥', '💀', '🤡', '👏', '☕', '💸', '🍕', '💔'];

  @override
  void initState() {
    super.initState();
    _counter = widget.counter;
    _updateTimer();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _updateTimer();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _commentController.dispose();
    super.dispose();
  }

  void _updateTimer() {
    _timeElapsed = DateTime.now().difference(_counter.lastResetTime);
  }

  Future<void> _handleReset() async {
    final TextEditingController reasonController = TextEditingController();
    final isDark = widget.themeMode == 'dark';

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E1E22) : const Color(0xFFFAF6F0),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF2D55)),
            const SizedBox(width: 8),
            Text(
              widget.currentLanguage == 'tr' ? "Trend Sayacı Sıfırla" : "Reset Trend Counter",
              style: TextStyle(
                color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.currentLanguage == 'tr'
                  ? "Bu sayacı sıfırlama sebebinizi veya gördüğünüz olayı yazın:"
                  : "Enter your reason or incident details:",
              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: widget.currentLanguage == 'tr'
                    ? "Örn: Köprüde kaza oldu / Dolar arttı..."
                    : "e.g., Incident witnessed...",
                filled: true,
                fillColor: isDark ? const Color(0xFF2C2C32) : Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.currentLanguage == 'tr' ? "Vazgeç" : "Cancel", style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF2D55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context, reasonController.text.trim());
            },
            child: Text(
              widget.currentLanguage == 'tr' ? "SIFIRLA! 🚨" : "RESET! 🚨",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _isResetting = true;
      });

      // Play Sound Effect
      await SoundService.play(SoundEffect.siren);

      // Perform reset in service
      await PublicCountersService.resetPublicCounter(_counter.id, result);

      // Generate AI Roast
      final roast = await GeminiService.generateRoast(
        name: _counter.title,
        category: _counter.category,
        note: result,
        counterTitle: _counter.title,
        elapsedTimeFormatted: _formatDuration(_timeElapsed),
        lang: widget.currentLanguage,
      );

      // Update local state
      final updated = await PublicCountersService.getPublicCounter(_counter.id);
      if (mounted) {
        setState(() {
          if (updated != null) _counter = updated;
          _isResetting = false;
        });

        // Show Roast Overlay
        _showRoastSnackbar(roast);
      }
    }
  }

  void _showRoastSnackbar(String roast) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF800020),
        duration: const Duration(seconds: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Text("🤖", style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.currentLanguage == 'tr' ? "GEMINI AI ROAST 🧠" : "GEMINI AI ROAST 🧠",
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    roast,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    _commentController.clear();
    await SoundService.play(SoundEffect.click);

    await PublicCountersService.addComment(
      counterId: _counter.id,
      content: text,
      emoji: _selectedReactionEmoji,
    );

    final updated = await PublicCountersService.getPublicCounter(_counter.id);
    if (mounted && updated != null) {
      setState(() {
        _counter = updated;
      });
    }
  }

  Future<void> _handleLike() async {
    await SoundService.play(SoundEffect.victory);
    await PublicCountersService.likeCounter(_counter.id);
    final updated = await PublicCountersService.getPublicCounter(_counter.id);
    if (mounted && updated != null) {
      setState(() {
        _counter = updated;
      });
    }
  }

  String _formatDuration(Duration d) {
    final days = d.inDays;
    final hours = d.inHours % 24;
    final mins = d.inMinutes % 60;
    final secs = d.inSeconds % 60;
    return "${days}g ${hours}s ${mins}d ${secs}sn";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeMode == 'dark';
    final days = _timeElapsed.inDays;
    final hours = _timeElapsed.inHours % 24;
    final minutes = _timeElapsed.inMinutes % 60;
    final seconds = _timeElapsed.inSeconds % 60;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121214) : const Color(0xFFFAF6F0),
      appBar: AppBar(
        title: Text(
          widget.currentLanguage == 'tr' ? "TREND SAYAÇ" : "TRENDING COUNTER",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.2,
            color: isDark ? const Color(0xFFFF2D55) : const Color(0xFFFAF6F0),
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E1E22) : const Color(0xFF800020),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              SoundService.isSoundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: isDark ? Colors.white : Colors.white,
            ),
            onPressed: () async {
              await SoundService.toggleSound();
              setState(() {});
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E22) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 12, offset: const Offset(0, 4))
                        ],
                        border: Border.all(color: isDark ? Colors.grey.shade800 : const Color(0xFFE8D0D5).withOpacity(0.4)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFFFF2D55).withOpacity(0.2) : const Color(0xFF800020).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on_rounded, color: Color(0xFFFF2D55), size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      _counter.locationTag,
                                      style: TextStyle(
                                        color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.favorite, color: Colors.pink, size: 20),
                                    onPressed: _handleLike,
                                  ),
                                  Text(
                                    "${_counter.likesCount}",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(_counter.avatarEmoji, style: const TextStyle(fontSize: 48)),
                          const SizedBox(height: 8),
                          Text(
                            _counter.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF2C2526),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _counter.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                          const SizedBox(height: 20),

                          // Digital Counter
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildSegment(days.toString().padLeft(2, '0'), "GÜN", isDark),
                              const SizedBox(width: 6),
                              _buildSegment(hours.toString().padLeft(2, '0'), "SAAT", isDark),
                              const SizedBox(width: 6),
                              _buildSegment(minutes.toString().padLeft(2, '0'), "DAKİKA", isDark),
                              const SizedBox(width: 6),
                              _buildSegment(seconds.toString().padLeft(2, '0'), "SANİYE", isDark),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Text(
                            "Toplam ${_counter.resetCount} Kez Sıfırlandı",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB57C8A)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Reset Button
                    SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF2D55),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          shadowColor: const Color(0xFFFF2D55).withOpacity(0.4),
                        ),
                        onPressed: _isResetting ? null : _handleReset,
                        icon: const Icon(Icons.rotate_left_rounded, color: Colors.white, size: 22),
                        label: Text(
                          _isResetting
                              ? (widget.currentLanguage == 'tr' ? "Sıfırlanıyor..." : "Resetting...")
                              : (widget.currentLanguage == 'tr' ? "SAYACI SIFIRLA! 🚨" : "RESET COUNTER! 🚨"),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Live Comments Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.currentLanguage == 'tr' ? "CANLI TOPLULUK AKIŞI" : "COMMUNITY FEED",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          "${_counter.recentComments.length} Yorum",
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB57C8A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Comments List
                    if (_counter.recentComments.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          child: Text(
                            widget.currentLanguage == 'tr' ? "Henüz yorum yok, ilk sen yaz! 💬" : "No comments yet!",
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _counter.recentComments.length,
                        itemBuilder: (context, idx) {
                          final c = _counter.recentComments[idx];
                          final formattedTime = DateFormat('HH:mm, dd MMM').format(c.timestamp);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1E22) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDark ? Colors.grey.shade800 : const Color(0xFFE8D0D5).withOpacity(0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isDark ? const Color(0xFF2C2C32) : const Color(0xFFF3E8EB),
                                  child: Text(c.reactionEmoji, style: const TextStyle(fontSize: 16)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              c.authorName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: isDark ? Colors.white : const Color(0xFF2C2526),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            formattedTime,
                                            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        c.content,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark ? Colors.grey.shade300 : const Color(0xFF4A3E3F),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),

            // Bottom Comment Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E22) : Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, -2))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Emoji reaction selector row
                  SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _quickEmojis.length,
                      itemBuilder: (context, i) {
                        final em = _quickEmojis[i];
                        final isSel = em == _selectedReactionEmoji;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedReactionEmoji = em;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? (isDark ? const Color(0xFFFF2D55).withOpacity(0.3) : const Color(0xFF800020).withOpacity(0.15))
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSel ? const Color(0xFFFF2D55) : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Center(child: Text(em, style: const TextStyle(fontSize: 16))),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: widget.currentLanguage == 'tr' ? "Sen de bir şeyler yaz..." : "Add a comment...",
                            filled: true,
                            fillColor: isDark ? const Color(0xFF2C2C32) : const Color(0xFFF3E8EB),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                          ),
                          onSubmitted: (_) => _sendComment(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.send_rounded, size: 18),
                        onPressed: _sendComment,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegment(String val, String label, bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C32) : const Color(0xFF800020),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            val,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
              color: isDark ? const Color(0xFFFF2D55) : Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
          ),
        ),
      ],
    );
  }
}
