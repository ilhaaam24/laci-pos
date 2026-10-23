import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:laci/core/services/tutorial_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('TutorialService defaults to false on fresh install', () async {
    final service = TutorialService();
    final seen = await service.hasSeenPosTutorial();
    expect(seen, isFalse);
  });

  test('TutorialService updates and persists seen state', () async {
    final service = TutorialService();
    await service.setPosTutorialSeen(true);
    final seen = await service.hasSeenPosTutorial();
    expect(seen, isTrue);
  });

  test('TutorialService reset restores state to false', () async {
    final service = TutorialService();
    await service.setPosTutorialSeen(true);
    expect(await service.hasSeenPosTutorial(), isTrue);

    await service.resetPosTutorial();
    expect(await service.hasSeenPosTutorial(), isFalse);
  });
}
