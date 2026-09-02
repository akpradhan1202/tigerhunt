/// Utility to detect and filter abusive/offensive language in chat.
class ProfanityFilter {
  static const Set<String> _blockedWords = {
    // English abusive / vulgar words
    'damn', 'hell', 'crap', 'ass', 'asshole', 'bastard', 'bitch', 'idiot',
    'stupid', 'dumb', 'loser', 'suck', 'dick', 'fuck', 'fucking', 'fucker',
    'shit', 'shitty', 'piss', 'cunt', 'whore', 'slut', 'nigger', 'nigga',
    'fag', 'faggot', 'retard', 'moron', 'cock', 'pussy', 'douche',
    // Common regional abusive terms
    'bc', 'mc', 'bhenchod', 'madarchod', 'chutiya', 'gandu', 'harami',
    'saala', 'kamina', 'kutta', 'bhadwa', 'randi', 'lund', 'chut', 'gaand',
  };

  /// Returns true if the given text contains prohibited or abusive words.
  static bool hasProfanity(String text) {
    if (text.isEmpty) return false;
    final normalized = _normalize(text);
    final words = normalized.split(RegExp(r'\s+'));

    for (final word in words) {
      final cleanWord = word.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      if (_blockedWords.contains(cleanWord)) {
        return true;
      }
    }

    // Also check for sub-word matches on severe words
    for (final bad in _blockedWords) {
      if (bad.length >= 4 && normalized.contains(bad)) {
        return true;
      }
    }

    return false;
  }

  /// Replaces detected offensive words with asterisks (e.g. 'f***').
  static String censor(String text) {
    if (text.isEmpty) return text;
    var result = text;

    for (final bad in _blockedWords) {
      final regex = RegExp('\\b$bad\\b', caseSensitive: false);
      result = result.replaceAllMapped(regex, (match) {
        final matched = match.group(0)!;
        if (matched.length <= 2) return '*' * matched.length;
        return matched[0] + ('*' * (matched.length - 2)) + matched[matched.length - 1];
      });
    }

    return result;
  }

  static String _normalize(String input) {
    return input
        .toLowerCase()
        // Replace common leetspeak substitutions
        .replaceAll('@', 'a')
        .replaceAll('\$', 's')
        .replaceAll('0', 'o')
        .replaceAll('1', 'i')
        .replaceAll('3', 'e')
        .replaceAll('!', 'i');
  }
}
