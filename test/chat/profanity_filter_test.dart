import 'package:flutter_test/flutter_test.dart';
import 'package:tigerhunt/features/chat/utils/profanity_filter.dart';

void main() {
  group('ProfanityFilter', () {
    test('detects severe offensive English words', () {
      expect(ProfanityFilter.hasProfanity('You are an idiot'), isTrue);
      expect(ProfanityFilter.hasProfanity('What the fuck'), isTrue);
      expect(ProfanityFilter.hasProfanity('Piece of shit move'), isTrue);
    });

    test('detects prohibited regional abusive words', () {
      expect(ProfanityFilter.hasProfanity('kutta move'), isTrue);
      expect(ProfanityFilter.hasProfanity('chutiya player'), isTrue);
    });

    test('allows regular respectful chess and bagh-chal chat', () {
      expect(ProfanityFilter.hasProfanity('Good game! Well played.'), isFalse);
      expect(ProfanityFilter.hasProfanity('Nice move with the tiger!'), isFalse);
      expect(ProfanityFilter.hasProfanity('Trap the goat on the corner'), isFalse);
      expect(ProfanityFilter.hasProfanity('Rematch?'), isFalse);
      expect(ProfanityFilter.hasProfanity('Hi, let\'s play square board'), isFalse);
    });

    test('censors profanity with asterisks', () {
      final censored = ProfanityFilter.censor('That was a shit move');
      expect(censored, contains('s**t'));
      expect(censored.contains('shit'), isFalse);
    });
  });
}
