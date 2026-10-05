/// A day has no clock times; items are just ordered by [ItineraryItem.order].
class TripDay {
  const TripDay({
    required this.id,
    required this.dayNumber,
    this.title = '',
    this.story = '',
    this.photoUrls = const [],
  });

  final String id;
  final int dayNumber;
  final String title; // "Arrival & Exploring"
  final String story;
  final List<String> photoUrls;

  Map<String, dynamic> toMap() => {
    'dayNumber': dayNumber,
    'title': title,
    'story': story,
    'photoUrls': photoUrls,
  };

  factory TripDay.fromMap(String id, Map<String, dynamic> m) => TripDay(
    id: id,
    dayNumber: (m['dayNumber'] as num?)?.toInt() ?? 1,
    title: m['title'] as String? ?? '',
    story: m['story'] as String? ?? '',
    photoUrls: List<String>.from((m['photoUrls'] as List?) ?? []),
  );
}
