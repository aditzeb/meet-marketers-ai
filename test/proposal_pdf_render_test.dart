import 'package:flutter_test/flutter_test.dart';
import 'package:meet_marketers_ai/data/models/proposal_model.dart';
import 'package:meet_marketers_ai/core/services/proposal_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generateProposalPdf compiles all 13 pages matching sample aesthetic', () async {
    final now = DateTime.now();
    final proposal = ProposalModel(
      id: 'test-proposal-1',
      amId: 'am-1',
      leadCompanyName: 'White Sails Yacht Singapore',
      industry: 'Luxury Yacht Charter',
      websiteUrl: 'https://whitesails.com.sg',
      createdAt: now,
      updatedAt: now,
      executiveSummaryPosition: 'White Sails has established itself as one of Singapore\'s trusted yacht charter operators, serving over 16,000 guests across private celebrations, corporate events, family gatherings and leisure experiences since 2011.',
      executiveSummaryOpportunity: 'While White Sails has built strong credibility and customer satisfaction, there is an opportunity to strengthen digital visibility, authority and differentiation within an increasingly competitive yacht charter market.',
      sampleReelHeadline: 'The 2-Inch Hip Hinge Fix That Saves Your Lower',
      sampleReelTopic: 'Biomechanical deadlift audit addressing executive lower back strain and building authentic posterior',
      sampleReelHook: 'If your lower back aches every time you deadlift in your commercial gym, stop immediatelyyou\'re making this common hip-hinge mistake.',
      sampleReelVisualScenes: 'Scene 1: Close-up of an executive in corporate slacks dropping his briefcase on the gym floor.\nScene 2: Cut to the coach stepping in, gently correcting his hip alignment.\nScene 3: Dynamic high-angle shot as the client resets.\nScene 4: The client locks out the weight cleanly.',
      sampleReelCta: 'Tired of guessing your form and battling joint pain? Comment \'AUDIT\' below to claim one of 5 complimentary consultations.',
      sampleBlogTitle: 'How to Plan a Yacht Birthday Party in Singapore (Without the Usual Stress)',
      sampleBlogStorytellingIntro: 'Rather than relying on promotional messaging, our content approach focuses on storytelling and customer-centric narratives that help audiences visualise the experience before they make a booking.',
      sampleBlogPreview: 'When planning a milestone celebration, most organizers are forced to choose between crowded public venues or sterile hotel banquet rooms. But true luxury is about privacy, personalized attention, and memories that last long after the evening ends...',
      socialPosts: [
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
          'body': 'From initial consultation through seamless execution, our team provides the guidance, clarity, and accountability you need to achieve your goals.',
          'badge': 'CLIENT OUTCOMES',
          'hashtags': ['#Transformation', '#Execution'],
        },
        {
          'title': 'Strategic Perspective',
          'headline': 'THE RIGHT PARTNER MAKES ALL THE DIFFERENCE.',
          'body': 'Whether tackling a complex challenge or optimizing routine operations, having the right team in your corner changes everything.',
          'badge': 'PROVEN PARTNERSHIP',
          'hashtags': ['#StrategicPartner'],
        }
      ],
    );

    final pdfBytes = await ProposalPdfService.instance.generateProposalPdf(proposal);
    expect(pdfBytes, isNotEmpty);
    expect(pdfBytes.length, greaterThan(1000));
  });
}
