import 'dart:ui' as ui;
import 'package:flutter/services.dart' show rootBundle;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../data/models/proposal_model.dart';
import 'web_download_helper.dart';

/// Service to generate and export professional 13-section proposals
/// matching the exact dark luxury & lime-accent design from the reference sample.
class ProposalPdfService {
  static final ProposalPdfService instance = ProposalPdfService._internal();
  ProposalPdfService._internal();

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
      bgImageBytes = data.buffer.asUint8List();
    } catch (_) {}

    List<int>? logoBytes;
    try {
      final data = await rootBundle.load('assets/logos/meet_marketers_pdf_logo.png');
      logoBytes = data.buffer.asUint8List();
    } catch (_) {}

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
    final titleFont = PdfStandardFont(PdfFontFamily.helvetica, 28, style: PdfFontStyle.bold);
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
        g.drawImage(
          PdfBitmap(bgImageBytes),
          const ui.Rect.fromLTWH(0, 0, pageWidth, pageHeight),
        );
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
        // Draw the real MM transparent logo
        g.drawImage(
          PdfBitmap(logoBytes),
          ui.Rect.fromLTWH(x, y - 2, 28, 22),
        );
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
    // PAGE 1: Cover Page & Table of Contents
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      drawDarkBase(page);

      // Logo at Top
      drawMeetMarketersLogo(g, contentX, 85);

      // Main Title (Lime Green)
      g.drawString(
        'Digital & Content\nDirection Proposal',
        titleFont,
        brush: PdfSolidBrush(accentLime),
        bounds: const ui.Rect.fromLTWH(contentX, 230, contentWidth, 75),
      );

      // Subtitle in Clean White
      g.drawString(
        'Prepared for ${proposal.leadCompanyName}',
        PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.regular),
        brush: PdfSolidBrush(textWhite),
        bounds: const ui.Rect.fromLTWH(contentX, 320, contentWidth, 24),
      );

      // CONTENTS Section
      double curY = 385;
      g.drawString(
        'CONTENTS',
        PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: ui.Rect.fromLTWH(contentX, curY, contentWidth, 16),
      );
      curY += 22;

      // Marketing Strategy
      g.drawString(
        'Marketing Strategy',
        h3Font,
        brush: PdfSolidBrush(accentLime),
        bounds: ui.Rect.fromLTWH(contentX, curY, contentWidth, 16),
      );
      curY += 18;

      final strategyItems = [
        'Executive Summary',
        'SWOT Analysis',
        'Marketing Mix (4Ps Analysis)',
        'PEST Analysis',
        'USP Analysis',
        'Perceptual Map',
      ];
      for (final item in strategyItems) {
        g.drawString(
          '  • $item',
          bodyFont,
          brush: PdfSolidBrush(textOffWhite),
          bounds: ui.Rect.fromLTWH(contentX, curY, contentWidth, 16),
        );
        curY += 16;
      }

      curY += 10;
      // Marketing Operation
      g.drawString(
        'Marketing Operation',
        h3Font,
        brush: PdfSolidBrush(accentLime),
        bounds: ui.Rect.fromLTWH(contentX, curY, contentWidth, 16),
      );
      curY += 18;

      final operationItems = [
        'Creative Direction',
        'Visual Guideline',
        'Content Framework',
        'Sample Reel',
        'Sample Blog',
        'SEO Audit & Recommendation',
        'Conclusion',
      ];
      for (final item in operationItems) {
        g.drawString(
          '  • $item',
          bodyFont,
          brush: PdfSolidBrush(textOffWhite),
          bounds: ui.Rect.fromLTWH(contentX, curY, contentWidth, 16),
        );
        curY += 16;
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PAGE 2: Current Position, Opportunity & SWOT Analysis
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      drawDarkBase(page);

      // Top Lead Brand Badge
      g.drawString(
        proposal.leadCompanyName.toUpperCase(),
        PdfStandardFont(PdfFontFamily.helvetica, 13.5, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(PdfColor(56, 189, 248)),
        bounds: const ui.Rect.fromLTWH(0, 48, pageWidth, 18),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      g.drawString(
        'STRATEGIC AUDIT & DIRECTION',
        captionFont,
        brush: PdfSolidBrush(textMuted),
        bounds: const ui.Rect.fromLTWH(0, 68, pageWidth, 14),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );

      // Current Position & Opportunity Card
      const cardRect = ui.Rect.fromLTWH(contentX, 95, contentWidth, 230);
      drawCard(g, cardRect);

      double cy = 115;
      g.drawString(
        'Current Position',
        h2Font,
        brush: PdfSolidBrush(textWhite),
        bounds: const ui.Rect.fromLTWH(contentX + 22, 115, contentWidth - 44, 20),
      );
      cy += 24;

      final posText = proposal.executiveSummaryPosition.isNotEmpty
          ? proposal.executiveSummaryPosition
          : '${proposal.leadCompanyName} has established itself as one of the trusted providers in ${proposal.industry}, building strong credibility, customer satisfaction, and reliable service quality across diverse customer segments.';
      g.drawString(
        posText,
        bodyFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: ui.Rect.fromLTWH(contentX + 22, cy, contentWidth - 44, 65),
      );

      cy += 70;
      g.drawString(
        'Opportunity',
        h2Font,
        brush: PdfSolidBrush(textWhite),
        bounds: ui.Rect.fromLTWH(contentX + 22, cy, contentWidth - 44, 20),
      );
      cy += 24;

      final oppText = proposal.executiveSummaryOpportunity.isNotEmpty
          ? proposal.executiveSummaryOpportunity
          : 'While ${proposal.leadCompanyName} has built strong credibility, significant opportunity exists to expand organic search visibility, corporate authority, and video storytelling within an increasingly competitive digital landscape.';
      g.drawString(
        oppText,
        bodyFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: ui.Rect.fromLTWH(contentX + 22, cy, contentWidth - 44, 65),
      );

      // SWOT Analysis Section Heading (Lime Green)
      drawSectionTitle(g, 'SWOT Analysis', 350);

      // 2x2 SWOT Matrix
      const swotTop = 390.0;
      const colWidth = contentWidth / 2.0;
      const headerH = 25.0;
      const cellH = 160.0;

      // Row 1: Strength & Weaknesses
      drawTableHeader(g, 'Strength', const ui.Rect.fromLTWH(contentX, swotTop, colWidth, headerH));
      drawTableHeader(g, 'Weaknesses', const ui.Rect.fromLTWH(contentX + colWidth, swotTop, colWidth, headerH));

      drawTableCell(g, const ui.Rect.fromLTWH(contentX, swotTop + headerH, colWidth, cellH));
      drawTableCell(g, const ui.Rect.fromLTWH(contentX + colWidth, swotTop + headerH, colWidth, cellH));

      double ty = swotTop + headerH + 12;
      for (final s in proposal.swot.strengths.take(4)) {
        g.drawString('•  $s', bodyFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + 10, ty, colWidth - 20, 32));
        ty += 34;
      }

      ty = swotTop + headerH + 12;
      for (final w in proposal.swot.weaknesses.take(4)) {
        g.drawString('•  $w', bodyFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + colWidth + 10, ty, colWidth - 20, 32));
        ty += 34;
      }

      // Row 2: Opportunities & Threats
      const row2Top = swotTop + headerH + cellH;
      drawTableHeader(g, 'Opportunities', const ui.Rect.fromLTWH(contentX, row2Top, colWidth, headerH));
      drawTableHeader(g, 'Threats', const ui.Rect.fromLTWH(contentX + colWidth, row2Top, colWidth, headerH));

      drawTableCell(g, const ui.Rect.fromLTWH(contentX, row2Top + headerH, colWidth, cellH));
      drawTableCell(g, const ui.Rect.fromLTWH(contentX + colWidth, row2Top + headerH, colWidth, cellH));

      ty = row2Top + headerH + 12;
      for (final o in proposal.swot.opportunities.take(4)) {
        g.drawString('•  $o', bodyFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + 10, ty, colWidth - 20, 32));
        ty += 34;
      }

      ty = row2Top + headerH + 12;
      for (final t in proposal.swot.threats.take(4)) {
        g.drawString('•  $t', bodyFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + colWidth + 10, ty, colWidth - 20, 32));
        ty += 34;
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
    // PAGE 4: PEST Analysis & Competitor / USP Analysis
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      drawDarkBase(page);

      // PEST Analysis Heading
      drawSectionTitle(g, 'PEST Analysis', 45);

      const pestTop = 80.0;
      const colWidth = contentWidth / 2.0;
      const headerH = 24.0;
      const cellH = 100.0;

      // Row 1: Political & Economic
      drawTableHeader(g, 'Political', const ui.Rect.fromLTWH(contentX, pestTop, colWidth, headerH));
      drawTableHeader(g, 'Economic', const ui.Rect.fromLTWH(contentX + colWidth, pestTop, colWidth, headerH));

      drawTableCell(g, const ui.Rect.fromLTWH(contentX, pestTop + headerH, colWidth, cellH));
      drawTableCell(g, const ui.Rect.fromLTWH(contentX + colWidth, pestTop + headerH, colWidth, cellH));

      double py = pestTop + headerH + 8;
      for (final p in proposal.pestAnalysis.political.take(3)) {
        g.drawString('•  $p', bodyFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + 10, py, colWidth - 20, 24));
        py += 24;
      }

      py = pestTop + headerH + 8;
      for (final e in proposal.pestAnalysis.economic.take(3)) {
        g.drawString('•  $e', bodyFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + colWidth + 10, py, colWidth - 20, 24));
        py += 24;
      }

      // Row 2: Social & Technological
      const row2Top = pestTop + headerH + cellH;
      drawTableHeader(g, 'Social', const ui.Rect.fromLTWH(contentX, row2Top, colWidth, headerH));
      drawTableHeader(g, 'Technological', const ui.Rect.fromLTWH(contentX + colWidth, row2Top, colWidth, headerH));

      drawTableCell(g, const ui.Rect.fromLTWH(contentX, row2Top + headerH, colWidth, cellH));
      drawTableCell(g, const ui.Rect.fromLTWH(contentX + colWidth, row2Top + headerH, colWidth, cellH));

      py = row2Top + headerH + 8;
      for (final s in proposal.pestAnalysis.social.take(3)) {
        g.drawString('•  $s', bodyFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + 10, py, colWidth - 20, 24));
        py += 24;
      }

      py = row2Top + headerH + 8;
      for (final t in proposal.pestAnalysis.technological.take(3)) {
        g.drawString('•  $t', bodyFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + colWidth + 10, py, colWidth - 20, 24));
        py += 24;
      }

      // Competitor Analysis Heading
      double curY = row2Top + headerH + cellH + 20;
      drawSectionTitle(g, 'Competitor Analysis', curY);
      curY += 30;

      g.drawString(
        'Competitors:',
        bodyBold,
        brush: PdfSolidBrush(textWhite),
        bounds: ui.Rect.fromLTWH(contentX, curY, contentWidth, 16),
      );
      curY += 18;

      final comps = proposal.competitorUsps.where((c) => !c.isLeadBrand).take(3).toList();
      for (final c in comps) {
        g.drawString(
          '  • ${c.brandName}',
          bodyFont,
          brush: PdfSolidBrush(textOffWhite),
          bounds: ui.Rect.fromLTWH(contentX, curY, contentWidth, 16),
        );
        curY += 16;
      }

      // USP Analysis Heading
      curY += 12;
      drawSectionTitle(g, 'USP Analysis', curY);
      curY += 30;

      // USP Table
      const brandColW = 160.0;
      final uspColW = contentWidth - brandColW;
      const uspHeaderH = 25.0;

      drawTableHeader(g, 'Brand', ui.Rect.fromLTWH(contentX, curY, brandColW, uspHeaderH));
      drawTableHeader(g, 'Primary USP', ui.Rect.fromLTWH(contentX + brandColW, curY, uspColW, uspHeaderH));
      curY += uspHeaderH;

      final allComps = proposal.competitorUsps.isNotEmpty
          ? proposal.competitorUsps
          : [
              CompetitorUsp(brandName: proposal.leadCompanyName, primaryUsp: 'Premier tailored experiences, verified reliability', isLeadBrand: true),
              const CompetitorUsp(brandName: 'Competitor A', primaryUsp: 'Largest fleet with extensive options'),
              const CompetitorUsp(brandName: 'Competitor B', primaryUsp: 'Premium boutique experiences'),
              const CompetitorUsp(brandName: 'Competitor C', primaryUsp: 'Event-focused group packages'),
            ];

      for (final c in allComps.take(4)) {
        const rowH = 34.0;
        drawTableCell(g, ui.Rect.fromLTWH(contentX, curY, brandColW, rowH));
        drawTableCell(g, ui.Rect.fromLTWH(contentX + brandColW, curY, uspColW, rowH));

        g.drawString(
          c.brandName,
          c.isLeadBrand ? bodyBold : bodyFont,
          brush: PdfSolidBrush(c.isLeadBrand ? accentLime : textWhite),
          bounds: ui.Rect.fromLTWH(contentX + 10, curY + 9, brandColW - 20, 18),
        );

        g.drawString(
          c.primaryUsp,
          bodyFont,
          brush: PdfSolidBrush(textOffWhite),
          bounds: ui.Rect.fromLTWH(contentX + brandColW + 10, curY + 6, uspColW - 20, 24),
        );

        curY += rowH;
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

      // Top Y-Axis Label (Placed clearly above the top arrow)
      g.drawString(
        'HIGH',
        h3Font,
        brush: PdfSolidBrush(textWhite),
        bounds: const ui.Rect.fromLTWH(graphCenterX - 80, 110, 160, 14),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      g.drawString(
        'Premium Experience Perception',
        captionFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: const ui.Rect.fromLTWH(graphCenterX - 80, 124, 160, 14),
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

      // Bottom Y-Axis Label (Placed clearly below the bottom arrow)
      g.drawString(
        'LOW',
        h3Font,
        brush: PdfSolidBrush(textWhite),
        bounds: const ui.Rect.fromLTWH(graphCenterX - 80, 406, 160, 14),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      g.drawString(
        'Premium Experience Perception',
        captionFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: const ui.Rect.fromLTWH(graphCenterX - 80, 420, 160, 14),
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
        'LOW\nService Breadth',
        captionFont,
        brush: PdfSolidBrush(textWhite),
        bounds: const ui.Rect.fromLTWH(graphCenterX - axisLen - 75, graphCenterY - 12, 70, 24),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      g.drawString(
        'HIGH\nService Breadth',
        captionFont,
        brush: PdfSolidBrush(textWhite),
        bounds: const ui.Rect.fromLTWH(graphCenterX + axisLen + 6, graphCenterY - 12, 70, 24),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );

      // Plotted Brands in 4 Quadrants with ample space
      // Quadrant 1 (Top Left): Lead Brand
      g.drawString(
        proposal.leadCompanyName.toUpperCase(),
        bodyBold,
        brush: PdfSolidBrush(accentLime),
        bounds: const ui.Rect.fromLTWH(contentX + 15, graphCenterY - 85, 150, 16),
      );
      g.drawString(
        'Strong balance of premium experiences with wide range of offerings for diverse clients.',
        captionFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: const ui.Rect.fromLTWH(contentX + 15, graphCenterY - 68, 140, 36),
      );

      // Quadrant 2 (Top Right): Competitor 1
      g.drawString(
        'CATEGORY PEER A',
        bodyBold,
        brush: PdfSolidBrush(textWhite),
        bounds: const ui.Rect.fromLTWH(graphCenterX + 45, graphCenterY - 85, 150, 16),
      );
      g.drawString(
        'Niche luxury focus with limited accessibility.',
        captionFont,
        brush: PdfSolidBrush(textMuted),
        bounds: const ui.Rect.fromLTWH(graphCenterX + 45, graphCenterY - 68, 130, 24),
      );

      // Quadrant 3 (Bottom Left): Competitor 2
      g.drawString(
        'CATEGORY PEER B',
        bodyBold,
        brush: PdfSolidBrush(textWhite),
        bounds: const ui.Rect.fromLTWH(contentX + 15, graphCenterY + 45, 150, 16),
      );
      g.drawString(
        'Event-focused with standard generic options.',
        captionFont,
        brush: PdfSolidBrush(textMuted),
        bounds: const ui.Rect.fromLTWH(contentX + 15, graphCenterY + 62, 140, 24),
      );

      // Quadrant 4 (Bottom Right): Competitor 3
      g.drawString(
        'MASS OPERATOR C',
        bodyBold,
        brush: PdfSolidBrush(textWhite),
        bounds: const ui.Rect.fromLTWH(graphCenterX + 45, graphCenterY + 45, 150, 16),
      );
      g.drawString(
        'High volume operations with discount pricing.',
        captionFont,
        brush: PdfSolidBrush(textMuted),
        bounds: const ui.Rect.fromLTWH(graphCenterX + 45, graphCenterY + 62, 130, 24),
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

      // (1) Visual Direction (Top Left)
      const box1R = ui.Rect.fromLTWH(contentX, 68, 245, 175);
      drawCard(g, box1R);
      g.drawString('1  VISUAL DIRECTION', h3Font, brush: PdfSolidBrush(accentLime), bounds: const ui.Rect.fromLTWH(contentX + 12, 78, 220, 16));
      g.drawString('CREATIVE DIRECTION', captionFont, brush: PdfSolidBrush(textMuted), bounds: const ui.Rect.fromLTWH(contentX + 12, 96, 220, 12));
      g.drawString(
        proposal.visualGuidelineNotes.isNotEmpty
            ? proposal.visualGuidelineNotes
            : 'Our visual direction focuses on the experiences, emotions and memorable moments that customers enjoy. The objective is to position ${proposal.leadCompanyName} as the definitive category choice through authentic connection.',
        captionFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: const ui.Rect.fromLTWH(contentX + 12, 110, 220, 65),
      );
      g.drawString('KEYWORDS', captionFont, brush: PdfSolidBrush(textMuted), bounds: const ui.Rect.fromLTWH(contentX + 12, 180, 220, 12));
      final kws = proposal.visualKeywords.isNotEmpty ? proposal.visualKeywords : ['Experiential', 'Lifestyle-driven', 'Aspirational', 'Authentic', 'Human-centric'];
      g.drawString(kws.join(' · '), captionFont, brush: PdfSolidBrush(accentLime), bounds: const ui.Rect.fromLTWH(contentX + 12, 196, 220, 38));

      // (2) Photography Style (Top Right)
      const box2R = ui.Rect.fromLTWH(contentX + 255, 68, 255, 175);
      drawCard(g, box2R);
      g.drawString('2  PHOTOGRAPHY STYLE', h3Font, brush: PdfSolidBrush(accentLime), bounds: const ui.Rect.fromLTWH(contentX + 267, 78, 230, 16));
      g.drawString('FOCUS MORE ON:', captionFont, brush: PdfSolidBrush(PdfColor(134, 239, 172)), bounds: const ui.Rect.fromLTWH(contentX + 267, 96, 120, 12));
      final moreOn = proposal.focusMoreOn.isNotEmpty ? proposal.focusMoreOn : ['People', 'Interactions', 'Celebrations', 'Team moments'];
      double fmy = 110;
      for (final f in moreOn.take(4)) {
        g.drawString('✓ $f', captionFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + 267, fmy, 115, 14));
        fmy += 14;
      }

      g.drawString('FOCUS LESS ON:', captionFont, brush: PdfSolidBrush(PdfColor(248, 113, 113)), bounds: const ui.Rect.fromLTWH(contentX + 390, 96, 120, 12));
      final lessOn = proposal.focusLessOn.isNotEmpty ? proposal.focusLessOn : ['Empty shots', 'Generic photos', 'Promotional visuals'];
      double fly = 110;
      for (final l in lessOn.take(4)) {
        g.drawString('✕ $l', captionFont, brush: PdfSolidBrush(textMuted), bounds: ui.Rect.fromLTWH(contentX + 390, fly, 115, 14));
        fly += 14;
      }
      g.drawString(
        '“${proposal.photographyQuote}”',
        captionFont,
        brush: PdfSolidBrush(accentLime),
        bounds: const ui.Rect.fromLTWH(contentX + 267, 185, 230, 30),
      );

      // (3) Design Style (Mid Left)
      const box3R = ui.Rect.fromLTWH(contentX, 250, 245, 140);
      drawCard(g, box3R);
      g.drawString('3  DESIGN STYLE', h3Font, brush: PdfSolidBrush(accentLime), bounds: const ui.Rect.fromLTWH(contentX + 12, 260, 220, 16));
      g.drawString('TYPOGRAPHY & VISUALS', captionFont, brush: PdfSolidBrush(textMuted), bounds: const ui.Rect.fromLTWH(contentX + 12, 278, 220, 12));
      g.drawString('Clean · Modern · High readability · Minimal clutter', captionFont, brush: PdfSolidBrush(textOffWhite), bounds: const ui.Rect.fromLTWH(contentX + 12, 292, 220, 14));
      g.drawString(
        proposal.typographySampleHeadline,
        bodyBold,
        brush: PdfSolidBrush(textWhite),
        bounds: const ui.Rect.fromLTWH(contentX + 12, 310, 220, 16),
      );
      g.drawString('Editorial-inspired · Lifestyle focused · Bright & welcoming', captionFont, brush: PdfSolidBrush(accentLime), bounds: const ui.Rect.fromLTWH(contentX + 12, 330, 220, 14));
      g.drawString('Strong imagery · Clear hierarchy · Consistent CTA placement', captionFont, brush: PdfSolidBrush(textOffWhite), bounds: const ui.Rect.fromLTWH(contentX + 12, 348, 220, 26));

      // (4) Brand Voice & Colour Direction (Mid Right)
      const box4R = ui.Rect.fromLTWH(contentX + 255, 250, 255, 140);
      drawCard(g, box4R);
      g.drawString('4  BRAND VOICE & COLOUR DIRECTION', h3Font, brush: PdfSolidBrush(accentLime), bounds: const ui.Rect.fromLTWH(contentX + 267, 260, 230, 16));
      g.drawString('TONE OF VOICE:', captionFont, brush: PdfSolidBrush(textMuted), bounds: const ui.Rect.fromLTWH(contentX + 267, 278, 110, 12));
      g.drawString('• Friendly: Approachable & welcoming\n• Informative: Helping customers decide\n• Aspirational: Inspiring customer dreams\n• Trustworthy: Track record & safety', captionFont, brush: PdfSolidBrush(textOffWhite), bounds: const ui.Rect.fromLTWH(contentX + 267, 292, 140, 52));

      // Swatches
      g.drawString('PALETTE:', captionFont, brush: PdfSolidBrush(textMuted), bounds: const ui.Rect.fromLTWH(contentX + 415, 278, 90, 12));
      double px = contentX + 415;
      final pal = proposal.brandPaletteHex.take(3).toList();
      for (final c in pal) {
        final cl = c.replaceAll('#', '');
        final r = int.tryParse(cl.substring(0, 2), radix: 16) ?? 16;
        final gr = int.tryParse(cl.substring(2, 4), radix: 16) ?? 185;
        final b = int.tryParse(cl.substring(4, 6), radix: 16) ?? 129;
        g.drawRectangle(brush: PdfSolidBrush(PdfColor(r, gr, b)), bounds: ui.Rect.fromLTWH(px, 294, 26, 26));
        px += 30;
      }

      // (5) Instagram Feed Preview Strip
      const box5R = ui.Rect.fromLTWH(contentX, 396, contentWidth, 48);
      drawCard(g, box5R);
      g.drawString('5  SAMPLE INSTAGRAM FEED PREVIEW', captionFont, brush: PdfSolidBrush(accentLime), bounds: const ui.Rect.fromLTWH(contentX + 12, 402, 250, 12));
      final feedItems = ['Experience Story', 'Educational', 'Celebration', 'Corporate', 'Testimonial', 'Destination', 'Educational', 'Experience', 'Promotional'];
      double ix = contentX + 12;
      const iw = (contentWidth - 24) / 9;
      for (final item in feedItems) {
        g.drawRectangle(brush: PdfSolidBrush(PdfColor(25, 34, 34)), bounds: ui.Rect.fromLTWH(ix, 418, iw - 4, 20));
        g.drawString(item, PdfStandardFont(PdfFontFamily.helvetica, 6.5), brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(ix, 423, iw - 4, 12), format: PdfStringFormat(alignment: PdfTextAlignment.center));
        ix += iw;
      }

      // (6) Monthly Content Framework (4 Weeks Table)
      const fwTop = 450.0;
      g.drawString('EXAMPLE MONTHLY CONTENT FRAMEWORK (4 WEEKS)', h3Font, brush: PdfSolidBrush(accentLime), bounds: const ui.Rect.fromLTWH(contentX, fwTop, contentWidth, 16));

      final tableHeaders = ['WEEK', 'EXPERIENCE STORIES', 'EDUCATIONAL', 'CORPORATE', 'TESTIMONIALS', 'PROMOTIONAL', 'EXAMPLES'];
      final colWidths = [45.0, 85.0, 78.0, 78.0, 72.0, 72.0, 80.0];

      // Table Header Row
      double thx = contentX;
      for (int i = 0; i < tableHeaders.length; i++) {
        final w = colWidths[i];
        g.drawRectangle(brush: PdfSolidBrush(PdfColor(15, 23, 42)), pen: PdfPen(cardBorder, width: 0.5), bounds: ui.Rect.fromLTWH(thx, fwTop + 18, w, 18));
        g.drawString(tableHeaders[i], PdfStandardFont(PdfFontFamily.helvetica, 6.5, style: PdfFontStyle.bold), brush: PdfSolidBrush(accentLime), bounds: ui.Rect.fromLTWH(thx + 2, fwTop + 22, w - 4, 12), format: PdfStringFormat(alignment: PdfTextAlignment.center));
        thx += w;
      }

      // Table Data Rows (4 Weeks)
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
          g.drawRectangle(brush: PdfSolidBrush(PdfColor(18, 24, 24)), pen: PdfPen(cardBorder, width: 0.5), bounds: ui.Rect.fromLTWH(cellX, rowY, cw, 60));
          g.drawString(
            cells[i],
            PdfStandardFont(PdfFontFamily.helvetica, 6.5),
            brush: PdfSolidBrush(i == 0 ? accentLime : textOffWhite),
            bounds: ui.Rect.fromLTWH(cellX + 3, rowY + 5, cw - 6, 50),
          );
          cellX += cw;
        }
        rowY += 60;
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

      // Gradient / Atmospheric Backdrop inside phone
      g.drawRectangle(
        brush: PdfSolidBrush(PdfColor(15, 34, 45)),
        bounds: ui.Rect.fromLTWH(phoneX + 4, phoneY + 4, phoneW - 8, phoneH - 8),
      );

      // Hero Headline Overlay (e.g. "Live in the moment")
      final headline = proposal.sampleReelHeadline.isNotEmpty ? proposal.sampleReelHeadline : 'Live in the moment';
      g.drawString(
        headline,
        PdfStandardFont(PdfFontFamily.helvetica, 24, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(textWhite),
        bounds: ui.Rect.fromLTWH(phoneX + 15, phoneY + 160, phoneW - 30, 80),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );

      g.drawString(
        proposal.sampleReelTopic.isNotEmpty ? proposal.sampleReelTopic : 'A Milestone Celebration On The Water',
        captionFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: ui.Rect.fromLTWH(phoneX + 15, phoneY + 245, phoneW - 30, 30),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );

      // Bottom Clickable Link "View Reel Here"
      const linkRect = ui.Rect.fromLTWH(contentX, 610, contentWidth, 26);
      g.drawString(
        'View Reel Here',
        PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: linkRect,
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );

      // Add interactive PDF hyperlink annotation!
      final reelUri = proposal.sampleReelLink.isNotEmpty ? proposal.sampleReelLink : 'https://meet-marketers.com/reels';
      page.annotations.add(PdfUriAnnotation(bounds: linkRect, uri: reelUri));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PAGE 10: Sample Social Media Copywriting/Caption (Matching Reference Deck)
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      drawDarkBase(page);

      drawSectionTitle(g, 'Sample Social Media Copywriting/Caption', 40);

      // 3 Multi-Angle Social Media Post Cards matching Image 3
      final posts = proposal.socialPosts.isNotEmpty
          ? proposal.socialPosts
          : [
              {
                'headline': 'YOUR TEAM DESERVES BETTER THAN A HOTEL BALLROOM.',
                'body': 'Team bonding works when people stop feeling like they\'re at work.\n\nA 5-hour private charter does that faster than any workshop or lunch outing.\n\nProfessional crew, charcoal BBQ, water activities, Singapore skyline on the way back.\n\nNo GST. No hidden fees. Just book and show up.\n\nDM us or WhatsApp 8661 7600 to lock in your date.',
                'badge': 'NO GST · PRIVATE YACHT',
                'hashtags': ['#CorporateEventsSingapore', '#TeamBondingSingapore', '#YachtCharterSG'],
              },
              {
                'headline': 'Turning 30?',
                'body': 'No restaurant private room. No shared space. No two-hour limit.\n\nJust your group, a private catamaran, charcoal BBQ, and five hours on the water.\n\nThis is what a birthday actually feels like when it\'s done right.\n\nCheck availability for your date via link in bio or WhatsApp at 8661 7600.',
                'badge': 'FROM \$849 · PRIVATE YACHT',
                'hashtags': ['#BirthdayCelebrationSG', '#Turning30', '#PrivateYachtSG'],
              },
              {
                'headline': 'It was the best birthday I\'ve ever had.',
                'body': 'When your guests say that on the way back to the marina, the planning was worth it.\n\nPrivate catamarans from \$649. Full crew included. Charcoal BBQ available. No surprise charges.\n\nWe\'ve been doing this since 2011. Book with confidence.\n\nwhitesails.com.sg or WhatsApp 8661 7600.',
                'badge': '16,000+ GUESTS · 1,550+ TRIPS · 14 YEARS',
                'hashtags': ['#YachtCharterSingapore', '#PrivateYacht', '#WhiteSailsSG'],
              },
            ];

      // Post 1 (Top Left)
      final p1 = posts[0];
      const p1Rect = ui.Rect.fromLTWH(contentX, 85, 245, 310);
      drawCard(g, p1Rect);
      g.drawString(p1['headline'] as String? ?? '', h3Font, brush: PdfSolidBrush(accentLime), bounds: const ui.Rect.fromLTWH(contentX + 12, 95, 220, 36));
      g.drawString(p1['body'] as String? ?? '', captionFont, brush: PdfSolidBrush(textOffWhite), bounds: const ui.Rect.fromLTWH(contentX + 12, 135, 220, 190));
      g.drawString(p1['badge'] as String? ?? '', captionFont, brush: PdfSolidBrush(accentLime), bounds: const ui.Rect.fromLTWH(contentX + 12, 335, 220, 16));
      final hts1 = (p1['hashtags'] as List?)?.join(' ') ?? '';
      g.drawString(hts1, captionFont, brush: PdfSolidBrush(textMuted), bounds: const ui.Rect.fromLTWH(contentX + 12, 355, 220, 30));

      // Post 2 (Top Right)
      final p2 = posts.length > 1 ? posts[1] : posts[0];
      const p2Rect = ui.Rect.fromLTWH(contentX + 255, 85, 255, 310);
      drawCard(g, p2Rect);
      g.drawString(p2['headline'] as String? ?? '', h2Font, brush: PdfSolidBrush(accentLime), bounds: const ui.Rect.fromLTWH(contentX + 267, 95, 230, 30));
      g.drawString(p2['body'] as String? ?? '', captionFont, brush: PdfSolidBrush(textOffWhite), bounds: const ui.Rect.fromLTWH(contentX + 267, 135, 230, 190));
      g.drawString(p2['badge'] as String? ?? '', captionFont, brush: PdfSolidBrush(accentLime), bounds: const ui.Rect.fromLTWH(contentX + 267, 335, 230, 16));
      final hts2 = (p2['hashtags'] as List?)?.join(' ') ?? '';
      g.drawString(hts2, captionFont, brush: PdfSolidBrush(textMuted), bounds: const ui.Rect.fromLTWH(contentX + 267, 355, 230, 30));

      // Post 3 (Bottom Centered Card)
      final p3 = posts.length > 2 ? posts[2] : posts[0];
      const p3Rect = ui.Rect.fromLTWH(contentX, 410, contentWidth, 310);
      drawCard(g, p3Rect);
      g.drawString('“${p3['headline']}”', h2Font, brush: PdfSolidBrush(accentLime), bounds: const ui.Rect.fromLTWH(contentX + 20, 422, contentWidth - 40, 26));
      g.drawString(p3['body'] as String? ?? '', bodyFont, brush: PdfSolidBrush(textOffWhite), bounds: const ui.Rect.fromLTWH(contentX + 20, 455, contentWidth - 40, 170));
      g.drawString(p3['badge'] as String? ?? '', h3Font, brush: PdfSolidBrush(accentLime), bounds: const ui.Rect.fromLTWH(contentX + 20, 635, contentWidth - 40, 18));
      final hts3 = (p3['hashtags'] as List?)?.join(' ') ?? '';
      g.drawString(hts3, captionFont, brush: PdfSolidBrush(textMuted), bounds: const ui.Rect.fromLTWH(contentX + 20, 660, contentWidth - 40, 40));
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
    // PAGE 12: SEO & Digital Presence Opportunities (Matching Image 4)
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      drawDarkBase(page);

      drawSectionTitle(g, 'SEO & Digital Presence Opportunities', 40);

      // Current SEO Score in Lime Green
      g.drawString('Current SEO Score', h3Font, brush: PdfSolidBrush(accentLime), bounds: const ui.Rect.fromLTWH(contentX, 85, contentWidth, 18));
      g.drawString('${proposal.seoAudit.healthScore} / 100', PdfStandardFont(PdfFontFamily.helvetica, 30, style: PdfFontStyle.bold), brush: PdfSolidBrush(accentLime), bounds: const ui.Rect.fromLTWH(contentX, 105, contentWidth, 38));

      // Summary narrative
      g.drawString(
        proposal.seoAudit.summaryText.isNotEmpty
            ? proposal.seoAudit.summaryText
            : '${proposal.leadCompanyName} has established a solid SEO foundation, with HTTPS security, mobile responsiveness, optimised WebP images, canonical tags and an active content strategy already in place. However, several high-impact technical and content opportunities remain that could significantly improve search visibility and lead generation.',
        bodyFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: const ui.Rect.fromLTWH(contentX, 150, contentWidth, 65),
      );

      // Card 1: High Priority (Rounded Dark Pill Card)
      const highR = ui.Rect.fromLTWH(contentX, 230, contentWidth, 140);
      drawCard(g, highR);
      g.drawString('High Priority', h3Font, brush: PdfSolidBrush(accentLime), bounds: const ui.Rect.fromLTWH(contentX + 20, 245, contentWidth - 40, 18));
      final highs = proposal.seoAudit.highPriority.isNotEmpty
          ? proposal.seoAudit.highPriority
          : ['Occasion-specific landing pages', 'Structured data implementation', 'Review schema markup', 'Improved H1 optimisation'];
      double hy = 270;
      for (final h in highs.take(4)) {
        g.drawString('•  $h', bodyFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + 20, hy, contentWidth - 40, 18));
        hy += 20;
      }

      // Card 2: Medium Priority (Rounded Dark Pill Card)
      const medR = ui.Rect.fromLTWH(contentX, 390, contentWidth, 120);
      drawCard(g, medR);
      g.drawString('Medium Priority', h3Font, brush: PdfSolidBrush(accentLime), bounds: const ui.Rect.fromLTWH(contentX + 20, 405, contentWidth - 40, 18));
      final meds = proposal.seoAudit.mediumPriority.isNotEmpty
          ? proposal.seoAudit.mediumPriority
          : ['Yacht detail page optimisation', 'Open Graph implementation', 'Author markup'];
      double my = 430;
      for (final m in meds.take(3)) {
        g.drawString('•  $m', bodyFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + 20, my, contentWidth - 40, 18));
        my += 20;
      }

      // Card 3: Long-Term Opportunities (Rounded Dark Pill Card)
      const longR = ui.Rect.fromLTWH(contentX, 530, contentWidth, 120);
      drawCard(g, longR);
      g.drawString('Long-Term Opportunities', h3Font, brush: PdfSolidBrush(accentLime), bounds: const ui.Rect.fromLTWH(contentX + 20, 545, contentWidth - 40, 18));
      final longs = proposal.seoAudit.longTermOpportunities.isNotEmpty
          ? proposal.seoAudit.longTermOpportunities
          : ['AI search visibility', 'Educational content ecosystem', 'Corporate-focused landing pages'];
      double ly = 570;
      for (final l in longs.take(3)) {
        g.drawString('•  $l', bodyFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + 20, ly, contentWidth - 40, 18));
        ly += 20;
      }

      // Bottom Link: View Full SEO/AIO Audit Here
      const auditLinkR = ui.Rect.fromLTWH(contentX, 675, contentWidth, 24);
      g.drawString(
        'View Full SEO/AIO Audit Here',
        PdfStandardFont(PdfFontFamily.helvetica, 13, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: auditLinkR,
      );
      final auditUri = proposal.seoAuditLink.isNotEmpty ? proposal.seoAuditLink : 'https://meet-marketers.com/seo-audit';
      page.annotations.add(PdfUriAnnotation(bounds: auditLinkR, uri: auditUri));
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
