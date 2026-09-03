import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// PDF Text Extraction Service — Extracts textual content from client pitch decks and documents
class PdfExtractorService {
  static final PdfExtractorService instance = PdfExtractorService._internal();
  PdfExtractorService._internal();

  /// Extracts text from PDF bytes using Syncfusion pure Dart PDF engine
  String extractTextFromBytes(Uint8List bytes) {
    if (bytes.isEmpty) return '';
    PdfDocument? document;
    try {
      document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);
      final text = extractor.extractText();
      debugPrint('PdfExtractorService: Successfully extracted ${text.length} characters across ${document.pages.count} pages.');
      return text.trim();
    } catch (e) {
      debugPrint('PdfExtractorService error: $e');
      return '';
    } finally {
      try {
        document?.dispose();
      } catch (_) {}
    }
  }
}
