import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiParticle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  Color color;
  double rotation;
  double rotationSpeed;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class ConfettiCelebration extends StatefulWidget {
  final Widget child;
  final bool isPlaying;

  const ConfettiCelebration({
    super.key,
    required this.child,
    this.isPlaying = false,
  });

  @override
  State<ConfettiCelebration> createState() => _ConfettiCelebrationState();
}

class _ConfettiCelebrationState extends State<ConfettiCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<ConfettiParticle> _particles = [];
  final Random _random = Random();

  final List<Color> _colors = [
    const Color(0xFFFF2D55),
    const Color(0xFFFFCC00),
    const Color(0xFF34C759),
    const Color(0xFF007AFF),
    const Color(0xFFAF52DE),
    const Color(0xFFFF9500),
    const Color(0xFF00C7BE),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addListener(_updateParticles);

    if (widget.isPlaying) {
      _startConfetti();
    }
  }

  @override
  void didUpdateWidget(covariant ConfettiCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _startConfetti();
    }
  }

  void _startConfetti() {
    _particles.clear();
    for (int i = 0; i < 70; i++) {
      _particles.add(
        ConfettiParticle(
          x: 0.5 + (_random.nextDouble() - 0.5) * 0.4,
          y: 0.3,
          vx: (_random.nextDouble() - 0.5) * 1.6,
          vy: -_random.nextDouble() * 1.5 - 0.5,
          size: 6.0 + _random.nextDouble() * 6.0,
          color: _colors[_random.nextInt(_colors.length)],
          rotation: _random.nextDouble() * 2 * pi,
          rotationSpeed: (_random.nextDouble() - 0.5) * 0.3,
        ),
      );
    }
    _controller.forward(from: 0.0);
  }

  void _updateParticles() {
    for (var p in _particles) {
      p.x += p.vx * 0.016;
      p.y += p.vy * 0.016;
      p.vy += 1.8 * 0.016; // gravity
      p.rotation += p.rotationSpeed;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_controller.isAnimating)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ConfettiPainter(particles: _particles),
              ),
            ),
          ),
      ],
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;

  _ConfettiPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()..color = p.color;
      final center = Offset(p.x * size.width, p.y * size.height);

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(p.rotation);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
