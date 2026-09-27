import 'dart:math';

import '../engine/models/game_config.dart';
import 'bot.dart';
import 'easy_bot.dart';
import 'medium_bot.dart';

/// Ayarlardaki seviyeye göre bot üretir. Zor bot sonraki sürümde eklenecek;
/// şimdilik Orta'ya düşer.
Bot createBot(BotLevel level, Random random) => switch (level) {
      BotLevel.easy => EasyBot(random),
      BotLevel.medium => MediumBot(random),
      BotLevel.hard => MediumBot(random),
    };
