import 'strategy_deliverable_model.dart';

/// Status lifecycle for a client proposal
enum ProposalStatus {
  draft('draft', 'Draft'),
  generating('generating', 'Generating AI Strategy'),
  readyForReview('ready_for_review', 'Ready for Review'),
  approved('approved', 'Approved by AM'),
  sent('sent', 'Sent to Lead'),
  converted('converted', 'Converted to Client');

  final String value;
  final String label;
  const ProposalStatus(this.value, this.label);

  static ProposalStatus fromString(String val) {
    return ProposalStatus.values.firstWhere(
      (s) => s.value == val,
      orElse: () => ProposalStatus.draft,
    );
  }
}

/// 4Ps Marketing Mix Section (Product, Price, Place, Promotion)
class MarketingMix4Ps {
  final String productCurrent;
  final String productOpportunity;
  final String priceCurrent;
  final String priceOpportunity;
  final String placeCurrent;
  final String placeOpportunity;
  final String promotionCurrent;
  final String promotionOpportunity;

  const MarketingMix4Ps({
    this.productCurrent = '',
    this.productOpportunity = '',
    this.priceCurrent = '',
    this.priceOpportunity = '',
    this.placeCurrent = '',
    this.placeOpportunity = '',
    this.promotionCurrent = '',
    this.promotionOpportunity = '',
  });

  Map<String, dynamic> toJson() => {
    'productCurrent': productCurrent,
    'productOpportunity': productOpportunity,
    'priceCurrent': priceCurrent,
    'priceOpportunity': priceOpportunity,
    'placeCurrent': placeCurrent,
    'placeOpportunity': placeOpportunity,
    'promotionCurrent': promotionCurrent,
    'promotionOpportunity': promotionOpportunity,
  };

  factory MarketingMix4Ps.fromJson(Map<String, dynamic> json) => MarketingMix4Ps(
    productCurrent: json['productCurrent'] as String? ?? '',
    productOpportunity: json['productOpportunity'] as String? ?? '',
    priceCurrent: json['priceCurrent'] as String? ?? '',
    priceOpportunity: json['priceOpportunity'] as String? ?? '',
    placeCurrent: json['placeCurrent'] as String? ?? '',
    placeOpportunity: json['placeOpportunity'] as String? ?? '',
    promotionCurrent: json['promotionCurrent'] as String? ?? '',
    promotionOpportunity: json['promotionOpportunity'] as String? ?? '',
  );

  MarketingMix4Ps copyWith({
    String? productCurrent,
    String? productOpportunity,
    String? priceCurrent,
    String? priceOpportunity,
    String? placeCurrent,
    String? placeOpportunity,
    String? promotionCurrent,
    String? promotionOpportunity,
  }) => MarketingMix4Ps(
    productCurrent: productCurrent ?? this.productCurrent,
    productOpportunity: productOpportunity ?? this.productOpportunity,
    priceCurrent: priceCurrent ?? this.priceCurrent,
    priceOpportunity: priceOpportunity ?? this.priceOpportunity,
    placeCurrent: placeCurrent ?? this.placeCurrent,
    placeOpportunity: placeOpportunity ?? this.placeOpportunity,
    promotionCurrent: promotionCurrent ?? this.promotionCurrent,
    promotionOpportunity: promotionOpportunity ?? this.promotionOpportunity,
  );
}

/// PEST Macro-Environmental Analysis
class PestAnalysis {
  final List<String> political;
  final List<String> economic;
  final List<String> social;
  final List<String> technological;

  const PestAnalysis({
    this.political = const [],
    this.economic = const [],
    this.social = const [],
    this.technological = const [],
  });

  Map<String, dynamic> toJson() => {
    'political': political,
    'economic': economic,
    'social': social,
    'technological': technological,
  };

  factory PestAnalysis.fromJson(Map<String, dynamic> json) => PestAnalysis(
    political: List<String>.from(json['political'] as List? ?? []),
    economic: List<String>.from(json['economic'] as List? ?? []),
    social: List<String>.from(json['social'] as List? ?? []),
    technological: List<String>.from(json['technological'] as List? ?? []),
  );

  PestAnalysis copyWith({
    List<String>? political,
    List<String>? economic,
    List<String>? social,
    List<String>? technological,
  }) => PestAnalysis(
    political: political ?? this.political,
    economic: economic ?? this.economic,
    social: social ?? this.social,
    technological: technological ?? this.technological,
  );
}

/// Competitor Comparison with Primary USPs
class CompetitorUsp {
  final String brandName;
  final String primaryUsp;
  final bool isLeadBrand;

  const CompetitorUsp({
    required this.brandName,
    required this.primaryUsp,
    this.isLeadBrand = false,
  });

  Map<String, dynamic> toJson() => {
    'brandName': brandName,
    'primaryUsp': primaryUsp,
    'isLeadBrand': isLeadBrand,
  };

  factory CompetitorUsp.fromJson(Map<String, dynamic> json) => CompetitorUsp(
    brandName: json['brandName'] as String? ?? '',
    primaryUsp: json['primaryUsp'] as String? ?? '',
    isLeadBrand: json['isLeadBrand'] as bool? ?? false,
  );
}

/// Strategic Content Pillar in Creative Direction
class ContentPillar {
  final String title;
  final String objective;
  final List<String> contentStyle;
  final List<String> exampleTopics;

  const ContentPillar({
    required this.title,
    required this.objective,
    this.contentStyle = const [],
    this.exampleTopics = const [],
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'objective': objective,
    'contentStyle': contentStyle,
    'exampleTopics': exampleTopics,
  };

  factory ContentPillar.fromJson(Map<String, dynamic> json) => ContentPillar(
    title: json['title'] as String? ?? '',
    objective: json['objective'] as String? ?? '',
    contentStyle: List<String>.from(json['contentStyle'] as List? ?? []),
    exampleTopics: List<String>.from(json['exampleTopics'] as List? ?? []),
  );
}

/// SEO & Digital Presence Audit Section
class SeoAuditSummary {
  final int healthScore;
  final String summaryText;
  final List<String> highPriority;
  final List<String> mediumPriority;
  final List<String> longTermOpportunities;

  const SeoAuditSummary({
    this.healthScore = 65,
    this.summaryText = '',
    this.highPriority = const [],
    this.mediumPriority = const [],
    this.longTermOpportunities = const [],
  });

  Map<String, dynamic> toJson() => {
    'healthScore': healthScore,
    'summaryText': summaryText,
    'highPriority': highPriority,
    'mediumPriority': mediumPriority,
    'longTermOpportunities': longTermOpportunities,
  };

  factory SeoAuditSummary.fromJson(Map<String, dynamic> json) => SeoAuditSummary(
    healthScore: json['healthScore'] as int? ?? 65,
    summaryText: json['summaryText'] as String? ?? '',
    highPriority: List<String>.from(json['highPriority'] as List? ?? []),
    mediumPriority: List<String>.from(json['mediumPriority'] as List? ?? []),
    longTermOpportunities: List<String>.from(json['longTermOpportunities'] as List? ?? []),
  );

  SeoAuditSummary copyWith({
    int? healthScore,
    String? summaryText,
    List<String>? highPriority,
    List<String>? mediumPriority,
    List<String>? longTermOpportunities,
  }) => SeoAuditSummary(
    healthScore: healthScore ?? this.healthScore,
    summaryText: summaryText ?? this.summaryText,
    highPriority: highPriority ?? this.highPriority,
    mediumPriority: mediumPriority ?? this.mediumPriority,
    longTermOpportunities: longTermOpportunities ?? this.longTermOpportunities,
  );
}

/// Primary Master Model for Automated Strategic Proposals (matching ProposalSample.pdf)
class ProposalModel {
  final String id;
  final String amId;
  final String leadCompanyName;
  final String industry;
  final String websiteUrl;
  final Map<String, String> socialUrls;
  final String contactName;
  final String contactEmail;
  final ProposalStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? sentAt;
  final DateTime? convertedAt;
  final String? convertedClientId;
  final String? pdfStorageUrl;
  final String? pitchDeckFileName;
  final String? pitchDeckStorageUrl;
  final String? extractedPitchDeckText;

  // ── 13 Core Sections matching ProposalSample.pdf ──
  final String executiveSummaryPosition;
  final String executiveSummaryOpportunity;
  final SwotMatrix swot;
  final MarketingMix4Ps marketingMix4Ps;
  final PestAnalysis pestAnalysis;
  final List<CompetitorUsp> competitorUsps;
  final String perceptualMapNarrative;
  final String perceptualMapInsight;
  final String perceptualMapOpportunity;
  final List<ContentPillar> creativePillars;
  final String visualGuidelineNotes;
  final List<String> brandPaletteHex;
  final String sampleReelTopic;
  final String sampleReelHook;
  final String sampleReelVisualScenes;
  final String sampleReelCta;
  final String sampleBlogTitle;
  final String sampleBlogStorytellingIntro;
  final String sampleBlogPreview;
  final String sampleSocialCaptionHook;
  final String sampleSocialCaptionBody;
  final String sampleSocialCaptionCta;
  final List<String> sampleSocialHashtags;
  final SeoAuditSummary seoAudit;
  final String finalThoughtsSummary;
  final String finalThoughtsRecommendation;

  // ── Enhanced Visual Guideline & Media Synthesis (matching ProposalSample.pdf) ──
  final List<String> visualKeywords;
  final List<String> focusMoreOn;
  final List<String> focusLessOn;
  final String photographyQuote;
  final String typographySampleHeadline;
  final List<Map<String, String>> brandToneOfVoice;
  final Map<String, dynamic> brandColorDetails;
  final List<Map<String, dynamic>> contentFrameworkWeeks;
  final String sampleReelHeadline;
  final String? sampleReelMediaUrl;
  final String sampleReelLink;
  final List<Map<String, dynamic>> socialPosts;
  final String seoAssessmentText;
  final String seoAuditLink;
  final String? visualDirectionImageUrl;

  const ProposalModel({
    required this.id,
    required this.amId,
    required this.leadCompanyName,
    required this.industry,
    required this.websiteUrl,
    this.socialUrls = const {},
    this.contactName = '',
    this.contactEmail = '',
    this.status = ProposalStatus.draft,
    required this.createdAt,
    required this.updatedAt,
    this.sentAt,
    this.convertedAt,
    this.convertedClientId,
    this.pdfStorageUrl,
    this.pitchDeckFileName,
    this.pitchDeckStorageUrl,
    this.extractedPitchDeckText,
    this.executiveSummaryPosition = '',
    this.executiveSummaryOpportunity = '',
    this.swot = const SwotMatrix(),
    this.marketingMix4Ps = const MarketingMix4Ps(),
    this.pestAnalysis = const PestAnalysis(),
    this.competitorUsps = const [],
    this.perceptualMapNarrative = '',
    this.perceptualMapInsight = '',
    this.perceptualMapOpportunity = '',
    this.creativePillars = const [],
    this.visualGuidelineNotes = '',
    this.brandPaletteHex = const ['#10B981', '#064E3B', '#8B5CF6', '#1E293B', '#F8FAFC'],
    this.sampleReelTopic = '',
    this.sampleReelHook = '',
    this.sampleReelVisualScenes = '',
    this.sampleReelCta = '',
    this.sampleBlogTitle = '',
    this.sampleBlogStorytellingIntro = '',
    this.sampleBlogPreview = '',
    this.sampleSocialCaptionHook = '',
    this.sampleSocialCaptionBody = '',
    this.sampleSocialCaptionCta = '',
    this.sampleSocialHashtags = const [],
    this.seoAudit = const SeoAuditSummary(),
    this.finalThoughtsSummary = '',
    this.finalThoughtsRecommendation = '',
    this.visualKeywords = const ['Authoritative', 'Professional', 'Modern', 'Trustworthy', 'Dynamic'],
    this.focusMoreOn = const ['Executive collaboration', 'High-stakes presentations', 'Authentic team interactions', 'Data-driven results'],
    this.focusLessOn = const ['Generic stock handshakes', 'Empty auditoriums/offices', 'Sterile clip-art graphics', 'Overly promotional sales banners'],
    this.photographyQuote = "Customers don't just buy service features. They buy certainty, verified outcomes, and trusted execution.",
    this.typographySampleHeadline = "CONNECT. INNOVATE. SCALE.",
    this.brandToneOfVoice = const [
      {'trait': 'AUTHORITATIVE', 'desc': 'Speaking with deep domain experience, verified results, and industry leadership.'},
      {'trait': 'CATALYTIC', 'desc': 'Inspiring decisive action, customer velocity, and ambitious growth.'},
      {'trait': 'RESULTS-DRIVEN', 'desc': 'Focusing on tangible business outcomes, customer value, and measurable ROI.'},
      {'trait': 'TRUSTWORTHY', 'desc': 'Consistent, transparent, and upholding the highest professional standards.'},
    ],
    this.brandColorDetails = const {
      'primary': {'name': 'Slate Navy', 'hex': '#0F172A'},
      'secondary': {'name': 'Executive Indigo', 'hex': '#4F46E5'},
      'accent': {'name': 'Growth Emerald', 'hex': '#10B981'},
    },
    this.contentFrameworkWeeks = const [
      {
        'week': 'WEEK 1',
        'experienceStories': 'Customer Transformation Case Study',
        'educational': '3 Critical Mistakes to Avoid in Your Strategy',
        'corporate': 'Enterprise Solutions & Pilot Capabilities Overview',
        'testimonials': 'Client Testimonial (Execution Excellence)',
        'promotional': 'Schedule Your Strategic Discovery Consultation',
        'contentExamples': '• Case study breakdown\n• Mistake checklist\n• Enterprise solutions post\n• Client review quote\n• Consultation booking link',
      },
      {
        'week': 'WEEK 2',
        'experienceStories': 'Process Walkthrough: How We Deliver High-Impact Outcomes',
        'educational': 'Demystifying the Top Industry Misconceptions',
        'corporate': 'Tailored Advisory & High-Value Retainers',
        'testimonials': 'Partner Testimonial (Speed & Reliability)',
        'promotional': 'Download Our Comprehensive Industry Roadmap',
        'contentExamples': '• Workflow tour\n• Myth-busting carousel\n• Advisory highlight\n• Partner quote\n• Download resource link',
      },
      {
        'week': 'WEEK 3',
        'experienceStories': 'Behind the Scenes with Our Core Specialist Team',
        'educational': 'How to Measure Value vs Cost in Modern Solutions',
        'corporate': 'Executive Q&A on Emerging Market Trends',
        'testimonials': 'Client Review (Measurable ROI)',
        'promotional': 'Limited Consultation Openings for Upcoming Cohort',
        'contentExamples': '• Team spotlight\n• Value breakdown carousel\n• Executive interview clip\n• Client review quote\n• Calendar reservation link',
      },
      {
        'week': 'WEEK 4',
        'experienceStories': 'Monthly Milestone Recap & Strategic Wins',
        'educational': 'The 5 Essential Questions Every Leader Must Ask',
        'corporate': 'Long-Term Strategic Partnerships & Co-Innovation',
        'testimonials': 'Executive Sponsor Testimonial (Long-Term Impact)',
        'promotional': 'Get Started with Our Strategic Assessment',
        'contentExamples': '• Milestone wins video\n• Leadership checklist\n• Partnership overview\n• Executive review\n• Assessment signup link',
      },
    ],
    this.sampleReelHeadline = 'Scale with Certainty',
    this.sampleReelMediaUrl,
    this.sampleReelLink = 'https://meet-marketers.com',
    this.socialPosts = const [
      {
        'title': 'Enterprise Authority',
        'headline': 'BUILT ON TRUST. DRIVEN BY MEASURABLE RESULTS.',
        'body': 'We do not believe in one-size-fits-all templates.\n\nEvery initiative is tailored to your strategic objectives, backed by dedicated professionals who care about your long-term success.\n\nLearn more at our website.',
        'badge': 'VERIFIED EXCELLENCE',
        'hashtags': ['#BusinessGrowth', '#Strategy', '#Leadership', '#MeetMarketers'],
        'imageUrl': '',
      },
      {
        'title': 'Transformation Stories',
        'headline': 'WHAT SEPARATES INDUSTRY BENCHMARKS FROM THE REST.',
        'body': 'From initial strategic alignment to seamless execution, our team provides the clarity and accountability required to achieve market leadership.\n\nExplore how we help organizations scale.',
        'badge': 'PROVEN OUTCOMES',
        'hashtags': ['#Transformation', '#Execution', '#Scale', '#Innovation'],
        'imageUrl': '',
      },
      {
        'title': 'Executive Perspective',
        'headline': 'THE RIGHT STRATEGIC PARTNER MAKES ALL THE DIFFERENCE.',
        'body': 'Whether unlocking new market opportunities or accelerating high-stakes initiatives, having the right team in your corner changes everything.\n\nConnect with our specialists today.',
        'badge': 'STRATEGIC PARTNERSHIP',
        'hashtags': ['#StrategicPartner', '#Excellence', '#Leadership'],
        'imageUrl': '',
      },
    ],
    this.seoAssessmentText = 'Based on our review, we recommend prioritising high-intent service landing pages and technical on-page SEO quick wins in Phase 1 to capture qualified organic search and AI-assisted discovery.',
    this.seoAuditLink = 'https://meet-marketers.com/seo-audit',
    this.visualDirectionImageUrl,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'amId': amId,
    'leadCompanyName': leadCompanyName,
    'industry': industry,
    'websiteUrl': websiteUrl,
    'socialUrls': socialUrls,
    'contactName': contactName,
    'contactEmail': contactEmail,
    'status': status.value,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'sentAt': sentAt?.toIso8601String(),
    'convertedAt': convertedAt?.toIso8601String(),
    'convertedClientId': convertedClientId,
    'pdfStorageUrl': pdfStorageUrl,
    'pitchDeckFileName': pitchDeckFileName,
    'pitchDeckStorageUrl': pitchDeckStorageUrl,
    'extractedPitchDeckText': extractedPitchDeckText,
    'executiveSummaryPosition': executiveSummaryPosition,
    'executiveSummaryOpportunity': executiveSummaryOpportunity,
    'swot': swot.toJson(),
    'marketingMix4Ps': marketingMix4Ps.toJson(),
    'pestAnalysis': pestAnalysis.toJson(),
    'competitorUsps': competitorUsps.map((c) => c.toJson()).toList(),
    'perceptualMapNarrative': perceptualMapNarrative,
    'perceptualMapInsight': perceptualMapInsight,
    'perceptualMapOpportunity': perceptualMapOpportunity,
    'creativePillars': creativePillars.map((p) => p.toJson()).toList(),
    'visualGuidelineNotes': visualGuidelineNotes,
    'brandPaletteHex': brandPaletteHex,
    'sampleReelTopic': sampleReelTopic,
    'sampleReelHook': sampleReelHook,
    'sampleReelVisualScenes': sampleReelVisualScenes,
    'sampleReelCta': sampleReelCta,
    'sampleBlogTitle': sampleBlogTitle,
    'sampleBlogStorytellingIntro': sampleBlogStorytellingIntro,
    'sampleBlogPreview': sampleBlogPreview,
    'sampleSocialCaptionHook': sampleSocialCaptionHook,
    'sampleSocialCaptionBody': sampleSocialCaptionBody,
    'sampleSocialCaptionCta': sampleSocialCaptionCta,
    'sampleSocialHashtags': sampleSocialHashtags,
    'seoAudit': seoAudit.toJson(),
    'finalThoughtsSummary': finalThoughtsSummary,
    'finalThoughtsRecommendation': finalThoughtsRecommendation,
    'visualKeywords': visualKeywords,
    'focusMoreOn': focusMoreOn,
    'focusLessOn': focusLessOn,
    'photographyQuote': photographyQuote,
    'typographySampleHeadline': typographySampleHeadline,
    'brandToneOfVoice': brandToneOfVoice,
    'brandColorDetails': brandColorDetails,
    'contentFrameworkWeeks': contentFrameworkWeeks,
    'sampleReelHeadline': sampleReelHeadline,
    'sampleReelMediaUrl': sampleReelMediaUrl,
    'sampleReelLink': sampleReelLink,
    'socialPosts': socialPosts,
    'seoAssessmentText': seoAssessmentText,
    'seoAuditLink': seoAuditLink,
    'visualDirectionImageUrl': visualDirectionImageUrl,
  };

  factory ProposalModel.fromJson(String id, Map<String, dynamic> json) {
    return ProposalModel(
      id: id,
      amId: json['amId'] as String? ?? 'am-default',
      leadCompanyName: json['leadCompanyName'] as String? ?? '',
      industry: json['industry'] as String? ?? '',
      websiteUrl: json['websiteUrl'] as String? ?? '',
      socialUrls: Map<String, String>.from(json['socialUrls'] as Map? ?? {}),
      contactName: json['contactName'] as String? ?? '',
      contactEmail: json['contactEmail'] as String? ?? '',
      status: ProposalStatus.fromString(json['status'] as String? ?? 'draft'),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      sentAt: json['sentAt'] != null ? DateTime.tryParse(json['sentAt'] as String) : null,
      convertedAt: json['convertedAt'] != null ? DateTime.tryParse(json['convertedAt'] as String) : null,
      convertedClientId: json['convertedClientId'] as String?,
      pdfStorageUrl: json['pdfStorageUrl'] as String?,
      pitchDeckFileName: json['pitchDeckFileName'] as String?,
      pitchDeckStorageUrl: json['pitchDeckStorageUrl'] as String?,
      extractedPitchDeckText: json['extractedPitchDeckText'] as String?,
      executiveSummaryPosition: json['executiveSummaryPosition'] as String? ?? '',
      executiveSummaryOpportunity: json['executiveSummaryOpportunity'] as String? ?? '',
      swot: json['swot'] != null
          ? SwotMatrix.fromJson(Map<String, dynamic>.from(json['swot'] as Map))
          : const SwotMatrix(),
      marketingMix4Ps: json['marketingMix4Ps'] != null
          ? MarketingMix4Ps.fromJson(Map<String, dynamic>.from(json['marketingMix4Ps'] as Map))
          : const MarketingMix4Ps(),
      pestAnalysis: json['pestAnalysis'] != null
          ? PestAnalysis.fromJson(Map<String, dynamic>.from(json['pestAnalysis'] as Map))
          : const PestAnalysis(),
      competitorUsps: (json['competitorUsps'] as List?)
              ?.map((c) => CompetitorUsp.fromJson(Map<String, dynamic>.from(c as Map)))
              .toList() ??
          [],
      perceptualMapNarrative: json['perceptualMapNarrative'] as String? ?? '',
      perceptualMapInsight: json['perceptualMapInsight'] as String? ?? '',
      perceptualMapOpportunity: json['perceptualMapOpportunity'] as String? ?? '',
      creativePillars: (json['creativePillars'] as List?)
              ?.map((p) => ContentPillar.fromJson(Map<String, dynamic>.from(p as Map)))
              .toList() ??
          [],
      visualGuidelineNotes: json['visualGuidelineNotes'] as String? ?? '',
      brandPaletteHex: List<String>.from(json['brandPaletteHex'] as List? ?? ['#10B981', '#064E3B', '#8B5CF6', '#1E293B', '#F8FAFC']),
      sampleReelTopic: json['sampleReelTopic'] as String? ?? '',
      sampleReelHook: json['sampleReelHook'] as String? ?? '',
      sampleReelVisualScenes: json['sampleReelVisualScenes'] as String? ?? '',
      sampleReelCta: json['sampleReelCta'] as String? ?? '',
      sampleBlogTitle: json['sampleBlogTitle'] as String? ?? '',
      sampleBlogStorytellingIntro: json['sampleBlogStorytellingIntro'] as String? ?? '',
      sampleBlogPreview: json['sampleBlogPreview'] as String? ?? '',
      sampleSocialCaptionHook: json['sampleSocialCaptionHook'] as String? ?? '',
      sampleSocialCaptionBody: json['sampleSocialCaptionBody'] as String? ?? '',
      sampleSocialCaptionCta: json['sampleSocialCaptionCta'] as String? ?? '',
      sampleSocialHashtags: List<String>.from(json['sampleSocialHashtags'] as List? ?? []),
      seoAudit: json['seoAudit'] != null
          ? SeoAuditSummary.fromJson(Map<String, dynamic>.from(json['seoAudit'] as Map))
          : const SeoAuditSummary(),
      finalThoughtsSummary: json['finalThoughtsSummary'] as String? ?? '',
      finalThoughtsRecommendation: json['finalThoughtsRecommendation'] as String? ?? '',
      visualKeywords: List<String>.from(json['visualKeywords'] as List? ?? ['Authoritative', 'Professional', 'Modern', 'Trustworthy', 'Dynamic']),
      focusMoreOn: List<String>.from(json['focusMoreOn'] as List? ?? ['Executive collaboration', 'High-stakes presentations', 'Authentic team interactions', 'Data-driven results']),
      focusLessOn: List<String>.from(json['focusLessOn'] as List? ?? ['Generic stock handshakes', 'Empty auditoriums/offices', 'Sterile clip-art graphics', 'Overly promotional sales banners']),
      photographyQuote: json['photographyQuote'] as String? ?? "Customers don't just buy service features. They buy certainty, verified outcomes, and trusted execution.",
      typographySampleHeadline: json['typographySampleHeadline'] as String? ?? "CONNECT. INNOVATE. SCALE.",
      brandToneOfVoice: (json['brandToneOfVoice'] as List?)
          ?.map((e) => Map<String, String>.from(e as Map))
          .toList() ?? const [
        {'trait': 'AUTHORITATIVE', 'desc': 'Speaking with deep domain experience, verified results, and industry leadership.'},
        {'trait': 'CATALYTIC', 'desc': 'Inspiring decisive action, customer velocity, and ambitious growth.'},
        {'trait': 'RESULTS-DRIVEN', 'desc': 'Focusing on tangible business outcomes, customer value, and measurable ROI.'},
        {'trait': 'TRUSTWORTHY', 'desc': 'Consistent, transparent, and upholding the highest professional standards.'},
      ],
      brandColorDetails: Map<String, dynamic>.from(json['brandColorDetails'] as Map? ?? const {
        'primary': {'name': 'Slate Navy', 'hex': '#0F172A'},
        'secondary': {'name': 'Executive Indigo', 'hex': '#4F46E5'},
        'accent': {'name': 'Growth Emerald', 'hex': '#10B981'},
      }),
      contentFrameworkWeeks: (json['contentFrameworkWeeks'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ?? const [
        {
          'week': 'WEEK 1',
          'experienceStories': 'Customer Transformation Case Study',
          'educational': '3 Critical Mistakes to Avoid in Your Strategy',
          'corporate': 'Enterprise Solutions & Pilot Capabilities Overview',
          'testimonials': 'Client Testimonial (Execution Excellence)',
          'promotional': 'Schedule Your Strategic Discovery Consultation',
          'contentExamples': '• Case study breakdown\n• Mistake checklist\n• Enterprise solutions post\n• Client review quote\n• Consultation booking link',
        },
        {
          'week': 'WEEK 2',
          'experienceStories': 'Process Walkthrough: How We Deliver High-Impact Outcomes',
          'educational': 'Demystifying the Top Industry Misconceptions',
          'corporate': 'Tailored Advisory & High-Value Retainers',
          'testimonials': 'Partner Testimonial (Speed & Reliability)',
          'promotional': 'Download Our Comprehensive Industry Roadmap',
          'contentExamples': '• Workflow tour\n• Myth-busting carousel\n• Advisory highlight\n• Partner quote\n• Download resource link',
        },
        {
          'week': 'WEEK 3',
          'experienceStories': 'Behind the Scenes with Our Core Specialist Team',
          'educational': 'How to Measure Value vs Cost in Modern Solutions',
          'corporate': 'Executive Q&A on Emerging Market Trends',
          'testimonials': 'Client Review (Measurable ROI)',
          'promotional': 'Limited Consultation Openings for Upcoming Cohort',
          'contentExamples': '• Team spotlight\n• Value breakdown carousel\n• Executive interview clip\n• Client review quote\n• Calendar reservation link',
        },
        {
          'week': 'WEEK 4',
          'experienceStories': 'Monthly Milestone Recap & Strategic Wins',
          'educational': 'The 5 Essential Questions Every Leader Must Ask',
          'corporate': 'Long-Term Strategic Partnerships & Co-Innovation',
          'testimonials': 'Executive Sponsor Testimonial (Long-Term Impact)',
          'promotional': 'Get Started with Our Strategic Assessment',
          'contentExamples': '• Milestone wins video\n• Leadership checklist\n• Partnership overview\n• Executive review\n• Assessment signup link',
        },
      ],
      sampleReelHeadline: json['sampleReelHeadline'] as String? ?? 'Scale with Certainty',
      sampleReelMediaUrl: json['sampleReelMediaUrl'] as String?,
      sampleReelLink: json['sampleReelLink'] as String? ?? 'https://meet-marketers.com',
      socialPosts: (json['socialPosts'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ?? const [
        {
          'title': 'Enterprise Authority',
          'headline': 'BUILT ON TRUST. DRIVEN BY MEASURABLE RESULTS.',
          'body': 'We do not believe in one-size-fits-all templates.\n\nEvery initiative is tailored to your strategic objectives, backed by dedicated professionals who care about your long-term success.\n\nLearn more at our website.',
          'badge': 'VERIFIED EXCELLENCE',
          'hashtags': ['#BusinessGrowth', '#Strategy', '#Leadership', '#MeetMarketers'],
          'imageUrl': '',
        },
        {
          'title': 'Transformation Stories',
          'headline': 'WHAT SEPARATES INDUSTRY BENCHMARKS FROM THE REST.',
          'body': 'From initial strategic alignment to seamless execution, our team provides the clarity and accountability required to achieve market leadership.\n\nExplore how we help organizations scale.',
          'badge': 'PROVEN OUTCOMES',
          'hashtags': ['#Transformation', '#Execution', '#Scale', '#Innovation'],
          'imageUrl': '',
        },
        {
          'title': 'Executive Perspective',
          'headline': 'THE RIGHT STRATEGIC PARTNER MAKES ALL THE DIFFERENCE.',
          'body': 'Whether unlocking new market opportunities or accelerating high-stakes initiatives, having the right team in your corner changes everything.\n\nConnect with our specialists today.',
          'badge': 'STRATEGIC PARTNERSHIP',
          'hashtags': ['#StrategicPartner', '#Excellence', '#Leadership'],
          'imageUrl': '',
        },
      ],
      seoAssessmentText: json['seoAssessmentText'] as String? ?? 'Based on our review, we recommend prioritising high-intent service landing pages and technical on-page SEO quick wins in Phase 1 to capture qualified organic search and AI-assisted discovery.',
      seoAuditLink: json['seoAuditLink'] as String? ?? 'https://meet-marketers.com/seo-audit',
      visualDirectionImageUrl: json['visualDirectionImageUrl'] as String?,
    );
  }

  ProposalModel copyWith({
    String? id,
    String? amId,
    String? leadCompanyName,
    String? industry,
    String? websiteUrl,
    Map<String, String>? socialUrls,
    String? contactName,
    String? contactEmail,
    ProposalStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? sentAt,
    DateTime? convertedAt,
    String? convertedClientId,
    String? pdfStorageUrl,
    String? pitchDeckFileName,
    String? pitchDeckStorageUrl,
    String? extractedPitchDeckText,
    String? executiveSummaryPosition,
    String? executiveSummaryOpportunity,
    SwotMatrix? swot,
    MarketingMix4Ps? marketingMix4Ps,
    PestAnalysis? pestAnalysis,
    List<CompetitorUsp>? competitorUsps,
    String? perceptualMapNarrative,
    String? perceptualMapInsight,
    String? perceptualMapOpportunity,
    List<ContentPillar>? creativePillars,
    String? visualGuidelineNotes,
    List<String>? brandPaletteHex,
    String? sampleReelTopic,
    String? sampleReelHook,
    String? sampleReelVisualScenes,
    String? sampleReelCta,
    String? sampleBlogTitle,
    String? sampleBlogStorytellingIntro,
    String? sampleBlogPreview,
    String? sampleSocialCaptionHook,
    String? sampleSocialCaptionBody,
    String? sampleSocialCaptionCta,
    List<String>? sampleSocialHashtags,
    SeoAuditSummary? seoAudit,
    String? finalThoughtsSummary,
    String? finalThoughtsRecommendation,
    List<String>? visualKeywords,
    List<String>? focusMoreOn,
    List<String>? focusLessOn,
    String? photographyQuote,
    String? typographySampleHeadline,
    List<Map<String, String>>? brandToneOfVoice,
    Map<String, dynamic>? brandColorDetails,
    List<Map<String, dynamic>>? contentFrameworkWeeks,
    String? sampleReelHeadline,
    String? sampleReelMediaUrl,
    String? sampleReelLink,
    List<Map<String, dynamic>>? socialPosts,
    String? seoAssessmentText,
    String? seoAuditLink,
    String? visualDirectionImageUrl,
  }) {
    return ProposalModel(
      id: id ?? this.id,
      amId: amId ?? this.amId,
      leadCompanyName: leadCompanyName ?? this.leadCompanyName,
      industry: industry ?? this.industry,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      socialUrls: socialUrls ?? this.socialUrls,
      contactName: contactName ?? this.contactName,
      contactEmail: contactEmail ?? this.contactEmail,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      sentAt: sentAt ?? this.sentAt,
      convertedAt: convertedAt ?? this.convertedAt,
      convertedClientId: convertedClientId ?? this.convertedClientId,
      pdfStorageUrl: pdfStorageUrl ?? this.pdfStorageUrl,
      pitchDeckFileName: pitchDeckFileName ?? this.pitchDeckFileName,
      pitchDeckStorageUrl: pitchDeckStorageUrl ?? this.pitchDeckStorageUrl,
      extractedPitchDeckText: extractedPitchDeckText ?? this.extractedPitchDeckText,
      executiveSummaryPosition: executiveSummaryPosition ?? this.executiveSummaryPosition,
      executiveSummaryOpportunity: executiveSummaryOpportunity ?? this.executiveSummaryOpportunity,
      swot: swot ?? this.swot,
      marketingMix4Ps: marketingMix4Ps ?? this.marketingMix4Ps,
      pestAnalysis: pestAnalysis ?? this.pestAnalysis,
      competitorUsps: competitorUsps ?? this.competitorUsps,
      perceptualMapNarrative: perceptualMapNarrative ?? this.perceptualMapNarrative,
      perceptualMapInsight: perceptualMapInsight ?? this.perceptualMapInsight,
      perceptualMapOpportunity: perceptualMapOpportunity ?? this.perceptualMapOpportunity,
      creativePillars: creativePillars ?? this.creativePillars,
      visualGuidelineNotes: visualGuidelineNotes ?? this.visualGuidelineNotes,
      brandPaletteHex: brandPaletteHex ?? this.brandPaletteHex,
      sampleReelTopic: sampleReelTopic ?? this.sampleReelTopic,
      sampleReelHook: sampleReelHook ?? this.sampleReelHook,
      sampleReelVisualScenes: sampleReelVisualScenes ?? this.sampleReelVisualScenes,
      sampleReelCta: sampleReelCta ?? this.sampleReelCta,
      sampleBlogTitle: sampleBlogTitle ?? this.sampleBlogTitle,
      sampleBlogStorytellingIntro: sampleBlogStorytellingIntro ?? this.sampleBlogStorytellingIntro,
      sampleBlogPreview: sampleBlogPreview ?? this.sampleBlogPreview,
      sampleSocialCaptionHook: sampleSocialCaptionHook ?? this.sampleSocialCaptionHook,
      sampleSocialCaptionBody: sampleSocialCaptionBody ?? this.sampleSocialCaptionBody,
      sampleSocialCaptionCta: sampleSocialCaptionCta ?? this.sampleSocialCaptionCta,
      sampleSocialHashtags: sampleSocialHashtags ?? this.sampleSocialHashtags,
      seoAudit: seoAudit ?? this.seoAudit,
      finalThoughtsSummary: finalThoughtsSummary ?? this.finalThoughtsSummary,
      finalThoughtsRecommendation: finalThoughtsRecommendation ?? this.finalThoughtsRecommendation,
      visualKeywords: visualKeywords ?? this.visualKeywords,
      focusMoreOn: focusMoreOn ?? this.focusMoreOn,
      focusLessOn: focusLessOn ?? this.focusLessOn,
      photographyQuote: photographyQuote ?? this.photographyQuote,
      typographySampleHeadline: typographySampleHeadline ?? this.typographySampleHeadline,
      brandToneOfVoice: brandToneOfVoice ?? this.brandToneOfVoice,
      brandColorDetails: brandColorDetails ?? this.brandColorDetails,
      contentFrameworkWeeks: contentFrameworkWeeks ?? this.contentFrameworkWeeks,
      sampleReelHeadline: sampleReelHeadline ?? this.sampleReelHeadline,
      sampleReelMediaUrl: sampleReelMediaUrl ?? this.sampleReelMediaUrl,
      sampleReelLink: sampleReelLink ?? this.sampleReelLink,
      socialPosts: socialPosts ?? this.socialPosts,
      seoAssessmentText: seoAssessmentText ?? this.seoAssessmentText,
      seoAuditLink: seoAuditLink ?? this.seoAuditLink,
      visualDirectionImageUrl: visualDirectionImageUrl ?? this.visualDirectionImageUrl,
    );
  }
}
