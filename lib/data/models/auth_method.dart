/// How an account identifies itself at sign-in. Stored on the user document
/// as `authMethod` so the profile can show the right contact detail.
enum AuthMethod {
  email,
  phone;

  String get storageValue => name;

  static AuthMethod fromStorage(String? value) {
    return value == AuthMethod.phone.name ? AuthMethod.phone : AuthMethod.email;
  }
}
