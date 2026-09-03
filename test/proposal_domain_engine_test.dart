import 'package:flutter_test/flutter_test.dart';
import 'package:meet_marketers_ai/core/services/proposal_domain_engine.dart';

void main() {
  test('Detects hospitalityFnbAndNightlife category for Moon Rooftop Bar', () {
    final cat = ProposalDomainEngine.instance.detectCategory(
      leadCompanyName: 'Moon Rooftop Bar & Lounge Pte. Ltd.',
      industry: 'Hospitality, F&B (Food and Beverage), and Events Management.',
      websiteUrl: 'https://www.moon.com.sg/',
    );
    expect(cat, equals(ProposalDomainCategory.hospitalityFnbAndNightlife));
  });

  test('Domain engine synthesizes authentic Singapore rooftop bar data', () {
    final proposal = ProposalDomainEngine.instance.synthesizeProposal(
      proposalId: 'test-prop-1',
      amId: 'test-am',
      leadCompanyName: 'Moon Rooftop Bar & Lounge Pte. Ltd.',
      industry: 'Hospitality, F&B (Food and Beverage), and Events Management.',
      websiteUrl: 'https://www.moon.com.sg/',
    );

    expect(proposal.perceptualMapYAxis, equals('Skyline Ambience & Panoramic View'));
    expect(proposal.perceptualMapXAxis, equals('Culinary & Craft Cocktail Exclusivity'));
    expect(proposal.competitorUsps.any((c) => c.brandName.contains('CÉ LA VI')), isTrue);
    expect(proposal.competitorUsps.any((c) => c.brandName.contains('Smoke & Mirrors')), isTrue);
    expect(proposal.competitorUsps.any((c) => c.brandName.contains('Top Category Competitor')), isFalse);

    final mapData = ProposalDomainEngine.instance.resolvePerceptualMapData(proposal);
    expect(mapData.yAxisLabel, equals('Skyline Ambience & Panoramic View'));
    expect(mapData.xAxisLabel, equals('Culinary & Craft Cocktail Exclusivity'));
    expect(mapData.topLeftBrand, contains('CÉ LA VI'));
  });
}
