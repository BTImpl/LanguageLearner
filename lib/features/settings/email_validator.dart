/// Whether [value] looks like an e-mail address.
///
/// A simple check, not the full standard: some text without spaces, one `@`,
/// then a domain of dot-separated parts with at least one dot (`a@b.c`). The
/// whitespace around the text is ignored. Whether the address exists is up to
/// the teacher's mail server.
bool isValidEmail(String value) => _pattern.hasMatch(value.trim());

final RegExp _pattern = RegExp(r'^[^\s@]+@[^\s@.]+(\.[^\s@.]+)+$');
