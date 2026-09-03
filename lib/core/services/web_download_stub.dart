import 'package:url_launcher/url_launcher.dart';

void triggerBrowserDownload(String url, String fileName) {
  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

void triggerBrowserDownloadBytes(List<int> bytes, String fileName) {
  // Stub for non-web environments
}
