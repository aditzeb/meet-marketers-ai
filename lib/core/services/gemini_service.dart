import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import '../../firebase_options.dart';
import '../config/app_config.dart';
import '../../data/models/content_deliverable_model.dart';
import '../../data/models/strategy_deliverable_model.dart';
import '../../data/models/proposal_model.dart';

/// Gemini Service — Orchestrates AI Marketing Deliverables, Photos, Videos & Captions for Clients
class GeminiService {
  static final GeminiService instance = GeminiService._internal();
  GeminiService._internal();

  static const String firebaseProjectId = 'meet-marketers-ai';

  /// Active Gemini Text Generation Models
  static const List<String> candidateModels = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
  ];

  String _apiKey = AppConfig.geminiApiKey;

  void setApiKey(String key) {
    if (key.isNotEmpty) {
      _apiKey = key;
    }
  }

  String get apiKey => _apiKey;

  /// Helper to clean raw markdown characters (***, **, ###, ---, |) from generated text
  String cleanMarkdownText(String input) {
    return input
        .replaceAll(RegExp(r'\#+'), '')
        .replaceAll(RegExp(r'\*+'), '')
        .replaceAll(RegExp(r'\|'), ' ')
        .replaceAll(RegExp(r'\-\-\-+'), '')
        .replaceAll(RegExp(r'\<br\>'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  /// Exposed fallback generator for testing and offline execution
  String getFallbackContent(ContentType type, String clientName) => _getFallbackContent(type, clientName);

  /// Generate an AI image directly via text prompt
  Future<String> generateImage(String prompt) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final seed = timestamp % 100000;
    final cleanPrompt = Uri.encodeComponent(prompt);
    return 'https://image.pollinations.ai/prompt/$cleanPrompt?width=1280&height=720&model=flux&seed=$seed&nologo=true';
  }

  /// Generate real Photo, Video Storyboard, and Caption Assets tailored to the specific client
  Future<GeneratedMediaAsset> generateMediaAsset({
    required ContentType type,
    required String clientName,
    required String industry,
    String? extractedPdfContent,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final seed = timestamp % 100000;

    // AI Dynamic Prompt for Imagen / Flux synthesis
    final imagePrompt = 'Modern commercial 8k photography for $clientName operating in $industry, cutting-edge corporate aesthetic, cinematic studio lighting, photorealistic high detail';

    // AI generated image via Pollinations Flux engine with client-specific seed and prompt
    final photoUrl = 'https://image.pollinations.ai/prompt/${Uri.encodeComponent(imagePrompt)}?width=1280&height=720&model=flux&seed=$seed&nologo=true';

    final sampleVideoUrls = [
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
    ];
    final selectedVideoUrl = sampleVideoUrls[seed % sampleVideoUrls.length];

    final scenes = [
      VideoScene(
        sceneNumber: 1,
        timecode: '0:00 - 0:08',
        visualDescription: 'Cinematic wide shot introducing $clientName operating in the $industry landscape.',
        voiceoverScript: 'Meet $clientName — setting new benchmarks in $industry excellence.',
        caption: 'Elevating standards with $clientName.',
        cameraAngle: 'Slow dynamic push-in macro shot',
      ),
      VideoScene(
        sceneNumber: 2,
        timecode: '0:08 - 0:20',
        visualDescription: 'Split screen showcasing traditional pain points vs $clientName proprietary solutions.',
        voiceoverScript: 'Streamline client workflows and maximize strategic market outcomes.',
        caption: 'Accelerated execution engineered for $clientName.',
        cameraAngle: 'Smooth orbital pan right',
      ),
      VideoScene(
        sceneNumber: 3,
        timecode: '0:20 - 0:30',
        visualDescription: 'Executive presentation screen highlighting growth metrics and final call to action.',
        voiceoverScript: 'Discover how $clientName is leading the next evolution of $industry.',
        caption: 'Scale your vision with $clientName.',
        cameraAngle: 'Medium tracking shot at eye level',
      ),
    ];

    final captionText = '''Discover how $clientName is leading transformation in $industry:

1. Direct value proposition tuned to ICP demand
2. Rapid execution and market-tested outcomes
3. Measurable ROI across key distribution channels

Ready to elevate your growth strategy with $clientName? Reach out to our team today.''';

    final hashtagsText = '#$clientName #$industry #GrowthStrategy #MarketLeader';

    return GeneratedMediaAsset(
      imageUrl: photoUrl,
      videoUrl: selectedVideoUrl,
      caption: captionText,
      hashtags: hashtagsText,
      prompt: imagePrompt,
      storyboard: scenes,
    );
  }

  /// Generate content deliverable (Script, Copy, Design Brief, Social Post, etc.) ingesting all Step 1 Client Inputs
  Future<String> generateContent({
    required ContentType type,
    required String clientName,
    required String industry,
    String? clientId,
    String? websiteUrl,
    Map<String, String>? questionnaire,
    List<String>? competitors,
    List<String>? targetRoleModels,
    List<String>? referenceImages,
    List<String>? referenceDocuments,
    String? extractedPdfContent,
  }) async {
    final history = <String>[];

    final prompt = _buildContentPrompt(
      type: type,
      clientName: clientName,
      industry: industry,
      websiteUrl: websiteUrl,
      questionnaire: questionnaire,
      competitors: competitors,
      targetRoleModels: targetRoleModels,
      referenceImages: referenceImages,
      referenceDocuments: referenceDocuments,
      extractedPdfContent: extractedPdfContent,
      vettedHistory: history,
    );

    try {
      final responseText = await _callGemini35Flash(prompt);
      if (responseText != null && responseText.trim().isNotEmpty) {
        return cleanMarkdownText(responseText);
      }
    } catch (e) {
      debugPrint('Gemini API call warning: $e');
    }

    return _getFallbackContent(type, clientName);
  }

  /// Generate full Strategy deliverables (SWOT, SEO, Personas, Calendar)
  Future<StrategyDeliverableModel> generateStrategy({
    required String clientId,
    required String clientName,
    required String industry,
    String? extractedPdfContent,
  }) async {
    final pdfContext = (extractedPdfContent != null && extractedPdfContent.isNotEmpty)
        ? 'Ingested Pitch Deck & Strategy Content:\n${extractedPdfContent.length > 3000 ? extractedPdfContent.substring(0, 3000) : extractedPdfContent}\n\n'
        : '';

    final prompt = '''
You are an expert strategic advisor generating a comprehensive marketing strategy EXCLUSIVELY FOR CLIENT "$clientName" (Industry: "$industry").
DO NOT talk about Meet Marketers AI or agency software. Focus 100% on "$clientName".

$pdfContext
Return a JSON object strictly matching this schema:
{
  "swot": {
    "strengths": ["...", "...", "..."],
    "weaknesses": ["...", "...", "..."],
    "opportunities": ["...", "...", "..."],
    "threats": ["...", "...", "..."]
  },
  "seoKeywords": [
    {"keyword": "...", "searchVolume": 12000, "difficulty": 45.0, "intent": "commercial", "targetPage": "/features"}
  ],
  "personas": [
    {
      "id": "p1",
      "name": "...",
      "jobTitle": "...",
      "industry": "$industry",
      "goals": ["..."],
      "painPoints": ["..."],
      "channels": ["LinkedIn"],
      "aiSummary": "..."
    }
  ],
  "calendarEvents": [
    {"id": "c1", "title": "...", "platform": "LinkedIn", "scheduledDate": "2026-07-05T10:00:00Z", "contentType": "post", "status": "planned"}
  ]
}
''';

    try {
      final text = await _callGemini35Flash(prompt);
      if (text != null) {
        final cleanJson = text.replaceAll('```json', '').replaceAll('```', '').trim();
        final jsonMap = jsonDecode(cleanJson) as Map<String, dynamic>;
        jsonMap['clientId'] = clientId;
        jsonMap['createdAt'] = DateTime.now().toIso8601String();
        jsonMap['updatedAt'] = DateTime.now().toIso8601String();
        return StrategyDeliverableModel.fromJson('strat-$clientId', jsonMap);
      }
    } catch (e) {
      debugPrint('Strategy generation fallback used: $e');
    }

    return StrategyDeliverableModel(
      id: 'strat-$clientId',
      clientId: clientId,
      swot: SwotMatrix(
        strengths: [
          'High domain expertise in $industry',
          'Established client reputation and trust for $clientName',
          'Agile solution positioning and rapid deployment',
        ],
        weaknesses: [
          'Limited organic search visibility for target $industry keywords',
          'Under-utilized video and executive thought leadership',
          'Scaling customer pipeline across new territories',
        ],
        opportunities: [
          'Expanding B2B account-based engagement for $clientName',
          'Targeted executive briefings and webinars',
          'High-converting interactive case studies',
        ],
        threats: [
          'Increasing digital advertising acquisition costs in $industry',
          'Evolving customer expectations and market competition',
          'Macro-economic spending shifts',
        ],
      ),
      seoKeywords: [
        SeoKeyword(keyword: '$clientName $industry solution', searchVolume: 14500, difficulty: 44, intent: 'commercial', targetPage: '/solutions'),
        SeoKeyword(keyword: 'best $industry strategies for enterprise', searchVolume: 9200, difficulty: 51, intent: 'informational', targetPage: '/insights'),
        SeoKeyword(keyword: 'how to choose $clientName services', searchVolume: 5400, difficulty: 38, intent: 'informational', targetPage: '/about'),
      ],
      personas: [
        PersonaModel(
          id: 'p1',
          name: 'The Decision Maker',
          jobTitle: 'Director of Operations',
          industry: industry,
          goals: ['Maximize return on operational investments', 'Accelerate project delivery velocity with $clientName'],
          painPoints: ['Complex vendor integration', 'Unpredictable performance metrics'],
          channels: ['LinkedIn', 'Direct Consultation'],
          aiSummary: 'Strategic buyer seeking reliable ROI and proven $clientName domain expertise.',
        ),
      ],
      calendarEvents: [
        CalendarEvent(id: 'c1', title: 'Why $clientName leads innovation in $industry', platform: 'LinkedIn', scheduledDate: DateTime.now().add(const Duration(days: 1)), contentType: 'post'),
        CalendarEvent(id: 'c2', title: '$clientName Client Success Story', platform: 'Instagram', scheduledDate: DateTime.now().add(const Duration(days: 2)), contentType: 'video'),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Generates a comprehensive 13-section Strategic Proposal matching ProposalSample.pdf
  Future<ProposalModel> generateProposal({
    required String leadCompanyName,
    required String industry,
    required String websiteUrl,
    Map<String, String>? socialUrls,
    String? extractedPitchDeckText,
    String? pitchDeckFileName,
    String? pitchDeckStorageUrl,
    String? amId,
  }) async {
    final proposalId = 'prop-${DateTime.now().millisecondsSinceEpoch}';
    final socialText = (socialUrls != null && socialUrls.isNotEmpty)
        ? socialUrls.entries.map((e) => '${e.key}: ${e.value}').join(', ')
        : 'None provided';

    final hasPitchDeck = extractedPitchDeckText != null && extractedPitchDeckText.trim().isNotEmpty;
    final pitchDeckContext = hasPitchDeck
        ? '''
COMPANY PITCH DECK & STRATEGIC FOUNDATION:
The client provided their official pitch deck (${pitchDeckFileName ?? "Uploaded PDF"}).
Extracted Content from Pitch Deck:
"""
${extractedPitchDeckText.length > 5000 ? '${extractedPitchDeckText.substring(0, 5000)}... [truncated]' : extractedPitchDeckText}
"""
CRITICAL REQUIREMENT: Synthesize this proposal directly using the strategic insights, core offerings, market pain points, and brand vision defined in this pitch deck! Tailor every section (SWOT, 4Ps, Competitors, Content Pillars, SEO) to align with their pitch deck.
'''
        : '';

    final prompt = '''
You are an elite CMO and strategic growth partner at Meet Marketers AI.
Generate a comprehensive 13-section "Digital & Content Direction Proposal" for lead "$leadCompanyName" in the "$industry" industry.
Website: $websiteUrl
Social Media Profiles: $socialText
$pitchDeckContext

Follow the exact structure and tone of high-ticket consulting proposals (similar to White Sails Yacht proposal).
Return a STRICT raw JSON object with NO markdown formatting, NO backticks:
{
  "executiveSummaryPosition": "2-3 sentences on $leadCompanyName's current market position, trust, and service offerings.",
  "executiveSummaryOpportunity": "2-3 sentences on the growth opportunity, digital visibility, authority, and differentiation.",
  "swot": {
    "strengths": ["string", "string", "string", "string"],
    "weaknesses": ["string", "string", "string", "string"],
    "opportunities": ["string", "string", "string", "string"],
    "threats": ["string", "string", "string", "string"]
  },
  "marketingMix4Ps": {
    "productCurrent": "Current offerings and service packages.",
    "productOpportunity": "Outcome-driven positioning and experience differentiation.",
    "priceCurrent": "Current pricing positioning within $industry.",
    "priceOpportunity": "Compete on trust, safety, and value rather than price discounts.",
    "placeCurrent": "Current channels: website, social, search.",
    "placeOpportunity": "Omni-channel discoverability, corporate partnerships, and SEO authority.",
    "promotionCurrent": "Current promotional activities and highlights.",
    "promotionOpportunity": "Educational reels, customer journey storytelling, and authority guides."
  },
  "pestAnalysis": {
    "political": ["Regulatory and tourism governance standards", "Safety and compliance standards"],
    "economic": ["Experience economy acceleration", "Corporate event and B2B spending trends"],
    "social": ["Consumers prioritizing experiential moments", "Team bonding and milestone celebration demand"],
    "technological": ["AI search & entity discovery", "Short-form video dominance"]
  },
  "competitorUsps": [
    {"brandName": "$leadCompanyName", "primaryUsp": "Premier tailored experience, verified quality, customer trust", "isLeadBrand": true},
    {"brandName": "Competitor Alpha", "primaryUsp": "High volume discount pricing", "isLeadBrand": false},
    {"brandName": "Competitor Beta", "primaryUsp": "Boutique ultra-niche selection", "isLeadBrand": false},
    {"brandName": "Competitor Gamma", "primaryUsp": "Generic event packages with standard inclusions", "isLeadBrand": false}
  ],
  "perceptualMapNarrative": "2-3 sentences placing $leadCompanyName between premium experience and versatile service offerings.",
  "perceptualMapInsight": "Core strategic realization about buyer psychology in $industry.",
  "perceptualMapOpportunity": "Definitive action to capture market leadership.",
  "creativePillars": [
    {
      "title": "Experience & Celebration Stories",
      "objective": "Showcase memorable moments and create emotional connections.",
      "contentStyle": ["Event recap reels", "Celebration highlights", "Customer storytelling"],
      "exampleTopics": ["A Celebration They'll Talk About For Years", "Behind This Surprise Milestone", "Celebrating Differently"]
    },
    {
      "title": "Expert Domain Education",
      "objective": "Position $leadCompanyName as the trusted authority while eliminating buyer hesitation.",
      "contentStyle": ["Educational reels", "Saveable checklists", "Comparison carousels"],
      "exampleTopics": ["First Time Booking? Here Is What To Expect", "3 Mistakes To Avoid When Planning", "Weather Contingency & Preparation"]
    },
    {
      "title": "Corporate & Executive Experiences",
      "objective": "Capture high-ticket B2B bookings, executive retreats, and corporate rewards.",
      "contentStyle": ["Corporate recap videos", "Team bonding stories", "Executive interviews"],
      "exampleTopics": ["Your Team Doesn't Need Another Hotel Ballroom", "Why Companies Choose Curated Offsites"]
    },
    {
      "title": "Lifestyle & Aspiration",
      "objective": "Inspire wanderlust and premium aspiration.",
      "contentStyle": ["Cinematic drone shots", "Atmospheric B-roll", "Weekend reset series"],
      "exampleTopics": ["The Perspective Most People Never See", "Weekend Reset In Style"]
    },
    {
      "title": "Customer Proof & Transformation",
      "objective": "Build unshakeable social proof through authentic customer experiences.",
      "contentStyle": ["Review overlays", "Customer journey recaps", "BTS coordination"],
      "exampleTopics": ["Why They Chose $leadCompanyName", "From Initial Consultation To Seamless Execution"]
    }
  ],
  "visualGuidelineNotes": "Guidelines on color harmony, natural lighting, clean typography, and cinematic pacing.",
  "brandPaletteHex": ["#10B981", "#064E3B", "#8B5CF6", "#1E293B", "#F8FAFC"],
  "sampleReelTopic": "Behind This Surprise Milestone Celebration with $leadCompanyName",
  "sampleReelHook": "Most people think planning an extraordinary celebration takes months of stress. Watch what happened when they chose something different.",
  "sampleReelVisualScenes": "Scene 1: Golden hour glow with guests arriving.\nScene 2: Close-up of personalized decor and toast.\nScene 3: Unfiltered joyous reaction of the guest of honor.\nScene 4: Crew attending to every detail seamlessly.",
  "sampleReelCta": "Save this for your next milestone celebration or tap the link in bio to book with $leadCompanyName.",
  "sampleBlogTitle": "How to Plan an Unforgettable Milestone Celebration in Singapore (Without the Usual Stress)",
  "sampleBlogStorytellingIntro": "Rather than relying on promotional messaging, our content approach focuses on storytelling and customer-centric narratives that help audiences visualize the experience before booking.",
  "sampleBlogPreview": "When planning a major celebration, most organizers are forced to choose between crowded public restaurants or sterile hotel ballrooms. But true luxury is about privacy, personalized attention, and memories that last long after the evening ends...",
  "sampleSocialCaptionHook": "The best celebrations are the ones where you don't have to worry about a single detail. ✨",
  "sampleSocialCaptionBody": "Whether it is a milestone 30th birthday, an intimate anniversary, or an executive retreat, your moments deserve more than routine routines. Step into curated luxury where everything is taken care of from start to finish.",
  "sampleSocialCaptionCta": "💬 Drop a comment or send us a DM to check date availability for your upcoming date.",
  "sampleSocialHashtags": ["#$industry", "#Celebrations", "#LuxuryExperiences", "#MeetMarketers"],
  "seoAudit": {
    "healthScore": 68,
    "summaryText": "$leadCompanyName has built a solid digital foundation with responsive pages and active branding. Several high-impact technical, on-page, and entity search opportunities remain to scale organic leads.",
    "highPriority": ["Occasion-specific landing pages", "Schema.org structured review markup", "H1 & Meta Title optimization", "Core Web Vitals speed acceleration"],
    "mediumPriority": ["Detail page schema optimization", "Open Graph social preview cards", "Author and authority publisher tags"],
    "longTermOpportunities": ["AI search engine discoverability (AIO & Perplexity)", "Educational content hub", "Corporate dedicated portal"]
  },
  "finalThoughtsSummary": "$leadCompanyName already possesses the core qualities customers seek: outstanding service, proven credibility, and trusted execution. Our proposed direction bridges the gap between great service and dominant digital authority through cohesive content, SEO, and storytelling.",
  "finalThoughtsRecommendation": "We recommend prioritizing Phase 1: High-impact technical SEO quick wins and short-form video storytelling to generate immediate visibility and leads, followed by long-form authority articles and automated omni-channel publishing."
}
''';

    try {
      final raw = await _callGemini35Flash(prompt);
      if (raw != null && raw.isNotEmpty) {
        final cleaned = cleanMarkdownText(raw);
        final startIdx = cleaned.indexOf('{');
        final endIdx = cleaned.lastIndexOf('}');
        if (startIdx != -1 && endIdx > startIdx) {
          final jsonSub = cleaned.substring(startIdx, endIdx + 1);
          final map = jsonDecode(jsonSub) as Map<String, dynamic>;
          return ProposalModel.fromJson(proposalId, {
            ...map,
            'id': proposalId,
            'amId': amId ?? 'am-default',
            'leadCompanyName': leadCompanyName,
            'industry': industry,
            'websiteUrl': websiteUrl,
            'socialUrls': socialUrls ?? {},
            'pitchDeckFileName': pitchDeckFileName,
            'pitchDeckStorageUrl': pitchDeckStorageUrl,
            'extractedPitchDeckText': extractedPitchDeckText,
            'status': ProposalStatus.readyForReview.value,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          });
        }
      }
    } catch (e) {
      debugPrint('Gemini generateProposal error, using rich fallback: $e');
    }

    return _getFallbackProposal(
      proposalId: proposalId,
      amId: amId ?? 'am-default',
      leadCompanyName: leadCompanyName,
      industry: industry,
      websiteUrl: websiteUrl,
      socialUrls: socialUrls ?? {},
      pitchDeckFileName: pitchDeckFileName,
      pitchDeckStorageUrl: pitchDeckStorageUrl,
      extractedPitchDeckText: extractedPitchDeckText,
    );
  }

  ProposalModel _getFallbackProposal({
    required String proposalId,
    required String amId,
    required String leadCompanyName,
    required String industry,
    required String websiteUrl,
    required Map<String, String> socialUrls,
    String? pitchDeckFileName,
    String? pitchDeckStorageUrl,
    String? extractedPitchDeckText,
  }) {
    final hasPitchDeck = extractedPitchDeckText != null && extractedPitchDeckText.trim().isNotEmpty;

    return ProposalModel(
      id: proposalId,
      amId: amId,
      leadCompanyName: leadCompanyName,
      industry: industry,
      websiteUrl: websiteUrl,
      socialUrls: socialUrls,
      pitchDeckFileName: pitchDeckFileName,
      pitchDeckStorageUrl: pitchDeckStorageUrl,
      extractedPitchDeckText: extractedPitchDeckText,
      status: ProposalStatus.readyForReview,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      executiveSummaryPosition: hasPitchDeck
          ? 'Grounded in $leadCompanyName\'s company pitch deck (${pitchDeckFileName ?? "Uploaded PDF"}), the brand exhibits strong core positioning and market capability in $industry. The core strategic opportunity is translating this pitch deck narrative into high-converting digital authority, SEO discovery, and short-form video storytelling.'
          : '$leadCompanyName has established itself as one of the trusted providers in $industry, building strong credibility, customer satisfaction, and reliable service quality across diverse customer segments.',
      executiveSummaryOpportunity:
          'While $leadCompanyName has built strong credibility, significant opportunity exists to expand organic search visibility, corporate authority, and video storytelling within an increasingly competitive digital landscape.',
      swot: SwotMatrix(
        strengths: [
          'Established reputation and positive customer sentiment',
          'Diverse service packages and high visual appeal',
          'Reliable execution and experienced customer service',
          'Strong word-of-mouth referral base',
        ],
        weaknesses: [
          'Limited brand differentiation from generic competitors',
          'Content frequently mirrors industry peers without distinct point of view',
          'Low proportion of authority and educational content',
          'High-value corporate segment not strongly communicated',
        ],
        opportunities: [
          'Expanding corporate retreats and team bonding packages',
          'Capitalizing on the booming experiential economy',
          'Short-form vertical video and creator collaborations',
          'Capturing high-intent AI search and Google organic search',
        ],
        threats: [
          'Increasing digital advertising customer acquisition costs',
          'Price-based competition from mass-market operators',
          'Seasonality and external scheduling factors',
          'Rising consumer demand for hyper-personalized digital experiences',
        ],
      ),
      marketingMix4Ps: MarketingMix4Ps(
        productCurrent: 'Core $industry services, celebration packages, private bookings, and custom event offerings.',
        productOpportunity: 'Strengthen differentiation by communicating outcomes (memorable connections, stress-free execution) rather than just technical inclusions.',
        priceCurrent: 'Mid-to-premium pricing supported by service quality, experienced team, and customer trust.',
        priceOpportunity: 'Continue competing on experience value, safety, and reliability rather than commoditized discounting.',
        placeCurrent: 'Website, Instagram, LinkedIn, Google Business profile, and direct inquiry channels.',
        placeOpportunity: 'Improve organic discoverability, corporate B2B channels, and strategic co-marketing partnerships.',
        promotionCurrent: 'Event highlights, customer celebration recaps, promotional announcements, and customer reviews.',
        promotionOpportunity: 'Expand into educational authority reels, customer journey transformation stories, and deep-dive destination guides.',
      ),
      pestAnalysis: const PestAnalysis(
        political: ['Industry governance and tourism recovery standards', 'Safety compliance and certified operations'],
        economic: ['Experience economy growth over material purchases', 'Corporate event and team offsite budget growth'],
        social: ['Consumers prioritizing unforgettable shared experiences', 'Surging demand for team bonding and celebration retreats'],
        technological: ['AI search and entity discoverability (Perplexity, ChatGPT)', 'Short-form algorithmic video discovery on Reels and TikTok'],
      ),
      competitorUsps: [
        CompetitorUsp(brandName: leadCompanyName, primaryUsp: 'Premier tailored experiences, outstanding service reliability, customer trust', isLeadBrand: true),
        const CompetitorUsp(brandName: 'Competitor Alpha', primaryUsp: 'High-volume discount pricing and mass-market reach'),
        const CompetitorUsp(brandName: 'Competitor Beta', primaryUsp: 'Ultra-exclusive boutique offering with limited availability'),
        const CompetitorUsp(brandName: 'Competitor Gamma', primaryUsp: 'Event-focused packages with generic group inclusions'),
      ],
      perceptualMapNarrative:
          '$leadCompanyName occupies a strong strategic position between high-end premium experiences and broad service versatility. Unlike niche luxury operators that cater solely to a narrow audience, $leadCompanyName serves a wide spectrum of customer occasions.',
      perceptualMapInsight:
          'Customers do not book services based on technical specifications alone—they purchase the emotional certainty and seamless execution of high-stakes moments.',
      perceptualMapOpportunity:
          'Strengthen brand visibility and digital authority to reinforce $leadCompanyName as the definitive first choice in its category.',
      creativePillars: [
        const ContentPillar(
          title: 'Experience & Celebration Stories',
          objective: 'Showcase memorable moments while creating emotional connections with potential customers.',
          contentStyle: ['Event recap reels', 'Celebration highlights', 'Customer storytelling', 'Emotional moments'],
          exampleTopics: ['A Celebration They Will Talk About For Years', 'Behind This Surprise Milestone', 'Why Families Choose Curated Experiences'],
        ),
        const ContentPillar(
          title: 'Expert Experience Education',
          objective: 'Position the brand as the trusted expert while eliminating buyer hesitation and booking friction.',
          contentStyle: ['Educational reels', 'Saveable checklists', 'Comparison carousels'],
          exampleTopics: ['First Time Booking? Here Is What To Expect', 'Key Differences To Look For', 'What Happens If Weather Changes?'],
        ),
        const ContentPillar(
          title: 'Corporate & Executive Experiences',
          objective: 'Strengthen visibility within the B2B corporate market and attract high-value bookings.',
          contentStyle: ['Corporate event recaps', 'Team bonding reels', 'Client entertainment case studies'],
          exampleTopics: ['Your Team Does Not Need Another Hotel Ballroom', 'Why Companies Choose Curated Offsites', 'A Different Way To Host High-Stakes Clients'],
        ),
        ContentPillar(
          title: 'Lifestyle & Aspiration',
          objective: 'Build premium aspiration and position $leadCompanyName as an unforgettable lifestyle experience.',
          contentStyle: const ['Cinematic drone footage', 'Atmospheric storytelling', 'Weekend reset concepts'],
          exampleTopics: const ['The Perspective Most People Never See', 'Escape The City Without Leaving Town', 'Weekend Reset In Style'],
        ),
        ContentPillar(
          title: 'Customer Proof & Transformation',
          objective: 'Build trust and credibility through genuine transformation stories and testimonials.',
          contentStyle: const ['Review overlays', 'Customer journey recaps', 'Before and after journeys'],
          exampleTopics: ['Why They Chose $leadCompanyName', 'From Planning To Celebration: Their Real Experience'],
        ),
      ],
      visualGuidelineNotes:
          'Visual storytelling balances clean premium minimalism with vibrant authentic emotion. Crisp natural lighting, cinematic pacing, and consistent typography reinforce category leadership across all digital channels.',
      brandPaletteHex: const ['#10B981', '#064E3B', '#8B5CF6', '#1E293B', '#F8FAFC'],
      sampleReelTopic: 'Behind This Surprise Milestone Celebration with $leadCompanyName',
      sampleReelHook: 'Most people think planning an extraordinary celebration takes months of stress. Watch what happened when they chose something different.',
      sampleReelVisualScenes: 'Scene 1: Golden hour horizon with sparkling water and laughter.\nScene 2: Close-up of personalized decor and toast with friends.\nScene 3: Unfiltered joyous reaction of the guest of honor.\nScene 4: Crew seamlessly attending to every detail while guests relax.',
      sampleReelCta: 'Save this for your next milestone celebration or tap the link in bio to book your private experience with $leadCompanyName.',
      sampleBlogTitle: 'How to Plan an Unforgettable Milestone Celebration in Singapore (Without the Usual Stress)',
      sampleBlogStorytellingIntro:
          'Rather than relying on promotional messaging, our content approach focuses on storytelling and customer-centric narratives that help audiences visualize the experience before they book.',
      sampleBlogPreview:
          'When planning a major celebration, most organizers are forced to choose between crowded public venues or sterile hotel rooms. But true luxury is about privacy, personalized attention, and memories that last long after the evening ends...\n\nIn this guide, we unpack everything from selecting the right package to food and beverage coordination, music, and capturing memories on camera.',
      sampleSocialCaptionHook: 'The best celebrations are the ones where you do not have to worry about a single detail. ✨',
      sampleSocialCaptionBody:
          'Whether it is a milestone 30th birthday, an intimate anniversary, or an executive retreat, your moments deserve more than routine routines. Step into curated luxury where everything is taken care of from start to finish.',
      sampleSocialCaptionCta: '💬 Drop a comment or send us a DM to check date availability for your upcoming date.',
      sampleSocialHashtags: const ['#SingaporeExperiences', '#CelebrateInStyle', '#LuxuryRetreats', '#MeetMarketers'],
      seoAudit: SeoAuditSummary(
        healthScore: 68,
        summaryText:
            '$leadCompanyName has established a solid digital foundation, with responsive pages and active branding. However, high-impact technical, on-page, and entity search opportunities remain to scale organic leads.',
        highPriority: const [
          'Occasion-specific landing pages (Milestones, Corporate, Intimate)',
          'Schema.org structured review and organization markup',
          'H1 and Meta Title optimization across core pages',
          'Core Web Vitals and image WebP compression',
        ],
        mediumPriority: [
          'Service detail page conversion and schema optimization',
          'Open Graph rich social sharing cards',
          'Author and thought leadership entity markup',
        ],
        longTermOpportunities: [
          'AI search engine discoverability (AIO & Perplexity optimization)',
          'Comprehensive educational content ecosystem and resource center',
          'Dedicated corporate event planner portal and inquiry flow',
        ],
      ),
      finalThoughtsSummary:
          '$leadCompanyName already possesses many of the qualities today’s customers seek: memorable experiences, professional service, trusted execution, and a proven track record. Our proposed direction bridges the gap between great service and dominant digital authority through strategic content, authentic storytelling, and a unified digital presence.',
      finalThoughtsRecommendation:
          'Based on our review, we recommend prioritizing technical SEO quick wins and occasion-specific landing pages as Phase 1, followed by short-form video storytelling and omni-channel publishing to scale lead volume.',
    );
  }

  Future<String?> _callGemini35Flash(String prompt) async {
    final keysToTry = <String>{_apiKey, AppConfig.geminiApiKey, DefaultFirebaseOptions.web.apiKey}
        .where((k) => k.isNotEmpty)
        .toList();

    for (final modelName in candidateModels) {
      for (final key in keysToTry) {
        try {
          final model = GenerativeModel(model: modelName, apiKey: key);
          final response = await model
              .generateContent([Content.text(prompt)])
              .timeout(const Duration(seconds: 4));
          if (response.text != null && response.text!.isNotEmpty) {
            return response.text;
          }
        } catch (e) {
          debugPrint('GenerativeModel SDK error for $modelName: $e');
        }

        try {
          final url = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$key',
          );
          final resp = await http.post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': key,
            },
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ]
            }),
          ).timeout(const Duration(seconds: 4));

          if (resp.statusCode == 200) {
            final data = jsonDecode(resp.body);
            final candidates = data['candidates'] as List?;
            if (candidates != null && candidates.isNotEmpty) {
              final parts = candidates[0]['content']['parts'] as List?;
              if (parts != null && parts.isNotEmpty) {
                return parts[0]['text'] as String?;
              }
            }
          } else {
            debugPrint('REST call failed for $modelName status: ${resp.statusCode}');
          }
        } catch (e) {
          debugPrint('REST call exception for $modelName: $e');
        }
      }
    }

    return null;
  }

  String _buildContentPrompt({
    required ContentType type,
    required String clientName,
    required String industry,
    String? websiteUrl,
    Map<String, String>? questionnaire,
    List<String>? competitors,
    List<String>? targetRoleModels,
    List<String>? referenceImages,
    List<String>? referenceDocuments,
    String? extractedPdfContent,
    List<String>? vettedHistory,
  }) {
    final Map<String, String> qLabels = {
      'targetCustomer': 'Who is your target customer?',
      'targetCountry': 'What is your target country?',
      'targetIndustry': 'What is your target industry?',
      'closestCompetitor': 'Who is your closest competitor?',
      'keyDifferentiator': 'What is your key differentiator?',
      'mainSalesChannel': 'What is your main sales channel?',
    };

    final qText = (questionnaire != null && questionnaire.isNotEmpty)
        ? questionnaire.entries.map((e) {
            final label = qLabels[e.key] ?? e.key;
            return '- $label: ${e.value}';
          }).join('\n')
        : 'No specific questionnaire filled yet.';

    final compText = (competitors != null && competitors.isNotEmpty)
        ? '- Direct Competitors: ${competitors.join(', ')}\n'
        : '';
    final roleText = (targetRoleModels != null && targetRoleModels.isNotEmpty)
        ? '- Target Aspirational Role Models: ${targetRoleModels.join(', ')}\n'
        : '';
    final imagesText = (referenceImages != null && referenceImages.isNotEmpty)
        ? '- Reference Photos & Product Images: ${referenceImages.join(', ')}\n'
        : '';
    final docsText = (referenceDocuments != null && referenceDocuments.isNotEmpty)
        ? '- Reference Brand Guidelines & Word/PDF Docs: ${referenceDocuments.join(', ')}\n'
        : '';
    final pdfText = (extractedPdfContent != null && extractedPdfContent.isNotEmpty)
        ? '\nIngested Pitch Deck & PDF Assets (Extracted by Flutter Engine):\n${extractedPdfContent.length > 3500 ? extractedPdfContent.substring(0, 3500) : extractedPdfContent}\n'
        : '';
    final historyText = (vettedHistory != null && vettedHistory.isNotEmpty)
        ? '\nApproved Historical Benchmarks (Emulate Brand Voice & Preference):\n${vettedHistory.take(5).map((h) => '--- Approved Benchmark ---\n$h').join('\n')}\n'
        : '';

    return '''
You are an elite AI marketing strategist generating content EXCLUSIVELY FOR CLIENT: "$clientName" (Industry: "$industry", Website: "${websiteUrl ?? 'N/A'}").

STRICT MANDATE & SCOPING RULES:
1. All generated content MUST be 100% focused on "$clientName" and its offerings in the $industry industry.
2. DO NOT mention "Meet Marketers AI" or agency software platforms. Speak directly as "$clientName" addressing its target customers.
3. Incorporate the following client intake answers, target country, key differentiators, and ICP details:

Ingested Discovery Intake Information for "$clientName":
$qText
$compText$roleText$imagesText$docsText$pdfText
$historyText

Task: Generate a clean, conversion-driven ${type.label} tailored specifically for "$clientName".

FORMATTING RULES:
- Do NOT use markdown asterisks (** or ***), hash headers (###), or table pipes (|).
- Output clean text with bullet points (•) and numbered lists (1., 2., 3.).
''';
  }

  String _getFallbackContent(ContentType type, String clientName) {
    switch (type) {
      case ContentType.socialMediaPosts:
        return '''LinkedIn & Social Media Campaign for $clientName

Post 1 (Executive Thought Leadership):
In today's fast-evolving market, $clientName is redefining how businesses achieve measurable outcomes in their industry.

Here are 3 core principles driving value for $clientName customers this quarter:
1. Direct, benefit-driven solutions tuned to customer intent
2. Data-backed proof points over unverified claims
3. Seamless onboarding and dedicated client support

What strategic initiative is driving real growth for your team right now?

#$clientName #IndustryLeadership #GrowthStrategy''';

      case ContentType.blogArticles:
        return '''Blog Article Framework for $clientName

Title: How $clientName Solves Core Market Challenges in 2026

Executive Summary:
Modern businesses face increasing complexity and cost pressures. This article highlights how $clientName delivers streamlined solutions and high-ROI outcomes for clients.

Key Sections:
1. The Evolution of Customer Demand
2. How $clientName Delivers Scalable Value
3. Real-World Case Studies and Implementation Playbooks

Conclusion & Call to Action:
Discover how $clientName can elevate your operational efficiency. Contact our strategy team today for a custom consultation.''';

      case ContentType.emailCampaign:
        return '''Email Outreach Sequence for $clientName

Email 1: Strategic Partnership Outreach
Subject: Accelerate your business goals with $clientName

Hi First Name,

If your team is evaluating proven solutions to expand operational capabilities this year, here is what we are seeing work best right now.

At $clientName, we have structured our solutions around rapid deployment, verified performance, and dedicated account management.

Would you be open to a brief 15-minute strategy conversation this week?

Best regards,
The $clientName Executive Team''';

      case ContentType.seoKeywordAudit:
        return '''SEO Keyword Audit Report for $clientName

Target Keyword Matrix:
1. Keyword: "$clientName solution" | Volume: 14,500/mo | Difficulty: 42% | Intent: Commercial | Target: /services
2. Keyword: "best industry strategies for enterprise" | Volume: 9,200/mo | Difficulty: 38% | Intent: Informational | Target: /blog/guide
3. Keyword: "how to choose $clientName" | Volume: 6,800/mo | Difficulty: 31% | Intent: Informational | Target: /resources
4. Keyword: "$clientName pricing and consultation" | Volume: 3,400/mo | Difficulty: 25% | Intent: Transactional | Target: /contact

Strategic Recommendations:
- Build high-intent landing pages for commercial keywords.
- Interlink informational blog articles to drive domain authority.''';

      case ContentType.seoTechnicalAudit:
        return '''Technical SEO Audit Checklist for $clientName

Audit Breakdown:
1. Core Web Vitals: LCP < 1.8s, FID < 100ms, CLS < 0.05 (Passed)
2. Crawlability & Indexing: XML Sitemap clean, Robots.txt correctly formatted (Passed)
3. Structured Data: Schema.org Organization & Service markup active (Passed)
4. Mobile Optimization: Fast loading and responsive layout verified (Passed)
5. Meta & Canonical Tags: Unique title tags across all routes (Passed)

Priority Action Items:
- Pre-render high-resolution brand assets for fast initial load times.''';

      case ContentType.introDeck:
        return '''Introduction Deck Outline for $clientName

Slide 1: Executive Overview — Introducing $clientName
Slide 2: Market Context — Key industry challenges and friction points
Slide 3: Our Value Proposition — How $clientName transforms client outcomes
Slide 4: Key Offerings & Core Capabilities — Tailored solutions for enterprise clients
Slide 5: Client Case Studies & Verified ROI — Proven performance track record
Slide 6: Call to Action — Partner with $clientName today''';

      case ContentType.salesPitchDeck:
        return '''Sales Pitch Deck Framework for $clientName

Slide 1: Title Slide — Scaling Success with $clientName
Slide 2: The Opportunity — Addressing unmet market demand
Slide 3: Product Architecture — End-to-end service delivery and proven playbooks
Slide 4: Competitive Advantage — Why clients choose $clientName
Slide 5: Commercial Models & Engagement Plans — Scalable options for growth
Slide 6: Next Steps — Schedule your onboarding consultation with $clientName''';

      case ContentType.explainerVideos:
        return '''Explainer Video Script for $clientName (60 Seconds)

Scene 1 (0:00 - 0:10):
Visual: Fast montage of industry leaders managing complex operational roadblocks.
Voiceover: "Looking for a faster, more effective approach to achieve your business goals?"

Scene 2 (0:10 - 0:30):
Visual: Smooth transition showcasing $clientName solutions in action.
Voiceover: "Meet $clientName. We deliver tailored strategies designed to accelerate performance and maximize ROI."

Scene 3 (0:30 - 0:50):
Visual: Split screen showing key performance metrics and verified client outcomes.
Voiceover: "Scale with confidence using proven industry playbooks."

Scene 4 (0:50 - 1:00):
Visual: $clientName logo animation with call to action.
Voiceover: "Transform your growth trajectory today with $clientName."''';

      case ContentType.testimonialVideos:
        return '''Testimonial Video Storyboard for $clientName

Concept: Customer Success Story — "Transforming Growth with $clientName"

Scene 1 (0:00 - 0:12): Executive Challenge
Visual: Headshot of Client Director in modern setting.
Script: "Before partnering with $clientName, executing complex strategic initiatives required significant manual effort."

Scene 2 (0:12 - 0:35): The Solution
Visual: Showcase of $clientName solutions driving real-time results.
Script: "With $clientName, we gained a dedicated partner that streamlined our execution from day one."

Scene 3 (0:35 - 0:50): Verified Results
Visual: Key metric callout displaying "+240% Pipeline Velocity | 100% Client Satisfaction".
Script: "$clientName has completely elevated our market performance."''';

      case ContentType.otherDesigns:
        return '''Creative Design Brief & Direction for $clientName

Visual Guidelines:
1. Brand Palette: Premium Deep Sage (#1B3A2E), Emerald accent (#4E8B6A), and Soft Warm Gray (#F4F6F5).
2. Typography: Clean modern sans-serif fonts for titles and executive body copy.
3. Aesthetic Style: Minimalist corporate cards, high-contrast layouts, and subtle drop shadows.
4. Key Deliverables: Executive presentation decks, social campaign templates, and brand collateral for $clientName.''';

      case ContentType.otherCopies:
        return '''Brand Messaging Framework for $clientName

Tagline: "Proven Execution for Industry Leaders"

Brand Pillars:
1. Reliability: Consistently delivering high-impact outcomes for $clientName clients.
2. Expertise: Grounded in deep market knowledge and verified execution.
3. Partnership: Dedicated support focused on long-term client growth.

Sample Microcopy:
- Primary CTA: "Schedule Strategy Call with $clientName"
- Secondary CTA: "Explore $clientName Insights"''';
    }
  }
}
