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
          // Draw the real MM transparent logo with crisp 4:3 proportions
          g.drawImage(
            PdfBitmap(logoBytes),
            ui.Rect.fromLTWH(x, y - 4, 30, 22.5),
          );
        } catch (_) {
          // Logo asset is invalid — skip image, still draw text fallback below
        }
        g.drawString(
          'MEET',
          PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
          brush: PdfSolidBrush(textWhite),
          bounds: ui.Rect.fromLTWH(x + 36, y, 42, 16),
        );
        g.drawString(
          'MARKETERS',
          PdfStandardFont(PdfFontFamily.helvetica, 12),
          brush: PdfSolidBrush(textOffWhite),
          bounds: ui.Rect.fromLTWH(x + 78, y, 100, 16),
        );
      } else {
        // Stylized vector MM icon fallback
        final logoPen = PdfPen(PdfColor(170, 180, 185), width: 2.5);
        g.drawLine(logoPen, ui.Offset(x, y + 14), ui.Offset(x + 5, y));
        g.drawLine(logoPen, ui.Offset(x + 5, y), ui.Offset(x + 10, y + 9));
        g.drawLine(logoPen, ui.Offset(x + 10, y + 9), ui.Offset(x + 15, y));
        g.drawLine(logoPen, ui.Offset(x + 15, y), ui.Offset(x + 20, y + 14));

        final logoPen2 = PdfPen(accentLime, width: 2.5);
        g.drawLine(logoPen2, ui.Offset(x + 12, y + 14), ui.Offset(x + 17, y));
        g.drawLine(logoPen2, ui.Offset(x + 17, y), ui.Offset(x + 22, y + 9));
        g.drawLine(logoPen2, ui.Offset(x + 22, y + 9), ui.Offset(x + 27, y));
        g.drawLine(logoPen2, ui.Offset(x + 27, y), ui.Offset(x + 32, y + 14));

        g.drawString(
          'MEET',
          PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
          brush: PdfSolidBrush(textWhite),
          bounds: ui.Rect.fromLTWH(x + 40, y, 42, 16),
        );
        g.drawString(
          'MARKETERS',
          PdfStandardFont(PdfFontFamily.helvetica, 12),
          brush: PdfSolidBrush(textOffWhite),
          bounds: ui.Rect.fromLTWH(x + 82, y, 100, 16),
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

    // ── Helper: Draw True Smooth Rounded Dark Card ───────────────
    void drawCard(
      PdfGraphics g,
      ui.Rect rect, {
      double radius = 16.0,
      PdfColor? bgColor,
      PdfColor? borderColor,
      double borderWidth = 1.0,
    }) {
      final r = radius.clamp(0.0, rect.height / 2.0).clamp(0.0, rect.width / 2.0);
      if (r <= 0) {
        g.drawRectangle(
          brush: PdfSolidBrush(bgColor ?? bgCard),
          pen: borderColor != null ? PdfPen(borderColor, width: borderWidth) : PdfPen(cardBorder, width: borderWidth),
          bounds: rect,
        );
        return;
      }
      final path = PdfPath();
      final d = r * 2.0;
      path.addArc(ui.Rect.fromLTWH(rect.left, rect.top, d, d), 180, 90);
      path.addLine(ui.Offset(rect.left + r, rect.top), ui.Offset(rect.right - r, rect.top));
      path.addArc(ui.Rect.fromLTWH(rect.right - d, rect.top, d, d), 270, 90);
      path.addLine(ui.Offset(rect.right, rect.top + r), ui.Offset(rect.right, rect.bottom - r));
      path.addArc(ui.Rect.fromLTWH(rect.right - d, rect.bottom - d, d, d), 0, 90);
      path.addLine(ui.Offset(rect.right - r, rect.bottom), ui.Offset(rect.left + r, rect.bottom));
      path.addArc(ui.Rect.fromLTWH(rect.left, rect.bottom - d, d, d), 90, 90);
      path.closeFigure();

      g.drawPath(
        path,
        brush: PdfSolidBrush(bgColor ?? bgCard),
        pen: borderColor != null ? PdfPen(borderColor, width: borderWidth) : PdfPen(cardBorder, width: borderWidth),
      );
    }

    // ── Helper: Draw Styled Rounded Pill / Tag ────────────────────
    void drawPill(
      PdfGraphics g,
      ui.Rect rect, {
      PdfColor? bgColor,
      PdfColor? borderColor,
      double borderWidth = 0.8,
      double radius = 6.0,
    }) {
      drawCard(
        g,
        rect,
        radius: radius,
        bgColor: bgColor ?? PdfColor(14, 28, 22),
        borderColor: borderColor,
        borderWidth: borderWidth,
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
    // PAGE 1: Cover Page & Table of Contents (Matching Sample Image 3 Exactly)
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      drawDarkBase(page);

      // Top Header: Meet Marketers Logo
      drawMeetMarketersLogo(g, contentX, 100);

      // Main Hero Title: Both lines in vibrant Lime Green (#A3E635)
      const titleY = 320.0;
      final heroTitleFont = PdfStandardFont(PdfFontFamily.helvetica, 34, style: PdfFontStyle.bold);
      g.drawString(
        'Digital & Content',
        heroTitleFont,
        brush: PdfSolidBrush(accentLime),
        bounds: const ui.Rect.fromLTWH(contentX, titleY, contentWidth, 42),
      );
      g.drawString(
        'Direction Proposal',
        heroTitleFont,
        brush: PdfSolidBrush(accentLime),
        bounds: const ui.Rect.fromLTWH(contentX, titleY + 44, contentWidth, 42),
      );

      // Subtitle: Prepared for [Lead Company Name]
      const subY = titleY + 105.0;
      g.drawString(
        'Prepared for ${proposal.leadCompanyName}',
        PdfStandardFont(PdfFontFamily.helvetica, 14),
        brush: PdfSolidBrush(textOffWhite),
        bounds: const ui.Rect.fromLTWH(contentX, subY, contentWidth, 22),
      );

      // CONTENTS Section Heading
      const tocHeaderY = subY + 48.0;
      g.drawString(
        'CONTENTS',
        PdfStandardFont(PdfFontFamily.helvetica, 11, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: const ui.Rect.fromLTWH(contentX, tocHeaderY, contentWidth, 18),
      );

      // Category 1: Marketing Strategy
      const stratY = tocHeaderY + 24.0;
      g.drawString(
        'Marketing Strategy',
        PdfStandardFont(PdfFontFamily.helvetica, 10.5, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: const ui.Rect.fromLTWH(contentX, stratY, contentWidth, 16),
      );

      final strategyBullets = [
        'Executive Summary',
        'SWOT Analysis',
        'Marketing Mix (4Ps Analysis)',
        'PEST Analysis',
        'USP Analysis',
        'Perceptual Map',
      ];
      final tocFont = PdfStandardFont(PdfFontFamily.helvetica, 9.5);
      double sy = stratY + 18.0;
      for (final bullet in strategyBullets) {
        g.drawString(
          '•   $bullet',
          tocFont,
          brush: PdfSolidBrush(textOffWhite),
          bounds: ui.Rect.fromLTWH(contentX + 8, sy, contentWidth - 16, 14),
        );
        sy += 16.0;
      }

      // Category 2: Marketing Operation
      final operY = sy + 8.0;
      g.drawString(
        'Marketing Operation',
        PdfStandardFont(PdfFontFamily.helvetica, 10.5, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: ui.Rect.fromLTWH(contentX, operY, contentWidth, 16),
      );

      final operationBullets = [
        'Creative Direction',
        'Visual Guideline',
        'Content Framework',
        'Sample Reel',
        'Sample Blog',
        'SEO Audit & Recommendation',
        'Conclusion',
      ];
      double oy = operY + 18.0;
      for (final bullet in operationBullets) {
        g.drawString(
          '•   $bullet',
          tocFont,
          brush: PdfSolidBrush(textOffWhite),
          bounds: ui.Rect.fromLTWH(contentX + 8, oy, contentWidth - 16, 14),
        );
        oy += 16.0;
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PAGE 2: Current Position, Opportunity & SWOT Analysis
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      drawDarkBase(page);
      // Top Center Client Brand Logo (Centered horizontally as in Image 4)
      if (companyLogoBytes != null) {
        try {
          const logoW = 140.0;
          const logoH = 55.0;
          final logoRect = ui.Rect.fromLTWH((pageWidth - logoW) / 2.0, 36, logoW, logoH);
          g.drawImage(PdfBitmap(companyLogoBytes), logoRect);
        } catch (_) {
          g.drawString(
            proposal.leadCompanyName.toUpperCase(),
            PdfStandardFont(PdfFontFamily.helvetica, 15, style: PdfFontStyle.bold),
            brush: PdfSolidBrush(accentLime),
            bounds: const ui.Rect.fromLTWH(0, 48, pageWidth, 22),
            format: PdfStringFormat(alignment: PdfTextAlignment.center),
          );
        }
      } else {
        g.drawString(
          proposal.leadCompanyName.toUpperCase(),
          PdfStandardFont(PdfFontFamily.helvetica, 15, style: PdfFontStyle.bold),
          brush: PdfSolidBrush(accentLime),
          bounds: const ui.Rect.fromLTWH(0, 48, pageWidth, 22),
          format: PdfStringFormat(alignment: PdfTextAlignment.center),
        );
      }

      // Single Large Rounded Card: Current Position & Opportunity (Matching Image 4)
      const cardTop = 104.0;
      const cardHeight = 224.0;
      final posCardRect = const ui.Rect.fromLTWH(contentX, cardTop, contentWidth, cardHeight);
      drawCard(g, posCardRect, radius: 18);

      // Inside Card: Current Position Heading & Text
      g.drawString(
        'Current Position',
        PdfStandardFont(PdfFontFamily.helvetica, 13.5, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(textWhite),
        bounds: const ui.Rect.fromLTWH(contentX + 24, cardTop + 20, contentWidth - 48, 18),
      );

      final posText = proposal.executiveSummaryPosition.isNotEmpty
          ? proposal.executiveSummaryPosition
          : '${proposal.leadCompanyName} has established itself as one of Singapore\'s trusted leaders in ${proposal.industry}, delivering proven value, professional service standards, and verified client satisfaction across its customer base.';
      g.drawString(
        posText,
        PdfStandardFont(PdfFontFamily.helvetica, 9.5),
        brush: PdfSolidBrush(textOffWhite),
        bounds: const ui.Rect.fromLTWH(contentX + 24, cardTop + 44, contentWidth - 48, 62),
      );

      // Inside Card: Opportunity Heading & Text
      g.drawString(
        'Opportunity',
        PdfStandardFont(PdfFontFamily.helvetica, 13.5, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(textWhite),
        bounds: const ui.Rect.fromLTWH(contentX + 24, cardTop + 118, contentWidth - 48, 18),
      );

      final oppText = proposal.executiveSummaryOpportunity.isNotEmpty
          ? proposal.executiveSummaryOpportunity
          : 'While ${proposal.leadCompanyName} has built strong credibility and customer satisfaction, there is an opportunity to strengthen digital visibility, authority, and differentiation within an increasingly competitive market.';
      g.drawString(
        oppText,
        PdfStandardFont(PdfFontFamily.helvetica, 9.5),
        brush: PdfSolidBrush(textOffWhite),
        bounds: const ui.Rect.fromLTWH(contentX + 24, cardTop + 142, contentWidth - 48, 68),
      );

      // SWOT Analysis Section Title (Lime Green)
      drawSectionTitle(g, 'SWOT Analysis', 350);

      // 2x2 SWOT Matrix with Lime Green Header Bars & Dark Content Cells
      const swotTop = 384.0;
      const colW = (contentWidth - 12.0) / 2.0;
      const headerH = 24.0;
      const cellH = 168.0;

      // Row 1: Strength & Weaknesses
      drawTableHeader(g, 'Strength', const ui.Rect.fromLTWH(contentX, swotTop, colW, headerH));
      drawTableHeader(g, 'Weaknesses', const ui.Rect.fromLTWH(contentX + colW + 12, swotTop, colW, headerH));

      drawTableCell(g, const ui.Rect.fromLTWH(contentX, swotTop + headerH, colW, cellH));
      drawTableCell(g, const ui.Rect.fromLTWH(contentX + colW + 12, swotTop + headerH, colW, cellH));

      final swotFont = PdfStandardFont(PdfFontFamily.helvetica, 8.8);
      double ty = swotTop + headerH + 12;
      for (final s in proposal.swot.strengths.take(4)) {
        g.drawString('•  $s', swotFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + 12, ty, colW - 24, 36));
        ty += 37;
      }

      ty = swotTop + headerH + 12;
      for (final w in proposal.swot.weaknesses.take(4)) {
        g.drawString('•  $w', swotFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + colW + 24, ty, colW - 24, 36));
        ty += 37;
      }

      // Row 2: Opportunities & Threats
      const row2Top = swotTop + headerH + cellH + 12;
      drawTableHeader(g, 'Opportunities', const ui.Rect.fromLTWH(contentX, row2Top, colW, headerH));
      drawTableHeader(g, 'Threats', const ui.Rect.fromLTWH(contentX + colW + 12, row2Top, colW, headerH));

      drawTableCell(g, const ui.Rect.fromLTWH(contentX, row2Top + headerH, colW, cellH));
      drawTableCell(g, const ui.Rect.fromLTWH(contentX + colW + 12, row2Top + headerH, colW, cellH));

      ty = row2Top + headerH + 12;
      for (final o in proposal.swot.opportunities.take(4)) {
        g.drawString('•  $o', swotFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + 12, ty, colW - 24, 36));
        ty += 37;
      }

      ty = row2Top + headerH + 12;
      for (final t in proposal.swot.threats.take(4)) {
        g.drawString('•  $t', swotFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + colW + 24, ty, colW - 24, 36));
        ty += 37;
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
      final row2Top = pTop + headerH + cellH + 16;
      drawTableHeader(g, 'Place', ui.Rect.fromLTWH(contentX, row2Top, colWidth, headerH));
      drawTableHeader(g, 'Promotion', ui.Rect.fromLTWH(contentX + colWidth, row2Top, colWidth, headerH));

      drawTableCell(g, ui.Rect.fromLTWH(contentX, row2Top + headerH, colWidth, cellH));
      drawTableCell(g, ui.Rect.fromLTWH(contentX + colWidth, row2Top + headerH, colWidth, cellH));

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
    // ─────────────────────────────────────────────────────────────────────────
    // PAGE 9: Sample Reel (Matching Reference Deck)
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      drawDarkBase(page);

      drawSectionTitle(g, 'Sample Reel', 40);

      // Category / Format Subtitle Pill
      const pillR = ui.Rect.fromLTWH(contentX + contentWidth - 210, 40, 210, 22);
      drawPill(g, pillR, bgColor: PdfColor(14, 28, 24), borderColor: accentLime, borderWidth: 0.8);
      g.drawString(
        '9:16 VERTICAL VIDEO BLUEPRINT',
        PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: pillR,
        format: PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle),
      );

      // ── Dual-Column Layout: Left (9:16 Phone Mockup) + Right (Strategic Breakdown) ──
      const phoneW = 210.0;
      const phoneH = 425.0;
      const phoneX = contentX;
      const phoneY = 82.0;

      // Phone Outer Body (Sleek Bezel)
      g.drawRectangle(
        brush: PdfSolidBrush(PdfColor(10, 15, 17)),
        pen: PdfPen(accentLime, width: 1.2),
        bounds: const ui.Rect.fromLTWH(phoneX, phoneY, phoneW, phoneH),
      );

      final innerPhoneRect = ui.Rect.fromLTWH(phoneX + 3, phoneY + 3, phoneW - 6, phoneH - 6);

      if (reelImageBytes != null) {
        try {
          // Render visual poster inside the phone frame
          g.drawImage(PdfBitmap(reelImageBytes), innerPhoneRect);

          // Sleek official brand badge in top-left corner of the reel
          if (companyLogoBytes != null) {
            const logoW = 44.0;
            const logoH = 22.0;
            const logoX = phoneX + 10.0;
            const logoY = phoneY + 10.0;
            // Clean dark translucent glass pill container with soft padding
            drawPill(g, const ui.Rect.fromLTWH(logoX, logoY, logoW, logoH), bgColor: PdfColor(14, 22, 26, 210), borderColor: PdfColor(255, 255, 255, 70), borderWidth: 0.5);
            g.drawImage(PdfBitmap(companyLogoBytes), const ui.Rect.fromLTWH(logoX + 4, logoY + 3, logoW - 8, logoH - 6));
          }

          // Subtle dark gradient vignette at the bottom of the video for typography contrast
          g.drawRectangle(
            brush: PdfSolidBrush(PdfColor(0, 0, 0, 185)),
            bounds: ui.Rect.fromLTWH(phoneX + 3, phoneY + phoneH - 120, phoneW - 6, 117),
          );
        } catch (_) {
          g.drawRectangle(
            brush: PdfSolidBrush(PdfColor(15, 30, 38)),
            bounds: innerPhoneRect,
          );
        }
      } else {
        // Atmospheric dark backdrop inside phone if no media
        g.drawRectangle(
          brush: PdfSolidBrush(PdfColor(15, 30, 38)),
          bounds: innerPhoneRect,
        );
      }

      // True Vector Play Button (Eliminates font glyph dependency box)
      const playSize = 38.0;
      final playRect = ui.Rect.fromLTWH(phoneX + (phoneW - playSize) / 2, phoneY + (phoneH / 2) - 25, playSize, playSize);
      drawPill(g, playRect, bgColor: PdfColor(10, 16, 20, 220), borderColor: accentLime, borderWidth: 1.2);
      final pcx = playRect.left + playSize / 2;
      final pcy = playRect.top + playSize / 2;
      final p1 = ui.Offset(pcx - 4, pcy - 8);
      final p2 = ui.Offset(pcx - 4, pcy + 8);
      final p3 = ui.Offset(pcx + 7, pcy);
      g.drawPolygon([p1, p2, p3], brush: PdfSolidBrush(accentLime));

      // Hero Headline Overlay inside phone
      final headline = proposal.sampleReelHeadline.isNotEmpty ? proposal.sampleReelHeadline : 'Scale Across Asia';
      final headlineY = phoneY + phoneH - 105;
      g.drawString(
        headline,
        PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(textWhite),
        bounds: ui.Rect.fromLTWH(phoneX + 10, headlineY, phoneW - 20, 38),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );

      final topicY = headlineY + 40;
      final topicText = proposal.sampleReelTopic.isNotEmpty ? proposal.sampleReelTopic : 'Enterprise Innovation';
      g.drawString(
        topicText,
        captionFont,
        brush: PdfSolidBrush(accentLime),
        bounds: ui.Rect.fromLTWH(phoneX + 10, topicY, phoneW - 20, 24),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );

      // Clickable "View Reel Here" Button Below the Phone
      const btnH = 32.0;
      final btnRect = ui.Rect.fromLTWH(phoneX, phoneY + phoneH + 12, phoneW, btnH);
      drawPill(g, btnRect, bgColor: PdfColor(14, 30, 24), borderColor: accentLime, borderWidth: 0.8);
      g.drawString(
        'VIEW PRODUCTION REEL',
        PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: btnRect,
        format: PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle),
      );

      final reelUri = proposal.sampleReelLink.isNotEmpty ? proposal.sampleReelLink : 'https://meet-marketers.com/reels';
      final reelAnnotation = PdfUriAnnotation(bounds: btnRect, uri: reelUri);
      reelAnnotation.border = PdfAnnotationBorder(0);
      page.annotations.add(reelAnnotation);

      // ── Right Column: Strategic Production Breakdown (3 Structured Cards) ──
      const rightX = contentX + phoneW + 18.0;
      const rightW = contentWidth - phoneW - 18.0;

      // Card 1: The 3-Second Psychological Hook
      const c1Y = phoneY;
      const c1H = 100.0;
      final c1R = const ui.Rect.fromLTWH(rightX, c1Y, rightW, c1H);
      drawCard(g, c1R);

      const pill1 = ui.Rect.fromLTWH(rightX + 12, c1Y + 10, 160, 18);
      drawPill(g, pill1, bgColor: PdfColor(18, 38, 30), borderColor: accentLime, borderWidth: 0.6);
      g.drawString(
        '01 · THE 3-SECOND RETENTION HOOK',
        PdfStandardFont(PdfFontFamily.helvetica, 7, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: pill1,
        format: PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle),
      );

      final hookText = proposal.sampleReelHook.isNotEmpty
          ? '"${proposal.sampleReelHook.replaceAll(RegExp(r'([a-z])([A-Z])'), r'$1 $2')}"'
          : '"Stop losing students to generic tuition — here is how modular mastery changes results."';
      g.drawString(
        hookText,
        PdfStandardFont(PdfFontFamily.helvetica, 9, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(textWhite),
        bounds: ui.Rect.fromLTWH(rightX + 12, c1Y + 34, rightW - 24, 40),
      );
      g.drawString(
        'Goal: Interrupt passive scrolling within 3s using customer pain & curiosity gap.',
        captionFont,
        brush: PdfSolidBrush(textMuted),
        bounds: ui.Rect.fromLTWH(rightX + 12, c1Y + 76, rightW - 24, 14),
      );

      // Card 2: Visual Storyboard & Multi-Scene Script
      const c2Y = c1Y + c1H + 12.0;
      const c2H = 215.0;
      final c2R = const ui.Rect.fromLTWH(rightX, c2Y, rightW, c2H);
      drawCard(g, c2R);

      const pill2 = ui.Rect.fromLTWH(rightX + 12, c2Y + 10, 175, 18);
      drawPill(g, pill2, bgColor: PdfColor(18, 38, 30), borderColor: accentLime, borderWidth: 0.6);
      g.drawString(
        '02 · MULTI-SCENE STORYBOARD & SCRIPT',
        PdfStandardFont(PdfFontFamily.helvetica, 7, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: pill2,
        format: PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle),
      );

      // Render scenes line by line or parsed
      final rawScenes = proposal.sampleReelVisualScenes.isNotEmpty
          ? proposal.sampleReelVisualScenes
          : 'Scene 1: Close-up of challenging math problem and student focus.\nScene 2: Tutor demonstrates modular heuristics technique.\nScene 3: "Aha!" moment as solution clicks.\nScene 4: Clear outcome & invitation for diagnostic assessment.';
      final sceneLines = rawScenes.split('\n').where((s) => s.trim().isNotEmpty).toList();

      double sY = c2Y + 34.0;
      for (int i = 0; i < sceneLines.length && i < 4; i++) {
        final line = sceneLines[i].trim();
        final sPill = ui.Rect.fromLTWH(rightX + 12, sY, 50, 15);
        drawPill(g, sPill, bgColor: PdfColor(20, 28, 32), borderColor: cardBorder, borderWidth: 0.5);
        g.drawString(
          'SCENE ${i + 1}',
          PdfStandardFont(PdfFontFamily.helvetica, 6.5, style: PdfFontStyle.bold),
          brush: PdfSolidBrush(accentLime),
          bounds: sPill,
          format: PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle),
        );

        final desc = line.replaceAll(RegExp(r'^Scene\s*\d+\s*:\s*', caseSensitive: false), '').trim();
        g.drawString(
          desc,
          bodyFont,
          brush: PdfSolidBrush(textOffWhite),
          bounds: ui.Rect.fromLTWH(rightX + 68, sY, rightW - 80, 28),
        );
        sY += 38.0;
      }

      // Card 3: Outro Call-To-Action & Audio Direction
      const c3Y = c2Y + c2H + 12.0;
      const c3H = 88.0;
      final c3R = const ui.Rect.fromLTWH(rightX, c3Y, rightW, c3H);
      drawCard(g, c3R);

      const pill3 = ui.Rect.fromLTWH(rightX + 12, c3Y + 10, 175, 18);
      drawPill(g, pill3, bgColor: PdfColor(18, 38, 30), borderColor: accentLime, borderWidth: 0.6);
      g.drawString(
        '03 · CALL-TO-ACTION & AUDIO DIRECTION',
        PdfStandardFont(PdfFontFamily.helvetica, 7, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: pill3,
        format: PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle),
      );

      final ctaText = proposal.sampleReelCta.isNotEmpty
          ? proposal.sampleReelCta
          : 'Book your complimentary diagnostic evaluation via link in bio today.';
      g.drawString(
        ctaText,
        PdfStandardFont(PdfFontFamily.helvetica, 9.5, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(textWhite),
        bounds: ui.Rect.fromLTWH(rightX + 12, c3Y + 34, rightW - 24, 26),
      );
      g.drawString(
        'Audio: Rhythmic upbeat ambient pacing with crisp voiceover narrative.',
        captionFont,
        brush: PdfSolidBrush(textMuted),
        bounds: ui.Rect.fromLTWH(rightX + 12, c3Y + 64, rightW - 24, 14),
      );

      // ── Bottom Full-Width Card: Production Specifications Badge ──
      const btmY = phoneY + phoneH + 54.0;
      const btmH = 44.0;
      final btmR = const ui.Rect.fromLTWH(contentX, btmY, contentWidth, btmH);
      drawCard(g, btmR);
      g.drawString(
        'SPECIFICATIONS: 1080×1920 (9:16) Vertical Video  ·  CHANNELS: Instagram Reels, TikTok, YouTube Shorts  ·  TARGET: Inbound Trial Inquiries',
        PdfStandardFont(PdfFontFamily.helvetica, 7.5, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: ui.Rect.fromLTWH(contentX + 14, btmY + 14, contentWidth - 28, 16),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PAGE 10: Sample Social Media Copywriting/Caption (Matching Sample Image 5 Exactly)
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      drawDarkBase(page);

      // Clean, uncollided Section Title (Matching Image 5)
      drawSectionTitle(g, 'Sample Social Media Copywriting/Caption', 38);

      final posts = proposal.socialPosts.isNotEmpty
          ? proposal.socialPosts
          : [
              {
                'title': 'Core Positioning',
                'headline': 'BUILT ON TRUST. DRIVEN BY RESULTS.',
                'body': 'We don\'t believe in one-size-fits-all solutions. Every client engagement is tailored to your specific goals, supported by experienced professionals who care about your long-term success.\n\nLearn more at our website.',
                'badge': 'VERIFIED EXCELLENCE',
                'hashtags': ['#QualityService', '#ClientSuccess', '#Expertise'],
              },
              {
                'title': 'Client Transformation',
                'headline': 'HOW WE HELP OUR CLIENTS SUCCEED',
                'body': 'From initial consultation through seamless execution, our team provides the guidance, clarity, and accountability you need to achieve your goals.\n\nExplore our case studies today.',
                'badge': 'CLIENT OUTCOMES',
                'hashtags': ['#Transformation', '#Execution', '#Results'],
              },
              {
                'title': 'Strategic Perspective',
                'headline': 'THE RIGHT PARTNER MAKES ALL THE DIFFERENCE.',
                'body': 'Whether tackling a complex challenge or optimizing routine operations, having the right team in your corner changes everything.\n\nConnect with our specialists today.',
                'badge': 'PROVEN PARTNERSHIP',
                'hashtags': ['#StrategicPartner', '#Innovation', '#Excellence'],
              },
            ];

      final p1 = posts[0];
      final p2 = posts.length > 1 ? posts[1] : posts[0];
      final p3 = posts.length > 2 ? posts[2] : posts[0];

      // ── Post 1: Hero Ad Showcase (Instagram Frame + Ad Creative Visual) ──
      const heroY = 74.0;
      const instaW = 210.0;
      const heroH = 300.0;
      final instaRect = const ui.Rect.fromLTWH(contentX, heroY, instaW, heroH);

      // Instagram White Mockup Card
      drawCard(g, instaRect, radius: 12, bgColor: PdfColor(255, 255, 255), borderColor: PdfColor(226, 232, 240));

      // Phone Status Bar (9:41)
      g.drawString(
        '9:41',
        PdfStandardFont(PdfFontFamily.helvetica, 7, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(PdfColor(15, 23, 42)),
        bounds: const ui.Rect.fromLTWH(contentX + 12, heroY + 6, 40, 10),
      );
      // Wifi / Battery dots on right
      g.drawEllipse(ui.Rect.fromLTWH(contentX + instaW - 32, heroY + 8, 5, 5), brush: PdfSolidBrush(PdfColor(15, 23, 42)));
      g.drawRectangle(bounds: ui.Rect.fromLTWH(contentX + instaW - 22, heroY + 8, 10, 5), brush: PdfSolidBrush(PdfColor(15, 23, 42)));

      // Instagram Profile Header Bar
      g.drawString(
        '<  Posts',
        PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(PdfColor(15, 23, 42)),
        bounds: const ui.Rect.fromLTWH(contentX + 10, heroY + 22, 60, 12),
      );

      // Avatar
      const avSize = 22.0;
      final avR = ui.Rect.fromLTWH(contentX + 10, heroY + 38, avSize, avSize);
      g.drawEllipse(avR, brush: PdfSolidBrush(PdfColor(241, 245, 249)), pen: PdfPen(PdfColor(203, 213, 225), width: 0.5));
      if (companyLogoBytes != null) {
        try {
          g.drawImage(PdfBitmap(companyLogoBytes), ui.Rect.fromLTWH(avR.left + 2, avR.top + 2, avSize - 4, avSize - 4));
        } catch (_) {}
      }

      final handleStr = proposal.leadCompanyName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
      g.drawString(
        proposal.leadCompanyName.length > 18 ? '${proposal.leadCompanyName.substring(0, 18)}...' : proposal.leadCompanyName,
        PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(PdfColor(15, 23, 42)),
        bounds: ui.Rect.fromLTWH(contentX + 38, heroY + 37, instaW - 70, 11),
      );
      g.drawString(
        'Sponsored  ·  Official Campaign',
        PdfStandardFont(PdfFontFamily.helvetica, 6.5),
        brush: PdfSolidBrush(PdfColor(100, 116, 139)),
        bounds: ui.Rect.fromLTWH(contentX + 38, heroY + 49, instaW - 70, 9),
      );

      // Social Proof Action Icons (Heart, Comment, Share, Bookmark)
      const iconY = heroY + 66.0;
      // Vector Heart
      final heartPath = PdfPath();
      heartPath.addArc(const ui.Rect.fromLTWH(contentX + 10, iconY, 6, 6), 180, 180);
      heartPath.addArc(const ui.Rect.fromLTWH(contentX + 16, iconY, 6, 6), 180, 180);
      heartPath.addLine(const ui.Offset(contentX + 22, iconY + 3), const ui.Offset(contentX + 16, iconY + 11));
      heartPath.addLine(const ui.Offset(contentX + 16, iconY + 11), const ui.Offset(contentX + 10, iconY + 3));
      heartPath.closeFigure();
      g.drawPath(heartPath, brush: PdfSolidBrush(PdfColor(239, 68, 68)));

      // Vector Comment bubble
      g.drawEllipse(const ui.Rect.fromLTWH(contentX + 28, iconY, 11, 9), pen: PdfPen(PdfColor(100, 116, 139), width: 1));

      // Vector Share plane
      final planePath = PdfPath();
      planePath.addLine(const ui.Offset(contentX + 46, iconY + 10), const ui.Offset(contentX + 56, iconY));
      planePath.addLine(const ui.Offset(contentX + 56, iconY), const ui.Offset(contentX + 51, iconY + 7));
      planePath.addLine(const ui.Offset(contentX + 51, iconY + 7), const ui.Offset(contentX + 46, iconY + 10));
      planePath.closeFigure();
      g.drawPath(planePath, pen: PdfPen(PdfColor(100, 116, 139), width: 1));

      // Vector Bookmark
      final bmPath = PdfPath();
      bmPath.addLine(const ui.Offset(contentX + instaW - 22, iconY), const ui.Offset(contentX + instaW - 14, iconY));
      bmPath.addLine(const ui.Offset(contentX + instaW - 14, iconY), const ui.Offset(contentX + instaW - 14, iconY + 10));
      bmPath.addLine(const ui.Offset(contentX + instaW - 14, iconY + 10), const ui.Offset(contentX + instaW - 18, iconY + 7));
      bmPath.addLine(const ui.Offset(contentX + instaW - 18, iconY + 7), const ui.Offset(contentX + instaW - 22, iconY + 10));
      bmPath.closeFigure();
      g.drawPath(bmPath, pen: PdfPen(PdfColor(100, 116, 139), width: 1));

      // Likes count
      g.drawString(
        'Liked by 1,420 industry leaders and professionals',
        PdfStandardFont(PdfFontFamily.helvetica, 7, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(PdfColor(15, 23, 42)),
        bounds: const ui.Rect.fromLTWH(contentX + 10, iconY + 16, instaW - 20, 11),
      );

      // Caption inside phone
      final captionHeadline = (p1['headline'] as String? ?? 'BUILT ON TRUST. DRIVEN BY RESULTS.').replaceAll(RegExp(r'["“”]'), '');
      g.drawString(
        '@$handleStr  $captionHeadline',
        PdfStandardFont(PdfFontFamily.helvetica, 7.5, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(PdfColor(15, 23, 42)),
        bounds: const ui.Rect.fromLTWH(contentX + 10, iconY + 30, instaW - 20, 26),
      );

      final captionBody = p1['body'] as String? ?? '';
      g.drawString(
        captionBody,
        PdfStandardFont(PdfFontFamily.helvetica, 7),
        brush: PdfSolidBrush(PdfColor(51, 65, 85)),
        bounds: const ui.Rect.fromLTWH(contentX + 10, iconY + 58, instaW - 20, 110),
      );

      final hts1 = (p1['hashtags'] as List?)?.join(' ') ?? '#QualityService #ClientSuccess #Expertise';
      g.drawString(
        hts1,
        PdfStandardFont(PdfFontFamily.helvetica, 6.5, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(PdfColor(2, 132, 199)),
        bounds: const ui.Rect.fromLTWH(contentX + 10, iconY + 172, instaW - 20, 12),
      );

      // Button at bottom of Instagram frame
      const ctaBtnR = ui.Rect.fromLTWH(contentX + 10, heroY + heroH - 24, instaW - 20, 18);
      drawPill(g, ctaBtnR, bgColor: PdfColor(241, 245, 249), borderColor: PdfColor(203, 213, 225), borderWidth: 0.5);
      g.drawString(
        'LEARN MORE  /  BOOK AUDIT',
        PdfStandardFont(PdfFontFamily.helvetica, 7, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(PdfColor(15, 23, 42)),
        bounds: ctaBtnR,
        format: PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle),
      );

      // Right: High-Converting Ad Visual Card (Matching Image 5)
      final adVisualX = contentX + instaW + 14.0;
      final adVisualW = contentWidth - instaW - 14.0;
      final adVisualRect = ui.Rect.fromLTWH(adVisualX, heroY, adVisualW, heroH);
      drawCard(g, adVisualRect, radius: 12, bgColor: PdfColor(15, 20, 22), borderColor: cardBorder);

      final List<int>? post1Img = post1ImageBytes ?? visualDirectionImageBytes;
      if (post1Img != null) {
        try {
          final imgInner = ui.Rect.fromLTWH(adVisualX + 4, heroY + 4, adVisualW - 8, heroH - 8);
          g.drawImage(PdfBitmap(post1Img), imgInner);

          // Dark luxury vignette overlay at bottom of ad visual for contrast
          g.drawRectangle(
            brush: PdfSolidBrush(PdfColor(0, 0, 0, 195)),
            bounds: ui.Rect.fromLTWH(adVisualX + 4, heroY + heroH - 95, adVisualW - 8, 91),
          );

          // Client Logo Watermark in top-right of ad visual
          if (companyLogoBytes != null) {
            const logoBadgeW = 56.0;
            const logoBadgeH = 26.0;
            final logoBadgeR = ui.Rect.fromLTWH(adVisualX + adVisualW - logoBadgeW - 12, heroY + 12, logoBadgeW, logoBadgeH);
            drawPill(g, logoBadgeR, bgColor: PdfColor(10, 16, 18, 220), borderColor: PdfColor(255, 255, 255, 80), borderWidth: 0.5);
            g.drawImage(PdfBitmap(companyLogoBytes), ui.Rect.fromLTWH(logoBadgeR.left + 4, logoBadgeR.top + 3, logoBadgeW - 8, logoBadgeH - 6));
          }
        } catch (_) {}
      } else {
        g.drawString(
          'HIGH-CONVERTING AD VISUAL',
          PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
          brush: PdfSolidBrush(accentLime),
          bounds: ui.Rect.fromLTWH(adVisualX + 16, heroY + 90, adVisualW - 32, 20),
          format: PdfStringFormat(alignment: PdfTextAlignment.center),
        );
      }

      // Ad Visual Text Overlay
      g.drawString(
        '“${p1['headline'] as String? ?? 'BUILT ON TRUST. DRIVEN BY RESULTS.'}”',
        PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(textWhite),
        bounds: ui.Rect.fromLTWH(adVisualX + 16, heroY + heroH - 80, adVisualW - 32, 34),
      );

      // Feature Badges
      final b1W = (adVisualW - 40.0) / 3.0;
      final badges = ['VERIFIED CARE', 'AUTHENTIC ENGAGEMENT', 'PROVEN OUTCOMES'];
      double bx = adVisualX + 16;
      for (final b in badges) {
        final bRect = ui.Rect.fromLTWH(bx, heroY + heroH - 38, b1W, 18);
        drawPill(g, bRect, bgColor: PdfColor(14, 28, 22, 220), borderColor: accentLime, borderWidth: 0.5);
        g.drawString(
          b,
          PdfStandardFont(PdfFontFamily.helvetica, 6, style: PdfFontStyle.bold),
          brush: PdfSolidBrush(accentLime),
          bounds: bRect,
          format: PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle),
        );
        bx += b1W + 4.0;
      }

      // ── Posts 2 & 3: Multi-Angle Ad Deliverables (Side-by-Side as in Image 5) ──
      const row2Y = heroY + heroH + 14.0;
      final postCardW = (contentWidth - 14.0) / 2.0;
      const postCardH = 345.0;

      // Post 2 Card (Angle A: Client Transformation)
      final p2Rect = ui.Rect.fromLTWH(contentX, row2Y, postCardW, postCardH);
      drawCard(g, p2Rect, radius: 14);

      // Top thumbnail of Post 2
      const imgThumbH = 150.0;
      final p2ImgRect = ui.Rect.fromLTWH(contentX + 3, row2Y + 3, postCardW - 6, imgThumbH);
      if (post2ImageBytes != null) {
        try {
          g.drawImage(PdfBitmap(post2ImageBytes), p2ImgRect);
          // Logo watermark
          if (companyLogoBytes != null) {
            const pillW = 44.0;
            const pillH = 20.0;
            final pillR = ui.Rect.fromLTWH(p2ImgRect.right - pillW - 8, p2ImgRect.top + 8, pillW, pillH);
            drawPill(g, pillR, bgColor: PdfColor(10, 16, 18, 220), borderColor: PdfColor(255, 255, 255, 80), borderWidth: 0.5);
            g.drawImage(PdfBitmap(companyLogoBytes), ui.Rect.fromLTWH(pillR.left + 3, pillR.top + 2, pillW - 6, pillH - 4));
          }
        } catch (_) {}
      } else {
        g.drawRectangle(brush: PdfSolidBrush(PdfColor(18, 24, 28)), bounds: p2ImgRect);
        g.drawString(
          'CLIENT TRANSFORMATION AD VISUAL',
          PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.bold),
          brush: PdfSolidBrush(accentLime),
          bounds: ui.Rect.fromLTWH(p2ImgRect.left + 10, p2ImgRect.top + 65, postCardW - 26, 14),
          format: PdfStringFormat(alignment: PdfTextAlignment.center),
        );
      }

      // Content for Post 2
      double c2Y = row2Y + imgThumbH + 12.0;
      final p2BadgeR = ui.Rect.fromLTWH(contentX + 12, c2Y, postCardW - 24, 18);
      drawPill(g, p2BadgeR, bgColor: PdfColor(14, 30, 24), borderColor: accentLime, borderWidth: 0.5);
      g.drawString(
        '02 · ANGLE A: CLIENT OUTCOMES',
        PdfStandardFont(PdfFontFamily.helvetica, 7, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: p2BadgeR,
        format: PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle),
      );

      c2Y += 24.0;
      g.drawString(
        p2['headline'] as String? ?? 'HOW WE HELP OUR CLIENTS SUCCEED',
        PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(textWhite),
        bounds: ui.Rect.fromLTWH(contentX + 12, c2Y, postCardW - 24, 28),
      );

      c2Y += 32.0;
      g.drawString(
        p2['body'] as String? ?? '',
        PdfStandardFont(PdfFontFamily.helvetica, 8.2),
        brush: PdfSolidBrush(textOffWhite),
        bounds: ui.Rect.fromLTWH(contentX + 12, c2Y, postCardW - 24, 88),
      );

      c2Y += 92.0;
      g.drawString(
        'Connect with our specialists today →',
        PdfStandardFont(PdfFontFamily.helvetica, 8.5, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: ui.Rect.fromLTWH(contentX + 12, c2Y, postCardW - 24, 16),
      );

      // Post 3 Card (Angle B: Strategic Perspective / Proven Partnership)
      final p3X = contentX + postCardW + 14.0;
      final p3Rect = ui.Rect.fromLTWH(p3X, row2Y, postCardW, postCardH);
      drawCard(g, p3Rect, radius: 14);

      // Top thumbnail of Post 3
      final p3ImgRect = ui.Rect.fromLTWH(p3X + 3, row2Y + 3, postCardW - 6, imgThumbH);
      if (post3ImageBytes != null) {
        try {
          g.drawImage(PdfBitmap(post3ImageBytes), p3ImgRect);
          if (companyLogoBytes != null) {
            const pillW = 44.0;
            const pillH = 20.0;
            final pillR = ui.Rect.fromLTWH(p3ImgRect.right - pillW - 8, p3ImgRect.top + 8, pillW, pillH);
            drawPill(g, pillR, bgColor: PdfColor(10, 16, 18, 220), borderColor: PdfColor(255, 255, 255, 80), borderWidth: 0.5);
            g.drawImage(PdfBitmap(companyLogoBytes), ui.Rect.fromLTWH(pillR.left + 3, pillR.top + 2, pillW - 6, pillH - 4));
          }
        } catch (_) {}
      } else {
        g.drawRectangle(brush: PdfSolidBrush(PdfColor(18, 24, 28)), bounds: p3ImgRect);
        g.drawString(
          'STRATEGIC PERSPECTIVE AD VISUAL',
          PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.bold),
          brush: PdfSolidBrush(accentLime),
          bounds: ui.Rect.fromLTWH(p3ImgRect.left + 10, p3ImgRect.top + 65, postCardW - 26, 14),
          format: PdfStringFormat(alignment: PdfTextAlignment.center),
        );
      }

      // Content for Post 3
      double c3Y = row2Y + imgThumbH + 12.0;
      final p3BadgeR = ui.Rect.fromLTWH(p3X + 12, c3Y, postCardW - 24, 18);
      drawPill(g, p3BadgeR, bgColor: PdfColor(14, 30, 24), borderColor: accentLime, borderWidth: 0.5);
      g.drawString(
        '03 · ANGLE B: STRATEGIC PERSPECTIVE',
        PdfStandardFont(PdfFontFamily.helvetica, 7, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: p3BadgeR,
        format: PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle),
      );

      c3Y += 24.0;
      g.drawString(
        p3['headline'] as String? ?? 'THE RIGHT PARTNER MAKES ALL THE DIFFERENCE.',
        PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(textWhite),
        bounds: ui.Rect.fromLTWH(p3X + 12, c3Y, postCardW - 24, 28),
      );

      c3Y += 32.0;
      g.drawString(
        p3['body'] as String? ?? '',
        PdfStandardFont(PdfFontFamily.helvetica, 8.2),
        brush: PdfSolidBrush(textOffWhite),
        bounds: ui.Rect.fromLTWH(p3X + 12, c3Y, postCardW - 24, 88),
      );

      c3Y += 92.0;
      g.drawString(
        'Book your consultation audit today →',
        PdfStandardFont(PdfFontFamily.helvetica, 8.5, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: ui.Rect.fromLTWH(p3X + 12, c3Y, postCardW - 24, 16),
      );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PAGE 11: Sample Copywriting Direction & Blog Content Preview (Matching Sample Image 4 Bottom)
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      drawDarkBase(page);

      // Single Elegant Rounded Dark Card (Matching Image 4 Bottom)
      const cardTop = 100.0;
      const cardHeight = 610.0;
      final cardRect = const ui.Rect.fromLTWH(contentX, cardTop, contentWidth, cardHeight);
      drawCard(g, cardRect, radius: 18);

      // Main Heading inside Card: Sample Copywriting Direction (Lime Green)
      g.drawString(
        'Sample Copywriting Direction',
        PdfStandardFont(PdfFontFamily.helvetica, 20, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: const ui.Rect.fromLTWH(contentX + 28, cardTop + 26, contentWidth - 56, 26),
      );

      // Subheading: Building Trust Through Storytelling
      g.drawString(
        'Building Trust Through Storytelling',
        PdfStandardFont(PdfFontFamily.helvetica, 11, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(textWhite),
        bounds: const ui.Rect.fromLTWH(contentX + 28, cardTop + 58, contentWidth - 56, 16),
      );

      // Narrative Paragraph 1
      final p1 = proposal.sampleBlogStorytellingIntro.isNotEmpty
          ? proposal.sampleBlogStorytellingIntro
          : 'Rather than relying on promotional messaging, our content approach focuses on storytelling and customer-centric narratives that help audiences visualise the experience before they make a booking.';
      g.drawString(
        p1,
        PdfStandardFont(PdfFontFamily.helvetica, 9.5),
        brush: PdfSolidBrush(textOffWhite),
        bounds: const ui.Rect.fromLTWH(contentX + 28, cardTop + 78, contentWidth - 56, 44),
      );

      // Narrative Paragraph 2
      final p2 = 'The objective is to move beyond simply showcasing ${proposal.leadCompanyName} and instead communicate the emotions, memories and moments that make client engagements meaningful.';
      g.drawString(
        p2,
        PdfStandardFont(PdfFontFamily.helvetica, 9.5),
        brush: PdfSolidBrush(textOffWhite),
        bounds: const ui.Rect.fromLTWH(contentX + 28, cardTop + 128, contentWidth - 56, 40),
      );

      // Narrative Paragraph 3
      final p3 = 'This approach allows ${proposal.leadCompanyName} to build stronger emotional connections while creating content that feels authentic, engaging and shareable.';
      g.drawString(
        p3,
        PdfStandardFont(PdfFontFamily.helvetica, 9.5),
        brush: PdfSolidBrush(textOffWhite),
        bounds: const ui.Rect.fromLTWH(contentX + 28, cardTop + 174, contentWidth - 56, 40),
      );

      // Sub-Section inside Card: Blog Content Preview (Lime Green)
      const blogHeaderY = cardTop + 242.0;
      g.drawString(
        'Blog Content Preview',
        PdfStandardFont(PdfFontFamily.helvetica, 14.5, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: const ui.Rect.fromLTWH(contentX + 28, blogHeaderY, contentWidth - 56, 20),
      );

      // Suggested Article Label
      g.drawString(
        'Suggested Article:',
        PdfStandardFont(PdfFontFamily.helvetica, 10.5, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(textWhite),
        bounds: const ui.Rect.fromLTWH(contentX + 28, blogHeaderY + 28, contentWidth - 56, 16),
      );

      // Article Title
      final articleTitle = proposal.sampleBlogTitle.isNotEmpty
          ? proposal.sampleBlogTitle
          : 'How to Plan a Yacht Birthday Party in Singapore (Without the Usual Stress)';
      g.drawString(
        '“$articleTitle”',
        PdfStandardFont(PdfFontFamily.helvetica, 10.5),
        brush: PdfSolidBrush(textOffWhite),
        bounds: const ui.Rect.fromLTWH(contentX + 28, blogHeaderY + 48, contentWidth - 56, 32),
      );

      // Article Preview Content
      final previewExcerpt = proposal.sampleBlogPreview.isNotEmpty
          ? proposal.sampleBlogPreview
          : 'When planning a milestone celebration, most organizers are forced to choose between crowded public venues or sterile hotel banquet rooms. But true luxury is about privacy, personalized attention, and memories that last long after the evening ends...\n\nIn this comprehensive guide, we unpack everything from selecting the right package to catering coordination, ambient music, and capturing high-definition memories.';
      g.drawString(
        previewExcerpt,
        PdfStandardFont(PdfFontFamily.helvetica, 9.5),
        brush: PdfSolidBrush(textOffWhite),
        bounds: const ui.Rect.fromLTWH(contentX + 28, blogHeaderY + 86, contentWidth - 56, 175),
      );

      // Clickable Call-To-Action Link (Underlined in Lime Green)
      const linkY = blogHeaderY + 276.0;
      final linkRect = ui.Rect.fromLTWH(contentX + 28, linkY, 210, 20);
      g.drawString(
        'Read Full Blog Article Here',
        PdfStandardFont(PdfFontFamily.helvetica, 11, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: linkRect,
      );
      // Underline
      g.drawLine(
        PdfPen(accentLime, width: 1.2),
        ui.Offset(contentX + 28, linkY + 15),
        ui.Offset(contentX + 195, linkY + 15),
      );

      final blogUrl = proposal.sampleReelLink.isNotEmpty ? proposal.sampleReelLink : 'https://meet-marketers.com/blog';
      final blogAnnotation = PdfUriAnnotation(bounds: linkRect, uri: blogUrl);
      blogAnnotation.border = PdfAnnotationBorder(0);
      page.annotations.add(blogAnnotation);
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
