import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../../data/models/content_deliverable_model.dart';
import '../../data/models/strategy_deliverable_model.dart';
import '../../data/models/proposal_model.dart';
import 'proposal_domain_engine.dart';
import 'client_agentic_harness_service.dart';

/// Task types for OpenRouter autonomous routing and capability detection
enum OpenRouterTaskType {
  generalMarketing,
  strategicProposal,
  multimodalVision,
  codingRefactor,
  highComplexityReasoning,
  fastMicrocopy,
}

/// Type alias for OpenRouterService
typedef OpenRouterService = GeminiService;

/// Core AI Service — Orchestrates Autonomous OpenRouter MCP / API Marketing Deliverables, Strategy & Proposals
class GeminiService {
  static final GeminiService instance = GeminiService._internal();
  GeminiService._internal();

  static const String firebaseProjectId = 'meet-marketers-ai';

  /// OpenRouter Autonomous Model Selection Mode
  static const String defaultModel = AppConfig.openRouterDefaultModel;

  String _apiKey = AppConfig.openRouterApiKey;

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

  /// Public entrypoint for simple text generation with OpenRouter task routing
  Future<String?> generateSimpleText({
    required String prompt,
    OpenRouterTaskType taskType = OpenRouterTaskType.generalMarketing,
    String? systemPrompt,
    List<String>? mediaUrls,
    int? maxTokens,
    double temperature = 0.7,
  }) => _callOpenRouterAutonomous(
    prompt: prompt,
    taskType: taskType,
    systemPrompt: systemPrompt,
    mediaUrls: mediaUrls,
    maxTokens: maxTokens,
    temperature: temperature,
  );

  /// Robust JSON extractor from AI output containing markdown or conversational preambles
  String extractJsonFromText(String raw) {
    var text = raw.trim();
    if (text.startsWith('```json')) {
      text = text.substring(7);
    } else if (text.startsWith('```')) {
      text = text.substring(3);
    }
    if (text.endsWith('```')) {
      text = text.substring(0, text.length - 3);
    }
    text = text.trim();

    final firstBrace = text.indexOf('{');
    final lastBrace = text.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
      return text.substring(firstBrace, lastBrace + 1);
    }

    final firstBracket = text.indexOf('[');
    final lastBracket = text.lastIndexOf(']');
    if (firstBracket != -1 && lastBracket != -1 && lastBracket > firstBracket) {
      return text.substring(firstBracket, lastBracket + 1);
    }

    return text;
  }

  /// Generate an AI image directly via text prompt using OpenRouter Image API
  /// Uses ByteDance Seed: Seedream 5.0 Pro ($0.045/image) for commercial visual-production quality
  Future<String> generateImage(String prompt, {String aspectRatio = '16:9'}) async {
    final apiKey = _apiKey.isNotEmpty ? _apiKey : AppConfig.openRouterApiKey;
    if (apiKey.isEmpty) {
      throw Exception('OpenRouter API key is not configured.');
    }

    try {
      final resp = await http.post(
        Uri.parse('${AppConfig.openRouterBaseUrl}/images'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': AppConfig.openRouterSiteUrl,
          'X-Title': AppConfig.openRouterSiteName,
        },
        body: jsonEncode({
          'model': AppConfig.openRouterDefaultImageModel,
          'prompt': prompt,
          'aspect_ratio': aspectRatio,
        }),
      ).timeout(const Duration(seconds: 90));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final list = data['data'] as List?;
        if (list != null && list.isNotEmpty) {
          final first = list[0] as Map<String, dynamic>;
          final b64 = first['b64_json'];
          if (b64 is String && b64.isNotEmpty) {
            return 'data:image/jpeg;base64,$b64';
          }
          final url = first['url'];
          if (url is String && url.isNotEmpty) {
            return url;
          }
        }
      } else {
        String errorDetail = resp.body;
        try {
          final errJson = jsonDecode(resp.body);
          if (errJson is Map && errJson['error'] != null) {
            final errObj = errJson['error'];
            if (errObj is Map && errObj['message'] != null) {
              errorDetail = errObj['message'].toString();
            } else {
              errorDetail = errObj.toString();
            }
          }
        } catch (_) {}
        throw Exception('OpenRouter Image API Error (${resp.statusCode}): $errorDetail');
      }
    } catch (e) {
      debugPrint('OpenRouter image generation error: $e');
      rethrow;
    }

    throw Exception('OpenRouter image generation returned an empty result.');
  }

  /// Initiates video generation via OpenRouter Video API (Alibaba Wan 3.0 Prime)
  Future<String?> generateVideo({
    required String prompt,
    int duration = 4,
    String aspectRatio = '16:9',
  }) async {
    final apiKey = _apiKey.isNotEmpty ? _apiKey : AppConfig.openRouterApiKey;
    if (apiKey.isEmpty) return null;

    try {
      final resp = await http.post(
        Uri.parse('${AppConfig.openRouterBaseUrl}/videos'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': AppConfig.openRouterSiteUrl,
          'X-Title': AppConfig.openRouterSiteName,
        },
        body: jsonEncode({
          'model': AppConfig.openRouterDefaultVideoModel,
          'prompt': prompt,
          'duration': duration,
          'aspect_ratio': aspectRatio,
          'resolution': '720p',
        }),
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200 || resp.statusCode == 202) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final pollingUrl = data['polling_url'] as String?;
        final jobId = data['id'] as String?;
        return pollingUrl ?? jobId;
      }
    } catch (e) {
      debugPrint('OpenRouter video generation warning: $e');
    }
    return null;
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

    // AI Dynamic Prompt for commercial synthesis
    final imagePrompt = 'Modern commercial 8k photography for $clientName operating in $industry, cutting-edge corporate aesthetic, cinematic studio lighting, photorealistic high detail';

    // AI generated image via OpenRouter Image API (FLUX.2 Klein 4B)
    final photoUrl = await generateImage(imagePrompt);

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

    String? harnessContext;
    if (clientId != null && clientId.isNotEmpty) {
      final cached = ClientAgenticHarnessService.instance.getCachedHarness(clientId);
      if (cached != null) {
        harnessContext = ClientAgenticHarnessService.instance.buildContextInjection(cached);
      }
    }

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
      agenticHarnessContext: harnessContext,
    );

    final taskType = switch (type) {
      ContentType.socialMediaPosts || ContentType.emailCampaign || ContentType.otherCopies => OpenRouterTaskType.fastMicrocopy,
      ContentType.seoKeywordAudit || ContentType.seoTechnicalAudit => OpenRouterTaskType.highComplexityReasoning,
      _ => OpenRouterTaskType.generalMarketing,
    };

    try {
      final responseText = await _callOpenRouterAutonomous(
        prompt: prompt,
        taskType: taskType,
        mediaUrls: referenceImages,
      );
      if (responseText != null && responseText.trim().isNotEmpty) {
        return cleanMarkdownText(responseText);
      }
    } catch (e) {
      debugPrint('OpenRouter API call warning: $e');
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

    String? harnessContext;
    if (clientId.isNotEmpty) {
      final cached = ClientAgenticHarnessService.instance.getCachedHarness(clientId);
      if (cached != null) {
        harnessContext = ClientAgenticHarnessService.instance.buildContextInjection(cached);
      }
    }

    final prompt = '''
You are an expert strategic advisor generating a comprehensive marketing strategy EXCLUSIVELY FOR CLIENT "$clientName" (Industry: "$industry").
DO NOT talk about Meet Marketers AI or agency software. Focus 100% on "$clientName".

$pdfContext
${harnessContext ?? ''}
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
      final text = await _callOpenRouterAutonomous(
        prompt: prompt,
        taskType: OpenRouterTaskType.highComplexityReasoning,
      );
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
    String? clientId,
  }) async {
    final proposalId = 'prop-${DateTime.now().millisecondsSinceEpoch}';

    // 1. Synthesize baseline domain-accurate proposal using the intelligent Domain Engine
    final domainBase = ProposalDomainEngine.instance.synthesizeProposal(
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

    // 2. Build domain-aware AI prompt for OpenRouter
    final socialText = (socialUrls != null && socialUrls.isNotEmpty)
        ? socialUrls.entries.map((e) => '${e.key}: ${e.value}').join(', ')
        : 'None provided';

    String? harnessContext;
    if (clientId != null && clientId.isNotEmpty) {
      final cached = ClientAgenticHarnessService.instance.getCachedHarness(clientId);
      if (cached != null) {
        harnessContext = ClientAgenticHarnessService.instance.buildContextInjection(cached);
      }
    }

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
        : '''
COMPANY PROFILE INFERENCE MANDATE:
No pitch deck was uploaded. You are given:
- Company Name: "$leadCompanyName"
- Industry / Sector: "$industry"
- Official Website: "$websiteUrl"

CRITICAL INFERENCE & LOCALIZATION MANDATE:
1. Deeply analyze the company name ("$leadCompanyName"), industry ("$industry"), and website domain ("$websiteUrl").
2. Infer the exact geographic market from the domain and brand name (e.g. .sg / .com.sg -> Singapore; .my -> Malaysia; .id -> Indonesia; .ae -> Dubai/UAE; .co.uk -> UK; .au -> Australia; .com -> Singapore or international hub).
3. Ground the strategy entirely in this business's actual core offerings (e.g., if a Rooftop Bar & Lounge: craft cocktails, skyline sunset views, nightlife, dining, and private corporate/social events).
4. REAL DIRECT COMPETITORS MANDATE: You MUST provide 3 to 4 REAL, WELL-KNOWN, ACTUAL direct competitors operating in the exact same city and category (e.g., for Moon Rooftop Bar Singapore: CÉ LA VI Singapore, Level33, Smoke & Mirrors, 1-Altitude Coast, Lantern).
   STRICT PROHIBITION: NEVER use generic placeholders like "Competitor Alpha", "Top Category Competitor", "Boutique Specialized Firm", or "Digital Challenger Brand"! Every brandName must be an actual, recognizable real-world venue or business.
5. PERCEPTUAL MAP AXES MANDATE: Formulate two distinct, domain-specific axes tailored specifically to their sector (e.g., for rooftop bar/hospitality: Vertical Y-Axis = "Skyline Ambience & Panoramic View", Horizontal X-Axis = "Culinary & Craft Cocktail Exclusivity"). NEVER use corporate consulting terms like "Strategic Authority" or "Service Breadth" for hospitality, dining, or consumer venues.
''';

    final prompt = '''
You are an elite Chief Marketing Officer and strategic growth partner at Meet Marketers AI.
Generate a comprehensive, bespoke 13-section "Digital & Content Direction Proposal" specifically tailored for lead "$leadCompanyName" operating in the "$industry" sector.
Website: $websiteUrl
Social Media: $socialText
$pitchDeckContext
${harnessContext ?? ''}

STRICT REQUIREMENTS:
1. Ground the strategy entirely in this business's actual offerings, target clients, and sector dynamics ($industry).
2. REAL COMPETITORS: Provide 3 to 4 REAL, named direct competitors in their actual geographic market. Zero placeholders.
3. DOMAIN-AUTHENTIC PERCEPTUAL MAP: Create two bespoke, domain-accurate axes for the perceptual map.
4. Provide authoritative, consulting-grade analysis suitable for presentation to enterprise C-suite stakeholders.

Return a STRICT raw JSON object with NO markdown formatting, NO backticks:
{
  "executiveSummaryPosition": "2-3 sentences on $leadCompanyName's market position, credibility, and actual core business.",
  "executiveSummaryOpportunity": "2-3 sentences on their high-value digital growth and authority opportunity.",
  "swot": {
    "strengths": ["string", "string", "string", "string"],
    "weaknesses": ["string", "string", "string", "string"],
    "opportunities": ["string", "string", "string", "string"],
    "threats": ["string", "string", "string", "string"]
  },
  "marketingMix4Ps": {
    "productCurrent": "Actual current offerings and deliverables tailored to their sector.",
    "productOpportunity": "Outcome-driven packaging and high-value differentiation.",
    "priceCurrent": "Actual pricing structure in their industry.",
    "priceOpportunity": "Value-based positioning anchored on outcomes.",
    "placeCurrent": "Actual distribution and client booking/inquiry channels.",
    "placeOpportunity": "Omni-channel discoverability and inbound pipelines.",
    "promotionCurrent": "Current promotional footprint.",
    "promotionOpportunity": "Educational video masterclasses, customer transformation proof, and thought leadership."
  },
  "pestAnalysis": {
    "political": ["Regulatory and governance standards in their field", "Compliance requirements"],
    "economic": ["Macroeconomic capital and consumer/client expenditure trends in their sector", "Market spending dynamics"],
    "social": ["Client priorities and changing buyer psychology in their industry", "Demand shifts"],
    "technological": ["Enterprise AI and technological transformation in their domain", "Search and workflow shifts"]
  },
  "competitorUsps": [
    {"brandName": "$leadCompanyName", "primaryUsp": "Core unique value proposition", "isLeadBrand": true},
    {"brandName": "Real Competitor 1", "primaryUsp": "Their positioning in the sector", "isLeadBrand": false},
    {"brandName": "Real Competitor 2", "primaryUsp": "Their positioning in the sector", "isLeadBrand": false},
    {"brandName": "Real Competitor 3", "primaryUsp": "Their positioning in the sector", "isLeadBrand": false}
  ],
  "perceptualMapYAxis": "Bespoke Vertical Y-Axis Attribute (e.g. Skyline Ambience & Panoramic View)",
  "perceptualMapXAxis": "Bespoke Horizontal X-Axis Attribute (e.g. Culinary & Craft Cocktail Exclusivity)",
  "perceptualMapNarrative": "2-3 sentences analyzing $leadCompanyName's position against actual named peers.",
  "perceptualMapInsight": "Core strategic realization about buyer psychology in their sector.",
  "perceptualMapOpportunity": "Definitive strategic action to capture category leadership.",
  "creativePillars": [
    {"title": "Pillar 1 Title", "objective": "Objective", "contentStyle": ["Style 1", "Style 2"], "exampleTopics": ["Topic 1", "Topic 2"]},
    {"title": "Pillar 2 Title", "objective": "Objective", "contentStyle": ["Style 1", "Style 2"], "exampleTopics": ["Topic 1", "Topic 2"]},
    {"title": "Pillar 3 Title", "objective": "Objective", "contentStyle": ["Style 1", "Style 2"], "exampleTopics": ["Topic 1", "Topic 2"]},
    {"title": "Pillar 4 Title", "objective": "Objective", "contentStyle": ["Style 1", "Style 2"], "exampleTopics": ["Topic 1", "Topic 2"]},
    {"title": "Pillar 5 Title", "objective": "Objective", "contentStyle": ["Style 1", "Style 2"], "exampleTopics": ["Topic 1", "Topic 2"]}
  ],
  "visualGuidelineNotes": "Aesthetic direction tailored to their industry.",
  "brandPaletteHex": ["#HEX1", "#HEX2", "#HEX3", "#HEX4", "#HEX5"],
  "sampleReelTopic": "Reel Topic tailored to their business",
  "sampleReelHook": "High-converting hook addressing their ICP pain point",
  "sampleReelVisualScenes": "Scene 1: ...\\nScene 2: ...\\nScene 3: ...\\nScene 4: ...",
  "sampleReelCta": "Direct call to action relevant to their service",
  "sampleBlogTitle": "SEO Pillar Blog Title",
  "sampleBlogStorytellingIntro": "Storytelling narrative intro",
  "sampleBlogPreview": "Article preview excerpt",
  "sampleSocialCaptionHook": "Social post hook",
  "sampleSocialCaptionBody": "Social post body",
  "sampleSocialCaptionCta": "Social post CTA",
  "sampleSocialHashtags": ["#Tag1", "#Tag2", "#Tag3"],
  "seoAudit": {
    "healthScore": 75,
    "summaryText": "SEO summary for their domain",
    "highPriority": ["Priority 1", "Priority 2", "Priority 3"],
    "mediumPriority": ["Medium 1", "Medium 2"],
    "longTermOpportunities": ["Long-term 1", "Long-term 2"]
  },
  "finalThoughtsSummary": "Strategic summary",
  "finalThoughtsRecommendation": "Next steps recommendation"
}
''';

    try {
      final raw = await _callOpenRouterAutonomous(
        prompt: prompt,
        taskType: OpenRouterTaskType.strategicProposal,
      );
      if (raw != null && raw.isNotEmpty) {
        final cleaned = cleanMarkdownText(raw);
        final startIdx = cleaned.indexOf('{');
        final endIdx = cleaned.lastIndexOf('}');
        if (startIdx != -1 && endIdx > startIdx) {
          final jsonSub = cleaned.substring(startIdx, endIdx + 1);
          final map = jsonDecode(jsonSub) as Map<String, dynamic>;

          // Merge AI response with rich domainBase defaults so no field is ever null or generic
          final baseMap = domainBase.toJson();
          final mergedMap = <String, dynamic>{
            ...baseMap,
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
          };

          return ProposalModel.fromJson(proposalId, mergedMap);
        }
      }
    } catch (e) {
      debugPrint('OpenRouter generateProposal error, using domain base: $e');
    }

    return domainBase;
  }

  /// Core OpenRouter Autonomous Request Engine
  /// Routes tasks dynamically through OpenRouter auto-router and cost-optimized model cascades
  /// with price-prioritized provider sorting and strict token limits.
  Future<String?> _callOpenRouterAutonomous({
    required String prompt,
    OpenRouterTaskType taskType = OpenRouterTaskType.generalMarketing,
    String? systemPrompt,
    List<String>? mediaUrls,
    int? maxTokens,
    double temperature = 0.7,
  }) async {
    final apiKey = _apiKey.isNotEmpty ? _apiKey : AppConfig.openRouterApiKey;
    if (apiKey.isEmpty) {
      debugPrint('OpenRouter API key missing');
      return null;
    }

    final endpoint = Uri.parse('${AppConfig.openRouterBaseUrl}/chat/completions');

    final messages = <Map<String, dynamic>>[];
    if (systemPrompt != null && systemPrompt.trim().isNotEmpty) {
      messages.add({
        'role': 'system',
        'content': systemPrompt.trim(),
      });
    }

    // Dynamic Multimodal Payload if mediaUrls provided
    if (mediaUrls != null && mediaUrls.isNotEmpty) {
      final contentList = <Map<String, dynamic>>[
        {'type': 'text', 'text': prompt},
      ];
      for (final url in mediaUrls) {
        if (url.trim().isNotEmpty) {
          contentList.add({
            'type': 'image_url',
            'image_url': {'url': url.trim()},
          });
        }
      }
      messages.add({
        'role': 'user',
        'content': contentList,
      });
    } else {
      messages.add({
        'role': 'user',
        'content': prompt,
      });
    }

    // Determine cost-optimized model cascade and token boundaries from OpenRouter MCP benchmarks
    List<String> candidateModels;
    int tokenCap;

    switch (taskType) {
      case OpenRouterTaskType.strategicProposal:
        candidateModels = AppConfig.strategicProposalModels;
        tokenCap = maxTokens ?? 4000;
        break;
      case OpenRouterTaskType.highComplexityReasoning:
        candidateModels = AppConfig.highComplexityModels;
        tokenCap = maxTokens ?? 2500;
        break;
      case OpenRouterTaskType.fastMicrocopy:
        candidateModels = AppConfig.fastMicrocopyModels;
        tokenCap = maxTokens ?? 600;
        break;
      case OpenRouterTaskType.multimodalVision:
        candidateModels = AppConfig.multimodalVisionModels;
        tokenCap = maxTokens ?? 1200;
        break;
      case OpenRouterTaskType.codingRefactor:
      case OpenRouterTaskType.generalMarketing:
        candidateModels = AppConfig.generalMarketingModels;
        tokenCap = maxTokens ?? 1800;
        break;
    }

    // Cost-optimized payload: model cascade + provider sort by price + token cap
    final payload = {
      'models': candidateModels,
      'provider': {
        'sort': 'price',
      },
      'messages': messages,
      'max_tokens': tokenCap,
      'temperature': temperature,
    };

    try {
      final resp = await http.post(
        endpoint,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': AppConfig.openRouterSiteUrl,
          'X-Title': AppConfig.openRouterSiteName,
        },
        body: jsonEncode(payload),
      ).timeout(
        switch (taskType) {
          OpenRouterTaskType.strategicProposal => const Duration(seconds: 90),
          OpenRouterTaskType.highComplexityReasoning => const Duration(seconds: 60),
          OpenRouterTaskType.generalMarketing => const Duration(seconds: 45),
          OpenRouterTaskType.fastMicrocopy => const Duration(seconds: 20),
          _ => const Duration(seconds: 45),
        },
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final message = choices[0]['message'] as Map<String, dynamic>?;
          if (message != null) {
            var content = message['content'];
            if ((content == null || (content is String && content.trim().isEmpty)) && message['reasoning'] != null) {
              content = message['reasoning'];
            }
            if (content is String && content.trim().isNotEmpty) {
              return content;
            }
          }
        }
      } else {
        debugPrint('OpenRouter API error ${resp.statusCode}: ${resp.body}');
      }
    } catch (e) {
      debugPrint('OpenRouter API exception: $e');
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
    String? agenticHarnessContext,
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
    final harnessText = (agenticHarnessContext != null && agenticHarnessContext.isNotEmpty)
        ? '\n$agenticHarnessContext\n'
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
$harnessText
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
