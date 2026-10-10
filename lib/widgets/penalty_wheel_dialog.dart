import 'dart:math';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/penalty_item.dart';
import '../services/penalty_service.dart';
import '../services/sound_service.dart';

class PenaltyWheelDialog extends StatefulWidget {
  final String targetName;
  final String currentLanguage;
  final bool isDark;

  const PenaltyWheelDialog({
    super.key,
    required this.targetName,
    required this.currentLanguage,
    required this.isDark,
  });

  @override
  State<PenaltyWheelDialog> createState() => _PenaltyWheelDialogState();
}

class _PenaltyWheelDialogState extends State<PenaltyWheelDialog>
    with SingleTickerProviderStateMixin {
  List<PenaltyItem> _penalties = [];
  late AnimationController _animController;
  late Animation<double> _spinAnimation;
  double _currentAngle = 0.0;
  double _targetAngle = 0.0;
  bool _isSpinning = false;
  PenaltyItem? _selectedPenalty;

  final List<Color> _sliceColors = [
    const Color(0xFFFF2D55),
    const Color(0xFFFF9500),
    const Color(0xFFFFCC00),
    const Color(0xFF34C759),
    const Color(0xFF00C7BE),
    const Color(0xFF30B0C7),
    const Color(0xFF007AFF),
    const Color(0xFF5856D6),
    const Color(0xFFAF52DE),
    const Color(0xFFFF2D55),
    const Color(0xFFFF3B30),
    const Color(0xFFE040FB),
  ];

  @override
  void initState() {
    super.initState();
    _penalties = PenaltyService.defaultPenalties.take(8).toList();
    _loadPenalties();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );

    _animController.addListener(() {
      setState(() {
        _currentAngle = _spinAnimation.value;
      });
    });

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _calculateWinner();
      }
    });
  }

  Future<void> _loadPenalties() async {
    final list = await PenaltyService.getAllPenalties();
    if (mounted) {
      setState(() {
        _penalties = list.take(8).toList();
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _spinWheel() {
    if (_isSpinning) return;

    SoundService.play(SoundEffect.click);

    final random = Random();
    final extraRounds = 5 + random.nextInt(4); // 5 to 8 full spins
    final randomOffset = random.nextDouble() * 2 * pi;
    _targetAngle = _currentAngle + (extraRounds * 2 * pi) + randomOffset;

    _spinAnimation = Tween<double>(
      begin: _currentAngle,
      end: _targetAngle,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    setState(() {
      _isSpinning = true;
      _selectedPenalty = null;
    });

    _animController.forward(from: 0.0);
  }

  void _calculateWinner() {
    final normalized = (_targetAngle % (2 * pi));
    final sliceAngle = (2 * pi) / _penalties.length;
    // Pointer is at the top (3*pi/2)
    final pointerAngle = (3 * pi / 2 - normalized + 2 * pi) % (2 * pi);
    final index = (pointerAngle / sliceAngle).floor() % _penalties.length;

    SoundService.play(SoundEffect.victory);

    setState(() {
      _isSpinning = false;
      _selectedPenalty = _penalties[index];
    });
  }

  void _shareResult() {
    if (_selectedPenalty == null) return;
    final text = """🚨 SIFIRLANDI! CEZA ÇARKI SONUCU 🎯

${widget.targetName} adlı arkadaşımızın sayacı sıfırlandı ve çarktan ceza çıktı!
${_selectedPenalty!.emoji} Ceza: ${_selectedPenalty!.title}
"${_selectedPenalty!.description}"

Bakalım görevi yerine getirecek mi? 🍿👀""";

    Share.share(text, subject: "Sıfırlandı! Ceza Çarkı");
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: isDark ? const Color(0xFF1E1E22) : const Color(0xFFFAF6F0),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Text("🎯", style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.currentLanguage == 'tr' ? "CEZA & GÖREV ÇARKI" : "PENALTY WHEEL",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                              color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.currentLanguage == 'tr'
                    ? "${widget.targetName} için ceza çarkını çevirin!"
                    : "Spin the wheel for ${widget.targetName}!",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 20),

              // Wheel Canvas with Pointer
              SizedBox(
                width: 250,
                height: 250,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Spinning Wheel
                    Transform.rotate(
                      angle: _currentAngle,
                      child: CustomPaint(
                        size: const Size(240, 240),
                        painter: _WheelPainter(
                          items: _penalties,
                          colors: _sliceColors,
                          isDark: isDark,
                        ),
                      ),
                    ),

                    // Outer Border Ring
                    Container(
                      width: 242,
                      height: 242,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                          width: 4,
                        ),
                      ),
                    ),

                    // Center Hub Button / Pin
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? const Color(0xFF1E1E22) : Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                          )
                        ],
                        border: Border.all(
                          color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                          width: 3,
                        ),
                      ),
                      child: const Center(
                        child: Text("🎯", style: TextStyle(fontSize: 18)),
                      ),
                    ),

                    // Top Pointer Arrow
                    Positioned(
                      top: 0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF2D55).withOpacity(0.6),
                              blurRadius: 8,
                            )
                          ],
                        ),
                        child: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Winner Announcement Card
              if (_selectedPenalty != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C1E24) : const Color(0xFFFDEEF2),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFFF2D55), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _selectedPenalty!.emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedPenalty!.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF2C2526),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedPenalty!.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        onPressed: _shareResult,
                        icon: const Icon(Icons.chat_rounded, size: 16),
                        label: Text(
                          widget.currentLanguage == 'tr' ? "Gruba Gönder" : "Share with Group",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Spin Action Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF2D55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  onPressed: _isSpinning ? null : _spinWheel,
                  icon: const Icon(Icons.autorenew_rounded, color: Colors.white, size: 20),
                  label: Text(
                    _isSpinning
                        ? (widget.currentLanguage == 'tr' ? "ÇARK DÖNÜYOR..." : "SPINNING...")
                        : (widget.currentLanguage == 'tr' ? "ÇARKI ÇEVİR! 🎯" : "SPIN THE WHEEL! 🎯"),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<PenaltyItem> items;
  final List<Color> colors;
  final bool isDark;

  _WheelPainter({
    required this.items,
    required this.colors,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweepAngle = (2 * pi) / items.length;

    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < items.length; i++) {
      paint.color = colors[i % colors.length];
      final startAngle = i * sweepAngle;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw Emoji in sector
      final textAngle = startAngle + (sweepAngle / 2);
      final textRadius = radius * 0.65;
      final x = center.dx + textRadius * cos(textAngle);
      final y = center.dy + textRadius * sin(textAngle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: items[i].emoji,
          style: const TextStyle(fontSize: 20),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(textAngle + pi / 2);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) {
    return oldDelegate.items != items;
  }
}
