/// How an account identifies itself at sign-in. Stored on the user document
/// as `authMethod` so the profile can show the right contact detail.
///
/// Email and phone use a password and appear on the Email / Phone switch.
/// Google signs in through the Google account picker and has its own button.
enum AuthMethod {
  email,
  phone,
  google;

  String get storageValue => name;

  static AuthMethod fromStorage(String? value) {
    for (final method in AuthMethod.values) {
      if (method.name == value) return method;
    }
    return AuthMethod.email;
  }
}
