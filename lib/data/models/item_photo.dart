class ItemPhoto {
  const ItemPhoto({this.id, required this.url, this.caption = ''});

  /// null for a photo that hasn't been saved yet.
  final String? id;
  final String url;
  final String caption;

  ItemPhoto copyWith({String? caption}) =>
      ItemPhoto(id: id, url: url, caption: caption ?? this.caption);

  Map<String, dynamic> toJson() => {'url': url, 'caption': caption};

  factory ItemPhoto.fromJson(Map<String, dynamic> m) => ItemPhoto(
        id: m['id'] as String?,
        url: m['url'] as String? ?? '',
        caption: m['caption'] as String? ?? '',
      );
}