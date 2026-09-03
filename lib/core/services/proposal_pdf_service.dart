import 'dart:ui' as ui;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../data/models/proposal_model.dart';
import 'web_download_helper.dart';

/// Service to generate and export professional 13-section proposals
/// styled with the exact dark luxury & lime-accent design shown in the sample images.
class ProposalPdfService {
  static final ProposalPdfService instance = ProposalPdfService._internal();
  ProposalPdfService._internal();

  /// Compiles a complete 13-page PDF proposal with dark background & lime accents
  Future<List<int>> generateProposalPdf(ProposalModel proposal) async {
    final document = PdfDocument();
    document.pageSettings.size = PdfPageSize.a4;
    document.pageSettings.margins.all = 0; // Full bleed for dark theme

    const pageWidth = 595.28;
    const pageHeight = 841.89;
    const contentX = 42.0;
    const contentWidth = 511.28;

    // ── Exact Design Color Palette from Sample Images ────────────
    final bgDark = PdfColor(13, 17, 17); // #0D1111 (deep dark)
    final bgGlowTop = PdfColor(18, 48, 30); // Soft dark emerald wash top
    final bgGlowBottom = PdfColor(14, 38, 24); // Soft dark emerald wash bottom
    final bgCard = PdfColor(22, 27, 27); // #161B1B (card surface)
    final cardBorder = PdfColor(44, 54, 54); // #2C3636
    final tableBorder = PdfColor(55, 65, 65); // #374141
    final accentLime = PdfColor(163, 230, 53); // #A3E635 (vibrant lime green)
    final textWhite = PdfColor(255, 255, 255);
    final textOffWhite = PdfColor(226, 232, 240); // #E2E8F0
    final textMuted = PdfColor(148, 163, 184); // #94A3B8
    final textBlack = PdfColor(10, 13, 13); // #0A0D0D

    // ── Typography ───────────────────────────────────────────────
    final titleFont = PdfStandardFont(PdfFontFamily.helvetica, 30, style: PdfFontStyle.bold);
    final h1Font = PdfStandardFont(PdfFontFamily.helvetica, 22, style: PdfFontStyle.bold);
    final h2Font = PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold);
    final h3Font = PdfStandardFont(PdfFontFamily.helvetica, 11, style: PdfFontStyle.bold);
    final bodyFont = PdfStandardFont(PdfFontFamily.helvetica, 9.5);
    final bodyBold = PdfStandardFont(PdfFontFamily.helvetica, 9.5, style: PdfFontStyle.bold);
    final captionFont = PdfStandardFont(PdfFontFamily.helvetica, 8);

    // ── Helper: Draw Dark Background with Soft Glows & Footer ────
    void drawDarkBase(PdfPage page, {bool isCover = false}) {
      final g = page.graphics;

      // 1. Fill deep dark base
      g.drawRectangle(
        brush: PdfSolidBrush(bgDark),
        bounds: const ui.Rect.fromLTWH(0, 0, pageWidth, pageHeight),
      );

      // 2. Corner Ambient Glows
      g.drawEllipse(
        const ui.Rect.fromLTWH(-90, -90, 360, 360),
        brush: PdfSolidBrush(bgGlowTop),
      );
      g.drawEllipse(
        const ui.Rect.fromLTWH(pageWidth - 270, pageHeight - 270, 360, 360),
        brush: PdfSolidBrush(bgGlowBottom),
      );

      // 3. Centered Footer
      g.drawString(
        'Meet Marketers © 2026',
        captionFont,
        brush: PdfSolidBrush(textMuted),
        bounds: const ui.Rect.fromLTWH(0, pageHeight - 28, pageWidth, 14),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
    }

    // ── Helper: Draw Meet Marketers Brand Logo ───────────────────
    void drawMeetMarketersLogo(PdfGraphics g, double x, double y) {
      // Draw stylized 'MM' icon
      final logoPen = PdfPen(PdfColor(170, 180, 185), width: 3.5);
      // M 1
      g.drawLine(logoPen, ui.Offset(x, y + 16), ui.Offset(x + 5, y));
      g.drawLine(logoPen, ui.Offset(x + 5, y), ui.Offset(x + 10, y + 10));
      g.drawLine(logoPen, ui.Offset(x + 10, y + 10), ui.Offset(x + 15, y));
      g.drawLine(logoPen, ui.Offset(x + 15, y), ui.Offset(x + 20, y + 16));

      // M 2 (slightly offset layered behind)
      final logoPen2 = PdfPen(PdfColor(130, 140, 145), width: 3.5);
      g.drawLine(logoPen2, ui.Offset(x + 12, y + 16), ui.Offset(x + 17, y));
      g.drawLine(logoPen2, ui.Offset(x + 17, y), ui.Offset(x + 22, y + 10));
      g.drawLine(logoPen2, ui.Offset(x + 22, y + 10), ui.Offset(x + 27, y));
      g.drawLine(logoPen2, ui.Offset(x + 27, y), ui.Offset(x + 32, y + 16));

      // Brand Wordmark: "MEET MARKETERS"
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

    // ── Helper: Draw Section Header (Page Title) in Lime Green ───
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
        brush: PdfSolidBrush(PdfColor(17, 22, 22)),
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
      drawDarkBase(page, isCover: true);

      // 1. Logo at Top
      drawMeetMarketersLogo(g, contentX, 90);

      // 2. Main Title (Huge bold Lime Green)
      g.drawString(
        'Digital & Content\nDirection Proposal',
        titleFont,
        brush: PdfSolidBrush(accentLime),
        bounds: const ui.Rect.fromLTWH(contentX, 260, contentWidth, 80),
      );

      // 3. Subtitle in Clean White
      g.drawString(
        'Prepared for ${proposal.leadCompanyName}',
        PdfStandardFont(PdfFontFamily.helvetica, 15, style: PdfFontStyle.regular),
        brush: PdfSolidBrush(textWhite),
        bounds: const ui.Rect.fromLTWH(contentX, 350, contentWidth, 24),
      );

      // 4. CONTENTS Section
      double curY = 410;
      g.drawString(
        'CONTENTS',
        PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(accentLime),
        bounds: ui.Rect.fromLTWH(contentX, curY, contentWidth, 16),
      );
      curY += 20;

      // Marketing Strategy
      g.drawString(
        'Marketing Strategy',
        h3Font,
        brush: PdfSolidBrush(accentLime),
        bounds: ui.Rect.fromLTWH(contentX, curY, contentWidth, 16),
      );
      curY += 16;

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
          bounds: ui.Rect.fromLTWH(contentX, curY, contentWidth, 15),
        );
        curY += 15;
      }

      curY += 6;
      // Marketing Operation
      g.drawString(
        'Marketing Operation',
        h3Font,
        brush: PdfSolidBrush(accentLime),
        bounds: ui.Rect.fromLTWH(contentX, curY, contentWidth, 16),
      );
      curY += 16;

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
          bounds: ui.Rect.fromLTWH(contentX, curY, contentWidth, 15),
        );
        curY += 15;
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
        PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(PdfColor(56, 189, 248)), // Soft blue accent
        bounds: const ui.Rect.fromLTWH(0, 50, pageWidth, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      g.drawString(
        'STRATEGIC AUDIT & DIRECTION',
        captionFont,
        brush: PdfSolidBrush(textMuted),
        bounds: const ui.Rect.fromLTWH(0, 70, pageWidth, 14),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );

      // Current Position & Opportunity Card
      const cardRect = ui.Rect.fromLTWH(contentX, 100, contentWidth, 230);
      drawCard(g, cardRect);

      double cy = 120;
      g.drawString(
        'Current Position',
        h2Font,
        brush: PdfSolidBrush(textWhite),
        bounds: const ui.Rect.fromLTWH(contentX + 24, 120, contentWidth - 48, 20),
      );
      cy += 24;

      final posText = proposal.executiveSummaryPosition.isNotEmpty
          ? proposal.executiveSummaryPosition
          : '${proposal.leadCompanyName} is an established provider in ${proposal.industry}, serving clients with verified credibility and reliable service quality.';
      g.drawString(
        posText,
        bodyFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: ui.Rect.fromLTWH(contentX + 24, cy, contentWidth - 48, 65),
      );

      cy += 70;
      g.drawString(
        'Opportunity',
        h2Font,
        brush: PdfSolidBrush(textWhite),
        bounds: ui.Rect.fromLTWH(contentX + 24, cy, contentWidth - 48, 20),
      );
      cy += 24;

      final oppText = proposal.executiveSummaryOpportunity.isNotEmpty
          ? proposal.executiveSummaryOpportunity
          : 'Significant opportunity exists to strengthen organic search visibility, corporate authority, and high-converting video storytelling across digital channels.';
      g.drawString(
        oppText,
        bodyFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: ui.Rect.fromLTWH(contentX + 24, cy, contentWidth - 48, 65),
      );

      // ── SWOT Analysis Section Heading (Lime Green) ────────────
      drawSectionTitle(g, 'SWOT Analysis', 355);

      // ── 2x2 SWOT Matrix ───────────────────────────────────────
      const swotTop = 395.0;
      const colWidth = (contentWidth) / 2.0; // ~255.6 pt each
      const headerH = 26.0;
      const cellH = 155.0;

      // Row 1: Strength & Weaknesses
      drawTableHeader(g, 'Strength', const ui.Rect.fromLTWH(contentX, swotTop, colWidth, headerH));
      drawTableHeader(g, 'Weaknesses', const ui.Rect.fromLTWH(contentX + colWidth, swotTop, colWidth, headerH));

      drawTableCell(g, const ui.Rect.fromLTWH(contentX, swotTop + headerH, colWidth, cellH));
      drawTableCell(g, const ui.Rect.fromLTWH(contentX + colWidth, swotTop + headerH, colWidth, cellH));

      // Strengths text
      double ty = swotTop + headerH + 12;
      for (final s in proposal.swot.strengths.take(4)) {
        g.drawString('•  $s', bodyFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + 10, ty, colWidth - 20, 32));
        ty += 32;
      }

      // Weaknesses text
      ty = swotTop + headerH + 12;
      for (final w in proposal.swot.weaknesses.take(4)) {
        g.drawString('•  $w', bodyFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + colWidth + 10, ty, colWidth - 20, 32));
        ty += 32;
      }

      // Row 2: Opportunities & Threats
      const row2Top = swotTop + headerH + cellH;
      drawTableHeader(g, 'Opportunities', const ui.Rect.fromLTWH(contentX, row2Top, colWidth, headerH));
      drawTableHeader(g, 'Threats', const ui.Rect.fromLTWH(contentX + colWidth, row2Top, colWidth, headerH));

      drawTableCell(g, const ui.Rect.fromLTWH(contentX, row2Top + headerH, colWidth, cellH));
      drawTableCell(g, const ui.Rect.fromLTWH(contentX + colWidth, row2Top + headerH, colWidth, cellH));

      // Opportunities text
      ty = row2Top + headerH + 12;
      for (final o in proposal.swot.opportunities.take(4)) {
        g.drawString('•  $o', bodyFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + 10, ty, colWidth - 20, 32));
        ty += 32;
      }

      // Threats text
      ty = row2Top + headerH + 12;
      for (final t in proposal.swot.threats.take(4)) {
        g.drawString('•  $t', bodyFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + colWidth + 10, ty, colWidth - 20, 32));
        ty += 32;
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PAGE 3: 4Ps Analysis
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      drawDarkBase(page);

      drawSectionTitle(g, '4Ps Analysis', 60);

      const pTop = 110.0;
      const colWidth = (contentWidth) / 2.0;
      const headerH = 26.0;
      const cellH = 310.0;

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
        bounds: ui.Rect.fromLTWH(contentX + 14, py, colWidth - 28, 90),
      );
      py += 105;
      g.drawString('Opportunity', bodyBold, brush: PdfSolidBrush(textWhite), bounds: ui.Rect.fromLTWH(contentX + 14, py, colWidth - 28, 16));
      py += 18;
      g.drawString(
        proposal.marketingMix4Ps.productOpportunity.isNotEmpty ? proposal.marketingMix4Ps.productOpportunity : 'Strengthen differentiation by communicating outcomes rather than just technical inclusions.',
        bodyFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: ui.Rect.fromLTWH(contentX + 14, py, colWidth - 28, 140),
      );

      // Price content
      py = pTop + headerH + 14;
      g.drawString('Current Position', bodyBold, brush: PdfSolidBrush(textWhite), bounds: ui.Rect.fromLTWH(contentX + colWidth + 14, py, colWidth - 28, 16));
      py += 18;
      g.drawString(
        proposal.marketingMix4Ps.priceCurrent.isNotEmpty ? proposal.marketingMix4Ps.priceCurrent : 'Mid-to-premium pricing supported by experienced team, safety, and brand reputation.',
        bodyFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: ui.Rect.fromLTWH(contentX + colWidth + 14, py, colWidth - 28, 90),
      );
      py += 105;
      g.drawString('Opportunity', bodyBold, brush: PdfSolidBrush(textWhite), bounds: ui.Rect.fromLTWH(contentX + colWidth + 14, py, colWidth - 28, 16));
      py += 18;
      g.drawString(
        proposal.marketingMix4Ps.priceOpportunity.isNotEmpty ? proposal.marketingMix4Ps.priceOpportunity : 'Continue competing on experience value, safety, and reliability rather than commoditized discounting.',
        bodyFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: ui.Rect.fromLTWH(contentX + colWidth + 14, py, colWidth - 28, 140),
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
        bounds: ui.Rect.fromLTWH(contentX + 14, py, colWidth - 28, 90),
      );
      py += 105;
      g.drawString('Opportunity', bodyBold, brush: PdfSolidBrush(textWhite), bounds: ui.Rect.fromLTWH(contentX + 14, py, colWidth - 28, 16));
      py += 18;
      g.drawString(
        proposal.marketingMix4Ps.placeOpportunity.isNotEmpty ? proposal.marketingMix4Ps.placeOpportunity : 'Improve organic discoverability, corporate B2B channels, and strategic co-marketing partnerships.',
        bodyFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: ui.Rect.fromLTWH(contentX + 14, py, colWidth - 28, 140),
      );

      // Promotion content
      py = row2Top + headerH + 14;
      g.drawString('Current Approach', bodyBold, brush: PdfSolidBrush(textWhite), bounds: ui.Rect.fromLTWH(contentX + colWidth + 14, py, colWidth - 28, 16));
      py += 18;
      g.drawString(
        proposal.marketingMix4Ps.promotionCurrent.isNotEmpty ? proposal.marketingMix4Ps.promotionCurrent : 'Highlights customer celebrations, promotional offers, and customer reviews.',
        bodyFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: ui.Rect.fromLTWH(contentX + colWidth + 14, py, colWidth - 28, 90),
      );
      py += 105;
      g.drawString('Opportunity', bodyBold, brush: PdfSolidBrush(textWhite), bounds: ui.Rect.fromLTWH(contentX + colWidth + 14, py, colWidth - 28, 16));
      py += 18;
      g.drawString(
        proposal.marketingMix4Ps.promotionOpportunity.isNotEmpty ? proposal.marketingMix4Ps.promotionOpportunity : 'Expand into educational authority reels, customer journey transformation stories, and deep-dive guides.',
        bodyFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: ui.Rect.fromLTWH(contentX + colWidth + 14, py, colWidth - 28, 140),
      );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PAGE 4: PEST Analysis & Competitor / USP Analysis
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      drawDarkBase(page);

      // 1. PEST Analysis Heading
      drawSectionTitle(g, 'PEST Analysis', 50);

      const pestTop = 85.0;
      const colWidth = (contentWidth) / 2.0;
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

      // 2. Competitor Analysis Heading
      double curY = row2Top + headerH + cellH + 20;
      drawSectionTitle(g, 'Competitor Analysis', curY);
      curY += 32;

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

      // 3. USP Analysis Heading
      curY += 12;
      drawSectionTitle(g, 'USP Analysis', curY);
      curY += 32;

      // USP Table
      const brandColW = 160.0;
      final uspColW = contentWidth - brandColW;
      const uspHeaderH = 26.0;

      // Table Header Row in Lime Green
      drawTableHeader(g, 'Brand', ui.Rect.fromLTWH(contentX, curY, brandColW, uspHeaderH));
      drawTableHeader(g, 'Primary USP', ui.Rect.fromLTWH(contentX + brandColW, curY, uspColW, uspHeaderH));
      curY += uspHeaderH;

      // Table Rows
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

        // Brand name
        g.drawString(
          c.brandName,
          c.isLeadBrand ? bodyBold : bodyFont,
          brush: PdfSolidBrush(c.isLeadBrand ? accentLime : textWhite),
          bounds: ui.Rect.fromLTWH(contentX + 10, curY + 9, brandColW - 20, 18),
        );

        // USP
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
    // PAGE 5: Perceptual Map & Strategic Positioning
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      drawDarkBase(page);

      drawSectionTitle(g, 'Perceptual Map', 50);

      // Graph Subtitle
      g.drawString(
        '${proposal.industry.isNotEmpty ? proposal.industry : proposal.leadCompanyName} Market Positioning',
        h3Font,
        brush: PdfSolidBrush(textWhite),
        bounds: const ui.Rect.fromLTWH(0, 85, pageWidth, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );

      // ── Coordinate Cross Graph ─────────────────────────────────
      const graphCenterX = pageWidth / 2.0; // 297.64
      const graphCenterY = 240.0;
      const axisLen = 145.0;

      final axisPen = PdfPen(textWhite, width: 1.2);

      // Vertical Axis (Y)
      g.drawLine(axisPen, ui.Offset(graphCenterX, graphCenterY - axisLen), ui.Offset(graphCenterX, graphCenterY + axisLen));
      // Top Arrow
      g.drawLine(axisPen, ui.Offset(graphCenterX - 5, graphCenterY - axisLen + 8), ui.Offset(graphCenterX, graphCenterY - axisLen));
      g.drawLine(axisPen, ui.Offset(graphCenterX + 5, graphCenterY - axisLen + 8), ui.Offset(graphCenterX, graphCenterY - axisLen));
      // Bottom Arrow
      g.drawLine(axisPen, ui.Offset(graphCenterX - 5, graphCenterY + axisLen - 8), ui.Offset(graphCenterX, graphCenterY + axisLen));
      g.drawLine(axisPen, ui.Offset(graphCenterX + 5, graphCenterY + axisLen - 8), ui.Offset(graphCenterX, graphCenterY + axisLen));

      // Horizontal Axis (X)
      g.drawLine(axisPen, ui.Offset(graphCenterX - axisLen, graphCenterY), ui.Offset(graphCenterX + axisLen, graphCenterY));
      // Left Arrow
      g.drawLine(axisPen, ui.Offset(graphCenterX - axisLen + 8, graphCenterY - 5), ui.Offset(graphCenterX - axisLen, graphCenterY));
      g.drawLine(axisPen, ui.Offset(graphCenterX - axisLen + 8, graphCenterY + 5), ui.Offset(graphCenterX - axisLen, graphCenterY));
      // Right Arrow
      g.drawLine(axisPen, ui.Offset(graphCenterX + axisLen - 8, graphCenterY - 5), ui.Offset(graphCenterX + axisLen, graphCenterY));
      g.drawLine(axisPen, ui.Offset(graphCenterX + axisLen - 8, graphCenterY + 5), ui.Offset(graphCenterX + axisLen, graphCenterY));

      // Axis Labels
      // Top
      g.drawString(
        'HIGH\nPremium Experience Perception',
        captionFont,
        brush: PdfSolidBrush(textWhite),
        bounds: const ui.Rect.fromLTWH(graphCenterX - 80, graphCenterY - axisLen - 28, 160, 24),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      // Bottom
      g.drawString(
        'LOW\nPremium Experience Perception',
        captionFont,
        brush: PdfSolidBrush(textWhite),
        bounds: const ui.Rect.fromLTWH(graphCenterX - 80, graphCenterY + axisLen + 8, 160, 24),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      // Left
      g.drawString(
        'LOW\nService Breadth',
        captionFont,
        brush: PdfSolidBrush(textWhite),
        bounds: const ui.Rect.fromLTWH(graphCenterX - axisLen - 75, graphCenterY - 12, 70, 24),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      // Right
      g.drawString(
        'HIGH\nService Breadth',
        captionFont,
        brush: PdfSolidBrush(textWhite),
        bounds: const ui.Rect.fromLTWH(graphCenterX + axisLen + 5, graphCenterY - 12, 70, 24),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );

      // ── Plotted Brands in 4 Quadrants ─────────────────────────
      // Quadrant 1 (Top Left): Lead Brand
      g.drawString(
        proposal.leadCompanyName.toUpperCase(),
        bodyBold,
        brush: PdfSolidBrush(accentLime),
        bounds: const ui.Rect.fromLTWH(contentX + 15, graphCenterY - 95, 150, 16),
      );
      g.drawString(
        'Strong balance of premium experiences with wide range of offerings for diverse clients.',
        captionFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: const ui.Rect.fromLTWH(contentX + 15, graphCenterY - 78, 140, 36),
      );

      // Quadrant 2 (Top Right): Competitor 1
      g.drawString(
        'CATEGORY PEER A',
        bodyBold,
        brush: PdfSolidBrush(textWhite),
        bounds: const ui.Rect.fromLTWH(graphCenterX + 45, graphCenterY - 95, 150, 16),
      );
      g.drawString(
        'Niche luxury focus with limited accessibility.',
        captionFont,
        brush: PdfSolidBrush(textMuted),
        bounds: const ui.Rect.fromLTWH(graphCenterX + 45, graphCenterY - 78, 130, 24),
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

      // ── Bottom Insight Card ───────────────────────────────────
      const insightCardRect = ui.Rect.fromLTWH(contentX, 480, contentWidth, 270);
      drawCard(g, insightCardRect);

      double iy = 505;
      g.drawString(
        'KEY INSIGHT',
        h3Font,
        brush: PdfSolidBrush(accentLime),
        bounds: const ui.Rect.fromLTWH(contentX + 24, 505, contentWidth - 48, 18),
      );
      iy += 22;

      final insightText = proposal.perceptualMapInsight.isNotEmpty
          ? proposal.perceptualMapInsight
          : '${proposal.leadCompanyName} occupies a strong strategic position between premium experiences and broad service offerings. Unlike niche operators that focus narrowly, ${proposal.leadCompanyName} caters to high-stakes milestone celebrations, corporate events, and family moments.';
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
          : 'Strengthen brand visibility and digital authority to reinforce ${proposal.leadCompanyName} as the definitive category leader in its market.';
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

      drawSectionTitle(g, 'Creative Direction (Part 1)', 50);

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

      double curY = 100;
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

      drawSectionTitle(g, 'Creative Direction (Part 2)', 50);

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

      double curY = 100;
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
    // PAGE 8: Visual Guideline & Content Framework
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      drawDarkBase(page);

      drawSectionTitle(g, 'Visual Guideline & Framework', 50);

      // Aesthetic Notes Card
      const cardR = ui.Rect.fromLTWH(contentX, 100, contentWidth, 230);
      drawCard(g, cardR);

      g.drawString('Aesthetic Direction', h2Font, brush: PdfSolidBrush(accentLime), bounds: const ui.Rect.fromLTWH(contentX + 20, 120, contentWidth - 40, 22));
      g.drawString(
        proposal.visualGuidelineNotes.isNotEmpty
            ? proposal.visualGuidelineNotes
            : 'Visual storytelling balances clean premium minimalism with vibrant authentic emotion. Crisp natural lighting, cinematic pacing, and consistent typography reinforce category leadership across all digital channels.',
        bodyFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: const ui.Rect.fromLTWH(contentX + 20, 150, contentWidth - 40, 60),
      );

      // Swatches
      g.drawString('Curated Brand Palette', h3Font, brush: PdfSolidBrush(textWhite), bounds: const ui.Rect.fromLTWH(contentX + 20, 220, contentWidth - 40, 18));
      double swatchX = contentX + 20;
      for (final hex in proposal.brandPaletteHex.take(5)) {
        final clean = hex.replaceAll('#', '');
        final r = int.tryParse(clean.substring(0, 2), radix: 16) ?? 163;
        final gr = int.tryParse(clean.substring(2, 4), radix: 16) ?? 230;
        final b = int.tryParse(clean.substring(4, 6), radix: 16) ?? 53;

        g.drawRectangle(
          brush: PdfSolidBrush(PdfColor(r, gr, b)),
          pen: PdfPen(textWhite, width: 1),
          bounds: ui.Rect.fromLTWH(swatchX, 245, 45, 45),
        );
        g.drawString(hex, captionFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(swatchX, 295, 45, 14), format: PdfStringFormat(alignment: PdfTextAlignment.center));
        swatchX += 65;
      }

      // 4-Step Framework
      const frameY = 360.0;
      g.drawString('High-Converting Short-Form Framework', h2Font, brush: PdfSolidBrush(accentLime), bounds: const ui.Rect.fromLTWH(contentX, frameY, contentWidth, 24));

      final steps = [
        {'step': 'HOOK (0-3s)', 'desc': 'Interrupt the scroll with a curiosity gap or emotional hook.'},
        {'step': 'RETAIN (3-15s)', 'desc': 'Build context and demonstrate immediate relevance.'},
        {'step': 'DELIVER (15-45s)', 'desc': 'Provide the payoff, reveal the behind-the-scenes or transformation.'},
        {'step': 'ACTION (45-60s)', 'desc': 'Direct call-to-action to save, share, or check availability.'},
      ];

      double sy = frameY + 36;
      for (final s in steps) {
        final stepR = ui.Rect.fromLTWH(contentX, sy, contentWidth, 68);
        drawCard(g, stepR);
        g.drawString(s['step']!, h3Font, brush: PdfSolidBrush(accentLime), bounds: ui.Rect.fromLTWH(contentX + 16, sy + 12, contentWidth - 32, 18));
        g.drawString(s['desc']!, bodyFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + 16, sy + 32, contentWidth - 32, 28));
        sy += 78;
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PAGE 9: Sample Reel Storyboard
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      drawDarkBase(page);

      drawSectionTitle(g, 'Sample Reel: Vertical Video Blueprint', 50);

      const cardR = ui.Rect.fromLTWH(contentX, 100, contentWidth, 650);
      drawCard(g, cardR);

      double ry = 125;
      g.drawString('Reel Topic', h3Font, brush: PdfSolidBrush(textWhite), bounds: const ui.Rect.fromLTWH(contentX + 24, 125, contentWidth - 48, 16));
      ry += 20;
      g.drawString(
        proposal.sampleReelTopic.isNotEmpty ? proposal.sampleReelTopic : 'Behind This Milestone Celebration with ${proposal.leadCompanyName}',
        h2Font,
        brush: PdfSolidBrush(accentLime),
        bounds: ui.Rect.fromLTWH(contentX + 24, ry, contentWidth - 48, 22),
      );

      ry += 40;
      g.drawString('The 3-Second Hook', h3Font, brush: PdfSolidBrush(textWhite), bounds: ui.Rect.fromLTWH(contentX + 24, ry, contentWidth - 48, 16));
      ry += 20;
      g.drawString(
        proposal.sampleReelHook.isNotEmpty ? '“${proposal.sampleReelHook}”' : '“Most people think planning an extraordinary experience takes months of stress. Watch what happened when they chose something different.”',
        bodyBold,
        brush: PdfSolidBrush(PdfColor(134, 239, 172)),
        bounds: ui.Rect.fromLTWH(contentX + 24, ry, contentWidth - 48, 50),
      );

      ry += 65;
      g.drawString('Visual Storyboard & Scenes', h3Font, brush: PdfSolidBrush(textWhite), bounds: ui.Rect.fromLTWH(contentX + 24, ry, contentWidth - 48, 16));
      ry += 22;
      final scenesText = proposal.sampleReelVisualScenes.isNotEmpty
          ? proposal.sampleReelVisualScenes
          : 'Scene 1: Golden hour horizon with sparkling water and laughter.\nScene 2: Close-up of personalized decor and toast with friends.\nScene 3: Unfiltered joyous reaction of the guest of honor.\nScene 4: Crew seamlessly attending to every detail while guests relax.';
      g.drawString(
        scenesText,
        bodyFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: ui.Rect.fromLTWH(contentX + 24, ry, contentWidth - 48, 180),
      );

      ry += 195;
      g.drawString('Call to Action (Outro)', h3Font, brush: PdfSolidBrush(textWhite), bounds: ui.Rect.fromLTWH(contentX + 24, ry, contentWidth - 48, 16));
      ry += 20;
      g.drawString(
        proposal.sampleReelCta.isNotEmpty ? proposal.sampleReelCta : 'Save this for your next milestone celebration or tap the link in bio to check date availability.',
        bodyFont,
        brush: PdfSolidBrush(accentLime),
        bounds: ui.Rect.fromLTWH(contentX + 24, ry, contentWidth - 48, 45),
      );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PAGE 10: Sample SEO Blog Article
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      drawDarkBase(page);

      drawSectionTitle(g, 'Sample Copywriting: SEO Pillar Blog', 50);

      const cardR = ui.Rect.fromLTWH(contentX, 100, contentWidth, 650);
      drawCard(g, cardR);

      double by = 130;
      g.drawString('Suggested Article Title', h3Font, brush: PdfSolidBrush(textWhite), bounds: const ui.Rect.fromLTWH(contentX + 24, 130, contentWidth - 48, 16));
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
    // PAGE 11: Sample Social Media Copywriting
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      drawDarkBase(page);

      drawSectionTitle(g, 'Sample Social Media Copywriting', 50);

      const cardR = ui.Rect.fromLTWH(contentX, 100, contentWidth, 650);
      drawCard(g, cardR);

      double sy = 130;
      g.drawString('Post Hook', h3Font, brush: PdfSolidBrush(textWhite), bounds: const ui.Rect.fromLTWH(contentX + 24, 130, contentWidth - 48, 16));
      sy += 20;
      g.drawString(
        proposal.sampleSocialCaptionHook.isNotEmpty ? proposal.sampleSocialCaptionHook : 'The best celebrations are the ones where you do not have to worry about a single detail. ✨',
        h2Font,
        brush: PdfSolidBrush(accentLime),
        bounds: ui.Rect.fromLTWH(contentX + 24, sy, contentWidth - 48, 35),
      );

      sy += 50;
      g.drawString('Caption Body Narrative', h3Font, brush: PdfSolidBrush(textWhite), bounds: ui.Rect.fromLTWH(contentX + 24, sy, contentWidth - 48, 16));
      sy += 20;
      final bodyText = proposal.sampleSocialCaptionBody.isNotEmpty
          ? proposal.sampleSocialCaptionBody
          : 'Whether it is a milestone 30th birthday, an intimate anniversary, or an executive retreat, your moments deserve more than routine routines. Step into curated luxury where everything is taken care of from start to finish.\n\nFrom personalized ambiance to tailored itineraries, we make planning effortless.';
      g.drawString(
        bodyText,
        bodyFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: ui.Rect.fromLTWH(contentX + 24, sy, contentWidth - 48, 150),
      );

      sy += 165;
      g.drawString('Call to Action (CTA)', h3Font, brush: PdfSolidBrush(textWhite), bounds: ui.Rect.fromLTWH(contentX + 24, sy, contentWidth - 48, 16));
      sy += 20;
      g.drawString(
        proposal.sampleSocialCaptionCta.isNotEmpty ? proposal.sampleSocialCaptionCta : '💬 Drop a comment or send us a DM to check date availability for your upcoming celebration.',
        bodyBold,
        brush: PdfSolidBrush(PdfColor(134, 239, 172)),
        bounds: ui.Rect.fromLTWH(contentX + 24, sy, contentWidth - 48, 40),
      );

      sy += 55;
      g.drawString('Targeted Hashtags', h3Font, brush: PdfSolidBrush(textWhite), bounds: ui.Rect.fromLTWH(contentX + 24, sy, contentWidth - 48, 16));
      sy += 20;
      final hashtags = proposal.sampleSocialHashtags.isNotEmpty
          ? proposal.sampleSocialHashtags.join(' ')
          : '#CelebrateInStyle #LuxuryExperiences #MeetMarketers #CategoryLeader';
      g.drawString(
        hashtags,
        bodyFont,
        brush: PdfSolidBrush(accentLime),
        bounds: ui.Rect.fromLTWH(contentX + 24, sy, contentWidth - 48, 40),
      );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PAGE 12: SEO & Digital Audit
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      drawDarkBase(page);

      drawSectionTitle(g, 'SEO & Digital Presence Opportunities', 50);

      // Score Header Card
      const cardR = ui.Rect.fromLTWH(contentX, 100, contentWidth, 110);
      drawCard(g, cardR);

      // Score Badge
      g.drawRectangle(
        brush: PdfSolidBrush(PdfColor(13, 22, 17)),
        pen: PdfPen(accentLime, width: 1.5),
        bounds: const ui.Rect.fromLTWH(contentX + 16, 115, 110, 80),
      );
      g.drawString(
        'SEO SCORE',
        captionFont,
        brush: PdfSolidBrush(textMuted),
        bounds: const ui.Rect.fromLTWH(contentX + 16, 125, 110, 14),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      g.drawString(
        '${proposal.seoAudit.healthScore}/100',
        h1Font,
        brush: PdfSolidBrush(accentLime),
        bounds: const ui.Rect.fromLTWH(contentX + 16, 145, 110, 30),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );

      // Score summary text
      g.drawString(
        proposal.seoAudit.summaryText.isNotEmpty
            ? proposal.seoAudit.summaryText
            : '${proposal.leadCompanyName} has established a solid digital foundation. Key opportunities exist in landing page architecture, schema markup, and entity discoverability.',
        bodyFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: const ui.Rect.fromLTWH(contentX + 140, 125, contentWidth - 160, 60),
      );

      // Priority Initiatives
      // High Priority
      const highR = ui.Rect.fromLTWH(contentX, 230, contentWidth, 160);
      drawCard(g, highR);
      g.drawString('High Priority Initiatives', h3Font, brush: PdfSolidBrush(PdfColor(248, 113, 113)), bounds: const ui.Rect.fromLTWH(contentX + 18, 245, contentWidth - 36, 18));
      double hy = 270;
      final highs = proposal.seoAudit.highPriority.isNotEmpty
          ? proposal.seoAudit.highPriority
          : [
              'Occasion-specific landing pages (Milestones, Corporate, Intimate)',
              'Schema.org structured review and organization markup',
              'H1 and Meta Title optimization across core pages',
              'Core Web Vitals and image WebP compression',
            ];
      for (final h in highs.take(4)) {
        g.drawString('•  $h', bodyFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + 18, hy, contentWidth - 36, 20));
        hy += 22;
      }

      // Medium Priority
      const medR = ui.Rect.fromLTWH(contentX, 410, contentWidth, 160);
      drawCard(g, medR);
      g.drawString('Medium Priority Enhancements', h3Font, brush: PdfSolidBrush(PdfColor(192, 132, 252)), bounds: const ui.Rect.fromLTWH(contentX + 18, 425, contentWidth - 36, 18));
      double my = 450;
      final meds = proposal.seoAudit.mediumPriority.isNotEmpty
          ? proposal.seoAudit.mediumPriority
          : [
              'Service detail page conversion and schema optimization',
              'Internal linking architecture between blog articles and booking packages',
              'Google Business Profile entity authority & review responses',
            ];
      for (final m in meds.take(4)) {
        g.drawString('•  $m', bodyFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + 18, my, contentWidth - 36, 20));
        my += 22;
      }

      // Long-Term Opportunities
      const longR = ui.Rect.fromLTWH(contentX, 590, contentWidth, 160);
      drawCard(g, longR);
      g.drawString('Long-Term Strategic Opportunities', h3Font, brush: PdfSolidBrush(accentLime), bounds: const ui.Rect.fromLTWH(contentX + 18, 605, contentWidth - 36, 18));
      double ly = 630;
      final longs = proposal.seoAudit.longTermOpportunities.isNotEmpty
          ? proposal.seoAudit.longTermOpportunities
          : [
              'AI search engine optimization for Perplexity, ChatGPT, and Google Gemini',
              'Digital PR collaborations with luxury media outlets',
              'Strategic event and destination video storytelling library',
            ];
      for (final l in longs.take(4)) {
        g.drawString('•  $l', bodyFont, brush: PdfSolidBrush(textOffWhite), bounds: ui.Rect.fromLTWH(contentX + 18, ly, contentWidth - 36, 20));
        ly += 22;
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PAGE 13: Final Thoughts & Assessment
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      drawDarkBase(page);

      drawSectionTitle(g, 'Final Thoughts & Assessment', 50);

      const cardR = ui.Rect.fromLTWH(contentX, 100, contentWidth, 650);
      drawCard(g, cardR);

      double fy = 130;
      g.drawString('Executive Conclusion', h2Font, brush: PdfSolidBrush(accentLime), bounds: const ui.Rect.fromLTWH(contentX + 24, 130, contentWidth - 48, 22));
      fy += 26;

      final conclusionText = proposal.finalThoughtsSummary.isNotEmpty
          ? proposal.finalThoughtsSummary
          : '${proposal.leadCompanyName} has all the foundational ingredients to dominate its category: strong reputation, genuine customer satisfaction, and exceptional visual appeal. By shifting the digital strategy from passive promotion to active storytelling, authority education, and technical search discoverability, the brand can significantly expand high-value bookings.';
      g.drawString(
        conclusionText,
        bodyFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: ui.Rect.fromLTWH(contentX + 24, fy, contentWidth - 48, 140),
      );

      fy += 160;
      g.drawString('Strategic Roadmap Recommendation', h2Font, brush: PdfSolidBrush(accentLime), bounds: ui.Rect.fromLTWH(contentX + 24, fy, contentWidth - 48, 22));
      fy += 26;

      final recText = proposal.finalThoughtsRecommendation.isNotEmpty
          ? proposal.finalThoughtsRecommendation
          : 'Phase 1: Implement technical SEO enhancements and occasion landing pages.\nPhase 2: Launch vertical video storytelling series focusing on celebrations and client transformations.\nPhase 3: Roll out corporate B2B authority campaign to capture executive retreats and offsites.';
      g.drawString(
        recText,
        bodyFont,
        brush: PdfSolidBrush(textOffWhite),
        bounds: ui.Rect.fromLTWH(contentX + 24, fy, contentWidth - 48, 160),
      );

      fy += 190;
      g.drawString('Prepared By:', h3Font, brush: PdfSolidBrush(textWhite), bounds: ui.Rect.fromLTWH(contentX + 24, fy, contentWidth - 48, 16));
      fy += 20;
      g.drawString('Meet Marketers AI Strategy Team', h2Font, brush: PdfSolidBrush(accentLime), bounds: ui.Rect.fromLTWH(contentX + 24, fy, contentWidth - 48, 22));
      fy += 22;
      g.drawString('Confidential Strategic Proposal · All Rights Reserved © 2026', captionFont, brush: PdfSolidBrush(textMuted), bounds: ui.Rect.fromLTWH(contentX + 24, fy, contentWidth - 48, 16));
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
