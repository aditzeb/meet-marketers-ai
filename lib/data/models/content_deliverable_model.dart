import 'package:equatable/equatable.dart';

/// Generated Media Asset for Photo, Video & Captions
class GeneratedMediaAsset extends Equatable {
  final String imageUrl;
  final String videoUrl;
  final String caption;
  final String hashtags;
  final String prompt;
  final List<VideoScene> storyboard;

  const GeneratedMediaAsset({
    required this.imageUrl,
    required this.videoUrl,
    required this.caption,
    required this.hashtags,
    required this.prompt,
    required this.storyboard,
  });

  @override
  List<Object?> get props => [imageUrl, videoUrl, caption, hashtags, prompt, storyboard];
}

class VideoScene extends Equatable {
  final int sceneNumber;
  final String timecode;
  final String visualDescription;
  final String voiceoverScript;
  final String caption;
  final String cameraAngle;

  const VideoScene({
    required this.sceneNumber,
    required this.timecode,
    required this.visualDescription,
    required this.voiceoverScript,
    required this.caption,
    required this.cameraAngle,
  });

  @override
  List<Object?> get props => [sceneNumber, timecode, visualDescription, voiceoverScript, caption, cameraAngle];
}

/// Immutable data model for AI-generated content deliverables.
/// Maps to Firestore path: /account_managers/{amId}/clients/{clientId}/deliverables/content
class ContentDeliverableModel extends Equatable {
  final String id;
  final ContentType type;
  final String aiGeneratedText;
  final String vettedOutputText;
  final bool isVetted;
  final VettingStatus status;
  final String? lastModifiedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final GeneratedMediaAsset? mediaAsset;

  const ContentDeliverableModel({
    required this.id,
    required this.type,
    this.aiGeneratedText = '',
    this.vettedOutputText = '',
    this.isVetted = false,
    this.status = VettingStatus.draft,
    this.lastModifiedBy,
    required this.createdAt,
    required this.updatedAt,
    this.mediaAsset,
  });

  factory ContentDeliverableModel.fromJson(String id, Map<String, dynamic> json) {
    return ContentDeliverableModel(
      id: id,
      type: ContentType.fromString(json['type'] as String? ?? 'copy'),
      aiGeneratedText: json['aiGeneratedText'] as String? ?? '',
      vettedOutputText: json['vettedOutputText'] as String? ?? '',
      isVetted: json['isVetted'] as bool? ?? false,
      status: VettingStatus.fromString(json['status'] as String? ?? 'draft'),
      lastModifiedBy: json['lastModifiedBy'] as String?,
      createdAt: _parseTimestamp(json['createdAt']),
      updatedAt: _parseTimestamp(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'aiGeneratedText': aiGeneratedText,
      'vettedOutputText': vettedOutputText,
      'isVetted': isVetted,
      'status': status.value,
      'lastModifiedBy': lastModifiedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ContentDeliverableModel copyWith({
    ContentType? type,
    String? aiGeneratedText,
    String? vettedOutputText,
    bool? isVetted,
    VettingStatus? status,
    String? lastModifiedBy,
    DateTime? updatedAt,
    GeneratedMediaAsset? mediaAsset,
  }) {
    return ContentDeliverableModel(
      id: id,
      type: type ?? this.type,
      aiGeneratedText: aiGeneratedText ?? this.aiGeneratedText,
      vettedOutputText: vettedOutputText ?? this.vettedOutputText,
      isVetted: isVetted ?? this.isVetted,
      status: status ?? this.status,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      mediaAsset: mediaAsset ?? this.mediaAsset,
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    try {
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return DateTime.now();
    }
  }

  @override
  List<Object?> get props => [id, type, aiGeneratedText, vettedOutputText, isVetted, status, lastModifiedBy, createdAt, updatedAt, mediaAsset];
}

enum ContentType {
  socialMediaPosts('socialMediaPosts', 'Social Media Posts'),
  blogArticles('blogArticles', 'Blog Articles'),
  emailCampaign('emailCampaign', 'Email Campaign'),
  seoKeywordAudit('seoKeywordAudit', 'SEO Keyword Audit'),
  seoTechnicalAudit('seoTechnicalAudit', 'SEO Technical Audit'),
  introDeck('introDeck', 'Introduction Deck'),
  salesPitchDeck('salesPitchDeck', 'Sales Pitch Deck'),
  explainerVideos('explainerVideos', 'Explainer Videos'),
  testimonialVideos('testimonialVideos', 'Testimonial Videos'),
  otherDesigns('otherDesigns', 'Other Designs'),
  otherCopies('otherCopies', 'Other Copies');

  const ContentType(this.value, this.label);
  final String value;
  final String label;

  static ContentType fromString(String value) {
    return ContentType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ContentType.socialMediaPosts,
    );
  }
}

enum VettingStatus {
  draft('draft', 'Draft / AI Generated'),
  inReview('inReview', 'In Review'),
  vetted('vetted', 'Vetted & Approved'),
  locked('locked', 'Locked & Exported');

  const VettingStatus(this.value, this.label);
  final String value;
  final String label;

  static VettingStatus fromString(String value) {
    return VettingStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => VettingStatus.draft,
    );
  }

  VettingStatus get nextStatus {
    switch (this) {
      case VettingStatus.draft:
        return VettingStatus.inReview;
      case VettingStatus.inReview:
        return VettingStatus.vetted;
      case VettingStatus.vetted:
        return VettingStatus.locked;
      case VettingStatus.locked:
        return VettingStatus.locked;
    }
  }
}
