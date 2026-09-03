// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:meet_marketers_ai/core/services/gemini_service.dart';

void main() {
  test('Live OpenRouter generateProposal for Moon Rooftop Bar produces real competitors and perceptual axes', () async {
    final proposal = await GeminiService.instance.generateProposal(
      leadCompanyName: 'Moon Rooftop Bar & Lounge Pte. Ltd.',
      industry: 'Hospitality, F&B (Food and Beverage), and Events Management.',
      websiteUrl: 'https://www.moon.com.sg/',
    );

    print('=== LIVE PROPOSAL GENERATION RESULT ===');
    print('Lead: ${proposal.leadCompanyName}');
    print('Industry: ${proposal.industry}');
    print('Perceptual Y-Axis: "${proposal.perceptualMapYAxis}"');
    print('Perceptual X-Axis: "${proposal.perceptualMapXAxis}"');
    print('Competitors:');
    for (final c in proposal.competitorUsps) {
      print('  - ${c.brandName} (isLead: ${c.isLeadBrand}): ${c.primaryUsp}');
    }

    expect(proposal.leadCompanyName, equals('Moon Rooftop Bar & Lounge Pte. Ltd.'));
    expect(proposal.perceptualMapYAxis, isNotEmpty);
    expect(proposal.perceptualMapXAxis, isNotEmpty);
    expect(proposal.competitorUsps.isNotEmpty, isTrue);

    // Verify zero generic placeholders
    expect(proposal.competitorUsps.any((c) => c.brandName.contains('Top Category Competitor')), isFalse);
    expect(proposal.competitorUsps.any((c) => c.brandName.contains('Boutique Specialized Firm')), isFalse);
    expect(proposal.competitorUsps.any((c) => c.brandName.contains('Competitor Alpha')), isFalse);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
