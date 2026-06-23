import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import '../constants/debug_flags.dart';
import '../game/config/level_generator.dart';
import '../services/progress_service.dart';

/// Per-world cosmetic theme for the chaptered map.
///
/// One entry per world (6 worlds × 5 levels = 30). The [tint] colours the
/// world label, the connecting constellation lines, and unlocked node borders so
/// each chapter reads distinctly; the [name] mirrors that world's dominant
/// flavour (calm → swarm → minefield → recall → shuffle → gauntlet).
class _WorldTheme {
  final String name;
  final String subtitle;
  final Color tint;
  const _WorldTheme(this.name, this.subtitle, this.tint);
}

const List<_WorldTheme> _worlds = [
  _WorldTheme('AWAKENING', 'Learn the rules', Color(0xFF3B82F6)), // blue
  _WorldTheme('THE SWARM', 'Visual search', Color(0xFF22C55E)), // green
  _WorldTheme('MINEFIELD', 'Hold your hand', Color(0xFFF59E0B)), // amber
  _WorldTheme('RECALL', 'Working memory', Color(0xFFA855F7)), // purple
  _WorldTheme('SHUFFLE', 'Set-shifting', Color(0xFFEC4899)), // pink
  _WorldTheme('GAUNTLET', 'Everything, at once', Color(0xFFEF4444)), // red
];

/// Map screen (S-Map): a **constellation** of all 30 levels.
///
/// Each world is its own constellation — 5 nodes placed at fixed positions and
/// joined by faint connecting lines (drawn with [_ConstellationPainter]); the
/// completed run of the trail glows in the world tint. Reads per-level stars and
/// unlock state from [ProgressService] and auto-scrolls to the current
/// (highest-unlocked) level. A node tap launches that level's forbidden-intro
/// (Phase 4C-2); locked nodes are inert.
class MapScreen extends StatefulWidget {
  /// Injectable for tests; defaults to a real [ProgressService].
  final ProgressService? progressService;

  const MapScreen({super.key, this.progressService});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const int _levelCount = LevelGenerator.totalLevels; // 30
  static const int _perWorld = LevelGenerator.levelsPerWorld; // 5

  // Layout metrics for one world's constellation segment.
  static const double _segmentHeight = 470.0;
  static const double _nodeSize = 58.0;
  static const double _labelReserve = 84.0; // top space for the world label

  /// Constellation templates: 5 relative node positions (dx, dy fractions). Each
  /// world cycles through these so consecutive chapters look distinct. dy is
  /// monotonic so the trail flows downward.
  static const List<List<Offset>> _patterns = [
    [
      Offset(0.26, 0.06),
      Offset(0.70, 0.28),
      Offset(0.40, 0.50),
      Offset(0.74, 0.72),
      Offset(0.44, 0.94),
    ],
    [
      Offset(0.56, 0.06),
      Offset(0.24, 0.30),
      Offset(0.62, 0.50),
      Offset(0.34, 0.72),
      Offset(0.72, 0.94),
    ],
    [
      Offset(0.40, 0.06),
      Offset(0.72, 0.30),
      Offset(0.30, 0.52),
      Offset(0.62, 0.72),
      Offset(0.80, 0.94),
    ],
  ];

  late final ProgressService _progress;
  final ScrollController _scrollController = ScrollController();

  /// Stars per level, index 0 == level 1. Empty until loaded.
  List<int> _stars = const [];
  bool _loaded = false;

  /// Key on the current (highest-unlocked) node, used for auto-scroll.
  final GlobalKey _currentNodeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _progress = widget.progressService ?? ProgressService();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final stars = await _progress.getAllStars(_levelCount);
    if (!mounted) return;
    setState(() {
      _stars = stars;
      _loaded = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
  }

  /// A level (1-indexed) is unlocked iff it's Level 1 or the previous level has
  /// ≥1 star.
  bool _isUnlocked(int level) {
    if (DebugFlags.unlockAllLevels) return true; // dev: whole campaign reachable
    if (level <= 1) return true;
    return _stars[level - 2] >= 1;
  }

  /// Highest unlocked level (1-indexed) — the node we focus on entry.
  int get _currentLevel {
    int current = 1;
    for (int level = 1; level <= _levelCount; level++) {
      if (_isUnlocked(level)) current = level;
    }
    return current;
  }

  void _scrollToCurrent() {
    final ctx = _currentNodeKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.5,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  /// Absolute centre of [level]'s node for the given content [width].
  Offset _nodeCentre(int level, double width) {
    final int w = (level - 1) ~/ _perWorld;
    final int i = (level - 1) % _perWorld;
    final Offset frac = _patterns[w % _patterns.length][i];
    final double segTop = w * _segmentHeight;
    final double top = segTop + _labelReserve;
    const double usableH = _segmentHeight - _labelReserve - 24.0;
    return Offset(frac.dx * width, top + frac.dy * usableH);
  }

  void _onNodeTap(int level) {
    Navigator.pushNamed(
      context,
      '/forbidden-intro',
      arguments: {'level': level},
    ).then((_) {
      if (mounted) _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBackground,
      appBar: AppBar(
        backgroundColor: AppColors.kBackground,
        elevation: 0,
        title: const Text(
          'LEVELS',
          style: TextStyle(
            fontFamily: AppFonts.kFontDisplay,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: AppColors.kPrimaryText,
            letterSpacing: 2.0,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.kSecondaryText),
      ),
      body: Stack(
        children: [
          _buildBody(),
          // Ship-safety badge: makes a dev-unlocked build unmistakable.
          if (DebugFlags.unlockAllLevels) _buildDevBadge(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return _loaded
          ? LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                const double totalHeight =
                    LevelGenerator.worldCount * _segmentHeight;

                // Precompute node centres + unlock state for the line painter.
                final List<Offset> centres = [
                  for (int n = 1; n <= _levelCount; n++) _nodeCentre(n, width),
                ];
                final List<bool> unlocked = [
                  for (int n = 1; n <= _levelCount; n++) _isUnlocked(n),
                ];

                return SingleChildScrollView(
                  controller: _scrollController,
                  child: SizedBox(
                    width: width,
                    height: totalHeight,
                    child: Stack(
                      children: [
                        // Faint constellation lines threading every node.
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _ConstellationPainter(
                              centres: centres,
                              unlocked: unlocked,
                            ),
                          ),
                        ),
                        // Per-world labels.
                        for (int w = 0; w < LevelGenerator.worldCount; w++)
                          _buildWorldLabel(w),
                        // Nodes.
                        for (int n = 1; n <= _levelCount; n++)
                          _buildNode(n, width),
                      ],
                    ),
                  ),
                );
              },
            )
          : const Center(
              child: CircularProgressIndicator(color: AppColors.kAccent),
            );
  }

  /// Semi-transparent red corner badge shown only when [DebugFlags.unlockAllLevels]
  /// is on, so a dev-unlocked build is never mistaken for production.
  Widget _buildDevBadge() {
    return Positioned(
      top: 8.0,
      right: 8.0,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: const Text(
            'DEV UNLOCK',
            style: TextStyle(
              fontFamily: AppFonts.kFontBody,
              fontSize: 10.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorldLabel(int worldIndex) {
    final theme = _worlds[worldIndex];
    return Positioned(
      top: worldIndex * _segmentHeight + 16.0,
      left: 18.0,
      right: 18.0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(width: 3.0, height: 34.0, color: theme.tint),
          const SizedBox(width: 10.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WORLD ${worldIndex + 1}',
                style: TextStyle(
                  fontFamily: AppFonts.kFontBody,
                  fontSize: 11.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: theme.tint,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    theme.name,
                    style: const TextStyle(
                      fontFamily: AppFonts.kFontDisplay,
                      fontSize: 17.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.kPrimaryText,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    theme.subtitle,
                    style: const TextStyle(
                      fontFamily: AppFonts.kFontBody,
                      fontSize: 11.0,
                      color: AppColors.kSecondaryText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNode(int level, double width) {
    final theme = _worlds[(level - 1) ~/ _perWorld];
    final Offset c = _nodeCentre(level, width);
    final bool unlocked = _isUnlocked(level);
    final int stars = _stars[level - 1];
    final bool isCurrent = level == _currentLevel;

    // Column (circle + stars) centred horizontally on the node point.
    return Positioned(
      left: c.dx - _nodeSize / 2,
      top: c.dy - _nodeSize / 2,
      width: _nodeSize,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            key: isCurrent ? _currentNodeKey : null,
            onTap: unlocked ? () => _onNodeTap(level) : null,
            child: Container(
              width: _nodeSize,
              height: _nodeSize,
              decoration: BoxDecoration(
                color: AppColors.kSurface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: unlocked ? theme.tint : AppColors.kSecondaryText,
                  width: isCurrent ? 3.0 : 2.0,
                ),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: theme.tint.withValues(alpha: 0.55),
                          blurRadius: 14.0,
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: unlocked
                  ? Text(
                      '$level',
                      style: const TextStyle(
                        fontFamily: AppFonts.kFontDisplay,
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.kPrimaryText,
                      ),
                    )
                  : const Icon(
                      Icons.lock_rounded,
                      size: 22.0,
                      color: AppColors.kSecondaryText,
                    ),
            ),
          ),
          const SizedBox(height: 4.0),
          if (unlocked) _StarRow(stars: stars),
        ],
      ),
    );
  }
}

/// Draws the faint connecting lines of the constellation through every node.
/// A segment between two **unlocked** nodes is tinted (the trail you've walked);
/// any segment touching a locked node is a dim grey hint of what's ahead.
class _ConstellationPainter extends CustomPainter {
  final List<Offset> centres;
  final List<bool> unlocked;

  _ConstellationPainter({required this.centres, required this.unlocked});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < centres.length - 1; i++) {
      final bool walked = unlocked[i] && unlocked[i + 1];
      final paint = Paint()
        ..strokeWidth = walked ? 2.0 : 1.2
        ..style = PaintingStyle.stroke
        ..color = walked
            ? const Color(0xFF3B82F6).withValues(alpha: 0.55)
            : const Color(0xFF8A8A8A).withValues(alpha: 0.18);
      canvas.drawLine(centres[i], centres[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter oldDelegate) =>
      oldDelegate.centres != centres || oldDelegate.unlocked != unlocked;
}

/// Three-pip star readout under an unlocked node.
class _StarRow extends StatelessWidget {
  final int stars;
  const _StarRow({required this.stars});

  static const Color _gold = Color(0xFFF5B301);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int s = 1; s <= 3; s++)
          Icon(
            s <= stars ? Icons.star_rounded : Icons.star_border_rounded,
            size: 13.0,
            color: s <= stars ? _gold : AppColors.kSecondaryText,
          ),
      ],
    );
  }
}
