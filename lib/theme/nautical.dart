import 'dart:math';
import 'package:flutter/material.dart';
import 'sea_themes.dart';

/// Nautical physical-material UI helpers for Sea Battle.
///
/// Wood backdrops (planked, beveled), brass buttons, parchment cards and a
/// parametric ship painter that gives each ship style a distinct physical
/// hull. Nothing neon, nothing synthetic.
class Nautical {
  static TextStyle display(double size, {required SeaThemeDef theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: theme.brassLight,
        letterSpacing: 1.2,
        shadows: const [
          Shadow(
            color: Colors.black54,
            offset: Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      );

  static TextStyle title(double size, {required SeaThemeDef theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: theme.parchment,
      );

  static TextStyle body(double size, {required SeaThemeDef theme}) =>
      TextStyle(fontSize: size, color: theme.parchment);

  static TextStyle ink(double size, {required SeaThemeDef theme}) =>
      TextStyle(fontSize: size, color: theme.ink, fontWeight: FontWeight.w600);

  static TextStyle label(double size, {required SeaThemeDef theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: theme.brassLight,
        letterSpacing: 2.0,
      );
}

/// Full-screen planked-wood backdrop with vignette.
class WoodBackdrop extends StatelessWidget {
  final SeaThemeDef theme;
  final Widget child;
  const WoodBackdrop({super.key, required this.theme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.woodMid, theme.woodDark],
        ),
      ),
      child: CustomPaint(
        painter: _PlankPainter(theme: theme),
        child: child,
      ),
    );
  }
}

class _PlankPainter extends CustomPainter {
  final SeaThemeDef theme;
  _PlankPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final plankH = size.height / 7;
    for (int i = 0; i < 7; i++) {
      final y = i * plankH;
      // Subtle plank separation line.
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.28)
          ..strokeWidth = 2,
      );
      // Bevel highlight under each plank.
      canvas.drawLine(
        Offset(0, y + 2),
        Offset(size.width, y + 2),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.05)
          ..strokeWidth = 1.5,
      );
      // Wood grain streaks.
      final rng = Random(i * 97);
      for (int g = 0; g < 5; g++) {
        final gy = y + rng.nextDouble() * plankH;
        canvas.drawLine(
          Offset(rng.nextDouble() * size.width * 0.4, gy),
          Offset(size.width * (0.5 + rng.nextDouble() * 0.5), gy),
          Paint()
            ..color = Colors.black.withValues(alpha: 0.08)
            ..strokeWidth = 1.2,
        );
      }
    }
    // Vignette.
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.1,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.45)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Parchment card — charts, score sheets, dialogs.
class ParchmentCard extends StatelessWidget {
  final SeaThemeDef theme;
  final Widget child;
  final EdgeInsets padding;
  const ParchmentCard({
    super.key,
    required this.theme,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.parchment, theme.parchmentDark],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.brass, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            offset: const Offset(0, 6),
            blurRadius: 14,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.25),
            offset: const Offset(0, 1),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Brass-framed button with pressed weight.
class BrassButton extends StatelessWidget {
  final String label;
  final SeaThemeDef theme;
  final VoidCallback? onTap;
  final bool primary;
  final IconData? icon;
  const BrassButton({
    super.key,
    required this.label,
    required this.theme,
    required this.onTap,
    this.primary = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: primary
                    ? [theme.brassLight, theme.brass]
                    : [theme.woodMid, theme.woodDark],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: primary ? theme.ink : theme.brass,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  offset: const Offset(0, 4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon,
                      size: 18,
                      color: primary ? theme.ink : theme.brassLight),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: primary ? theme.ink : theme.brassLight,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws one ship cell. Styles differ by hull silhouette:
/// 0 galleon (tall sails), 1 ironclad (smokestacks), 2 longship (dragon prow),
/// 3 pirate (black sails), 4 steam (funnel + paddle), 5 man-o-war (3 masts),
/// 6 ghost (translucent), 7 sub hunter (conning tower), 8 junk (batten sails).
class ShipCellPainter extends CustomPainter {
  final int style;
  final ShipStyleDef def;
  final bool horizontal;
  final bool bow; // leading cell
  final bool stern; // trailing cell
  final bool hit;

  ShipCellPainter({
    required this.style,
    required this.def,
    required this.horizontal,
    required this.bow,
    required this.stern,
    this.hit = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (!horizontal) {
      canvas.translate(size.width / 2, size.height / 2);
      canvas.rotate(pi / 2);
      canvas.translate(-size.width / 2, -size.height / 2);
    }
    _paintHorizontal(canvas, size);
    canvas.restore();
  }

  void _paintHorizontal(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final hull = Paint()..color = def.hull;
    final hullDark = Paint()..color = def.hullDark;
    final sailP = Paint()..color = def.sail;
    final trimP = Paint()..color = def.trim;

    // Sea sliver behind the ship.
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(3)),
      Paint()..color = Colors.white.withValues(alpha: 0.06),
    );

    // Hull: long body with bow taper / stern block.
    final hullPath = Path();
    final top = h * 0.52;
    final bottom = h * 0.92;
    if (bow) {
      hullPath.moveTo(w * 0.12, top);
      hullPath.lineTo(w * 0.96, h * 0.62);
      hullPath.lineTo(w * 0.96, h * 0.80);
      hullPath.lineTo(w * 0.12, bottom);
    } else if (stern) {
      hullPath.moveTo(w * 0.04, top + h * 0.08);
      hullPath.lineTo(w * 0.88, top);
      hullPath.lineTo(w * 0.88, bottom);
      hullPath.lineTo(w * 0.04, bottom - h * 0.08);
    } else {
      hullPath.addRect(Rect.fromLTWH(w * 0.04, top, w * 0.92, bottom - top));
    }
    hullPath.close();
    canvas.drawPath(hullPath, hull);
    // Hull planking lines.
    canvas.drawLine(
      Offset(w * 0.06, (top + bottom) / 2),
      Offset(w * 0.94, (top + bottom) / 2),
      Paint()
        ..color = def.hullDark
        ..strokeWidth = 1.2,
    );
    // Waterline trim.
    canvas.drawRect(
      Rect.fromLTWH(w * 0.04, bottom - 2, w * 0.92, 2),
      trimP,
    );

    if (style == 7) {
      // Submarine hunter: conning tower + periscope, no masts.
      canvas.drawRect(
          Rect.fromLTWH(w * 0.38, h * 0.30, w * 0.24, h * 0.24), hullDark);
      canvas.drawRect(
          Rect.fromLTWH(w * 0.47, h * 0.12, w * 0.06, h * 0.20), trimP);
      return;
    }

    // Masts + sails vary by style.
    final masts = style == 5 ? 3 : (style == 2 ? 1 : 2);
    for (int m = 0; m < masts; m++) {
      final mx = w * (0.30 + m * 0.40 / max(1, masts - 1));
      canvas.drawRect(
          Rect.fromLTWH(mx - 1.5, h * 0.10, 3, h * 0.44), hullDark);
      final sailW = w * (style == 8 ? 0.22 : 0.26);
      if (style == 1) {
        // Ironclad: smokestacks instead of sails.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(mx - 5, h * 0.14, 10, h * 0.28),
              const Radius.circular(3)),
          hullDark,
        );
        canvas.drawCircle(Offset(mx, h * 0.12), 4, trimP);
      } else if (style == 8) {
        // Junk: battened sail (horizontal slats).
        for (int b = 0; b < 3; b++) {
          canvas.drawRect(
            Rect.fromLTWH(mx - sailW / 2, h * (0.14 + b * 0.10), sailW,
                h * 0.085),
            sailP,
          );
        }
      } else {
        final sailPath = Path();
        sailPath.moveTo(mx - sailW / 2, h * 0.12);
        sailPath.quadraticBezierTo(
            mx, h * 0.20, mx + sailW / 2, h * 0.12);
        sailPath.lineTo(mx + sailW / 2, h * 0.40);
        sailPath.quadraticBezierTo(
            mx, h * 0.34, mx - sailW / 2, h * 0.40);
        sailPath.close();
        canvas.drawPath(sailPath, sailP);
        if (style == 2) {
          // Viking stripes.
          canvas.drawLine(Offset(mx - sailW / 4, h * 0.12),
              Offset(mx - sailW / 4, h * 0.40), trimP..strokeWidth = 2);
          canvas.drawLine(Offset(mx + sailW / 4, h * 0.12),
              Offset(mx + sailW / 4, h * 0.40), trimP..strokeWidth = 2);
        }
        if (style == 6) {
          // Ghost: pale translucent sail.
          canvas.drawPath(
              sailPath,
              Paint()
                ..color = Colors.white.withValues(alpha: 0.35)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2);
        }
      }
    }

    if (style == 2 && bow) {
      // Dragon prow.
      canvas.drawCircle(Offset(w * 0.94, h * 0.55), 4, trimP);
    }
    if (style == 3 && bow) {
      // Pirate flag on the bow mast.
      final flag = Path()
        ..moveTo(w * 0.30, h * 0.12)
        ..lineTo(w * 0.52, h * 0.18)
        ..lineTo(w * 0.30, h * 0.24)
        ..close();
      canvas.drawPath(flag, Paint()..color = const Color(0xFF1C1C1C));
    }
    if (style == 4 && stern) {
      // Paddle wheel.
      canvas.drawCircle(Offset(w * 0.10, h * 0.72), 7, trimP);
      canvas.drawCircle(
          Offset(w * 0.10, h * 0.72),
          7,
          Paint()
            ..color = def.hullDark
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }

    if (hit) {
      // Burn mark on a hit ship cell.
      canvas.drawCircle(
        Offset(w * 0.5, h * 0.70),
        w * 0.22,
        Paint()..color = Colors.black.withValues(alpha: 0.55),
      );
      canvas.drawCircle(
        Offset(w * 0.5, h * 0.70),
        w * 0.12,
        Paint()..color = const Color(0xFFE0642A).withValues(alpha: 0.8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant ShipCellPainter old) =>
      old.style != style ||
      old.horizontal != horizontal ||
      old.bow != bow ||
      old.stern != stern ||
      old.hit != hit;
}
