import 'package:url_launcher/url_launcher.dart';

/// Opens a web address (or a Google Maps link) outside the app.
/// Returns false instead of throwing when nothing could open it.
Future<bool> openUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}