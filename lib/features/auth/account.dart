import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The signed-in student.
class Account {
  const Account({required this.name, required this.email});

  final String name;
  final String email;

  /// The initials for the round avatar: the first letters of the first two
  /// words of the name, e.g. "KA" for "Kiss Anna".
  String get monogram {
    final words = name.split(' ').where((word) => word.isNotEmpty).take(2);
    final initials = [
      for (final word in words) String.fromCharCode(word.runes.first),
    ].join();
    return initials.isEmpty ? '?' : initials.toUpperCase();
  }
}

/// The signed-in student. A sample until card LL-27 adds the Google sign-in.
final accountProvider = Provider<Account>(
  (ref) => const Account(name: 'Kiss Anna', email: 'kiss.anna@example.com'),
);
