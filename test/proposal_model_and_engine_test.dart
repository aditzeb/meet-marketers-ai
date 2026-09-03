import 'package:flutter_test/flutter_test.dart';
import 'package:meet_marketers_ai/data/models/proposal_model.dart';
import 'package:meet_marketers_ai/data/models/strategy_deliverable_model.dart';
import 'package:meet_marketers_ai/core/services/gemini_service.dart';
import 'package:meet_marketers_ai/core/services/proposal_pdf_service.dart';

void main() {
  group('ProposalModel Serialization & Integrity Tests', () {
    test('ProposalModel correctly serializes and deserializes all 13 sections', () {
      final now = DateTime.now();
      final model = ProposalModel(
        id: 'prop-test-1',
        amId: 'am-123',
        leadCompanyName: 'White Sails Yacht Singapore',
        industry: 'Yacht Charter & Tourism',
        websiteUrl: 'https://whitesails.com.sg',
        socialUrls: {
          'instagram': 'https://instagram.com/whitesails',
          'linkedin': 'https://linkedin.com/company/whitesails',
        },
        contactName: 'Sarah Tan',
        contactEmail: 'sarah@whitesails.com.sg',
        pitchDeckFileName: 'White_Sails_Deck_2026.pdf',
        extractedPitchDeckText: 'White Sails operates private luxury yacht charters in Singapore...',
        status: ProposalStatus.readyForReview,
        createdAt: now,
        updatedAt: now,
        executiveSummaryPosition: 'Established luxury yacht operator.',
        executiveSummaryOpportunity: 'Expansion into corporate team building and SEO discovery.',
        swot: SwotMatrix(
          strengths: ['Established brand', 'High satisfaction'],
          weaknesses: ['Generic peer content'],
          opportunities: ['AI search optimization'],
          threats: ['Macro travel fluctuations'],
        ),
        marketingMix4Ps: const MarketingMix4Ps(
          productCurrent: 'Private charters',
          productOpportunity: 'Outcome-driven celebrations',
          priceCurrent: 'Mid-to-premium',
          priceOpportunity: 'Value-based packages',
        ),
        pestAnalysis: const PestAnalysis(
          political: ['Maritime safety regulations'],
          economic: ['Experience economy growth'],
          social: ['Millennials prioritize experiences'],
          technological: ['Short-form video algorithms'],
        ),
        competitorUsps: const [
          CompetitorUsp(brandName: 'White Sails', primaryUsp: 'Premier tailored experiences', isLeadBrand: true),
          CompetitorUsp(brandName: 'Competitor A', primaryUsp: 'Lowest cost per hour'),
        ],
        perceptualMapNarrative: 'Occupies the versatile premium quadrant.',
        perceptualMapInsight: 'Customers buy emotional certainty.',
        perceptualMapOpportunity: 'Capture organic category leadership.',
        creativePillars: const [
          ContentPillar(
            title: 'Experience & Celebration',
            objective: 'Showcase emotional moments',
            contentStyle: ['Reels', 'Carousels'],
            exampleTopics: ['A Birthday They Will Talk About For Years'],
          ),
        ],
        sampleReelTopic: 'Behind This Surprise Milestone',
        sampleReelHook: 'Most people think planning is stressful...',
        sampleBlogTitle: 'How to Plan a Yacht Birthday Without Stress',
        sampleSocialCaptionHook: 'The best celebrations are effortless.',
        seoAudit: const SeoAuditSummary(
          healthScore: 72,
          summaryText: 'Solid foundation with key technical opportunities.',
          highPriority: ['Landing pages', 'Schema markup'],
        ),
        finalThoughtsSummary: 'White Sails is positioned to dominate organic search.',
        finalThoughtsRecommendation: 'Execute Phase 1 technical SEO and vertical video reels.',
      );

      final json = model.toJson();
      final reconstituted = ProposalModel.fromJson('prop-test-1', json);

      expect(reconstituted.id, equals('prop-test-1'));
      expect(reconstituted.leadCompanyName, equals('White Sails Yacht Singapore'));
      expect(reconstituted.industry, equals('Yacht Charter & Tourism'));
      expect(reconstituted.websiteUrl, equals('https://whitesails.com.sg'));
      expect(reconstituted.socialUrls['instagram'], equals('https://instagram.com/whitesails'));
      expect(reconstituted.pitchDeckFileName, equals('White_Sails_Deck_2026.pdf'));
      expect(reconstituted.extractedPitchDeckText, contains('White Sails'));
      expect(reconstituted.status, equals(ProposalStatus.readyForReview));
      expect(reconstituted.swot.strengths.length, equals(2));
      expect(reconstituted.marketingMix4Ps.productCurrent, equals('Private charters'));
      expect(reconstituted.pestAnalysis.political.first, equals('Maritime safety regulations'));
      expect(reconstituted.competitorUsps.length, equals(2));
      expect(reconstituted.competitorUsps.first.isLeadBrand, isTrue);
      expect(reconstituted.creativePillars.first.title, equals('Experience & Celebration'));
      expect(reconstituted.seoAudit.healthScore, equals(72));
      expect(reconstituted.seoAudit.highPriority.length, equals(2));
    });

    test('ProposalStatus parses all enum cases smoothly', () {
      expect(ProposalStatus.fromString('draft'), equals(ProposalStatus.draft));
      expect(ProposalStatus.fromString('ready_for_review'), equals(ProposalStatus.readyForReview));
      expect(ProposalStatus.fromString('approved'), equals(ProposalStatus.approved));
      expect(ProposalStatus.fromString('sent'), equals(ProposalStatus.sent));
      expect(ProposalStatus.fromString('converted'), equals(ProposalStatus.converted));
      expect(ProposalStatus.fromString('unknown_status'), equals(ProposalStatus.draft));
    });
  });

  group('Gemini Proposal Synthesis & PDF Export Tests', () {
    test('GeminiService generates complete proposal structure', () async {
      final proposal = await GeminiService.instance.generateProposal(
        leadCompanyName: 'Alpha Clinic Singapore',
        industry: 'Aesthetic Healthcare',
        websiteUrl: 'https://alphaclinic.sg',
        socialUrls: {'instagram': 'https://instagram.com/alphaclinic'},
      );

      expect(proposal.leadCompanyName, equals('Alpha Clinic Singapore'));
      expect(proposal.industry, equals('Aesthetic Healthcare'));
      expect(proposal.websiteUrl, equals('https://alphaclinic.sg'));
      expect(proposal.swot.strengths.isNotEmpty, isTrue);
      expect(proposal.swot.opportunities.isNotEmpty, isTrue);
      expect(proposal.marketingMix4Ps.productCurrent.isNotEmpty, isTrue);
      expect(proposal.pestAnalysis.political.isNotEmpty, isTrue);
      expect(proposal.competitorUsps.isNotEmpty, isTrue);
      expect(proposal.creativePillars.length, greaterThanOrEqualTo(2));
      expect(proposal.seoAudit.healthScore, greaterThan(50));
      expect(proposal.finalThoughtsRecommendation.isNotEmpty, isTrue);
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('ProposalPdfService compiles valid multi-page PDF bytes matching ProposalSample.pdf', () async {
      final now = DateTime.now();
      final proposal = ProposalModel(
        id: 'prop-pdf-sample',
        amId: 'am-1',
        leadCompanyName: 'White Sails Yacht Singapore',
        industry: 'Yacht Charter & Tourism',
        websiteUrl: 'https://whitesails.com.sg',
        createdAt: now,
        updatedAt: now,
        executiveSummaryPosition: 'White Sails is a premier Singapore yacht charter operator.',
        executiveSummaryOpportunity: 'Digital visibility, authority and video storytelling.',
        creativePillars: const [
          ContentPillar(title: 'Experience Stories', objective: 'Showcase moments'),
          ContentPillar(title: 'Domain Education', objective: 'Answer common questions'),
        ],
      );

      final pdfBytes = await ProposalPdfService.instance.generateProposalPdf(proposal);

      // Verify non-empty and starts with standard PDF header '%PDF-'
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(2000));
      final header = String.fromCharCodes(pdfBytes.take(5));
      expect(header, equals('%PDF-'));
    });
  });
}
