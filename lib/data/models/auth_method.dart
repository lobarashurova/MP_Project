/// How an account identifies itself at sign-in. Stored on the user document
/// as `authMethod` so the profile can show the right contact detail.
///
/// Both methods use a password and appear on the Email / Phone switch.
///
/// Accounts created through the removed Google sign-in may still carry
/// `authMethod: "google"` on their user document; [fromStorage] reads those
/// as [email], which is what the profile screen should show for them.
enum AuthMethod {
  email,
  phone;

  String get storageValue => name;

  static AuthMethod fromStorage(String? value) {
    for (final method in AuthMethod.values) {
      if (method.name == value) return method;
    }
    return AuthMethod.email;
  }
}
