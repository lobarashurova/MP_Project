import 'package:shared_preferences/shared_preferences.dart';

/// Makes sure a fresh install of the app always starts signed out.
///
/// Firebase keeps the signed-in session outside the app's normal storage on
/// some platforms, so it can survive uninstalling the app:
///   - iOS stores it in the Keychain, which is not cleared on uninstall;
///   - Android can restore it from the automatic Google Drive backup. That
///     backup is turned off in AndroidManifest.xml, and this guard covers
///     anything that slips through.
///
/// SharedPreferences, on the other hand, is always wiped on uninstall. So the
/// guard stores a marker there on first launch. When the marker is missing,
/// this is a new install, and any session that came back with it is signed
/// out.
class InstallGuard {
  static const String markerKey = 'xurmo.install_marker';

  final SharedPreferences _prefs;
  final Future<void> Function() _signOut;

  InstallGuard({
    required SharedPreferences prefs,
    required Future<void> Function() signOut,
  })  : _prefs = prefs,
        _signOut = signOut;

  /// Signs out on the first launch after an install. Returns true when it
  /// did so.
  Future<bool> run() async {
    if (_prefs.getBool(markerKey) ?? false) return false;

    await _signOut();
    // Set the marker only after signing out succeeded, so a failure is
    // retried on the next launch instead of leaving a restored session.
    await _prefs.setBool(markerKey, true);
    return true;
  }
}
