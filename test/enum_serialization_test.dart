import 'package:flutter_test/flutter_test.dart';

import 'models/profile.dart';

void main() {
  test('generated enum serialization preserves names and parsing behavior',
      () async {
    final profile = Profile();
    for (final bot in Bot.values) {
      profile.bot = bot;
      expect(profile.map['bot'], bot.name);
      final restored = Profile();
      await restored.setMap({'bot': bot.name.toUpperCase()});
      expect(restored.bot, bot);
    }
    profile.bot = Bot.blue;
    for (final value in [null, '', 'unknown']) {
      await profile.setMap({'bot': value});
      expect(profile.bot, Bot.blue);
    }
  });
}
