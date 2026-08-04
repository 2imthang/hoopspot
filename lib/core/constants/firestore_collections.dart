/// Centralized Firestore collection names — never hard-code a collection
/// string inside a datasource.
class FirestoreCollections {
  const FirestoreCollections._();

  static const String users = 'users';
  static const String courts = 'courts';
  static const String bookings = 'bookings';

  /// One doc per (courtId, date, timeSlot) — the "unique constraint" that
  /// makes the anti-double-booking transaction possible on Firestore (see
  /// [BookingRemoteDataSource]/[BookingModel] for how it's used together
  /// with `bookings`).
  static const String slotLocks = 'slotLocks';
}
