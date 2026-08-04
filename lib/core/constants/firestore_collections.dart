/// Centralized Firestore collection names — never hard-code a collection
/// string inside a datasource.
class FirestoreCollections {
  const FirestoreCollections._();

  static const String users = 'users';
  static const String courts = 'courts';
  static const String bookings = 'bookings';
}
