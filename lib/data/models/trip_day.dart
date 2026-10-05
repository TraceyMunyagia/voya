/// A day has no clock times; items are just ordered by sort_order.
class TripDay {
  const TripDay({
    required this.id,
    required this.tripId,
    required this.dayNumber,
    this.title = '',
    this.story = '',
    this.photoUrls = const [],
  });

  final String id;
  final String tripId;
  final int dayNumber;
  final String title; // "Arrival & Exploring"
  final String story;
  final List<String> photoUrls;

  Map<String, dynamic> toJson() => {
    'trip_id': tripId,
    'day_number': dayNumber,
    'title': title,
    'story': story,
    'photo_urls': photoUrls,
  };

  factory TripDay.fromJson(Map<String, dynamic> m) => TripDay(
    id: m['id'] as String,
    tripId: m['trip_id'] as String,
    dayNumber: (m['day_number'] as num?)?.toInt() ?? 1,
    title: m['title'] as String? ?? '',
    story: m['story'] as String? ?? '',
    photoUrls: List<String>.from((m['photo_urls'] as List?) ?? []),
  );
}
