/// Roles a Xurmo account can hold.
///
/// Every account is created as [user]. The other roles are assigned by an
/// admin, never chosen at sign-up, and the Firestore rules enforce that a
/// user cannot change their own role.
class UserRole {
  UserRole._();

  static const String user = 'user';
  static const String courier = 'courier';
  static const String restaurant = 'restaurant';
  static const String admin = 'admin';

  static const List<String> all = [user, courier, restaurant, admin];
}
