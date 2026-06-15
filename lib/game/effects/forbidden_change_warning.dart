import 'dart:ui' hide TextStyle;
import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show TextStyle, FontWeight;
import '../../constants/app_colors.dart';
import '../../constants/app_fonts.dart';
import '../config/shape_type.dart';
import '../shapes/base_shape.dart';

/// Forbidden Change Warning (Level 4 & 5) (Section 4.6)
/// Screen dims, new shape shown at 60% intro size for 1.5s.
class ForbiddenChangeWarningEffect extends Component with HasGameReference {
  final ShapeType newShape;
  final double duration = 1.5;
  double _elapsed = 0.0;

  final Paint _scrimPaint = Paint()..color = const Color(0x99000000); // 60% dim screen
  final Paint _cardPaint = Paint()..color = AppColors.kSurface;
  final Paint _borderPaint = Paint()
    ..color = AppColors.kDecayWarning
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  late final TextComponent _titleText;
  late final BaseShape _shapePainter;

  ForbiddenChangeWarningEffect({required this.newShape}) {
    _shapePainter = BaseShape.forType(newShape);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _titleText = TextComponent(
      text: "NEW FORBIDDEN!",
      anchor: Anchor.center,
      position: Vector2(game.size.x / 2, game.size.y / 2 - 80.0),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: AppFonts.kFontDisplay,
          fontSize: 22.0,
          fontWeight: FontWeight.bold,
          color: AppColors.kDecayWarning,
        ),
      ),
    );
    add(_titleText);

    final String nameText = newShape.name.toUpperCase();
    final nameComponent = TextComponent(
      text: nameText,
      anchor: Anchor.center,
      position: Vector2(game.size.x / 2, game.size.y / 2 + 70.0),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: AppFonts.kFontBody,
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
          color: AppColors.kPrimaryText,
        ),
      ),
    );
    add(nameComponent);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 1. Draw full screen dim scrim
    canvas.drawRect(
      Rect.fromLTWH(0, 0, game.size.x, game.size.y),
      _scrimPaint,
    );

    // 2. Draw warning container card in center
    const double cardW = 280.0;
    const double cardH = 220.0;
    final double cardX = (game.size.x - cardW) / 2;
    final double cardY = (game.size.y - cardH) / 2;

    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cardX, cardY, cardW, cardH),
      const Radius.circular(16.0),
    );

    canvas.drawRRect(cardRect, _cardPaint);
    canvas.drawRRect(cardRect, _borderPaint);

    // 3. Draw new shape at 60% of intro size (60px x 60px)
    const double shapeSize = 60.0;
    final double shapeX = (game.size.x - shapeSize) / 2;
    final double shapeY = (game.size.y - shapeSize) / 2 - 10.0;

    canvas.save();
    canvas.translate(shapeX, shapeY);

    final shapePaint = Paint()
      ..color = AppColors.kPrimaryText
      ..style = PaintingStyle.fill;

    _shapePainter.paintShape(
      canvas,
      const Size(shapeSize, shapeSize),
      shapePaint,
    );

    canvas.restore();
  }
}
