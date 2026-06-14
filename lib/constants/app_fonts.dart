/// Font family constants from the planning document.
///
/// Two fonts. Space Grotesk Bold for numeric/display text (scores,
/// countdowns, large headings). Inter for body text, labels, and
/// instructions (Regular weight 400, SemiBold weight 600).
///
/// Reference: Section 4.3 -- Typography.
class AppFonts {
  AppFonts._();

  /// Space Grotesk Bold -- display and numeric text.
  /// Used for: score counter, countdown, title, milestone banners.
  static const String kFontDisplay = 'SpaceGrotesk';

  /// Inter Regular + SemiBold -- labels and body text.
  /// Used for: HUD labels, buttons, settings, instructions, captions.
  static const String kFontBody = 'Inter';
}
