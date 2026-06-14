import 'package:dont_tap_that/services/score_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ScoreService', () {
    late ScoreService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = ScoreService();
    });

    test('getBestScore returns 0 when no score exists yet', () async {
      final best = await service.getBestScore();
      expect(best, 0);
    });

    test('saveBestScore saves when new score > existing', () async {
      await service.saveBestScore(100);
      final best = await service.getBestScore();
      expect(best, 100);
    });

    test('saveBestScore does NOT overwrite when new score < existing',
        () async {
      await service.saveBestScore(200);
      await service.saveBestScore(50);
      final best = await service.getBestScore();
      expect(best, 200);
    });

    test('saveBestScore does NOT overwrite when new score == existing',
        () async {
      await service.saveBestScore(150);
      await service.saveBestScore(150);
      final best = await service.getBestScore();
      expect(best, 150);
    });

    test('saveBestScore overwrites when new score beats existing', () async {
      await service.saveBestScore(100);
      await service.saveBestScore(300);
      final best = await service.getBestScore();
      expect(best, 300);
    });
  });
}
