import 'dart:ui' as ui;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../data/models/proposal_model.dart';
import 'web_download_helper.dart';

/// Service to generate and export professional 13-section proposals matching ProposalSample.pdf
class ProposalPdfService {
  static final ProposalPdfService instance = ProposalPdfService._internal();
  ProposalPdfService._internal();

  /// Compiles a complete 13-page / multi-page PDF proposal
  Future<List<int>> generateProposalPdf(ProposalModel proposal) async {
    final document = PdfDocument();
    document.pageSettings.size = PdfPageSize.a4;
    document.pageSettings.margins.all = 36;

    // Palette Colors
    final primaryColor = PdfColor(15, 23, 42); // #0F172A
    final brandViolet = PdfColor(139, 92, 246); // #8B5CF6
    final brandEmerald = PdfColor(16, 185, 129); // #10B981
    final textDark = PdfColor(30, 41, 59); // #1E293B
    final textMuted = PdfColor(100, 116, 139); // #64748B
    final cardBg = PdfColor(248, 250, 252); // #F8FAFC
    final borderCol = PdfColor(226, 232, 240); // #E2E8F0

    // Fonts
    final titleFont = PdfStandardFont(PdfFontFamily.helvetica, 24, style: PdfFontStyle.bold);
    final h1Font = PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold);
    final h2Font = PdfStandardFont(PdfFontFamily.helvetica, 13, style: PdfFontStyle.bold);
    final h3Font = PdfStandardFont(PdfFontFamily.helvetica, 10.5, style: PdfFontStyle.bold);
    final bodyFont = PdfStandardFont(PdfFontFamily.helvetica, 9.5);
    final bodyBold = PdfStandardFont(PdfFontFamily.helvetica, 9.5, style: PdfFontStyle.bold);
    final captionFont = PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.italic);

    void drawHeader(PdfPage page, String sectionTitle) {
      final g = page.graphics;
      final width = page.getClientSize().width;

      // Top mini header
      g.drawString(
        'MEET MARKETERS AI · DIGITAL & CONTENT DIRECTION PROPOSAL',
        captionFont,
        brush: PdfSolidBrush(brandViolet),
        bounds: ui.Rect.fromLTWH(0, 0, width - 100, 12),
      );
      g.drawString(
        DateTime.now().year.toString(),
        captionFont,
        brush: PdfSolidBrush(textMuted),
        bounds: ui.Rect.fromLTWH(width - 50, 0, 50, 12),
        format: PdfStringFormat(alignment: PdfTextAlignment.right),
      );

      // Section title
      g.drawString(
        sectionTitle,
        h1Font,
        brush: PdfSolidBrush(primaryColor),
        bounds: ui.Rect.fromLTWH(0, 16, width, 24),
      );

      // Divider line
      g.drawLine(
        PdfPen(borderCol, width: 1),
        ui.Offset(0, 44),
        ui.Offset(width, 44),
      );
    }

    void drawFooter(PdfPage page, int pageNumber) {
      final g = page.graphics;
      final width = page.getClientSize().width;
      final height = page.getClientSize().height;

      g.drawLine(
        PdfPen(borderCol, width: 0.5),
        ui.Offset(0, height - 16),
        ui.Offset(width, height - 16),
      );

      g.drawString(
        'Prepared for ${proposal.leadCompanyName} · Strictly Confidential',
        captionFont,
        brush: PdfSolidBrush(textMuted),
        bounds: ui.Rect.fromLTWH(0, height - 12, width - 60, 12),
      );

      g.drawString(
        'Page $pageNumber',
        captionFont,
        brush: PdfSolidBrush(textMuted),
        bounds: ui.Rect.fromLTWH(width - 60, height - 12, 60, 12),
        format: PdfStringFormat(alignment: PdfTextAlignment.right),
      );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PAGE 1: Cover Page & Table of Contents
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      final width = page.getClientSize().width;

      // Decorative top accent banner
      g.drawRectangle(
        brush: PdfSolidBrush(brandViolet),
        bounds: ui.Rect.fromLTWH(0, 0, width, 8),
      );

      // Main Title
      g.drawString(
        'Digital & Content\nDirection Proposal',
        titleFont,
        brush: PdfSolidBrush(primaryColor),
        bounds: ui.Rect.fromLTWH(0, 40, width, 65),
      );

      g.drawString(
        'Prepared for ${proposal.leadCompanyName}',
        PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(brandEmerald),
        bounds: ui.Rect.fromLTWH(0, 115, width, 22),
      );

      g.drawString(
        'Industry: ${proposal.industry.isNotEmpty ? proposal.industry : 'Digital Marketing & Growth'} | Website: ${proposal.websiteUrl.isNotEmpty ? proposal.websiteUrl : 'Not specified'}',
        bodyFont,
        brush: PdfSolidBrush(textMuted),
        bounds: ui.Rect.fromLTWH(0, 140, width, 18),
      );

      g.drawLine(
        PdfPen(borderCol, width: 1.5),
        ui.Offset(0, 170),
        ui.Offset(width, 170),
      );

      // Table of Contents
      g.drawString(
        'CONTENTS',
        h2Font,
        brush: PdfSolidBrush(primaryColor),
        bounds: ui.Rect.fromLTWH(0, 190, width, 20),
      );

      final tocItems = [
        '1. Marketing Strategy: Executive Summary & Current Position',
        '2. SWOT Analysis Matrix (Strengths, Weaknesses, Opportunities, Threats)',
        '3. Marketing Mix (4Ps: Product, Price, Place, Promotion)',
        '4. PEST Macro-Environment & Competitor USP Benchmark',
        '5. Perceptual Map & Market Positioning Framework',
        '6. Creative Direction (Experience & Celebration / Educational Pillars)',
        '7. Creative Direction (Corporate Experiences / Lifestyle / Social Proof)',
        '8. Visual Guideline & Brand Aesthetic Framework',
        '9. Sample Reel Storyboard & Short-Form Video Direction',
        '10. Sample Copywriting Direction: SEO Blog Article Preview',
        '11. Sample Social Media Copywriting & Omni-Channel Captions',
        '12. SEO Audit & Digital Presence Optimization Roadmap',
        '13. Final Thoughts, Executive Assessment & Strategic Next Steps',
      ];

      double y = 220;
      for (final item in tocItems) {
        g.drawRectangle(
          brush: PdfSolidBrush(cardBg),
          bounds: ui.Rect.fromLTWH(0, y, width, 22),
        );
        g.drawRectangle(
          brush: PdfSolidBrush(brandViolet),
          bounds: ui.Rect.fromLTWH(0, y, 3, 22),
        );
        g.drawString(
          item,
          bodyFont,
          brush: PdfSolidBrush(textDark),
          bounds: ui.Rect.fromLTWH(12, y + 4, width - 20, 16),
        );
        y += 26;
      }

      drawFooter(page, 1);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PAGE 2: Executive Summary & SWOT Matrix
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      final width = page.getClientSize().width;
      drawHeader(page, 'Executive Summary & SWOT Analysis');

      // Executive Summary cards
      double y = 55;
      g.drawString('Current Position', h2Font, brush: PdfSolidBrush(primaryColor), bounds: ui.Rect.fromLTWH(0, y, width, 18));
      y += 22;
      g.drawString(
        proposal.executiveSummaryPosition.isNotEmpty
            ? proposal.executiveSummaryPosition
            : '${proposal.leadCompanyName} has built strong market presence and customer goodwill. Operating within ${proposal.industry}, the brand commands a loyal audience with opportunities to scale digital authority.',
        bodyFont,
        brush: PdfSolidBrush(textDark),
        bounds: ui.Rect.fromLTWH(0, y, width, 40),
      );

      y += 45;
      g.drawString('Strategic Growth Opportunity', h2Font, brush: PdfSolidBrush(primaryColor), bounds: ui.Rect.fromLTWH(0, y, width, 18));
      y += 22;
      g.drawString(
        proposal.executiveSummaryOpportunity.isNotEmpty
            ? proposal.executiveSummaryOpportunity
            : 'While the brand maintains credibility, substantial opportunity exists to enhance organic search discovery, corporate visibility, and high-converting storytelling content.',
        bodyFont,
        brush: PdfSolidBrush(textDark),
        bounds: ui.Rect.fromLTWH(0, y, width, 40),
      );

      // 4-Quadrant SWOT Matrix
      y += 50;
      g.drawString('SWOT Matrix Analysis', h2Font, brush: PdfSolidBrush(primaryColor), bounds: ui.Rect.fromLTWH(0, y, width, 18));
      y += 25;

      final halfW = (width - 12) / 2;
      final boxH = 145.0;

      void drawSwotBox(String title, List<String> items, PdfColor bgCol, PdfColor accentCol, double left, double top) {
        g.drawRectangle(brush: PdfSolidBrush(bgCol), bounds: ui.Rect.fromLTWH(left, top, halfW, boxH));
        g.drawRectangle(brush: PdfSolidBrush(accentCol), bounds: ui.Rect.fromLTWH(left, top, halfW, 22));
        g.drawString(title, h3Font, brush: PdfSolidBrush(PdfColor(255, 255, 255)), bounds: ui.Rect.fromLTWH(left + 8, top + 4, halfW - 16, 14));

        double itemY = top + 28;
        for (final item in items.take(4)) {
          g.drawString('• $item', bodyFont, brush: PdfSolidBrush(textDark), bounds: ui.Rect.fromLTWH(left + 8, itemY, halfW - 16, 26));
          itemY += 28;
        }
      }

      // Strengths & Weaknesses
      drawSwotBox('STRENGTHS', proposal.swot.strengths, PdfColor(236, 253, 245), brandEmerald, 0, y);
      drawSwotBox('WEAKNESSES', proposal.swot.weaknesses, PdfColor(254, 242, 242), PdfColor(239, 68, 68), halfW + 12, y);

      // Opportunities & Threats
      y += boxH + 10;
      drawSwotBox('OPPORTUNITIES', proposal.swot.opportunities, PdfColor(245, 243, 255), brandViolet, 0, y);
      drawSwotBox('THREATS', proposal.swot.threats, PdfColor(254, 243, 199), PdfColor(245, 158, 11), halfW + 12, y);

      drawFooter(page, 2);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PAGE 3: 4Ps Marketing Mix Analysis
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      final width = page.getClientSize().width;
      drawHeader(page, 'Marketing Mix (4Ps Analysis)');

      final p = proposal.marketingMix4Ps;
      final pList = [
        ('PRODUCT', p.productCurrent, p.productOpportunity),
        ('PRICE', p.priceCurrent, p.priceOpportunity),
        ('PLACE', p.placeCurrent, p.placeOpportunity),
        ('PROMOTION', p.promotionCurrent, p.promotionOpportunity),
      ];

      double y = 55;
      for (final item in pList) {
        final title = item.$1;
        final current = item.$2.isNotEmpty ? item.$2 : 'Current market offerings and core features.';
        final opp = item.$3.isNotEmpty ? item.$3 : 'Strategic opportunity to strengthen outcomes, messaging, and differentiation.';

        g.drawRectangle(brush: PdfSolidBrush(cardBg), bounds: ui.Rect.fromLTWH(0, y, width, 105));
        g.drawRectangle(brush: PdfSolidBrush(brandViolet), bounds: ui.Rect.fromLTWH(0, y, 4, 105));

        g.drawString(title, h2Font, brush: PdfSolidBrush(primaryColor), bounds: ui.Rect.fromLTWH(14, y + 8, width - 28, 18));
        g.drawString('Current Approach:', bodyBold, brush: PdfSolidBrush(textMuted), bounds: ui.Rect.fromLTWH(14, y + 30, width - 28, 14));
        g.drawString(current, bodyFont, brush: PdfSolidBrush(textDark), bounds: ui.Rect.fromLTWH(14, y + 46, width - 28, 22));

        g.drawString('Strategic Opportunity:', bodyBold, brush: PdfSolidBrush(brandEmerald), bounds: ui.Rect.fromLTWH(14, y + 68, width - 28, 14));
        g.drawString(opp, bodyFont, brush: PdfSolidBrush(textDark), bounds: ui.Rect.fromLTWH(14, y + 84, width - 28, 20));

        y += 115;
      }

      drawFooter(page, 3);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PAGE 4: PEST Analysis & Competitor Benchmark
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      final width = page.getClientSize().width;
      drawHeader(page, 'PEST Analysis & Competitor Benchmark');

      double y = 55;
      g.drawString('Macro-Environmental Drivers (PEST Analysis)', h2Font, brush: PdfSolidBrush(primaryColor), bounds: ui.Rect.fromLTWH(0, y, width, 18));
      y += 25;

      final pest = proposal.pestAnalysis;
      final colW = (width - 18) / 4;
      final pestCols = [
        ('POLITICAL', pest.political.isNotEmpty ? pest.political : ['Regulatory framework', 'Tourism standards']),
        ('ECONOMIC', pest.economic.isNotEmpty ? pest.economic : ['Experience economy growth', 'Corporate event budgets']),
        ('SOCIAL', pest.social.isNotEmpty ? pest.social : ['Priority for experiences', 'Team bonding demand']),
        ('TECHNOLOGICAL', pest.technological.isNotEmpty ? pest.technological : ['AI search visibility', 'Social video discovery']),
      ];

      for (int i = 0; i < pestCols.length; i++) {
        final left = i * (colW + 6);
        final title = pestCols[i].$1;
        final items = pestCols[i].$2;

        g.drawRectangle(brush: PdfSolidBrush(cardBg), bounds: ui.Rect.fromLTWH(left, y, colW, 110));
        g.drawRectangle(brush: PdfSolidBrush(brandViolet), bounds: ui.Rect.fromLTWH(left, y, colW, 18));
        g.drawString(title, captionFont, brush: PdfSolidBrush(PdfColor(255, 255, 255)), bounds: ui.Rect.fromLTWH(left + 4, y + 4, colW - 8, 12));

        double itemY = y + 24;
        for (final it in items.take(4)) {
          g.drawString('• $it', captionFont, brush: PdfSolidBrush(textDark), bounds: ui.Rect.fromLTWH(left + 4, itemY, colW - 8, 20));
          itemY += 20;
        }
      }

      // Competitor USP Analysis Table
      y += 130;
      g.drawString('Competitor & Unique Selling Proposition (USP) Analysis', h2Font, brush: PdfSolidBrush(primaryColor), bounds: ui.Rect.fromLTWH(0, y, width, 18));
      y += 24;

      final grid = PdfGrid();
      grid.columns.add(count: 3);
      grid.columns[0].width = 140;
      grid.columns[1].width = 250;
      grid.columns[2].width = 120;

      grid.headers.add(1);
      final headerRow = grid.headers[0];
      headerRow.cells[0].value = 'Brand / Entity';
      headerRow.cells[1].value = 'Primary Unique Selling Proposition (USP)';
      headerRow.cells[2].value = 'Category Role';
      headerRow.style = PdfGridRowStyle(
        backgroundBrush: PdfSolidBrush(brandViolet),
        textBrush: PdfSolidBrush(PdfColor(255, 255, 255)),
        font: bodyBold,
      );

      final comps = proposal.competitorUsps.isNotEmpty
          ? proposal.competitorUsps
          : [
              CompetitorUsp(brandName: proposal.leadCompanyName, primaryUsp: 'Premier tailored experiences, outstanding service reliability, customer trust', isLeadBrand: true),
              const CompetitorUsp(brandName: 'Industry Peer A', primaryUsp: 'High-volume discount pricing and mass-market reach'),
              const CompetitorUsp(brandName: 'Industry Peer B', primaryUsp: 'Ultra-exclusive boutique offering with limited availability'),
              const CompetitorUsp(brandName: 'Industry Peer C', primaryUsp: 'Event-focused packages with generic group inclusions'),
            ];

      for (final c in comps) {
        final row = grid.rows.add();
        row.cells[0].value = c.brandName;
        row.cells[1].value = c.primaryUsp;
        row.cells[2].value = c.isLeadBrand ? 'Lead Workspace (Target)' : 'Direct Competitor';
        if (c.isLeadBrand) {
          row.style = PdfGridRowStyle(backgroundBrush: PdfSolidBrush(PdfColor(236, 253, 245)), font: bodyBold);
        }
      }

      grid.draw(page: page, bounds: ui.Rect.fromLTWH(0, y, width, 180));
      drawFooter(page, 4);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PAGE 5: Perceptual Map & Strategic Positioning
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      final width = page.getClientSize().width;
      drawHeader(page, 'Perceptual Map & Strategic Positioning');

      double y = 55;
      g.drawString('Market Positioning Narrative', h2Font, brush: PdfSolidBrush(primaryColor), bounds: ui.Rect.fromLTWH(0, y, width, 18));
      y += 22;

      g.drawString(
        proposal.perceptualMapNarrative.isNotEmpty
            ? proposal.perceptualMapNarrative
            : '${proposal.leadCompanyName} occupies a strong strategic position between high-end premium experiences and comprehensive service versatility. While niche operators focus narrowly on luxury lifestyle, ${proposal.leadCompanyName} serves a wider spectrum of customer occasions.',
        bodyFont,
        brush: PdfSolidBrush(textDark),
        bounds: ui.Rect.fromLTWH(0, y, width, 60),
      );

      y += 75;
      // Key Insight Box
      g.drawRectangle(brush: PdfSolidBrush(cardBg), bounds: ui.Rect.fromLTWH(0, y, width, 85));
      g.drawRectangle(brush: PdfSolidBrush(brandViolet), bounds: ui.Rect.fromLTWH(0, y, 4, 85));
      g.drawString('KEY STRATEGIC INSIGHT', h3Font, brush: PdfSolidBrush(brandViolet), bounds: ui.Rect.fromLTWH(14, y + 10, width - 28, 14));
      g.drawString(
        proposal.perceptualMapInsight.isNotEmpty
            ? proposal.perceptualMapInsight
            : 'Customers do not buy services based on technical specifications alone—they purchase the emotional outcome and seamless execution of high-stakes moments.',
        bodyFont,
        brush: PdfSolidBrush(textDark),
        bounds: ui.Rect.fromLTWH(14, y + 28, width - 28, 48),
      );

      y += 105;
      // Core Opportunity Box
      g.drawRectangle(brush: PdfSolidBrush(PdfColor(236, 253, 245)), bounds: ui.Rect.fromLTWH(0, y, width, 85));
      g.drawRectangle(brush: PdfSolidBrush(brandEmerald), bounds: ui.Rect.fromLTWH(0, y, 4, 85));
      g.drawString('CORE MARKET OPPORTUNITY', h3Font, brush: PdfSolidBrush(brandEmerald), bounds: ui.Rect.fromLTWH(14, y + 10, width - 28, 14));
      g.drawString(
        proposal.perceptualMapOpportunity.isNotEmpty
            ? proposal.perceptualMapOpportunity
            : 'Strengthen digital discoverability, search presence, and video storytelling to cement ${proposal.leadCompanyName} as the definitive first choice in its category.',
        bodyFont,
        brush: PdfSolidBrush(textDark),
        bounds: ui.Rect.fromLTWH(14, y + 28, width - 28, 48),
      );

      drawFooter(page, 5);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PAGE 6: Creative Direction (Part 1)
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      final width = page.getClientSize().width;
      drawHeader(page, 'Creative Direction · Pillars 1 & 2');

      final pillars = proposal.creativePillars.isNotEmpty
          ? proposal.creativePillars
          : [
              const ContentPillar(
                title: 'Experience & Celebration Stories',
                objective: 'Showcase memorable moments while creating emotional connections with potential customers.',
                contentStyle: ['Event recap reels', 'Celebration highlights', 'Customer storytelling', 'Emotional moments'],
                exampleTopics: ['A Birthday They Will Talk About For Years', 'Behind This Surprise Proposal', 'Celebrating Milestones Differently'],
              ),
              const ContentPillar(
                title: 'Expert Experience Education',
                objective: 'Position the brand as the trusted authority while reducing buyer hesitation and booking friction.',
                contentStyle: ['Educational reels', 'Saveable carousel posts', 'Preparation checklists'],
                exampleTopics: ['First Time Booking? Here Is What To Expect', 'Key Differences To Look For', 'Weather Contingency & Preparation'],
              ),
            ];

      double y = 55;
      for (final p in pillars.take(2)) {
        g.drawRectangle(brush: PdfSolidBrush(cardBg), bounds: ui.Rect.fromLTWH(0, y, width, 185));
        g.drawRectangle(brush: PdfSolidBrush(brandViolet), bounds: ui.Rect.fromLTWH(0, y, width, 26));

        g.drawString(p.title.toUpperCase(), h3Font, brush: PdfSolidBrush(PdfColor(255, 255, 255)), bounds: ui.Rect.fromLTWH(12, y + 6, width - 24, 16));

        g.drawString('Objective:', bodyBold, brush: PdfSolidBrush(brandViolet), bounds: ui.Rect.fromLTWH(12, y + 34, width - 24, 14));
        g.drawString(p.objective, bodyFont, brush: PdfSolidBrush(textDark), bounds: ui.Rect.fromLTWH(12, y + 50, width - 24, 28));

        g.drawString('Content Formats & Style:', bodyBold, brush: PdfSolidBrush(textMuted), bounds: ui.Rect.fromLTWH(12, y + 84, width - 24, 14));
        g.drawString(p.contentStyle.join(' · '), bodyFont, brush: PdfSolidBrush(textDark), bounds: ui.Rect.fromLTWH(12, y + 100, width - 24, 18));

        g.drawString('High-Impact Example Topics:', bodyBold, brush: PdfSolidBrush(brandEmerald), bounds: ui.Rect.fromLTWH(12, y + 124, width - 24, 14));
        double topY = y + 140;
        for (final top in p.exampleTopics.take(3)) {
          g.drawString('“$top”', bodyFont, brush: PdfSolidBrush(textDark), bounds: ui.Rect.fromLTWH(12, topY, width - 24, 14));
          topY += 15;
        }

        y += 205;
      }

      drawFooter(page, 6);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PAGE 7: Creative Direction (Part 2)
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      final width = page.getClientSize().width;
      drawHeader(page, 'Creative Direction · Pillars 3, 4 & 5');

      final pillars = proposal.creativePillars.length > 2
          ? proposal.creativePillars.skip(2).toList()
          : [
              const ContentPillar(
                title: 'Corporate & Executive Experiences',
                objective: 'Strengthen visibility within the B2B corporate market and attract high-value team retreats.',
                contentStyle: ['Corporate event recaps', 'Team bonding reels', 'Client entertainment case studies'],
                exampleTopics: ['Why Companies Are Choosing Unique Retreats', 'A Different Way To Host High-Stakes Clients'],
              ),
              const ContentPillar(
                title: 'Lifestyle & Aspirational Content',
                objective: 'Build premium aspiration and position the service as an unforgettable experience.',
                contentStyle: ['Cinematic drone visuals', 'Atmospheric storytelling', 'Weekend reset concepts'],
                exampleTopics: ['The Perspective Most People Never See', 'Weekend Reset In Style'],
              ),
              const ContentPillar(
                title: 'Customer Proof & Trust Triggers',
                objective: 'Build trust and credibility through genuine transformation stories.',
                contentStyle: ['Testimonial interviews', 'Review overlays', 'Before and after journeys'],
                exampleTopics: ['Why They Chose Us', 'From Planning To Celebration: Their Real Experience'],
              ),
            ];

      double y = 55;
      for (final p in pillars.take(3)) {
        g.drawRectangle(brush: PdfSolidBrush(cardBg), bounds: ui.Rect.fromLTWH(0, y, width, 125));
        g.drawRectangle(brush: PdfSolidBrush(brandViolet), bounds: ui.Rect.fromLTWH(0, y, 4, 125));

        g.drawString(p.title, h2Font, brush: PdfSolidBrush(primaryColor), bounds: ui.Rect.fromLTWH(14, y + 8, width - 28, 16));
        g.drawString(p.objective, bodyFont, brush: PdfSolidBrush(textDark), bounds: ui.Rect.fromLTWH(14, y + 28, width - 28, 28));

        g.drawString('Styles: ${p.contentStyle.join(' · ')}', captionFont, brush: PdfSolidBrush(textMuted), bounds: ui.Rect.fromLTWH(14, y + 62, width - 28, 14));
        g.drawString('Sample Topics: “${p.exampleTopics.join('” · “')}”', bodyFont, brush: PdfSolidBrush(brandEmerald), bounds: ui.Rect.fromLTWH(14, y + 80, width - 28, 38));

        y += 135;
      }

      drawFooter(page, 7);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PAGE 8: Visual Guideline & Color Palette
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      final width = page.getClientSize().width;
      drawHeader(page, 'Visual Guideline & Content Framework');

      double y = 55;
      g.drawString('Brand Aesthetics & Visual Tone', h2Font, brush: PdfSolidBrush(primaryColor), bounds: ui.Rect.fromLTWH(0, y, width, 18));
      y += 24;

      g.drawString(
        proposal.visualGuidelineNotes.isNotEmpty
            ? proposal.visualGuidelineNotes
            : 'Visual storytelling balances clean premium minimalism with vibrant authentic emotion. Crisp natural lighting, cinematic pacing, and consistent typography reinforce category leadership across all channels.',
        bodyFont,
        brush: PdfSolidBrush(textDark),
        bounds: ui.Rect.fromLTWH(0, y, width, 55),
      );

      y += 70;
      g.drawString('Strategic Brand Color Palette', h2Font, brush: PdfSolidBrush(primaryColor), bounds: ui.Rect.fromLTWH(0, y, width, 18));
      y += 26;

      final palette = proposal.brandPaletteHex.isNotEmpty
          ? proposal.brandPaletteHex
          : ['#10B981', '#064E3B', '#8B5CF6', '#1E293B', '#F8FAFC'];

      final swatchW = (width - 40) / palette.length;
      for (int i = 0; i < palette.length; i++) {
        final hex = palette[i].replaceAll('#', '');
        final r = int.tryParse(hex.substring(0, 2), radix: 16) ?? 16;
        final gCol = int.tryParse(hex.substring(2, 4), radix: 16) ?? 185;
        final b = int.tryParse(hex.substring(4, 6), radix: 16) ?? 129;

        final left = i * (swatchW + 10);
        g.drawRectangle(brush: PdfSolidBrush(PdfColor(r, gCol, b)), bounds: ui.Rect.fromLTWH(left, y, swatchW, 55));
        g.drawString('#$hex', captionFont, brush: PdfSolidBrush(textDark), bounds: ui.Rect.fromLTWH(left, y + 60, swatchW, 14), format: PdfStringFormat(alignment: PdfTextAlignment.center));
      }

      y += 105;
      g.drawString('Content Framework Architecture', h2Font, brush: PdfSolidBrush(primaryColor), bounds: ui.Rect.fromLTWH(0, y, width, 18));
      y += 24;

      final frameworks = [
        ('Hook (0-3s)', 'Thumb-stopping visual question or pattern-interrupt hook.'),
        ('Retain (3-15s)', 'Story pacing with candid BTS moments and dynamic camera transitions.'),
        ('Deliver (15-45s)', 'Clear value proposition, emotional climax, and memorable transformation.'),
        ('Action (45-60s)', 'Clear call to action: save, share, or visit direct link in bio.'),
      ];

      for (final f in frameworks) {
        g.drawRectangle(brush: PdfSolidBrush(cardBg), bounds: ui.Rect.fromLTWH(0, y, width, 32));
        g.drawString(f.$1, bodyBold, brush: PdfSolidBrush(brandViolet), bounds: ui.Rect.fromLTWH(10, y + 8, 140, 16));
        g.drawString(f.$2, bodyFont, brush: PdfSolidBrush(textDark), bounds: ui.Rect.fromLTWH(160, y + 8, width - 170, 16));
        y += 38;
      }

      drawFooter(page, 8);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PAGE 9: Sample Reel Storyboard
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      final width = page.getClientSize().width;
      drawHeader(page, 'Sample Reel & Video Storyboard');

      double y = 55;
      g.drawString('Short-Form Video Production Blueprint', h2Font, brush: PdfSolidBrush(primaryColor), bounds: ui.Rect.fromLTWH(0, y, width, 18));
      y += 24;

      // Reel Metadata Card
      g.drawRectangle(brush: PdfSolidBrush(cardBg), bounds: ui.Rect.fromLTWH(0, y, width, 85));
      g.drawRectangle(brush: PdfSolidBrush(brandViolet), bounds: ui.Rect.fromLTWH(0, y, width, 24));
      g.drawString('FEATURED REEL TOPIC', h3Font, brush: PdfSolidBrush(PdfColor(255, 255, 255)), bounds: ui.Rect.fromLTWH(12, y + 4, width - 24, 16));

      g.drawString(
        proposal.sampleReelTopic.isNotEmpty ? proposal.sampleReelTopic : 'Behind This Surprise Milestone Celebration with ${proposal.leadCompanyName}',
        h2Font,
        brush: PdfSolidBrush(primaryColor),
        bounds: ui.Rect.fromLTWH(12, y + 32, width - 24, 22),
      );

      g.drawString(
        'Format: 9:16 Vertical Video · Duration: 30-45s · Tone: Cinematic, Warm, Authentic',
        captionFont,
        brush: PdfSolidBrush(textMuted),
        bounds: ui.Rect.fromLTWH(12, y + 58, width - 24, 14),
      );

      y += 105;
      // Hook
      g.drawString('The Hook (First 3 Seconds):', bodyBold, brush: PdfSolidBrush(brandEmerald), bounds: ui.Rect.fromLTWH(0, y, width, 16));
      y += 18;
      g.drawRectangle(brush: PdfSolidBrush(PdfColor(236, 253, 245)), bounds: ui.Rect.fromLTWH(0, y, width, 40));
      g.drawString(
        proposal.sampleReelHook.isNotEmpty ? proposal.sampleReelHook : '“Most people think planning an extraordinary celebration takes months of stress. Watch what happened when they chose something different.”',
        bodyFont,
        brush: PdfSolidBrush(textDark),
        bounds: ui.Rect.fromLTWH(10, y + 8, width - 20, 24),
      );

      y += 55;
      // Visual Scenes
      g.drawString('Visual Storyboard & Scene Breakdown:', bodyBold, brush: PdfSolidBrush(primaryColor), bounds: ui.Rect.fromLTWH(0, y, width, 16));
      y += 18;
      g.drawRectangle(brush: PdfSolidBrush(cardBg), bounds: ui.Rect.fromLTWH(0, y, width, 95));
      g.drawString(
        proposal.sampleReelVisualScenes.isNotEmpty
            ? proposal.sampleReelVisualScenes
            : 'Scene 1: Golden hour horizon with sparkling water and laughter.\nScene 2: Close-up of personalized decor and toast with friends.\nScene 3: Unfiltered joyous reaction of the guest of honor.\nScene 4: Crew seamlessly attending to every detail while guests relax.',
        bodyFont,
        brush: PdfSolidBrush(textDark),
        bounds: ui.Rect.fromLTWH(10, y + 10, width - 20, 75),
      );

      y += 110;
      // Call to Action
      g.drawString('Call To Action (Outro):', bodyBold, brush: PdfSolidBrush(brandViolet), bounds: ui.Rect.fromLTWH(0, y, width, 16));
      y += 18;
      g.drawString(
        proposal.sampleReelCta.isNotEmpty ? proposal.sampleReelCta : '“Save this for your next milestone celebration or tap the link in bio to book your private experience.”',
        bodyFont,
        brush: PdfSolidBrush(textDark),
        bounds: ui.Rect.fromLTWH(0, y, width, 24),
      );

      drawFooter(page, 9);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PAGE 10: Sample Copywriting Direction (Blog Article)
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      final width = page.getClientSize().width;
      drawHeader(page, 'Sample Copywriting Direction · SEO Blog');

      double y = 55;
      g.drawString('Suggested Long-Form Pillar Article:', h2Font, brush: PdfSolidBrush(primaryColor), bounds: ui.Rect.fromLTWH(0, y, width, 18));
      y += 24;

      g.drawRectangle(brush: PdfSolidBrush(cardBg), bounds: ui.Rect.fromLTWH(0, y, width, 60));
      g.drawString(
        proposal.sampleBlogTitle.isNotEmpty
            ? proposal.sampleBlogTitle
            : 'How to Plan an Unforgettable Milestone Celebration in Singapore (Without the Usual Stress)',
        h2Font,
        brush: PdfSolidBrush(brandViolet),
        bounds: ui.Rect.fromLTWH(12, y + 12, width - 24, 38),
      );

      y += 75;
      g.drawString('Building Trust Through Storytelling', h2Font, brush: PdfSolidBrush(primaryColor), bounds: ui.Rect.fromLTWH(0, y, width, 18));
      y += 20;

      g.drawString(
        proposal.sampleBlogStorytellingIntro.isNotEmpty
            ? proposal.sampleBlogStorytellingIntro
            : 'Rather than relying on promotional messaging, our content approach focuses on storytelling and customer-centric narratives that help audiences visualize the experience before booking.',
        bodyFont,
        brush: PdfSolidBrush(textDark),
        bounds: ui.Rect.fromLTWH(0, y, width, 40),
      );

      y += 50;
      g.drawString('Article Preview & Executive Narrative:', h3Font, brush: PdfSolidBrush(brandEmerald), bounds: ui.Rect.fromLTWH(0, y, width, 16));
      y += 18;

      g.drawRectangle(brush: PdfSolidBrush(cardBg), bounds: ui.Rect.fromLTWH(0, y, width, 170));
      g.drawString(
        proposal.sampleBlogPreview.isNotEmpty
            ? proposal.sampleBlogPreview
            : 'When planning a major celebration, most organizers are forced to choose between crowded public restaurants or sterile hotel ballrooms. But true luxury is about privacy, personalized attention, and memories that last long after the evening ends...\n\nIn this comprehensive guide, we unpack everything from selecting the right package to food and beverage coordination, music playlists, and capturing memories on camera.',
        bodyFont,
        brush: PdfSolidBrush(textDark),
        bounds: ui.Rect.fromLTWH(12, y + 12, width - 24, 146),
      );

      drawFooter(page, 10);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PAGE 11: Sample Social Media Captions
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      final width = page.getClientSize().width;
      drawHeader(page, 'Sample Social Media Copywriting & Caption');

      double y = 55;
      g.drawString('High-Converting Omni-Channel Social Post', h2Font, brush: PdfSolidBrush(primaryColor), bounds: ui.Rect.fromLTWH(0, y, width, 18));
      y += 24;

      g.drawRectangle(brush: PdfSolidBrush(cardBg), bounds: ui.Rect.fromLTWH(0, y, width, 240));
      g.drawRectangle(brush: PdfSolidBrush(brandViolet), bounds: ui.Rect.fromLTWH(0, y, width, 22));
      g.drawString('INSTAGRAM / LINKEDIN CAPTION BLUEPRINT', h3Font, brush: PdfSolidBrush(PdfColor(255, 255, 255)), bounds: ui.Rect.fromLTWH(12, y + 4, width - 24, 14));

      // Hook
      g.drawString('Opening Hook:', bodyBold, brush: PdfSolidBrush(brandViolet), bounds: ui.Rect.fromLTWH(12, y + 32, width - 24, 14));
      g.drawString(
        proposal.sampleSocialCaptionHook.isNotEmpty ? proposal.sampleSocialCaptionHook : '“The best celebrations are the ones where you don’t have to worry about a single detail.” ✨',
        bodyFont,
        brush: PdfSolidBrush(textDark),
        bounds: ui.Rect.fromLTWH(12, y + 48, width - 24, 20),
      );

      // Body
      g.drawString('Narrative Body:', bodyBold, brush: PdfSolidBrush(primaryColor), bounds: ui.Rect.fromLTWH(12, y + 76, width - 24, 14));
      g.drawString(
        proposal.sampleSocialCaptionBody.isNotEmpty
            ? proposal.sampleSocialCaptionBody
            : 'Whether it is a milestone 30th birthday, an intimate anniversary, or an executive retreat, your moments deserve more than routine routines. Step into curated luxury where everything is taken care of from start to finish.',
        bodyFont,
        brush: PdfSolidBrush(textDark),
        bounds: ui.Rect.fromLTWH(12, y + 92, width - 24, 45),
      );

      // CTA
      g.drawString('Call To Action:', bodyBold, brush: PdfSolidBrush(brandEmerald), bounds: ui.Rect.fromLTWH(12, y + 145, width - 24, 14));
      g.drawString(
        proposal.sampleSocialCaptionCta.isNotEmpty ? proposal.sampleSocialCaptionCta : '💬 Drop a comment or send us a DM to check date availability for your upcoming date.',
        bodyFont,
        brush: PdfSolidBrush(textDark),
        bounds: ui.Rect.fromLTWH(12, y + 161, width - 24, 20),
      );

      // Hashtags
      g.drawString('Optimized Hashtags:', bodyBold, brush: PdfSolidBrush(textMuted), bounds: ui.Rect.fromLTWH(12, y + 190, width - 24, 14));
      final tags = proposal.sampleSocialHashtags.isNotEmpty
          ? proposal.sampleSocialHashtags
          : ['#SingaporeExperiences', '#CelebrateInStyle', '#LuxuryRetreats', '#MeetMarketers'];
      g.drawString(
        tags.join(' '),
        captionFont,
        brush: PdfSolidBrush(brandViolet),
        bounds: ui.Rect.fromLTWH(12, y + 206, width - 24, 20),
      );

      drawFooter(page, 11);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PAGE 12: SEO & Digital Presence Opportunities
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      final width = page.getClientSize().width;
      drawHeader(page, 'SEO & Digital Presence Audit');

      final seo = proposal.seoAudit;
      double y = 55;

      // Score Badge Box
      g.drawRectangle(brush: PdfSolidBrush(cardBg), bounds: ui.Rect.fromLTWH(0, y, width, 75));
      g.drawRectangle(brush: PdfSolidBrush(brandEmerald), bounds: ui.Rect.fromLTWH(0, y, 6, 75));

      g.drawString('CURRENT SEO HEALTH SCORE', h3Font, brush: PdfSolidBrush(textMuted), bounds: ui.Rect.fromLTWH(16, y + 10, width - 100, 14));
      g.drawString('${seo.healthScore} / 100', titleFont, brush: PdfSolidBrush(brandEmerald), bounds: ui.Rect.fromLTWH(16, y + 26, width - 100, 30));

      y += 90;
      g.drawString(
        seo.summaryText.isNotEmpty
            ? seo.summaryText
            : '${proposal.leadCompanyName} possesses a solid foundational web presence with responsive pages and active branding. High-impact technical, on-page, and entity search opportunities remain to scale organic leads.',
        bodyFont,
        brush: PdfSolidBrush(textDark),
        bounds: ui.Rect.fromLTWH(0, y, width, 40),
      );

      y += 50;
      // High Priority
      g.drawString('High Priority Quick Wins:', bodyBold, brush: PdfSolidBrush(PdfColor(239, 68, 68)), bounds: ui.Rect.fromLTWH(0, y, width, 16));
      y += 18;
      final highP = seo.highPriority.isNotEmpty
          ? seo.highPriority
          : ['Occasion-specific landing pages', 'Schema.org structured review markup', 'H1 & Meta Title optimization', 'Core Web Vitals speed acceleration'];
      for (final it in highP) {
        g.drawString('• $it', bodyFont, brush: PdfSolidBrush(textDark), bounds: ui.Rect.fromLTWH(10, y, width - 20, 16));
        y += 18;
      }

      y += 10;
      // Medium Priority
      g.drawString('Medium Priority Enhancements:', bodyBold, brush: PdfSolidBrush(brandViolet), bounds: ui.Rect.fromLTWH(0, y, width, 16));
      y += 18;
      final medP = seo.mediumPriority.isNotEmpty
          ? seo.mediumPriority
          : ['Detail page schema optimization', 'Open Graph social preview cards', 'Author and authority publisher tags'];
      for (final it in medP) {
        g.drawString('• $it', bodyFont, brush: PdfSolidBrush(textDark), bounds: ui.Rect.fromLTWH(10, y, width - 20, 16));
        y += 18;
      }

      y += 10;
      // Long-term
      g.drawString('Long-Term Strategic Initiatives:', bodyBold, brush: PdfSolidBrush(brandEmerald), bounds: ui.Rect.fromLTWH(0, y, width, 16));
      y += 18;
      final longP = seo.longTermOpportunities.isNotEmpty
          ? seo.longTermOpportunities
          : ['AI search engine discoverability (AIO & Perplexity)', 'Educational content hub', 'Corporate dedicated portal'];
      for (final it in longP) {
        g.drawString('• $it', bodyFont, brush: PdfSolidBrush(textDark), bounds: ui.Rect.fromLTWH(10, y, width - 20, 16));
        y += 18;
      }

      drawFooter(page, 12);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PAGE 13: Final Thoughts & Assessment
    // ─────────────────────────────────────────────────────────────────────────
    {
      final page = document.pages.add();
      final g = page.graphics;
      final width = page.getClientSize().width;
      drawHeader(page, 'Final Thoughts & Assessment');

      double y = 55;
      g.drawString('Executive Conclusion', h2Font, brush: PdfSolidBrush(primaryColor), bounds: ui.Rect.fromLTWH(0, y, width, 18));
      y += 22;

      g.drawString(
        proposal.finalThoughtsSummary.isNotEmpty
            ? proposal.finalThoughtsSummary
            : '${proposal.leadCompanyName} already possesses the core qualities customers seek: outstanding service, proven credibility, and trusted execution. Our proposed direction bridges the gap between great service and dominant digital authority through cohesive content, SEO, and storytelling.',
        bodyFont,
        brush: PdfSolidBrush(textDark),
        bounds: ui.Rect.fromLTWH(0, y, width, 60),
      );

      y += 75;
      g.drawRectangle(brush: PdfSolidBrush(PdfColor(245, 243, 255)), bounds: ui.Rect.fromLTWH(0, y, width, 120));
      g.drawRectangle(brush: PdfSolidBrush(brandViolet), bounds: ui.Rect.fromLTWH(0, y, 4, 120));

      g.drawString('OUR STRATEGIC RECOMMENDATION', h3Font, brush: PdfSolidBrush(brandViolet), bounds: ui.Rect.fromLTWH(14, y + 12, width - 28, 16));
      g.drawString(
        proposal.finalThoughtsRecommendation.isNotEmpty
            ? proposal.finalThoughtsRecommendation
            : 'We recommend prioritizing Phase 1: High-impact technical SEO quick wins and short-form video storytelling to generate immediate visibility and leads, followed by long-form authority articles and automated omni-channel publishing.',
        bodyFont,
        brush: PdfSolidBrush(textDark),
        bounds: ui.Rect.fromLTWH(14, y + 34, width - 28, 70),
      );

      y += 140;
      g.drawString('Presented by:', bodyBold, brush: PdfSolidBrush(primaryColor), bounds: ui.Rect.fromLTWH(0, y, width, 16));
      y += 20;
      g.drawString('Meet Marketers AI Platform · www.meetmarketers.ai', bodyBold, brush: PdfSolidBrush(brandViolet), bounds: ui.Rect.fromLTWH(0, y, width, 16));
      y += 18;
      g.drawString('Empowering agencies and businesses with intelligent omni-channel growth engines.', captionFont, brush: PdfSolidBrush(textMuted), bounds: ui.Rect.fromLTWH(0, y, width, 16));

      drawFooter(page, 13);
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
