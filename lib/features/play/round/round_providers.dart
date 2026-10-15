import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The source of randomness of a round. Tests override it with a seeded
/// [Random] to know the order of the words.
final roundRandomProvider = Provider<Random>((ref) => Random());
