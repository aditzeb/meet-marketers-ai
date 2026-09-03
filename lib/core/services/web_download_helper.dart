import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

// Conditional import for Flutter Web Anchor element
import 'web_download_stub.dart' if (dart.library.html) 'web_download_html.dart';

void downloadWebFile(String url, String fileName) {
  if (kIsWeb) {
    try {
      triggerBrowserDownload(url, fileName);
      return;
    } catch (e) {
      debugPrint('Web download exception: $e');
    }
  }
  
  // Fallback to URL launcher
  try {
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('Launch URL exception: $e');
  }
}

void downloadWebBytes(List<int> bytes, String fileName) {
  if (kIsWeb) {
    try {
      triggerBrowserDownloadBytes(bytes, fileName);
      return;
    } catch (e) {
      debugPrint('Web download bytes exception: $e');
    }
  }
}
