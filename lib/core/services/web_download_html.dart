// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

void triggerBrowserDownload(String url, String fileName) {
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..target = '_blank';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}

void triggerBrowserDownloadBytes(List<int> bytes, String fileName) {
  // MUST pass Uint8List (ArrayBufferView) so browser writes binary bytes instead of stringified numbers
  final uint8List = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  final blob = html.Blob([uint8List], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..target = '_blank';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();

  // Delay revoking URL so browser has time to stream the download
  Future.delayed(const Duration(seconds: 15), () {
    html.Url.revokeObjectUrl(url);
  });
}
