import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xurmo/core/session/install_guard.dart';

void main() {
  late int signOuts;
  Future<void> fakeSignOut() async => signOuts++;

  setUp(() => signOuts = 0);

  test('signs out on the first launch after an install', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final didSignOut = await InstallGuard(prefs: prefs, signOut: fakeSignOut).run();

    expect(didSignOut, isTrue);
    expect(signOuts, 1);
    expect(prefs.getBool(InstallGuard.markerKey), isTrue);
  });

  test('does nothing on later launches', () async {
    SharedPreferences.setMockInitialValues({InstallGuard.markerKey: true});
    final prefs = await SharedPreferences.getInstance();

    final didSignOut = await InstallGuard(prefs: prefs, signOut: fakeSignOut).run();

    expect(didSignOut, isFalse);
    expect(signOuts, 0);
  });

  test('signs out only once across several launches', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final guard = InstallGuard(prefs: prefs, signOut: fakeSignOut);

    await guard.run();
    await guard.run();
    await guard.run();

    expect(signOuts, 1);
  });

  test('retries on the next launch if signing out fails', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final failing = InstallGuard(prefs: prefs, signOut: () async => throw Exception('offline'));
    await expectLater(failing.run(), throwsException);
    expect(prefs.getBool(InstallGuard.markerKey), isNull);

    expect(await InstallGuard(prefs: prefs, signOut: fakeSignOut).run(), isTrue);
    expect(signOuts, 1);
  });
}
