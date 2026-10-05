class ItemLink {
  const ItemLink({required this.label, required this.url});

  final String label; // e.g. "Booking", "Instagram"
  final String url;

  Map<String, dynamic> toJson() => {'label': label, 'url': url};

  factory ItemLink.fromJson(Map<String, dynamic> m) => ItemLink(
    label: m['label'] as String? ?? '',
    url: m['url'] as String? ?? '',
  );
}
