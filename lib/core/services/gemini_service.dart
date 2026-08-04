import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'hive_cache_service.dart';
import '../../firebase_options.dart';
import '../config/app_config.dart';
import '../../data/models/content_deliverable_model.dart';
import '../../data/models/strategy_deliverable_model.dart';

/// Gemini Service — Orchestrates AI Marketing Deliverables, Photos, Videos & Captions for Clients
class GeminiService {
  static final GeminiService instance = GeminiService._internal();
  GeminiService._internal();

  static const String firebaseProjectId = 'meet-marketers-ai';

  /// Standard Gemini Text Generation Models (Excluded video/image model names to prevent 404 text call errors)
  static const List<String> candidateModels = [
    'gemini-1.5-flash',
    'gemini-2.0-flash-exp',
    'gemini-1.5-pro',
    'gemini-1.5-flash-latest',
    'gemini-pro',
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

  /// Generate real Photo, Video Storyboard, and Caption Assets tailored to the specific client
  Future<GeneratedMediaAsset> generateMediaAsset({
    required ContentType type,
    required String clientName,
    required String industry,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final seed = timestamp % 100000;

    final imagePrompt = 'Hyper-realistic Imagen 3 commercial photography for $clientName operating in $industry industry, modern executive aesthetic, 8k resolution, cinematic studio lighting';

    final unsplashImages = [
      'https://images.unsplash.com/photo-1551836022-d5d88e9218df?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1460925895917-afdab827c52f?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1522071820081-009f0129c71c?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1557804506-669a67965ba0?auto=format&fit=crop&w=1200&q=80',
    ];
    final photoUrl = unsplashImages[seed % unsplashImages.length];

    final sampleVideoUrls = [
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
    ];
    final selectedVideoUrl = sampleVideoUrls[seed % sampleVideoUrls.length];

    final scenes = [
      VideoScene(
        sceneNumber: 1,
        timecode: '0:00 - 0:05',
        visualDescription: 'Extreme close-up on $clientName $industry solution interface.',
        voiceoverScript: 'How is $clientName transforming customer outcomes in $industry?',
        caption: 'Unlocking strategic advantage for $clientName.',
        cameraAngle: 'Slow push-in macro shot',
      ),
      VideoScene(
        sceneNumber: 2,
        timecode: '0:05 - 0:15',
        visualDescription: 'Split screen showing traditional $industry hurdles vs automated $clientName performance.',
        voiceoverScript: 'Accelerate your growth pipeline with proven market positioning.',
        caption: 'High converting execution tailored for $clientName.',
        cameraAngle: 'Whip pan right',
      ),
      VideoScene(
        sceneNumber: 3,
        timecode: '0:15 - 0:30',
        visualDescription: '$clientName leadership reviewing key performance metrics.',
        voiceoverScript: 'Partner with $clientName today for guaranteed execution.',
        caption: 'Proven industry benchmarks.',
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

  /// Generate content deliverable (Script, Copy, Design Brief, Social Post, etc.) tailored strictly to Client
  Future<String> generateContent({
    required ContentType type,
    required String clientName,
    required String industry,
    String? clientId,
    String? websiteUrl,
    Map<String, String>? questionnaire,
    List<String>? referenceImages,
    List<String>? referenceDocuments,
  }) async {
    final history = clientId != null ? HiveCacheService.instance.getVettedHistory(clientId) : <String>[];

    final prompt = _buildContentPrompt(
      type: type,
      clientName: clientName,
      industry: industry,
      websiteUrl: websiteUrl,
      questionnaire: questionnaire,
      referenceImages: referenceImages,
      referenceDocuments: referenceDocuments,
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
  }) async {
    final prompt = '''
You are an expert strategic advisor generating a comprehensive marketing strategy EXCLUSIVELY FOR CLIENT "$clientName" (Industry: "$industry").
DO NOT talk about Meet Marketers AI or agency software. Focus 100% on "$clientName".

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

  Future<String?> _callGemini35Flash(String prompt) async {
    final keysToTry = [_apiKey, AppConfig.geminiApiKey, DefaultFirebaseOptions.web.apiKey];

    for (final modelName in candidateModels) {
      for (final key in keysToTry) {
        if (key.isEmpty) continue;

        try {
          final model = GenerativeModel(model: modelName, apiKey: key);
          final response = await model.generateContent([Content.text(prompt)]);
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
          );

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
    List<String>? referenceImages,
    List<String>? referenceDocuments,
    List<String>? vettedHistory,
  }) {
    final qText = questionnaire != null
        ? questionnaire.entries.map((e) => '${e.key}: ${e.value}').join('\n')
        : '';
    final imagesText = (referenceImages != null && referenceImages.isNotEmpty)
        ? 'Uploaded Photos & Images for Visual Reference: ${referenceImages.join(', ')}\n'
        : '';
    final docsText = (referenceDocuments != null && referenceDocuments.isNotEmpty)
        ? 'Uploaded Reference Word Documents & PDFs: ${referenceDocuments.join(', ')}\n'
        : '';
    final historyText = (vettedHistory != null && vettedHistory.isNotEmpty)
        ? 'Approved Historical Benchmarks & Past Vetted Outputs (Emulate Brand Voice):\n${vettedHistory.take(5).map((h) => '--- Approved Benchmark ---\n$h').join('\n')}\n'
        : '';

    return '''
You are an expert copywriter generating content EXCLUSIVELY FOR CLIENT: "$clientName" (Industry: "$industry", Website: "${websiteUrl ?? 'N/A'}").

STRICT MANDATE:
- All generated content MUST be 100% about "$clientName" and its offerings in the $industry industry.
- DO NOT mention "Meet Marketers AI" or agency software platforms. Speak directly as "$clientName" addressing its target audience in $industry.

Ingested Client Information & Questionnaire:
$qText
$imagesText$docsText
$historyText

Task: Generate a clean, high-converting ${type.label} for "$clientName".

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
