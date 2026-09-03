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
    );
  }

  ProposalModel copyWith({
    String? leadCompanyName,
    String? industry,
    String? websiteUrl,
    Map<String, String>? socialUrls,
    String? contactName,
    String? contactEmail,
    ProposalStatus? status,
    DateTime? updatedAt,
    DateTime? sentAt,
    DateTime? convertedAt,
    String? convertedClientId,
    String? pdfStorageUrl,
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
  }) {
    return ProposalModel(
      id: id,
      amId: amId,
      leadCompanyName: leadCompanyName ?? this.leadCompanyName,
      industry: industry ?? this.industry,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      socialUrls: socialUrls ?? this.socialUrls,
      contactName: contactName ?? this.contactName,
      contactEmail: contactEmail ?? this.contactEmail,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      sentAt: sentAt ?? this.sentAt,
      convertedAt: convertedAt ?? this.convertedAt,
      convertedClientId: convertedClientId ?? this.convertedClientId,
      pdfStorageUrl: pdfStorageUrl ?? this.pdfStorageUrl,
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
    );
  }
}
