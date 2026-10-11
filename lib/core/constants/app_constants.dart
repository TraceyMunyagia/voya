class AppConstants {
  static const defaultCurrency = 'KES';
  static const tagline = 'Travel through real stories.';
  static const maxPhotosPerItem = 10;
  static const minPasswordLength = 8;
  static const authRedirect = 'app.voya://login-callback';
  static const maxTripDays = 60;
  static const maxDestinations = 10;
}

/// Table names in one place.
class Tbl {
  static const profiles = 'profiles';
  static const trips = 'trips';
  static const tripMembers = 'trip_members';
  static const tripDays = 'trip_days';
  static const itineraryItems = 'itinerary_items';
  static const tripActivity = 'trip_activity';
}

/// Storage buckets. Paths: avatars/{userId}/..., trip-photos/{tripId}/...
class Buckets {
  static const avatars = 'avatars';
  static const tripPhotos = 'trip-photos';
}
