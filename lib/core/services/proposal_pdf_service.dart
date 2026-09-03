import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../data/models/proposal_model.dart';
import 'proposal_domain_engine.dart';
import 'web_download_helper.dart';

/// Service to generate and export professional 13-section proposals
/// matching the exact dark luxury & lime-accent design from the reference sample.
class ProposalPdfService {
  static final ProposalPdfService instance = ProposalPdfService._internal();
  ProposalPdfService._internal();

  /// Safe helper to fetch image bytes from HTTP URLs or base64 data URIs
  Future<List<int>?> _fetchImageBytes(String? url) async {
    if (url == null || url.trim().isEmpty) return null;
    final trimmed = url.trim();
    try {
      if (trimmed.startsWith('data:image')) {
        final commaIdx = trimmed.indexOf(',');
        if (commaIdx != -1) {
          return base64Decode(trimmed.substring(commaIdx + 1));
        }
      }
      if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        final response = await http.get(Uri.parse(trimmed)).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          return response.bodyBytes;
        }
      }
    } catch (e) {
      debugPrint('ProposalPdfService image load note: $e');
    }
    return null;
  }

  /// Compiles a complete 13-page PDF proposal with smooth ambient dark background & lime accents
  Future<List<int>> generateProposalPdf(ProposalModel proposal) async {
    final document = PdfDocument();
    document.pageSettings.size = PdfPageSize.a4;
    document.pageSettings.margins.all = 0; // Full bleed for dark theme

    const pageWidth = 595.28;
    const pageHeight = 841.89;
    const contentX = 42.0;
    const contentWidth = 511.28;

    // Load background image & logo if available
    List<int>? bgImageBytes;
    try {
      final data = await rootBundle.load('assets/images/proposal_bg.png');
      final bytes = data.buffer.asUint8List();
      // Validate PNG signature: first 8 bytes must be 137 80 78 71 13 10 26 10
      if (bytes.length > 8 &&
          bytes[0] == 137 && bytes[1] == 80 && bytes[2] == 78 && bytes[3] == 71) {
        bgImageBytes = bytes;
      }
    } catch (_) {}

    List<int>? logoBytes;
    try {
      final data = await rootBundle.load('assets/logos/meet_marketers_pdf_logo.png');
      final bytes = data.buffer.asUint8List();
      // Validate PNG/JPEG signature before passing to PdfBitmap to avoid "Invalid array length" crash
      final isPng = bytes.length > 8 &&
          bytes[0] == 137 && bytes[1] == 80 && bytes[2] == 78 && bytes[3] == 71;
      final isJpeg = bytes.length > 3 &&
          bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;
      if (isPng || isJpeg) {
        logoBytes = bytes;
      } else {
        debugPrint('ProposalPdfService: meet_marketers_pdf_logo.png is not a valid PNG/JPEG — skipping logo.');
      }
    } catch (_) {}

    // Asynchronously load user uploaded / AI generated asset images
    final reelImageBytes = await _fetchImageBytes(proposal.sampleReelMediaUrl);
    final visualDirectionImageBytes = await _fetchImageBytes(proposal.visualDirectionImageUrl);
    final companyLogoBytes = await _fetchImageBytes(proposal.companyLogoUrl);
    final post1ImageBytes = proposal.socialPosts.isNotEmpty
        ? await _fetchImageBytes(proposal.socialPosts[0]['imageUrl'] as String?)
        : null;
    final post2ImageBytes = proposal.socialPosts.length > 1
        ? await _fetchImageBytes(proposal.socialPosts[1]['imageUrl'] as String?)
        : null;
    final post3ImageBytes = proposal.socialPosts.length > 2
        ? await _fetchImageBytes(proposal.socialPosts[2]['imageUrl'] as String?)
        : null;

    // ── Palette Colors Matching Sample Images ────────────────────
    final bgDark = PdfColor(11, 14, 14); // Deep luxury dark base
    final bgCard = PdfColor(20, 25, 25); // Card surface
    final cardBorder = PdfColor(40, 50, 50); // Subtle card border
    final tableBorder = PdfColor(50, 60, 60); // Table border
    final accentLime = PdfColor(163, 230, 53); // #A3E635 (vibrant lime green)
    final textWhite = PdfColor(255, 255, 255);
    final textOffWhite = PdfColor(226, 232, 240); // #E2E8F0
    final textMuted = PdfColor(148, 163, 184); // #94A3B8
    final textBlack = PdfColor(10, 13, 13); // #0A0D0D

    // ── Typography ───────────────────────────────────────────────
    final h1Font = PdfStandardFont(PdfFontFamily.helvetica, 22, style: PdfFontStyle.bold);
    final h2Font = PdfStandardFont(PdfFontFamily.helvetica, 13.5, style: PdfFontStyle.bold);
    final h3Font = PdfStandardFont(PdfFontFamily.helvetica, 10.5, style: PdfFontStyle.bold);
    final bodyFont = PdfStandardFont(PdfFontFamily.helvetica, 9.5);
    final bodyBold = PdfStandardFont(PdfFontFamily.helvetica, 9.5, style: PdfFontStyle.bold);
    final captionFont = PdfStandardFont(PdfFontFamily.helvetica, 8);

    // ── Helper: Draw Base Background (Smooth Gaussian Glow) ──────
    void drawDarkBase(PdfPage page) {
      final g = page.graphics;

      if (bgImageBytes != null) {
        try {
          g.drawImage(
            PdfBitmap(bgImageBytes),
            const ui.Rect.fromLTWH(0, 0, pageWidth, pageHeight),
          );
        } catch (_) {
          // Fallback to flat dark if bg asset is corrupt
          g.drawRectangle(
            brush: PdfSolidBrush(bgDark),
            bounds: const ui.Rect.fromLTWH(0, 0, pageWidth, pageHeight),
          );
        }
      } else {
        // Flat dark base fallback with NO harsh discs
        g.drawRectangle(
          brush: PdfSolidBrush(bgDark),
          bounds: const ui.Rect.fromLTWH(0, 0, pageWidth, pageHeight),
        );
      }

      // Centered Footer on every page
      g.drawString(
        'Meet Marketers © 2026',
        captionFont,
        brush: PdfSolidBrush(textMuted),
        bounds: const ui.Rect.fromLTWH(0, pageHeight - 26, pageWidth, 14),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
    }

    // ── Helper: Draw Meet Marketers Brand Logo on Cover ──────────
    void drawMeetMarketersLogo(PdfGraphics g, double x, double y) {
      if (logoBytes != null) {
        try {
          // Draw the real MM transparent logo
          g.drawImage(
            PdfBitmap(logoBytes),
            ui.Rect.fromLTWH(x, y - 2, 28, 22),
          );
        } catch (_) {
          // Logo asset is invalid — skip image, still draw text fallback below
        }
        g.drawString(
          'MEET',
          PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
          brush: PdfSolidBrush(textWhite),
          bounds: ui.Rect.fromLTWH(x + 36, y + 2, 45, 16),
        );
        g.drawString(
          'MARKETERS',
          PdfStandardFont(PdfFontFamily.helvetica, 12),
          brush: PdfSolidBrush(textOffWhite),
          bounds: ui.Rect.fromLTWH(x + 78, y + 2, 100, 16),
        );
      } else {
        // Stylized vector MM icon
        final logoPen = PdfPen(PdfColor(170, 180, 185), width: 3);
        g.drawLine(logoPen, ui.Offset(x, y + 16), ui.Offset(x + 5, y));
        g.drawLine(logoPen, ui.Offset(x + 5, y), ui.Offset(x + 10, y + 10));
        g.drawLine(logoPen, ui.Offset(x + 10, y + 10), ui.Offset(x + 15, y));
        g.drawLine(logoPen, ui.Offset(x + 15, y), ui.Offset(x + 20, y + 16));

        final logoPen2 = PdfPen(PdfColor(130, 140, 145), width: 3);
        g.drawLine(logoPen2, ui.Offset(x + 12, y + 16), ui.Offset(x + 17, y));
        g.drawLine(logoPen2, ui.Offset(x + 17, y), ui.Offset(x + 22, y + 10));
        g.drawLine(logoPen2, ui.Offset(x + 22, y + 10), ui.Offset(x + 27, y));
        g.drawLine(logoPen2, ui.Offset(x + 27, y), ui.Offset(x + 32, y + 16));

        g.drawString(
          'MEET',
          PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
          brush: PdfSolidBrush(textWhite),
          bounds: ui.Rect.fromLTWH(x + 40, y + 2, 45, 16),
        );
        g.drawString(
          'MARKETERS',
          PdfStandardFont(PdfFontFamily.helvetica, 12),
          brush: PdfSolidBrush(textOffWhite),
          bounds: ui.Rect.fromLTWH(x + 82, y + 2, 100, 16),
        );
      }
    }

    // ── Helper: Draw Section Title in Lime Green ─────────────────
    void drawSectionTitle(PdfGraphics g, String title, double top) {
      g.drawString(
        title,
        h1Font,
        brush: PdfSolidBrush(accentLime),
        bounds: ui.Rect.fromLTWH(contentX, top, contentWidth, 30),
      );
    }

    // ── Helper: Draw Rounded Dark Card ───────────────────────────
    void drawCard(PdfGraphics g, ui.Rect rect) {
      g.drawRectangle(
        brush: PdfSolidBrush(bgCard),
        pen: PdfPen(cardBorder, width: 1),
        bounds: rect,
      );
    }

    // ── Helper: Draw Styled Pill / Tag ────────────────────────────
    void drawPill(PdfGraphics g, ui.Rect rect, {PdfColor? bgColor, PdfColor? borderColor, double borderWidth = 0.8}) {
      g.drawRectangle(
        brush: PdfSolidBrush(bgColor ?? PdfColor(14, 28, 22)),
        pen: borderColor != null ? PdfPen(borderColor, width: borderWidth) : null,
        bounds: rect,
      );
    }

    // ── Helper: Draw Table Header Banner in Lime Green ───────────
    void drawTableHeader(PdfGraphics g, String title, ui.Rect rect) {
      g.drawRectangle(
        brush: PdfSolidBrush(accentLime),
        pen: PdfPen(tableBorder, width: 0.5),
        bounds: rect,
      );
      g.drawString(
        title,
        h3Font,
        brush: PdfSolidBrush(textBlack),
        bounds: ui.Rect.fromLTWH(rect.left + 10, rect.top + 5, rect.width - 20, rect.height - 10),
      );
    }

    // ── Helper: Draw Dark Table Cell ─────────────────────────────
    void drawTableCell(PdfGraphics g, ui.Rect rect) {
      g.drawRectangle(
        brush: PdfSolidBrush(PdfColor(15, 19, 19)),
        pen: PdfPen(tableBorder, width: 0.5),
        bounds: rect,
      );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PAGE 1: Cover Page & Table of Contents (Luxury Strategic Agency Aesthetic)
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      drawDarkBase(page);

      // Top Header: Meet Marketers Logo & Confidential Badge
      drawMeetMarketersLogo(g, contentX, 60);

      // Category Badge Pill (Top Right)
      const badgeR = ui.Rect.fromLTWH(contentX + contentWidth - 210, 60, 210, 24);
      drawPill(g, badgeR, bgColor: PdfColor(13, 32, 26), borderColor: accentLime, borderWidth: 0.8);
      g.drawString(
        'STRATEGIC BLUEPRINT · 2026',
        PdfStandardFont(PdfFontFamily.helvetica, 8.5, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: badgeR,
        format: PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle),
      );

      // Two-Tone Main Hero Title
      g.drawString(
        'DIGITAL & CONTENT',
        PdfStandardFont(PdfFontFamily.helvetica, 28, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: const ui.Rect.fromLTWH(contentX, 130, contentWidth, 34),
      );
      g.drawString(
        'DIRECTION PROPOSAL',
        PdfStandardFont(PdfFontFamily.helvetica, 28, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(textWhite),
        bounds: const ui.Rect.fromLTWH(contentX, 166, contentWidth, 34),
      );

      // Client Metadata Card
      const metaR = ui.Rect.fromLTWH(contentX, 215, contentWidth, 75);
      drawPill(g, metaR, bgColor: PdfColor(14, 23, 28), borderColor: cardBorder, borderWidth: 0.8);

      if (companyLogoBytes != null) {
        try {
          const logoW = 56.0;
          const logoH = 46.0;
          final logoRect = ui.Rect.fromLTWH(metaR.right - logoW - 16, metaR.top + 14, logoW, logoH);
          drawPill(g, ui.Rect.fromLTWH(logoRect.left - 4, logoRect.top - 4, logoW + 8, logoH + 8), bgColor: PdfColor(255, 255, 255));
          g.drawImage(PdfBitmap(companyLogoBytes), logoRect);
        } catch (_) {}
      }

      g.drawString(
        'PREPARED EXCLUSIVELY FOR:',
        PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: const ui.Rect.fromLTWH(contentX + 16, 225, contentWidth - 32, 12),
      );
      g.drawString(
        proposal.leadCompanyName,
        PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(textWhite),
        bounds: const ui.Rect.fromLTWH(contentX + 16, 240, contentWidth - 32, 24),
      );

      final pitchInfo = (proposal.pitchDeckFileName != null && proposal.pitchDeckFileName!.isNotEmpty)
          ? '  ·  Deck: ${proposal.pitchDeckFileName}'
          : '';
      g.drawString(
        'Industry: ${proposal.industry.isNotEmpty ? proposal.industry : "Enterprise"}  ·  Strategy: Meet Marketers AI$pitchInfo',
        captionFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: const ui.Rect.fromLTWH(contentX + 16, 268, contentWidth - 32, 14),
      );

      // CONTENTS SECTION — 2 Elevated Cards Side-by-Side
      const tocTop = 310.0;
      const tocCardW = (contentWidth - 16) / 2.0;
      const tocCardH = 410.0;

      // Card 1: Market Strategy & Positioning
      const toc1R = ui.Rect.fromLTWH(contentX, tocTop, tocCardW, tocCardH);
      drawCard(g, toc1R);
      drawPill(g, ui.Rect.fromLTWH(contentX + 12, tocTop + 14, tocCardW - 24, 26), bgColor: PdfColor(12, 28, 22));
      g.drawString(
        'PART 01 · MARKET STRATEGY',
        PdfStandardFont(PdfFontFamily.helvetica, 9.5, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: ui.Rect.fromLTWH(contentX + 20, tocTop + 20, tocCardW - 40, 16),
      );

      final strategyItems = [
        '01  Executive Summary & Opportunity',
        '02  SWOT Strategic Matrix',
        '03  Marketing Mix (4Ps Framework)',
        '04  PEST Environmental Scan',
        '05  Competitor & USP Strategic Matrix',
        '06  Perceptual Positioning Landscape',
      ];
      double ty1 = tocTop + 55;
      for (final item in strategyItems) {
        g.drawString(
          item,
          PdfStandardFont(PdfFontFamily.helvetica, 9.5, style: PdfFontStyle.regular),
          brush: PdfSolidBrush(textWhite),
          bounds: ui.Rect.fromLTWH(contentX + 18, ty1, tocCardW - 36, 18),
        );
        ty1 += 34;
      }

      // Card 2: Campaign Architecture & Execution
      final toc2X = contentX + tocCardW + 16;
      final toc2R = ui.Rect.fromLTWH(toc2X, tocTop, tocCardW, tocCardH);
      drawCard(g, toc2R);
      drawPill(g, ui.Rect.fromLTWH(toc2X + 12, tocTop + 14, tocCardW - 24, 26), bgColor: PdfColor(12, 28, 22));
      g.drawString(
        'PART 02 · CREATIVE CAMPAIGN',
        PdfStandardFont(PdfFontFamily.helvetica, 9.5, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: ui.Rect.fromLTWH(toc2X + 20, tocTop + 20, tocCardW - 40, 16),
      );

      final operationItems = [
        '07  Creative Direction: 5 Pillars',
        '08  Visual Guidelines & Monthly Plan',
        '09  Sample Reel (Vertical Video)',
        '10  Sample Social Media Copywriting',
        '11  SEO Pillar Thought Leadership',
        '12  SEO & Digital Opportunities',
        '13  Strategic Assessment & Thoughts',
      ];
      double ty2 = tocTop + 55;
      for (final item in operationItems) {
        g.drawString(
          item,
          PdfStandardFont(PdfFontFamily.helvetica, 9.5, style: PdfFontStyle.regular),
          brush: PdfSolidBrush(textWhite),
          bounds: ui.Rect.fromLTWH(toc2X + 18, ty2, tocCardW - 36, 18),
        );
        ty2 += 34;
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PAGE 2: Current Position, Opportunity & SWOT Analysis
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      drawDarkBase(page);

      // Top Lead Brand Badge - Vibrant Lime Green (replaces blue)
      g.drawString(
        proposal.leadCompanyName.toUpperCase(),
        PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: const ui.Rect.fromLTWH(0, 44, pageWidth, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );

      // Subtitle Pill
      const subR = ui.Rect.fromLTWH((pageWidth - 220) / 2, 68, 220, 18);
      drawPill(g, subR, bgColor: PdfColor(14, 28, 22), borderColor: accentLime, borderWidth: 0.6);
      g.drawString(
        'STRATEGIC AUDIT & DIRECTION',
        PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: subR,
        format: PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle),
      );

      // Card 1: Current Position (Clean Padded Box)
      const posCardR = ui.Rect.fromLTWH(contentX, 96, contentWidth, 106);
      drawCard(g, posCardR);
      drawPill(g, ui.Rect.fromLTWH(contentX + 14, 106, 128, 20), bgColor: PdfColor(14, 32, 24), borderColor: accentLime, borderWidth: 0.6);
      g.drawString(
        'CURRENT POSITION',
        PdfStandardFont(PdfFontFamily.helvetica, 7.5, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: ui.Rect.fromLTWH(contentX + 14, 106, 128, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle),
      );

      final posText = proposal.executiveSummaryPosition.isNotEmpty
          ? proposal.executiveSummaryPosition
          : '${proposal.leadCompanyName} has established itself as one of the trusted leaders in ${proposal.industry}, delivering proven value, professional service standards, and verified client satisfaction across its customer base.';
      g.drawString(
        posText,
        PdfStandardFont(PdfFontFamily.helvetica, 9),
        brush: PdfSolidBrush(textOffWhite),
        bounds: const ui.Rect.fromLTWH(contentX + 16, 134, contentWidth - 32, 60),
      );

      // Card 2: Market Opportunity (Clean Padded Box)
      const oppCardR = ui.Rect.fromLTWH(contentX, 210, contentWidth, 106);
      drawCard(g, oppCardR);
      drawPill(g, ui.Rect.fromLTWH(contentX + 14, 220, 142, 20), bgColor: PdfColor(14, 32, 24), borderColor: accentLime, borderWidth: 0.6);
      g.drawString(
        'STRATEGIC OPPORTUNITY',
        PdfStandardFont(PdfFontFamily.helvetica, 7.5, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: ui.Rect.fromLTWH(contentX + 14, 220, 142, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle),
      );

      final oppText = proposal.executiveSummaryOpportunity.isNotEmpty
          ? proposal.executiveSummaryOpportunity
          : 'While ${proposal.leadCompanyName} has built strong foundational trust, substantial opportunity exists to capture market leadership through multi-channel digital authority, high-converting service landing pages, and educational content that eliminates client hesitation.';
      g.drawString(
        oppText,
        PdfStandardFont(PdfFontFamily.helvetica, 9),
        brush: PdfSolidBrush(textOffWhite),
        bounds: const ui.Rect.fromLTWH(contentX + 16, 248, contentWidth - 32, 60),
      );

      // SWOT Analysis Section Heading (Lime Green)
      drawSectionTitle(g, 'SWOT Analysis', 330);

      // 2x2 SWOT Matrix with Expanded Cell Heights & Zero Text Clipping
      const swotTop = 364.0;
      const colWidth = (contentWidth - 10.0) / 2.0;
      const headerH = 24.0;
      const cellH = 186.0;

      // Row 1: Strength & Weaknesses
      drawTableHeader(g, 'Strength', const ui.Rect.fromLTWH(contentX, swotTop, colWidth, headerH));
      drawTableHeader(g, 'Weaknesses', const ui.Rect.fromLTWH(contentX + colWidth + 10, swotTop, colWidth, headerH));

      drawTableCell(g, const ui.Rect.fromLTWH(contentX, swotTop + headerH, colWidth, cellH));
      drawTableCell(g, const ui.Rect.fromLTWH(contentX + colWidth + 10, swotTop + headerH, colWidth, cellH));

      final swotFont = PdfStandardFont(PdfFontFamily.helvetica, 8.2);
      double ty = swotTop + headerH + 10;
      for (final s in proposal.swot.strengths.take(4)) {
        g.drawString('•  $s', swotFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + 12, ty, colWidth - 24, 40));
        ty += 43;
      }

      ty = swotTop + headerH + 10;
      for (final w in proposal.swot.weaknesses.take(4)) {
        g.drawString('•  $w', swotFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + colWidth + 22, ty, colWidth - 24, 40));
        ty += 43;
      }

      // Row 2: Opportunities & Threats
      const row2Top = swotTop + headerH + cellH + 10;
      drawTableHeader(g, 'Opportunities', const ui.Rect.fromLTWH(contentX, row2Top, colWidth, headerH));
      drawTableHeader(g, 'Threats', const ui.Rect.fromLTWH(contentX + colWidth + 10, row2Top, colWidth, headerH));

      drawTableCell(g, const ui.Rect.fromLTWH(contentX, row2Top + headerH, colWidth, cellH));
      drawTableCell(g, const ui.Rect.fromLTWH(contentX + colWidth + 10, row2Top + headerH, colWidth, cellH));

      ty = row2Top + headerH + 10;
      for (final o in proposal.swot.opportunities.take(4)) {
        g.drawString('•  $o', swotFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + 12, ty, colWidth - 24, 40));
        ty += 43;
      }

      ty = row2Top + headerH + 10;
      for (final t in proposal.swot.threats.take(4)) {
        g.drawString('•  $t', swotFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + colWidth + 22, ty, colWidth - 24, 40));
        ty += 43;
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PAGE 3: 4Ps Analysis
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      drawDarkBase(page);

      drawSectionTitle(g, '4Ps Analysis', 55);

      const pTop = 100.0;
      const colWidth = contentWidth / 2.0;
      const headerH = 25.0;
      const cellH = 320.0;

      // Row 1: Product & Price
      drawTableHeader(g, 'Product', const ui.Rect.fromLTWH(contentX, pTop, colWidth, headerH));
      drawTableHeader(g, 'Price', const ui.Rect.fromLTWH(contentX + colWidth, pTop, colWidth, headerH));

      drawTableCell(g, const ui.Rect.fromLTWH(contentX, pTop + headerH, colWidth, cellH));
      drawTableCell(g, const ui.Rect.fromLTWH(contentX + colWidth, pTop + headerH, colWidth, cellH));

      // Product content
      double py = pTop + headerH + 14;
      g.drawString('• Current Offering', bodyBold, brush: PdfSolidBrush(textWhite), bounds: ui.Rect.fromLTWH(contentX + 14, py, colWidth - 28, 16));
      py += 18;
      g.drawString(
        proposal.marketingMix4Ps.productCurrent.isNotEmpty ? proposal.marketingMix4Ps.productCurrent : 'Core offerings, custom packages, and bespoke services.',
        bodyFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: ui.Rect.fromLTWH(contentX + 14, py, colWidth - 28, 95),
      );
      py += 105;
      g.drawString('Opportunity', bodyBold, brush: PdfSolidBrush(textWhite), bounds: ui.Rect.fromLTWH(contentX + 14, py, colWidth - 28, 16));
      py += 18;
      g.drawString(
        proposal.marketingMix4Ps.productOpportunity.isNotEmpty ? proposal.marketingMix4Ps.productOpportunity : 'Strengthen differentiation by communicating outcomes rather than just technical inclusions.',
        bodyFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: ui.Rect.fromLTWH(contentX + 14, py, colWidth - 28, 145),
      );

      // Price content
      py = pTop + headerH + 14;
      g.drawString('Current Position', bodyBold, brush: PdfSolidBrush(textWhite), bounds: ui.Rect.fromLTWH(contentX + colWidth + 14, py, colWidth - 28, 16));
      py += 18;
      g.drawString(
        proposal.marketingMix4Ps.priceCurrent.isNotEmpty ? proposal.marketingMix4Ps.priceCurrent : 'Mid-to-premium pricing supported by experienced team, safety, and brand reputation.',
        bodyFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: ui.Rect.fromLTWH(contentX + colWidth + 14, py, colWidth - 28, 95),
      );
      py += 105;
      g.drawString('Opportunity', bodyBold, brush: PdfSolidBrush(textWhite), bounds: ui.Rect.fromLTWH(contentX + colWidth + 14, py, colWidth - 28, 16));
      py += 18;
      g.drawString(
        proposal.marketingMix4Ps.priceOpportunity.isNotEmpty ? proposal.marketingMix4Ps.priceOpportunity : 'Continue competing on experience value, safety, and reliability rather than commoditized discounting.',
        bodyFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: ui.Rect.fromLTWH(contentX + colWidth + 14, py, colWidth - 28, 145),
      );

      // Row 2: Place & Promotion
      const row2Top = pTop + headerH + cellH + 16;
      drawTableHeader(g, 'Place', const ui.Rect.fromLTWH(contentX, row2Top, colWidth, headerH));
      drawTableHeader(g, 'Promotion', const ui.Rect.fromLTWH(contentX + colWidth, row2Top, colWidth, headerH));

      drawTableCell(g, const ui.Rect.fromLTWH(contentX, row2Top + headerH, colWidth, cellH));
      drawTableCell(g, const ui.Rect.fromLTWH(contentX + colWidth, row2Top + headerH, colWidth, cellH));

      // Place content
      py = row2Top + headerH + 14;
      g.drawString('Current Channels', bodyBold, brush: PdfSolidBrush(textWhite), bounds: ui.Rect.fromLTWH(contentX + 14, py, colWidth - 28, 16));
      py += 18;
      g.drawString(
        proposal.marketingMix4Ps.placeCurrent.isNotEmpty ? proposal.marketingMix4Ps.placeCurrent : 'Maintains presence across key digital channels including website, Instagram, and LinkedIn.',
        bodyFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: ui.Rect.fromLTWH(contentX + 14, py, colWidth - 28, 95),
      );
      py += 105;
      g.drawString('Opportunity', bodyBold, brush: PdfSolidBrush(textWhite), bounds: ui.Rect.fromLTWH(contentX + 14, py, colWidth - 28, 16));
      py += 18;
      g.drawString(
        proposal.marketingMix4Ps.placeOpportunity.isNotEmpty ? proposal.marketingMix4Ps.placeOpportunity : 'Improve organic discoverability, corporate B2B channels, and strategic co-marketing partnerships.',
        bodyFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: ui.Rect.fromLTWH(contentX + 14, py, colWidth - 28, 145),
      );

      // Promotion content
      py = row2Top + headerH + 14;
      g.drawString('Current Approach', bodyBold, brush: PdfSolidBrush(textWhite), bounds: ui.Rect.fromLTWH(contentX + colWidth + 14, py, colWidth - 28, 16));
      py += 18;
      g.drawString(
        proposal.marketingMix4Ps.promotionCurrent.isNotEmpty ? proposal.marketingMix4Ps.promotionCurrent : 'Highlights customer celebrations, promotional offers, and customer reviews.',
        bodyFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: ui.Rect.fromLTWH(contentX + colWidth + 14, py, colWidth - 28, 95),
      );
      py += 105;
      g.drawString('Opportunity', bodyBold, brush: PdfSolidBrush(textWhite), bounds: ui.Rect.fromLTWH(contentX + colWidth + 14, py, colWidth - 28, 16));
      py += 18;
      g.drawString(
        proposal.marketingMix4Ps.promotionOpportunity.isNotEmpty ? proposal.marketingMix4Ps.promotionOpportunity : 'Expand into educational authority reels, customer journey transformation stories, and deep-dive guides.',
        bodyFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: ui.Rect.fromLTWH(contentX + colWidth + 14, py, colWidth - 28, 145),
      );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PAGE 4: PEST Analysis & Competitor / USP Strategic Landscape
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      drawDarkBase(page);

      // PEST Analysis Heading
      drawSectionTitle(g, 'PEST Analysis', 40);

      const pestTop = 75.0;
      const colWidth = (contentWidth - 14) / 2.0;
      const cardH = 120.0;

      // Card 1: Political
      const polR = ui.Rect.fromLTWH(contentX, pestTop, colWidth, cardH);
      drawCard(g, polR);
      drawPill(g, ui.Rect.fromLTWH(contentX + 12, pestTop + 10, 95, 20), bgColor: PdfColor(12, 28, 22), borderColor: accentLime, borderWidth: 0.6);
      g.drawString(
        'POLITICAL',
        PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: ui.Rect.fromLTWH(contentX + 12, pestTop + 10, 95, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle),
      );
      double py = pestTop + 36;
      for (final p in proposal.pestAnalysis.political.take(3)) {
        g.drawString('•  $p', bodyFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + 12, py, colWidth - 24, 22));
        py += 24;
      }

      // Card 2: Economic
      final econX = contentX + colWidth + 14;
      final econR = ui.Rect.fromLTWH(econX, pestTop, colWidth, cardH);
      drawCard(g, econR);
      drawPill(g, ui.Rect.fromLTWH(econX + 12, pestTop + 10, 95, 20), bgColor: PdfColor(12, 28, 22), borderColor: accentLime, borderWidth: 0.6);
      g.drawString(
        'ECONOMIC',
        PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: ui.Rect.fromLTWH(econX + 12, pestTop + 10, 95, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle),
      );
      py = pestTop + 36;
      for (final e in proposal.pestAnalysis.economic.take(3)) {
        g.drawString('•  $e', bodyFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(econX + 12, py, colWidth - 24, 22));
        py += 24;
      }

      // Card 3: Social
      final row2Top = pestTop + cardH + 12;
      final socR = ui.Rect.fromLTWH(contentX, row2Top, colWidth, cardH);
      drawCard(g, socR);
      drawPill(g, ui.Rect.fromLTWH(contentX + 12, row2Top + 10, 95, 20), bgColor: PdfColor(12, 28, 22), borderColor: accentLime, borderWidth: 0.6);
      g.drawString(
        'SOCIAL',
        PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: ui.Rect.fromLTWH(contentX + 12, row2Top + 10, 95, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle),
      );
      py = row2Top + 36;
      for (final s in proposal.pestAnalysis.social.take(3)) {
        g.drawString('•  $s', bodyFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + 12, py, colWidth - 24, 22));
        py += 24;
      }

      // Card 4: Technological
      final techR = ui.Rect.fromLTWH(econX, row2Top, colWidth, cardH);
      drawCard(g, techR);
      drawPill(g, ui.Rect.fromLTWH(econX + 12, row2Top + 10, 115, 20), bgColor: PdfColor(12, 28, 22), borderColor: accentLime, borderWidth: 0.6);
      g.drawString(
        'TECHNOLOGICAL',
        PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: ui.Rect.fromLTWH(econX + 12, row2Top + 10, 115, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle),
      );
      py = row2Top + 36;
      for (final t in proposal.pestAnalysis.technological.take(3)) {
        g.drawString('•  $t', bodyFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(econX + 12, py, colWidth - 24, 22));
        py += 24;
      }

      // Unified Competitor & USP Strategic Matrix Section
      double curY = row2Top + cardH + 24;
      drawSectionTitle(g, 'Competitor & USP Strategic Matrix', curY);
      curY += 32;

      const brandColW = 150.0;
      const posColW = 130.0;
      final uspColW = contentWidth - brandColW - posColW;
      const matrixHeaderH = 26.0;

      // Table Header Row
      drawPill(g, ui.Rect.fromLTWH(contentX, curY, contentWidth, matrixHeaderH), bgColor: PdfColor(14, 25, 30), borderColor: cardBorder, borderWidth: 0.8);
      g.drawString(
        'BRAND',
        PdfStandardFont(PdfFontFamily.helvetica, 8.5, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: ui.Rect.fromLTWH(contentX + 12, curY + 6, brandColW - 12, 16),
      );
      g.drawString(
        'PRIMARY USP & VALUE PROPOSITION',
        PdfStandardFont(PdfFontFamily.helvetica, 8.5, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: ui.Rect.fromLTWH(contentX + brandColW + 8, curY + 6, uspColW - 16, 16),
      );
      g.drawString(
        'MARKET POSITION',
        PdfStandardFont(PdfFontFamily.helvetica, 8.5, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: ui.Rect.fromLTWH(contentX + brandColW + uspColW + 8, curY + 6, posColW - 16, 16),
      );
      curY += matrixHeaderH + 4;

      final allComps = proposal.competitorUsps.isNotEmpty
          ? proposal.competitorUsps
          : [
              CompetitorUsp(brandName: proposal.leadCompanyName, primaryUsp: 'Premier tailored experiences, outstanding service reliability, customer trust', isLeadBrand: true),
              const CompetitorUsp(brandName: 'Competitor Alpha', primaryUsp: 'High-volume discount pricing and mass-market reach'),
              const CompetitorUsp(brandName: 'Competitor Beta', primaryUsp: 'Ultra-exclusive boutique offering with limited availability'),
              const CompetitorUsp(brandName: 'Competitor Gamma', primaryUsp: 'Event-focused packages with generic group inclusions'),
            ];

      for (int i = 0; i < allComps.take(4).length; i++) {
        final c = allComps[i];
        const rowH = 46.0;
        final rowR = ui.Rect.fromLTWH(contentX, curY, contentWidth, rowH);

        if (c.isLeadBrand) {
          // Highlighted row for Client
          drawPill(g, rowR, bgColor: PdfColor(14, 32, 24), borderColor: accentLime, borderWidth: 0.8);
        } else {
          // Alternating rows for competitors
          drawPill(g, rowR, bgColor: i % 2 == 0 ? PdfColor(15, 20, 23) : PdfColor(11, 16, 18), borderColor: cardBorder, borderWidth: 0.5);
        }

        // Brand Name + Client Badge
        if (c.isLeadBrand) {
          g.drawString(
            '★  ${c.brandName}',
            PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
            brush: PdfSolidBrush(accentLime),
            bounds: ui.Rect.fromLTWH(contentX + 12, curY + 14, brandColW - 20, 18),
          );
        } else {
          g.drawString(
            c.brandName,
            PdfStandardFont(PdfFontFamily.helvetica, 9.5, style: PdfFontStyle.regular),
            brush: PdfSolidBrush(textWhite),
            bounds: ui.Rect.fromLTWH(contentX + 12, curY + 14, brandColW - 20, 18),
          );
        }

        // Primary USP
        g.drawString(
          c.primaryUsp,
          bodyFont,
          brush: PdfSolidBrush(textOffWhite),
          bounds: ui.Rect.fromLTWH(contentX + brandColW + 8, curY + 10, uspColW - 16, 30),
        );

        // Market Positioning Note
        final posNote = c.isLeadBrand
            ? 'Category Leader'
            : (i == 1 ? 'Mass Volume Operator' : (i == 2 ? 'Niche Boutique' : 'Generic Alternatives'));
        g.drawString(
          posNote,
          captionFont,
          brush: PdfSolidBrush(c.isLeadBrand ? accentLime : textMuted),
          bounds: ui.Rect.fromLTWH(contentX + brandColW + uspColW + 8, curY + 15, posColW - 16, 18),
        );

        curY += rowH + 4;
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PAGE 5: Perceptual Map & Strategic Positioning (FIXED SPACING NO COLLISION)
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      drawDarkBase(page);

      // 1. Heading
      drawSectionTitle(g, 'Perceptual Map', 44);

      // 2. Subtitle with generous spacing
      final indName = proposal.industry.isNotEmpty ? proposal.industry : proposal.leadCompanyName;
      g.drawString(
        '$indName Market Positioning',
        h3Font,
        brush: PdfSolidBrush(textWhite),
        bounds: const ui.Rect.fromLTWH(0, 78, pageWidth, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );

      // 3. Coordinate Cross Graph - Centered with plenty of vertical clearance
      const graphCenterX = pageWidth / 2.0; // 297.64
      const graphCenterY = 270.0;
      const axisLen = 130.0;

      final axisPen = PdfPen(textWhite, width: 1.2);

      final mapData = ProposalDomainEngine.instance.resolvePerceptualMapData(proposal);

      // Top Y-Axis Label
      g.drawString(
        'HIGH',
        h3Font,
        brush: PdfSolidBrush(textWhite),
        bounds: const ui.Rect.fromLTWH(graphCenterX - 110, 106, 220, 14),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      g.drawString(
        mapData.yAxisLabel,
        captionFont,
        brush: PdfSolidBrush(accentLime),
        bounds: const ui.Rect.fromLTWH(graphCenterX - 120, 120, 240, 14),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );

      // Vertical Axis Line & Arrows (from y = 140 to y = 400)
      g.drawLine(axisPen, ui.Offset(graphCenterX, graphCenterY - axisLen), ui.Offset(graphCenterX, graphCenterY + axisLen));
      // Top arrow
      g.drawLine(axisPen, ui.Offset(graphCenterX - 5, graphCenterY - axisLen + 8), ui.Offset(graphCenterX, graphCenterY - axisLen));
      g.drawLine(axisPen, ui.Offset(graphCenterX + 5, graphCenterY - axisLen + 8), ui.Offset(graphCenterX, graphCenterY - axisLen));
      // Bottom arrow
      g.drawLine(axisPen, ui.Offset(graphCenterX - 5, graphCenterY + axisLen - 8), ui.Offset(graphCenterX, graphCenterY + axisLen));
      g.drawLine(axisPen, ui.Offset(graphCenterX + 5, graphCenterY + axisLen - 8), ui.Offset(graphCenterX, graphCenterY + axisLen));

      // Bottom Y-Axis Label
      g.drawString(
        'LOW',
        h3Font,
        brush: PdfSolidBrush(textWhite),
        bounds: const ui.Rect.fromLTWH(graphCenterX - 110, 406, 220, 14),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      g.drawString(
        mapData.yAxisLabel,
        captionFont,
        brush: PdfSolidBrush(textMuted),
        bounds: const ui.Rect.fromLTWH(graphCenterX - 120, 420, 240, 14),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );

      // Horizontal Axis Line & Arrows (from x = graphCenterX - 130 to x = graphCenterX + 130)
      g.drawLine(axisPen, ui.Offset(graphCenterX - axisLen, graphCenterY), ui.Offset(graphCenterX + axisLen, graphCenterY));
      // Left arrow
      g.drawLine(axisPen, ui.Offset(graphCenterX - axisLen + 8, graphCenterY - 5), ui.Offset(graphCenterX - axisLen, graphCenterY));
      g.drawLine(axisPen, ui.Offset(graphCenterX - axisLen + 8, graphCenterY + 5), ui.Offset(graphCenterX - axisLen, graphCenterY));
      // Right arrow
      g.drawLine(axisPen, ui.Offset(graphCenterX + axisLen - 8, graphCenterY - 5), ui.Offset(graphCenterX + axisLen, graphCenterY));
      g.drawLine(axisPen, ui.Offset(graphCenterX + axisLen - 8, graphCenterY + 5), ui.Offset(graphCenterX + axisLen, graphCenterY));

      // Horizontal Axis Labels
      g.drawString(
        'LOW\n${mapData.xAxisLabel}',
        captionFont,
        brush: PdfSolidBrush(textMuted),
        bounds: const ui.Rect.fromLTWH(graphCenterX - axisLen - 95, graphCenterY - 14, 90, 28),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      g.drawString(
        'HIGH\n${mapData.xAxisLabel}',
        captionFont,
        brush: PdfSolidBrush(accentLime),
        bounds: const ui.Rect.fromLTWH(graphCenterX + axisLen + 6, graphCenterY - 14, 90, 28),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );

      // Plotted Brands in 4 Quadrants
      // Quadrant 1 (Top Right): THE WINNING QUADRANT (HIGH Y, HIGH X) -> LEAD BRAND!
      g.drawString(
        mapData.topRightBrand,
        bodyBold,
        brush: PdfSolidBrush(accentLime),
        bounds: const ui.Rect.fromLTWH(graphCenterX + 35, graphCenterY - 95, 160, 16),
      );
      g.drawString(
        mapData.topRightDesc,
        captionFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: const ui.Rect.fromLTWH(graphCenterX + 35, graphCenterY - 78, 155, 48),
      );

      // Quadrant 2 (Top Left): (HIGH Y, LOW X) -> Niche / Specialized
      g.drawString(
        mapData.topLeftBrand,
        bodyBold,
        brush: PdfSolidBrush(textWhite),
        bounds: const ui.Rect.fromLTWH(contentX + 10, graphCenterY - 95, 150, 16),
      );
      g.drawString(
        mapData.topLeftDesc,
        captionFont,
        brush: PdfSolidBrush(textMuted),
        bounds: const ui.Rect.fromLTWH(contentX + 10, graphCenterY - 78, 145, 48),
      );

      // Quadrant 3 (Bottom Left): (LOW Y, LOW X) -> Ad-Hoc / Basic
      g.drawString(
        mapData.bottomLeftBrand,
        bodyBold,
        brush: PdfSolidBrush(textWhite),
        bounds: const ui.Rect.fromLTWH(contentX + 10, graphCenterY + 45, 150, 16),
      );
      g.drawString(
        mapData.bottomLeftDesc,
        captionFont,
        brush: PdfSolidBrush(textMuted),
        bounds: const ui.Rect.fromLTWH(contentX + 10, graphCenterY + 62, 145, 48),
      );

      // Quadrant 4 (Bottom Right): (LOW Y, HIGH X) -> Mass / Generalist
      g.drawString(
        mapData.bottomRightBrand,
        bodyBold,
        brush: PdfSolidBrush(textWhite),
        bounds: const ui.Rect.fromLTWH(graphCenterX + 35, graphCenterY + 45, 160, 16),
      );
      g.drawString(
        mapData.bottomRightDesc,
        captionFont,
        brush: PdfSolidBrush(textMuted),
        bounds: const ui.Rect.fromLTWH(graphCenterX + 35, graphCenterY + 62, 155, 48),
      );

      // 4. Bottom Insight Card (Starts safely at y = 475)
      const insightCardRect = ui.Rect.fromLTWH(contentX, 475, contentWidth, 275);
      drawCard(g, insightCardRect);

      double iy = 500;
      g.drawString(
        'KEY INSIGHT',
        h3Font,
        brush: PdfSolidBrush(accentLime),
        bounds: const ui.Rect.fromLTWH(contentX + 24, 500, contentWidth - 48, 18),
      );
      iy += 22;

      final insightText = proposal.perceptualMapInsight.isNotEmpty
          ? proposal.perceptualMapInsight
          : 'Customers do not book services based on technical specifications alone; they purchase the emotional certainty and seamless execution of high-stakes moments.';
      g.drawString(
        insightText,
        bodyFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: ui.Rect.fromLTWH(contentX + 24, iy, contentWidth - 48, 85),
      );

      iy += 95;
      g.drawString(
        'OPPORTUNITY',
        h3Font,
        brush: PdfSolidBrush(accentLime),
        bounds: ui.Rect.fromLTWH(contentX + 24, iy, contentWidth - 48, 18),
      );
      iy += 22;

      final oppMapText = proposal.perceptualMapOpportunity.isNotEmpty
          ? proposal.perceptualMapOpportunity
          : 'Strengthen brand visibility and digital authority to reinforce ${proposal.leadCompanyName} as the definitive first choice in its category.';
      g.drawString(
        oppMapText,
        bodyFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: ui.Rect.fromLTWH(contentX + 24, iy, contentWidth - 48, 85),
      );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PAGE 6 & 7: Creative Direction (Content Pillars 1 - 5)
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      drawDarkBase(page);

      drawSectionTitle(g, 'Creative Direction (Part 1)', 45);

      final pillars = proposal.creativePillars.isNotEmpty
          ? proposal.creativePillars
          : [
              const ContentPillar(
                title: 'Experience & Celebration Stories',
                objective: 'Showcase memorable moments and emotional connections with customers.',
                contentStyle: ['Event recap reels', 'Celebration highlights', 'Customer storytelling'],
                exampleTopics: ['A Celebration They Will Talk About For Years', 'Behind This Milestone', 'Why Families Choose Curated Experiences'],
              ),
              const ContentPillar(
                title: 'Expert Domain Education',
                objective: 'Position brand as trusted authority and remove buyer hesitation.',
                contentStyle: ['Saveable checklists', 'Comparison carousels', 'Friction elimination'],
                exampleTopics: ['First Time Booking? Here Is What To Expect', 'Key Differences To Look For', 'What Happens If Weather Changes?'],
              ),
            ];

      double curY = 95;
      for (final p in pillars.take(2)) {
        final cardR = ui.Rect.fromLTWH(contentX, curY, contentWidth, 290);
        drawCard(g, cardR);

        double py = curY + 18;
        g.drawString(p.title, h2Font, brush: PdfSolidBrush(accentLime), bounds: ui.Rect.fromLTWH(contentX + 20, py, contentWidth - 40, 22));
        py += 26;

        g.drawString('Objective', bodyBold, brush: PdfSolidBrush(textWhite), bounds: ui.Rect.fromLTWH(contentX + 20, py, contentWidth - 40, 16));
        py += 18;
        g.drawString(p.objective, bodyFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + 20, py, contentWidth - 40, 50));
        py += 55;

        g.drawString('Content Formats', bodyBold, brush: PdfSolidBrush(textWhite), bounds: ui.Rect.fromLTWH(contentX + 20, py, contentWidth - 40, 16));
        py += 18;
        g.drawString(p.contentStyle.join(' · '), bodyFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + 20, py, contentWidth - 40, 24));
        py += 30;

        g.drawString('Sample Topics', bodyBold, brush: PdfSolidBrush(textWhite), bounds: ui.Rect.fromLTWH(contentX + 20, py, contentWidth - 40, 16));
        py += 18;
        for (final t in p.exampleTopics.take(3)) {
          g.drawString('• “$t”', bodyFont, brush: PdfSolidBrush(PdfColor(134, 239, 172)), bounds: ui.Rect.fromLTWH(contentX + 20, py, contentWidth - 40, 18));
          py += 18;
        }

        curY += 310;
      }
    }

    // Page 7: Creative Direction Part 2
    {
      final page = document.pages.add();
      final g = page.graphics;
      drawDarkBase(page);

      drawSectionTitle(g, 'Creative Direction (Part 2)', 45);

      final extraPillars = proposal.creativePillars.length > 2
          ? proposal.creativePillars.skip(2).take(3).toList()
          : [
              const ContentPillar(
                title: 'Corporate & Executive Experiences',
                objective: 'Strengthen visibility within B2B corporate market for retreats and offsites.',
                contentStyle: ['Executive recaps', 'Team bonding reels', 'Client entertainment case studies'],
                exampleTopics: ['Your Team Does Not Need Another Ballroom', 'Why Companies Choose Curated Offsites'],
              ),
              const ContentPillar(
                title: 'Lifestyle & Aspiration',
                objective: 'Build premium aspiration and position the brand as an unforgettable experience.',
                contentStyle: ['Cinematic drone footage', 'Atmospheric storytelling', 'Weekend reset'],
                exampleTopics: ['The Perspective Most People Never See', 'Escape The City In Style'],
              ),
              const ContentPillar(
                title: 'Customer Proof & Transformation',
                objective: 'Build trust and credibility through genuine transformation stories.',
                contentStyle: ['Review overlays', 'Customer journey recaps', 'Real experience reviews'],
                exampleTopics: ['Why They Chose Us', 'From Planning To Celebration: Their Real Experience'],
              ),
            ];

      double curY = 95;
      for (final p in extraPillars) {
        final cardR = ui.Rect.fromLTWH(contentX, curY, contentWidth, 195);
        drawCard(g, cardR);

        double py = curY + 14;
        g.drawString(p.title, h3Font, brush: PdfSolidBrush(accentLime), bounds: ui.Rect.fromLTWH(contentX + 18, py, contentWidth - 36, 18));
        py += 22;

        g.drawString(p.objective, bodyFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + 18, py, contentWidth - 36, 36));
        py += 40;

        g.drawString('Content Formats: ${p.contentStyle.join(' · ')}', bodyBold, brush: PdfSolidBrush(textWhite), bounds: ui.Rect.fromLTWH(contentX + 18, py, contentWidth - 36, 18));
        py += 22;

        g.drawString('Sample Topics:', bodyBold, brush: PdfSolidBrush(textWhite), bounds: ui.Rect.fromLTWH(contentX + 18, py, contentWidth - 36, 16));
        py += 16;
        for (final t in p.exampleTopics.take(2)) {
          g.drawString('• “$t”', bodyFont, brush: PdfSolidBrush(PdfColor(134, 239, 172)), bounds: ui.Rect.fromLTWH(contentX + 18, py, contentWidth - 36, 16));
          py += 16;
        }

        curY += 215;
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ─────────────────────────────────────────────────────────────────────────
    // PAGE 8: Visual Guideline/ Content Framework (Matching Reference Deck)
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      drawDarkBase(page);

      drawSectionTitle(g, 'Visual Guideline/ Content Framework', 35);

      // Symmetric Grid Constants
      const colW = (contentWidth - 12.0) / 2.0;
      const box12Top = 68.0;
      const box12H = 175.0;

      // (1) Visual Direction (Top Left)
      const box1R = ui.Rect.fromLTWH(contentX, box12Top, colW, box12H);
      drawCard(g, box1R);

      double b1ContentY = box12Top + 10;
      if (visualDirectionImageBytes != null) {
        try {
          final imgRect = ui.Rect.fromLTWH(contentX + 10, box12Top + 8, colW - 20, 68);
          g.drawImage(PdfBitmap(visualDirectionImageBytes), imgRect);
          if (companyLogoBytes != null) {
            const logoW = 28.0;
            const logoH = 18.0;
            final logoRect = ui.Rect.fromLTWH(imgRect.right - logoW - 6, imgRect.top + 6, logoW, logoH);
            drawPill(g, ui.Rect.fromLTWH(logoRect.left - 2, logoRect.top - 2, logoW + 4, logoH + 4), bgColor: PdfColor(0, 0, 0, 190), borderColor: PdfColor(255, 255, 255, 120), borderWidth: 0.5);
            g.drawImage(PdfBitmap(companyLogoBytes), logoRect);
          }
          b1ContentY = box12Top + 82;
        } catch (_) {}
      }

      g.drawString('1  VISUAL DIRECTION', h3Font, brush: PdfSolidBrush(accentLime), bounds: ui.Rect.fromLTWH(contentX + 12, b1ContentY, colW - 24, 16));
      if (visualDirectionImageBytes == null) {
        g.drawString('CREATIVE DIRECTION', captionFont, brush: PdfSolidBrush(textMuted), bounds: ui.Rect.fromLTWH(contentX + 12, box12Top + 28, colW - 24, 12));
      }
      g.drawString(
        proposal.visualGuidelineNotes.isNotEmpty
            ? proposal.visualGuidelineNotes
            : 'Our visual direction focuses on the experiences, emotions and memorable moments that customers enjoy. The objective is to position ${proposal.leadCompanyName} as the definitive category choice through authentic connection.',
        captionFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: ui.Rect.fromLTWH(contentX + 12, visualDirectionImageBytes != null ? b1ContentY + 18 : box12Top + 44, colW - 24, visualDirectionImageBytes != null ? 50 : 65),
      );
      if (visualDirectionImageBytes == null) {
        g.drawString('KEYWORDS', captionFont, brush: PdfSolidBrush(textMuted), bounds: ui.Rect.fromLTWH(contentX + 12, box12Top + 116, colW - 24, 12));
        final kws = proposal.visualKeywords.isNotEmpty ? proposal.visualKeywords : ['Experiential', 'Lifestyle-driven', 'Aspirational', 'Authentic', 'Human-centric'];
        g.drawString(kws.join(' · '), captionFont, brush: PdfSolidBrush(accentLime), bounds: ui.Rect.fromLTWH(contentX + 12, box12Top + 132, colW - 24, 34));
      } else {
        final kws = proposal.visualKeywords.isNotEmpty ? proposal.visualKeywords : ['Experiential', 'Lifestyle-driven', 'Aspirational'];
        g.drawString(kws.join(' · '), captionFont, brush: PdfSolidBrush(accentLime), bounds: ui.Rect.fromLTWH(contentX + 12, b1ContentY + 70, colW - 24, 20));
      }

      // (2) Photography Style (Top Right)
      final box2R = ui.Rect.fromLTWH(contentX + colW + 12, box12Top, colW, box12H);
      drawCard(g, box2R);
      g.drawString('2  PHOTOGRAPHY STYLE', h3Font, brush: PdfSolidBrush(accentLime), bounds: ui.Rect.fromLTWH(box2R.left + 12, box12Top + 10, colW - 24, 16));

      // Dual Sub-Columns for Focus More vs Focus Less
      final subColW = (colW - 24.0) / 2.0;
      final leftColX = box2R.left + 10;
      final rightColX = box2R.left + 14 + subColW;

      g.drawString('FOCUS MORE ON:', PdfStandardFont(PdfFontFamily.helvetica, 7.5, style: PdfFontStyle.bold), brush: PdfSolidBrush(PdfColor(134, 239, 172)), bounds: ui.Rect.fromLTWH(leftColX, box12Top + 28, subColW, 12));
      final moreOn = proposal.focusMoreOn.isNotEmpty ? proposal.focusMoreOn : ['Real team members in action', 'Clear infographic data', 'High-quality customer moments', 'Clean modern workspace'];
      double fmy = box12Top + 42;
      for (final f in moreOn.take(4)) {
        g.drawString('✓ $f', PdfStandardFont(PdfFontFamily.helvetica, 7), brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(leftColX, fmy, subColW, 14));
        fmy += 15;
      }

      g.drawString('FOCUS LESS ON:', PdfStandardFont(PdfFontFamily.helvetica, 7.5, style: PdfFontStyle.bold), brush: PdfSolidBrush(PdfColor(248, 113, 113)), bounds: ui.Rect.fromLTWH(rightColX, box12Top + 28, subColW, 12));
      final lessOn = proposal.focusLessOn.isNotEmpty ? proposal.focusLessOn : ['Cheesy stock handshakes', 'Overly complex technical jargon', 'Generic clip-art graphics', 'Unfocused low-resolution photos'];
      double fly = box12Top + 42;
      for (final l in lessOn.take(4)) {
        g.drawString('✕ $l', PdfStandardFont(PdfFontFamily.helvetica, 7), brush: PdfSolidBrush(textMuted), bounds: ui.Rect.fromLTWH(rightColX, fly, subColW, 14));
        fly += 15;
      }

      // Experience Quote Box at Bottom of Box 2
      final quoteR = ui.Rect.fromLTWH(box2R.left + 8, box12Top + 136, colW - 16, 32);
      drawPill(g, quoteR, bgColor: PdfColor(14, 26, 22), borderColor: cardBorder, borderWidth: 0.5);
      g.drawString(
        '“${proposal.photographyQuote}”',
        PdfStandardFont(PdfFontFamily.helvetica, 7, style: PdfFontStyle.italic),
        brush: PdfSolidBrush(accentLime),
        bounds: ui.Rect.fromLTWH(quoteR.left + 8, quoteR.top + 5, quoteR.width - 16, quoteR.height - 10),
      );

      // (3) Design Style (Mid Left)
      const box34Top = 252.0;
      const box34H = 136.0;
      const box3R = ui.Rect.fromLTWH(contentX, box34Top, colW, box34H);
      drawCard(g, box3R);
      g.drawString('3  DESIGN STYLE', h3Font, brush: PdfSolidBrush(accentLime), bounds: ui.Rect.fromLTWH(contentX + 12, box34Top + 10, colW - 24, 16));
      g.drawString('TYPOGRAPHY & VISUALS', captionFont, brush: PdfSolidBrush(textMuted), bounds: ui.Rect.fromLTWH(contentX + 12, box34Top + 28, colW - 24, 12));
      g.drawString('Clean · Modern · High readability · Minimal clutter', captionFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + 12, box34Top + 42, colW - 24, 14));
      g.drawString(
        proposal.typographySampleHeadline,
        bodyBold,
        brush: PdfSolidBrush(textWhite),
        bounds: ui.Rect.fromLTWH(contentX + 12, box34Top + 58, colW - 24, 16),
      );
      g.drawString('Editorial-inspired · Lifestyle focused · Bright & welcoming', captionFont, brush: PdfSolidBrush(accentLime), bounds: ui.Rect.fromLTWH(contentX + 12, box34Top + 78, colW - 24, 14));
      g.drawString('Strong imagery · Clear hierarchy · Consistent CTA placement', captionFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + 12, box34Top + 96, colW - 24, 26));

      // (4) Brand Voice & Colour Direction (Mid Right)
      final box4R = ui.Rect.fromLTWH(contentX + colW + 12, box34Top, colW, box34H);
      drawCard(g, box4R);
      g.drawString('4  BRAND VOICE & COLOUR DIRECTION', h3Font, brush: PdfSolidBrush(accentLime), bounds: ui.Rect.fromLTWH(box4R.left + 12, box34Top + 10, colW - 24, 16));

      // Left sub-column: Tone of Voice
      final toneW = colW - 84;
      g.drawString('TONE OF VOICE:', captionFont, brush: PdfSolidBrush(textMuted), bounds: ui.Rect.fromLTWH(box4R.left + 12, box34Top + 28, toneW, 12));
      g.drawString('• Friendly: Approachable & welcoming\n• Informative: Helping customers decide\n• Aspirational: Inspiring customer dreams\n• Trustworthy: Track record & safety', captionFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(box4R.left + 12, box34Top + 42, toneW, 56));

      // Right sub-column: Palette Swatches
      final paletteX = box4R.left + colW - 74;
      g.drawString('PALETTE:', captionFont, brush: PdfSolidBrush(textMuted), bounds: ui.Rect.fromLTWH(paletteX, box34Top + 28, 70, 12));
      double px = paletteX;
      final pal = proposal.brandPaletteHex.take(3).toList();
      for (final c in pal) {
        final cl = c.replaceAll('#', '');
        final r = int.tryParse(cl.substring(0, 2), radix: 16) ?? 16;
        final gr = int.tryParse(cl.substring(2, 4), radix: 16) ?? 185;
        final b = int.tryParse(cl.substring(4, 6), radix: 16) ?? 129;
        g.drawRectangle(brush: PdfSolidBrush(PdfColor(r, gr, b)), bounds: ui.Rect.fromLTWH(px, box34Top + 44, 20, 20));
        px += 23;
      }

      // (5) Instagram Feed Preview Strip
      const box5R = ui.Rect.fromLTWH(contentX, 396, contentWidth, 46);
      drawCard(g, box5R);
      g.drawString('5  SAMPLE INSTAGRAM FEED PREVIEW', captionFont, brush: PdfSolidBrush(accentLime), bounds: const ui.Rect.fromLTWH(contentX + 12, 401, 250, 12));
      final feedItems = ['Experience Story', 'Educational', 'Celebration', 'Corporate', 'Testimonial', 'Destination', 'Educational', 'Experience', 'Promotional'];
      double ix = contentX + 10;
      const iw = (contentWidth - 20) / 9;
      for (final item in feedItems) {
        g.drawRectangle(brush: PdfSolidBrush(PdfColor(25, 34, 34)), bounds: ui.Rect.fromLTWH(ix, 417, iw - 4, 20));
        g.drawString(item, PdfStandardFont(PdfFontFamily.helvetica, 6.5), brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(ix, 422, iw - 4, 12), format: PdfStringFormat(alignment: PdfTextAlignment.center));
        ix += iw;
      }

      // (6) Monthly Content Framework (4 Weeks Table with Expanded Heights)
      const fwTop = 450.0;
      g.drawString('EXAMPLE MONTHLY CONTENT FRAMEWORK (4 WEEKS)', h3Font, brush: PdfSolidBrush(accentLime), bounds: const ui.Rect.fromLTWH(contentX, fwTop, contentWidth, 16));

      final tableHeaders = ['WEEK', 'EXPERIENCE STORIES', 'EDUCATIONAL', 'CORPORATE', 'TESTIMONIALS', 'PROMOTIONAL', 'EXAMPLES'];
      final colWidths = [44.0, 80.0, 76.0, 76.0, 76.0, 76.0, 82.0];

      // Table Header Row
      double thx = contentX;
      for (int i = 0; i < tableHeaders.length; i++) {
        final w = colWidths[i];
        g.drawRectangle(brush: PdfSolidBrush(PdfColor(15, 28, 30)), pen: PdfPen(cardBorder, width: 0.5), bounds: ui.Rect.fromLTWH(thx, fwTop + 18, w, 18));
        g.drawString(tableHeaders[i], PdfStandardFont(PdfFontFamily.helvetica, 6.5, style: PdfFontStyle.bold), brush: PdfSolidBrush(accentLime), bounds: ui.Rect.fromLTWH(thx + 2, fwTop + 22, w - 4, 12), format: PdfStringFormat(alignment: PdfTextAlignment.center));
        thx += w;
      }

      // Table Data Rows (4 Weeks with Generous 66pt Row Clearance)
      double rowY = fwTop + 36;
      final weeks = proposal.contentFrameworkWeeks.isNotEmpty
          ? proposal.contentFrameworkWeeks
          : [
              {'week': 'WEEK 1', 'experienceStories': 'Birthday Celebration', 'educational': 'Charter Checklist', 'corporate': 'Team Bonding', 'testimonials': 'Team Testimonial', 'promotional': 'Weekend Special', 'contentExamples': 'Sunset dinner'},
              {'week': 'WEEK 2', 'experienceStories': 'Proposal Moments', 'educational': 'Etiquette 101', 'corporate': 'Client Appreciation', 'testimonials': 'Client Review', 'promotional': 'Mid-Week Offer', 'contentExamples': 'Proposal setup'},
              {'week': 'WEEK 3', 'experienceStories': 'Family Fun Day', 'educational': 'Best Times Guide', 'corporate': 'Leadership Retreat', 'testimonials': 'Family Story', 'promotional': 'Holiday Package', 'contentExamples': 'Family activities'},
              {'week': 'WEEK 4', 'experienceStories': 'Anniversary Cruise', 'educational': 'Weather FAQ', 'corporate': 'Networking Event', 'testimonials': 'Review Recap', 'promotional': 'Monthly Offer', 'contentExamples': 'Anniversary post'},
            ];

      for (final w in weeks.take(4)) {
        double cellX = contentX;
        final cells = [
          w['week'] as String? ?? 'WEEK',
          w['experienceStories'] as String? ?? '',
          w['educational'] as String? ?? '',
          w['corporate'] as String? ?? '',
          w['testimonials'] as String? ?? '',
          w['promotional'] as String? ?? '',
          w['contentExamples'] as String? ?? '',
        ];

        for (int i = 0; i < cells.length; i++) {
          final cw = colWidths[i];
          g.drawRectangle(brush: PdfSolidBrush(PdfColor(16, 22, 24)), pen: PdfPen(cardBorder, width: 0.5), bounds: ui.Rect.fromLTWH(cellX, rowY, cw, 66));
          if (i == 0) {
            // Pill badge for WEEK
            final weekPillR = ui.Rect.fromLTWH(cellX + 4, rowY + 22, cw - 8, 20);
            drawPill(g, weekPillR, bgColor: PdfColor(14, 32, 24), borderColor: accentLime, borderWidth: 0.5);
            g.drawString(
              cells[i],
              PdfStandardFont(PdfFontFamily.helvetica, 7, style: PdfFontStyle.bold),
              brush: PdfSolidBrush(accentLime),
              bounds: weekPillR,
              format: PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle),
            );
          } else {
            g.drawString(
              cells[i],
              PdfStandardFont(PdfFontFamily.helvetica, 6.2),
              brush: PdfSolidBrush(textOffWhite),
              bounds: ui.Rect.fromLTWH(cellX + 4, rowY + 5, cw - 8, 56),
            );
          }
          cellX += cw;
        }
        rowY += 66;
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PAGE 9: Sample Reel (Matching Reference Deck)
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      drawDarkBase(page);

      drawSectionTitle(g, 'Sample Reel', 42);

      // 9:16 Vertical Phone Poster Mockup
      const phoneW = 240.0;
      const phoneH = 470.0;
      final phoneX = (pageWidth - phoneW) / 2;
      const phoneY = 100.0;

      // Phone Outer Body
      g.drawRectangle(
        brush: PdfSolidBrush(PdfColor(12, 18, 20)),
        pen: PdfPen(accentLime, width: 1.5),
        bounds: ui.Rect.fromLTWH(phoneX, phoneY, phoneW, phoneH),
      );

      final innerPhoneRect = ui.Rect.fromLTWH(phoneX + 4, phoneY + 4, phoneW - 8, phoneH - 8);

      if (reelImageBytes != null) {
        try {
          // Render uploaded or AI-generated image directly into the 9:16 phone mockup!
          g.drawImage(PdfBitmap(reelImageBytes), innerPhoneRect);

          // Blend company logo watermark at the top of the vertical reel
          if (companyLogoBytes != null) {
            const logoW = 32.0;
            const logoH = 20.0;
            final logoX = phoneX + (phoneW - logoW) / 2.0;
            const logoY = phoneY + 16.0;
            drawPill(g, ui.Rect.fromLTWH(logoX - 3, logoY - 2, logoW + 6, logoH + 4), bgColor: PdfColor(0, 0, 0, 190), borderColor: PdfColor(255, 255, 255, 120), borderWidth: 0.5);
            g.drawImage(PdfBitmap(companyLogoBytes), ui.Rect.fromLTWH(logoX, logoY, logoW, logoH));
          }

          // Subtle dark vignette gradient overlay at bottom so overlay text is 100% legible
          g.drawRectangle(
            brush: PdfSolidBrush(PdfColor(0, 0, 0, 175)),
            bounds: ui.Rect.fromLTWH(phoneX + 4, phoneY + phoneH - 145, phoneW - 8, 141),
          );
        } catch (_) {
          g.drawRectangle(
            brush: PdfSolidBrush(PdfColor(15, 34, 45)),
            bounds: innerPhoneRect,
          );
        }
      } else {
        // Gradient / Atmospheric Backdrop inside phone if no image uploaded
        g.drawRectangle(
          brush: PdfSolidBrush(PdfColor(15, 34, 45)),
          bounds: innerPhoneRect,
        );
      }

      // Hero Headline Overlay (e.g. "Scale Across Asia")
      final headline = proposal.sampleReelHeadline.isNotEmpty ? proposal.sampleReelHeadline : 'Scale Across Asia';
      final headlineY = reelImageBytes != null ? (phoneY + phoneH - 130) : (phoneY + 160);
      g.drawString(
        headline,
        PdfStandardFont(PdfFontFamily.helvetica, reelImageBytes != null ? 18 : 22, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(textWhite),
        bounds: ui.Rect.fromLTWH(phoneX + 15, headlineY, phoneW - 30, 48),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );

      final topicY = reelImageBytes != null ? (headlineY + 40) : (phoneY + 245);
      g.drawString(
        proposal.sampleReelTopic.isNotEmpty ? proposal.sampleReelTopic : 'Enterprise Co-Innovation & Growth',
        captionFont,
        brush: PdfSolidBrush(accentLime),
        bounds: ui.Rect.fromLTWH(phoneX + 15, topicY, phoneW - 30, 30),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );

      // Bottom Clickable Button "View Reel Here"
      const btnW = 200.0;
      const btnH = 32.0;
      final btnX = (pageWidth - btnW) / 2.0;
      const btnY = 615.0;
      final btnRect = ui.Rect.fromLTWH(btnX, btnY, btnW, btnH);

      drawPill(g, btnRect, bgColor: PdfColor(14, 30, 24), borderColor: accentLime, borderWidth: 0.8);
      g.drawString(
        '▶   View Reel Here →',
        PdfStandardFont(PdfFontFamily.helvetica, 11, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: btnRect,
        format: PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle),
      );

      // Add interactive PDF hyperlink annotation without default black border!
      final reelUri = proposal.sampleReelLink.isNotEmpty ? proposal.sampleReelLink : 'https://meet-marketers.com/reels';
      final reelAnnotation = PdfUriAnnotation(bounds: btnRect, uri: reelUri);
      reelAnnotation.border = PdfAnnotationBorder(0);
      page.annotations.add(reelAnnotation);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PAGE 10: Sample Social Media Copywriting/Caption (Matching Reference Deck)
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      drawDarkBase(page);

      drawSectionTitle(g, 'Sample Social Media Copywriting/Caption', 40);

      // 3 Multi-Angle Social Media Post Cards
      final posts = proposal.socialPosts.isNotEmpty
          ? proposal.socialPosts
          : [
              {
                'headline': 'BUILT ON TRUST. DRIVEN BY MEASURABLE RESULTS.',
                'body': 'We do not believe in one-size-fits-all strategies.\n\nEvery initiative is tailored to your specific commercial objectives, backed by experienced specialists who take ownership of your growth.\n\nLearn more at our website.',
                'badge': 'VERIFIED EXCELLENCE',
                'hashtags': ['#BusinessGrowth', '#Strategy', '#Leadership'],
              },
              {
                'headline': 'WHAT SEPARATES MARKET BENCHMARKS FROM THE REST.',
                'body': 'From initial strategic alignment to flawless execution, our team provides the clarity and execution velocity required to capture category leadership.\n\nExplore our case studies and proven frameworks.',
                'badge': 'PROVEN IMPACT',
                'hashtags': ['#Transformation', '#Execution', '#Scale'],
              },
              {
                'headline': 'THE RIGHT STRATEGIC PARTNER MAKES ALL THE DIFFERENCE.',
                'body': 'Whether unlocking new market opportunities or accelerating high-stakes business initiatives, having the right team in your corner changes everything.\n\nConnect with our leadership team today.',
                'badge': 'STRATEGIC PARTNERSHIP',
                'hashtags': ['#StrategicPartner', '#Innovation', '#Excellence'],
              },
            ];

      // Post 1 (Top Left) & Post 2 (Top Right) - Symmetric Grid
      const postColW = (contentWidth - 12.0) / 2.0;
      final p1 = posts[0];
      const p1Rect = ui.Rect.fromLTWH(contentX, 85, postColW, 310);
      drawCard(g, p1Rect);

      double p1ContentY = 95;
      if (post1ImageBytes != null) {
        try {
          final imgRect = ui.Rect.fromLTWH(contentX + 10, 93, postColW - 20, 95);
          g.drawImage(PdfBitmap(post1ImageBytes), imgRect);
          p1ContentY = 196;
        } catch (_) {}
      }

      final p1HeadlineH = post1ImageBytes != null ? 24.0 : 36.0;
      final p1BodyH = post1ImageBytes != null ? 85.0 : 190.0;
      g.drawString(p1['headline'] as String? ?? '', post1ImageBytes != null ? captionFont : h3Font, brush: PdfSolidBrush(accentLime), bounds: ui.Rect.fromLTWH(contentX + 12, p1ContentY, postColW - 24, p1HeadlineH));
      g.drawString(p1['body'] as String? ?? '', captionFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + 12, p1ContentY + p1HeadlineH + 4, postColW - 24, p1BodyH));
      g.drawString(p1['badge'] as String? ?? '', captionFont, brush: PdfSolidBrush(accentLime), bounds: ui.Rect.fromLTWH(contentX + 12, 345, postColW - 24, 14));
      final hts1 = (p1['hashtags'] as List?)?.join(' ') ?? '';
      g.drawString(hts1, captionFont, brush: PdfSolidBrush(textMuted), bounds: ui.Rect.fromLTWH(contentX + 12, 362, postColW - 24, 24));

      // Post 2 (Top Right)
      final p2 = posts.length > 1 ? posts[1] : posts[0];
      final p2Rect = ui.Rect.fromLTWH(contentX + postColW + 12, 85, postColW, 310);
      drawCard(g, p2Rect);

      double p2ContentY = 95;
      if (post2ImageBytes != null) {
        try {
          final imgRect = ui.Rect.fromLTWH(p2Rect.left + 10, 93, postColW - 20, 95);
          g.drawImage(PdfBitmap(post2ImageBytes), imgRect);
          p2ContentY = 196;
        } catch (_) {}
      }

      final p2HeadlineH = post2ImageBytes != null ? 24.0 : 30.0;
      final p2BodyH = post2ImageBytes != null ? 85.0 : 190.0;
      g.drawString(p2['headline'] as String? ?? '', post2ImageBytes != null ? captionFont : h3Font, brush: PdfSolidBrush(accentLime), bounds: ui.Rect.fromLTWH(p2Rect.left + 12, p2ContentY, postColW - 24, p2HeadlineH));
      g.drawString(p2['body'] as String? ?? '', captionFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(p2Rect.left + 12, p2ContentY + p2HeadlineH + 4, postColW - 24, p2BodyH));
      g.drawString(p2['badge'] as String? ?? '', captionFont, brush: PdfSolidBrush(accentLime), bounds: ui.Rect.fromLTWH(p2Rect.left + 12, 345, postColW - 24, 14));
      final hts2 = (p2['hashtags'] as List?)?.join(' ') ?? '';
      g.drawString(hts2, captionFont, brush: PdfSolidBrush(textMuted), bounds: ui.Rect.fromLTWH(p2Rect.left + 12, 362, postColW - 24, 24));

      // Post 3 (Bottom Centered Card)
      final p3 = posts.length > 2 ? posts[2] : posts[0];
      const p3Rect = ui.Rect.fromLTWH(contentX, 410, contentWidth, 310);
      drawCard(g, p3Rect);

      double p3TextX = contentX + 20;
      double p3TextW = contentWidth - 40;

      if (post3ImageBytes != null) {
        try {
          const imgRect = ui.Rect.fromLTWH(contentX + 16, 424, 180, 280);
          g.drawImage(PdfBitmap(post3ImageBytes), imgRect);
          p3TextX = contentX + 210;
          p3TextW = contentWidth - 225;
        } catch (_) {}
      }

      g.drawString('“${p3['headline']}”', h2Font, brush: PdfSolidBrush(accentLime), bounds: ui.Rect.fromLTWH(p3TextX, 424, p3TextW, 36));
      g.drawString(p3['body'] as String? ?? '', bodyFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(p3TextX, 468, p3TextW, post3ImageBytes != null ? 150 : 170));
      g.drawString(p3['badge'] as String? ?? '', h3Font, brush: PdfSolidBrush(accentLime), bounds: ui.Rect.fromLTWH(p3TextX, 635, p3TextW, 18));
      final hts3 = (p3['hashtags'] as List?)?.join(' ') ?? '';
      g.drawString(hts3, captionFont, brush: PdfSolidBrush(textMuted), bounds: ui.Rect.fromLTWH(p3TextX, 660, p3TextW, 40));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PAGE 11: Sample SEO Pillar Blog Article
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      drawDarkBase(page);

      drawSectionTitle(g, 'Sample Copywriting: SEO Pillar Blog', 45);

      const cardR = ui.Rect.fromLTWH(contentX, 95, contentWidth, 650);
      drawCard(g, cardR);

      double by = 125;
      g.drawString('Suggested Article Title', h3Font, brush: PdfSolidBrush(textWhite), bounds: const ui.Rect.fromLTWH(contentX + 24, 125, contentWidth - 48, 16));
      by += 20;
      g.drawString(
        proposal.sampleBlogTitle.isNotEmpty ? proposal.sampleBlogTitle : 'How to Plan an Unforgettable Milestone Celebration (Without the Usual Stress)',
        h2Font,
        brush: PdfSolidBrush(accentLime),
        bounds: ui.Rect.fromLTWH(contentX + 24, by, contentWidth - 48, 45),
      );

      by += 55;
      g.drawString('Storytelling & Strategic Narrative Strategy', h3Font, brush: PdfSolidBrush(textWhite), bounds: ui.Rect.fromLTWH(contentX + 24, by, contentWidth - 48, 16));
      by += 20;
      g.drawString(
        proposal.sampleBlogStorytellingIntro.isNotEmpty
            ? proposal.sampleBlogStorytellingIntro
            : 'Rather than relying on promotional sales messaging, our content approach focuses on storytelling and customer-centric narratives that help audiences visualize the experience before they book.',
        bodyFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: ui.Rect.fromLTWH(contentX + 24, by, contentWidth - 48, 70),
      );

      by += 85;
      g.drawString('Article Preview Excerpt', h3Font, brush: PdfSolidBrush(textWhite), bounds: ui.Rect.fromLTWH(contentX + 24, by, contentWidth - 48, 16));
      by += 20;
      final previewText = proposal.sampleBlogPreview.isNotEmpty
          ? proposal.sampleBlogPreview
          : 'When planning a major celebration, most organizers are forced to choose between crowded public venues or sterile hotel banquet rooms. But true luxury is about privacy, personalized attention, and memories that last long after the evening ends...\n\nIn this comprehensive guide, we unpack everything from selecting the right package to food and beverage coordination, music, and capturing memories on camera.';
      g.drawString(
        previewText,
        bodyFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: ui.Rect.fromLTWH(contentX + 24, by, contentWidth - 48, 250),
      );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PAGE 12: SEO & Digital Presence Opportunities (Luxury Agency Audit Format)
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      drawDarkBase(page);

      drawSectionTitle(g, 'SEO & Digital Presence Opportunities', 38);

      // Dedicated SEO Health Score Card (Top)
      const scoreCardR = ui.Rect.fromLTWH(contentX, 68, contentWidth, 72);
      drawPill(g, scoreCardR, bgColor: PdfColor(14, 25, 30), borderColor: accentLime, borderWidth: 0.8);

      // Giant Score with perfect baseline alignment
      g.drawString(
        '${proposal.seoAudit.healthScore}',
        PdfStandardFont(PdfFontFamily.helvetica, 36, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: const ui.Rect.fromLTWH(contentX + 18, 78, 54, 46),
      );
      g.drawString(
        '/ 100',
        PdfStandardFont(PdfFontFamily.helvetica, 11, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(textMuted),
        bounds: const ui.Rect.fromLTWH(contentX + 74, 96, 45, 18),
      );

      // Audit status badge & quick-checks on right
      const statusPillR = ui.Rect.fromLTWH(contentX + 130, 78, 280, 20);
      drawPill(g, statusPillR, bgColor: PdfColor(14, 32, 24), borderColor: accentLime, borderWidth: 0.6);
      g.drawString(
        'CURRENT SEO HEALTH: STRONG DIGITAL FOUNDATION',
        PdfStandardFont(PdfFontFamily.helvetica, 7.5, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: statusPillR,
        format: PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle),
      );
      g.drawString(
        '✓ HTTPS Encrypted   ·   ✓ Mobile Responsive   ·   ⚡ Schema & Entity Optimization Needed',
        captionFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: const ui.Rect.fromLTWH(contentX + 130, 104, contentWidth - 146, 16),
      );

      // Summary narrative
      g.drawString(
        proposal.seoAudit.summaryText.isNotEmpty
            ? proposal.seoAudit.summaryText
            : '${proposal.leadCompanyName} has established a solid SEO foundation, with HTTPS security, mobile responsiveness, optimised WebP images, canonical tags and an active content strategy already in place. However, several high-impact technical and content opportunities remain that could significantly improve search visibility and lead generation.',
        bodyFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: const ui.Rect.fromLTWH(contentX, 148, contentWidth, 52),
      );

      // Card 1: High Priority (Rounded Dark Card with Coral Pill)
      const highR = ui.Rect.fromLTWH(contentX, 208, contentWidth, 126);
      drawCard(g, highR);
      drawPill(g, ui.Rect.fromLTWH(contentX + 16, 218, 100, 20), bgColor: PdfColor(36, 18, 20), borderColor: PdfColor(248, 113, 113), borderWidth: 0.6);
      g.drawString(
        'HIGH PRIORITY',
        PdfStandardFont(PdfFontFamily.helvetica, 7.5, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(PdfColor(248, 113, 113)),
        bounds: ui.Rect.fromLTWH(contentX + 16, 218, 100, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle),
      );

      final highs = proposal.seoAudit.highPriority.isNotEmpty
          ? proposal.seoAudit.highPriority
          : ['Occasion-specific landing pages (Milestones, Corporate, Intimate)', 'Structured data review & schema.org organization markup', 'H1 and Meta Title optimization across core pages', 'Core Web Vitals & WebP image compression'];
      double hy = 246;
      for (final h in highs.take(4)) {
        g.drawString('•  $h', bodyFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + 18, hy, contentWidth - 36, 18));
        hy += 20;
      }

      // Card 2: Medium Priority (Rounded Dark Card with Purple Pill)
      const medR = ui.Rect.fromLTWH(contentX, 344, contentWidth, 118);
      drawCard(g, medR);
      drawPill(g, ui.Rect.fromLTWH(contentX + 16, 354, 115, 20), bgColor: PdfColor(28, 18, 38), borderColor: PdfColor(192, 132, 252), borderWidth: 0.6);
      g.drawString(
        'MEDIUM PRIORITY',
        PdfStandardFont(PdfFontFamily.helvetica, 7.5, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(PdfColor(192, 132, 252)),
        bounds: ui.Rect.fromLTWH(contentX + 16, 354, 115, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle),
      );

      final meds = proposal.seoAudit.mediumPriority.isNotEmpty
          ? proposal.seoAudit.mediumPriority
          : ['Service detail page conversion and schema optimization', 'Open Graph rich social sharing cards', 'Author and thought leadership entity markup'];
      double my = 382;
      for (final m in meds.take(3)) {
        g.drawString('•  $m', bodyFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + 18, my, contentWidth - 36, 18));
        my += 22;
      }

      // Card 3: Long-Term Opportunities (Rounded Dark Card with Lime Pill)
      const longR = ui.Rect.fromLTWH(contentX, 472, contentWidth, 118);
      drawCard(g, longR);
      drawPill(g, ui.Rect.fromLTWH(contentX + 16, 482, 175, 20), bgColor: PdfColor(14, 30, 22), borderColor: accentLime, borderWidth: 0.6);
      g.drawString(
        'LONG-TERM OPPORTUNITIES',
        PdfStandardFont(PdfFontFamily.helvetica, 7.5, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: ui.Rect.fromLTWH(contentX + 16, 482, 175, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle),
      );

      final longs = proposal.seoAudit.longTermOpportunities.isNotEmpty
          ? proposal.seoAudit.longTermOpportunities
          : ['AI search engine discoverability (AIO & Perplexity optimization)', 'Comprehensive educational content ecosystem & resource center', 'Dedicated corporate partner portal & inquiry flow'];
      double ly = 510;
      for (final l in longs.take(3)) {
        g.drawString('•  $l', bodyFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + 18, ly, contentWidth - 36, 18));
        ly += 22;
      }

      // Bottom Button: View Full SEO/AIO Audit Here (Borderless Link Pill)
      const auditBtnW = 320.0;
      const auditBtnH = 36.0;
      final auditBtnX = (pageWidth - auditBtnW) / 2.0;
      const auditBtnY = 606.0;
      final auditBtnR = ui.Rect.fromLTWH(auditBtnX, auditBtnY, auditBtnW, auditBtnH);

      drawPill(g, auditBtnR, bgColor: PdfColor(14, 32, 24), borderColor: accentLime, borderWidth: 0.8);
      g.drawString(
        '▶   View Full SEO / AIO Audit Here →',
        PdfStandardFont(PdfFontFamily.helvetica, 10.5, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: auditBtnR,
        format: PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle),
      );

      final auditUri = proposal.seoAuditLink.isNotEmpty ? proposal.seoAuditLink : 'https://meet-marketers.com/seo-audit';
      final auditAnnotation = PdfUriAnnotation(bounds: auditBtnR, uri: auditUri);
      auditAnnotation.border = PdfAnnotationBorder(0);
      page.annotations.add(auditAnnotation);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PAGE 13: Our Assessment On SEO Audit & Final Thoughts (Matching Image 5)
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      drawDarkBase(page);

      drawSectionTitle(g, 'Our Assessment On SEO Audit', 45);

      // Assessment narrative paragraph
      final assessmentText = proposal.seoAssessmentText.isNotEmpty
          ? proposal.seoAssessmentText
          : 'Based on our review, we recommend prioritising technical SEO improvements and occasion-specific landing pages as the first phase of optimisation. These initiatives are likely to deliver the greatest impact on search visibility, user experience and lead generation while building upon ${proposal.leadCompanyName}\'s existing content and brand reputation.';
      g.drawString(
        assessmentText,
        bodyFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: const ui.Rect.fromLTWH(contentX, 90, contentWidth, 90),
      );

      // Solid Lime-Green Final Thoughts Container (Matching Image 5)
      const greenCardR = ui.Rect.fromLTWH(contentX, 205, contentWidth, 360);
      g.drawRectangle(
        brush: PdfSolidBrush(accentLime),
        bounds: greenCardR,
      );

      // Title: Final Thoughts in Bold Black Font
      g.drawString(
        'Final Thoughts',
        PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(textBlack),
        bounds: const ui.Rect.fromLTWH(contentX + 28, 235, contentWidth - 56, 26),
      );

      // Final Thoughts Paragraphs in Black Font
      final p1 = proposal.finalThoughtsSummary.isNotEmpty
          ? proposal.finalThoughtsSummary
          : '${proposal.leadCompanyName} already possesses many of the qualities today’s customers seek — memorable experiences, professional service, trusted crews and a proven track record. Our proposed direction focuses on strengthening visibility, authority and differentiation through strategic content, authentic storytelling and a more cohesive digital presence.';
      g.drawString(
        p1,
        bodyFont,
        brush: PdfSolidBrush(textBlack),
        bounds: const ui.Rect.fromLTWH(contentX + 28, 275, contentWidth - 56, 110),
      );

      final p2 = proposal.finalThoughtsRecommendation.isNotEmpty
          ? proposal.finalThoughtsRecommendation
          : 'By aligning social media, SEO and content marketing under one unified strategy, ${proposal.leadCompanyName} can strengthen brand awareness, improve discoverability and position itself as one of the most trusted brands in its category.';
      g.drawString(
        p2,
        bodyFont,
        brush: PdfSolidBrush(textBlack),
        bounds: const ui.Rect.fromLTWH(contentX + 28, 400, contentWidth - 56, 120),
      );
    }

    final List<int> bytes = await document.save();
    document.dispose();
    return bytes;
  }

  /// Downloads the compiled proposal PDF in the web browser
  Future<void> exportAndDownloadPdf(ProposalModel proposal) async {
    final bytes = await generateProposalPdf(proposal);
    final cleanName = proposal.leadCompanyName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final fileName = 'Meet_Marketers_Proposal_$cleanName.pdf';
    downloadWebBytes(bytes, fileName);
  }
}
