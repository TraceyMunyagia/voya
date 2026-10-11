class Urls {
  /// `diani.com/book` -> `https://diani.com/book`. Returns null when the text
  /// can't be a web address (no dot in the host, a non-web scheme, a password
  /// section, spaces...).
  static String? normalise(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return null;
    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(s)) s = 'https://$s';

    final uri = Uri.tryParse(s);
    if (uri == null) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    if (uri.userInfo.isNotEmpty) return null;
    if (uri.host.isEmpty || !uri.host.contains('.')) return null;
    return s;
  }
}