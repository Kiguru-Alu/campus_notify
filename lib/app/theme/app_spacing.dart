/// A single spacing and radius scale.
///
/// Radii are deliberately not uniform: containers that hold content are
/// softer than controls, and pills are fully round. Using one radius
/// everywhere flattens hierarchy.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Horizontal page gutter used by every scrollable screen.
  static const double gutter = 20;

  static const double radiusControl = 10;
  static const double radiusCard = 14;
  static const double radiusSheet = 24;
  static const double radiusPill = 999;
}
