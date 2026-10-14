import 'package:flutter/material.dart';

/// Corner radii of the design (`docs/design/README.md`, "Shapes and spacing").
///
/// The asymmetric radii have a larger bottom-right corner; the design writes
/// them in CSS order (top-left / top-right / bottom-right / bottom-left).
abstract final class AppRadii {
  static const BorderRadius button = BorderRadius.all(Radius.circular(18));
  static const BorderRadius choice = BorderRadius.all(Radius.circular(16));
  static const BorderRadius small = BorderRadius.all(Radius.circular(14));

  /// Settings cards.
  static const BorderRadius card = BorderRadius.all(Radius.circular(22));

  /// Tiles and cards: 18 / 18 / 36 / 18.
  static const BorderRadius tile = BorderRadius.only(
    topLeft: Radius.circular(18),
    topRight: Radius.circular(18),
    bottomRight: Radius.circular(36),
    bottomLeft: Radius.circular(18),
  );

  /// The wide Mix tile of the home screen: 18 / 18 / 44 / 18.
  static const BorderRadius wideTile = BorderRadius.only(
    topLeft: Radius.circular(18),
    topRight: Radius.circular(18),
    bottomRight: Radius.circular(44),
    bottomLeft: Radius.circular(18),
  );

  /// Highlighted cards: 28 / 28 / 64 / 28.
  static const BorderRadius highlighted = BorderRadius.only(
    topLeft: Radius.circular(28),
    topRight: Radius.circular(28),
    bottomRight: Radius.circular(64),
    bottomLeft: Radius.circular(28),
  );

  /// The flip card: 28 / 28 / 84 / 28.
  static const BorderRadius flip = BorderRadius.only(
    topLeft: Radius.circular(28),
    topRight: Radius.circular(28),
    bottomRight: Radius.circular(84),
    bottomLeft: Radius.circular(28),
  );
}

/// Sizes and spacing of the design.
abstract final class AppSizes {
  static const double buttonHeight = 56;

  /// Minimum size of anything the user can tap.
  static const double touchTarget = 44;

  /// Side margin of every screen.
  static const double screenMargin = 20;
}
