import 'package:equatable/equatable.dart';

/// Immutable data model for strategy deliverables.
/// Maps to Firestore path: /account_managers/{amId}/clients/{clientId}/deliverables/strategy
class StrategyDeliverableModel extends Equatable {
  final String id;
  final String clientId;
  final SwotMatrix swot;
  final List<SeoKeyword> seoKeywords;
  final List<PersonaModel> personas;
  final List<CalendarEvent> calendarEvents;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StrategyDeliverableModel({
    required this.id,
    required this.clientId,
    required this.swot,
    this.seoKeywords = const [],
    this.personas = const [],
    this.calendarEvents = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory StrategyDeliverableModel.fromJson(String id, Map<String, dynamic> json) {
    return StrategyDeliverableModel(
      id: id,
      clientId: json['clientId'] as String? ?? '',
      swot: SwotMatrix.fromJson(json['swot'] as Map<String, dynamic>? ?? {}),
      seoKeywords: (json['seoKeywords'] as List? ?? [])
          .map((e) => SeoKeyword.fromJson(e as Map<String, dynamic>))
          .toList(),
      personas: (json['personas'] as List? ?? [])
          .map((e) => PersonaModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      calendarEvents: (json['calendarEvents'] as List? ?? [])
          .map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: _parseTimestamp(json['createdAt']),
      updatedAt: _parseTimestamp(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'swot': swot.toJson(),
      'seoKeywords': seoKeywords.map((e) => e.toJson()).toList(),
      'personas': personas.map((e) => e.toJson()).toList(),
      'calendarEvents': calendarEvents.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  StrategyDeliverableModel copyWith({
    SwotMatrix? swot,
    List<SeoKeyword>? seoKeywords,
    List<PersonaModel>? personas,
    List<CalendarEvent>? calendarEvents,
    DateTime? updatedAt,
  }) {
    return StrategyDeliverableModel(
      id: id,
      clientId: clientId,
      swot: swot ?? this.swot,
      seoKeywords: seoKeywords ?? this.seoKeywords,
      personas: personas ?? this.personas,
      calendarEvents: calendarEvents ?? this.calendarEvents,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
  List<Object?> get props => [id, clientId, swot, seoKeywords, personas, calendarEvents, createdAt, updatedAt];
}

/// SWOT Matrix — 2x2 structure
class SwotMatrix extends Equatable {
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> opportunities;
  final List<String> threats;

  const SwotMatrix({
    this.strengths = const [],
    this.weaknesses = const [],
    this.opportunities = const [],
    this.threats = const [],
  });

  factory SwotMatrix.fromJson(Map<String, dynamic> json) {
    return SwotMatrix(
      strengths: List<String>.from(json['strengths'] as List? ?? []),
      weaknesses: List<String>.from(json['weaknesses'] as List? ?? []),
      opportunities: List<String>.from(json['opportunities'] as List? ?? []),
      threats: List<String>.from(json['threats'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'strengths': strengths,
      'weaknesses': weaknesses,
      'opportunities': opportunities,
      'threats': threats,
    };
  }

  SwotMatrix copyWith({
    List<String>? strengths,
    List<String>? weaknesses,
    List<String>? opportunities,
    List<String>? threats,
  }) {
    return SwotMatrix(
      strengths: strengths ?? this.strengths,
      weaknesses: weaknesses ?? this.weaknesses,
      opportunities: opportunities ?? this.opportunities,
      threats: threats ?? this.threats,
    );
  }

  static SwotMatrix get mock => const SwotMatrix(
    strengths: ['Strong brand recognition', 'Proprietary technology', 'Expert team'],
    weaknesses: ['Limited budget allocation', 'Narrow content distribution', 'Long sales cycle'],
    opportunities: ['Growing LinkedIn audience', 'Competitor content gaps', 'Emerging SEO niches'],
    threats: ['Market saturation', 'Platform algorithm shifts', 'Rising ad costs'],
  );

  @override
  List<Object?> get props => [strengths, weaknesses, opportunities, threats];
}

/// SEO Keyword entry for strategy planner
class SeoKeyword extends Equatable {
  final String keyword;
  final int searchVolume;
  final double difficulty;
  final String intent;
  final String? targetPage;

  const SeoKeyword({
    required this.keyword,
    this.searchVolume = 0,
    this.difficulty = 0.0,
    this.intent = 'informational',
    this.targetPage,
  });

  factory SeoKeyword.fromJson(Map<String, dynamic> json) {
    return SeoKeyword(
      keyword: json['keyword'] as String? ?? '',
      searchVolume: json['searchVolume'] as int? ?? 0,
      difficulty: (json['difficulty'] as num?)?.toDouble() ?? 0.0,
      intent: json['intent'] as String? ?? 'informational',
      targetPage: json['targetPage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'keyword': keyword,
      'searchVolume': searchVolume,
      'difficulty': difficulty,
      'intent': intent,
      'targetPage': targetPage,
    };
  }

  @override
  List<Object?> get props => [keyword, searchVolume, difficulty, intent, targetPage];
}

/// Target Persona card
class PersonaModel extends Equatable {
  final String id;
  final String name;
  final String jobTitle;
  final String industry;
  final List<String> goals;
  final List<String> painPoints;
  final List<String> channels;
  final String? aiSummary;

  const PersonaModel({
    required this.id,
    required this.name,
    required this.jobTitle,
    required this.industry,
    this.goals = const [],
    this.painPoints = const [],
    this.channels = const [],
    this.aiSummary,
  });

  factory PersonaModel.fromJson(Map<String, dynamic> json) {
    return PersonaModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      jobTitle: json['jobTitle'] as String? ?? '',
      industry: json['industry'] as String? ?? '',
      goals: List<String>.from(json['goals'] as List? ?? []),
      painPoints: List<String>.from(json['painPoints'] as List? ?? []),
      channels: List<String>.from(json['channels'] as List? ?? []),
      aiSummary: json['aiSummary'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'jobTitle': jobTitle,
      'industry': industry,
      'goals': goals,
      'painPoints': painPoints,
      'channels': channels,
      'aiSummary': aiSummary,
    };
  }

  @override
  List<Object?> get props => [id, name, jobTitle, industry, goals, painPoints, channels, aiSummary];
}

/// Social Media Calendar event
class CalendarEvent extends Equatable {
  final String id;
  final String title;
  final String platform;
  final DateTime scheduledDate;
  final String contentType;
  final String? content;
  final CalendarEventStatus status;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.platform,
    required this.scheduledDate,
    this.contentType = 'post',
    this.content,
    this.status = CalendarEventStatus.planned,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      platform: json['platform'] as String? ?? '',
      scheduledDate: _parseTimestamp(json['scheduledDate']),
      contentType: json['contentType'] as String? ?? 'post',
      content: json['content'] as String?,
      status: CalendarEventStatus.fromString(json['status'] as String? ?? 'planned'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'platform': platform,
      'scheduledDate': scheduledDate.toIso8601String(),
      'contentType': contentType,
      'content': content,
      'status': status.value,
    };
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
  List<Object?> get props => [id, title, platform, scheduledDate, contentType, content, status];
}

enum CalendarEventStatus {
  planned('planned'),
  drafted('drafted'),
  scheduled('scheduled'),
  published('published');

  const CalendarEventStatus(this.value);
  final String value;

  static CalendarEventStatus fromString(String value) {
    return CalendarEventStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CalendarEventStatus.planned,
    );
  }
}
