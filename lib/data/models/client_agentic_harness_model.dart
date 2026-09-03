import 'package:equatable/equatable.dart';

/// Single event in the client agentic learning evolution timeline
class HarnessLearningEvent extends Equatable {
  final String id;
  final String title;
  final String description;
  final String type; // 'pitch_deck_ingestion', 'questionnaire_sync', 'user_rule', 'deliverable_edit'
  final DateTime timestamp;

  const HarnessLearningEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.timestamp,
  });

  factory HarnessLearningEvent.fromJson(Map<String, dynamic> json) {
    return HarnessLearningEvent(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: json['type'] as String? ?? 'general',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, title, description, type, timestamp];
}

/// Persistent, evolving Agentic Knowledge & Voice Profile for a specific client.
/// Stored in Firestore: /account_managers/{amId}/clients/{clientId}/agentic_harness/profile
class ClientAgenticHarnessModel extends Equatable {
  final String clientId;
  final String brandVoice;
  final List<String> coreValueProps;
  final Map<String, String> targetAudienceProfile;
  final List<String> competitiveMoats;
  final List<String> learnedRules;
  final String knowledgeDigest;
  final List<HarnessLearningEvent> evolutionLog;
  final DateTime lastSynthesized;
  final int version;

  const ClientAgenticHarnessModel({
    required this.clientId,
    this.brandVoice = 'Professional, authoritative, and growth-oriented.',
    this.coreValueProps = const [],
    this.targetAudienceProfile = const {},
    this.competitiveMoats = const [],
    this.learnedRules = const [],
    this.knowledgeDigest = '',
    this.evolutionLog = const [],
    required this.lastSynthesized,
    this.version = 1,
  });

  factory ClientAgenticHarnessModel.initial(String clientId) {
    return ClientAgenticHarnessModel(
      clientId: clientId,
      brandVoice: 'Professional, consultative, and conversion-driven.',
      coreValueProps: const [],
      targetAudienceProfile: const {},
      competitiveMoats: const [],
      learnedRules: const [],
      knowledgeDigest: 'No discovery inputs ingested yet.',
      evolutionLog: [
        HarnessLearningEvent(
          id: 'init-1',
          title: 'Agentic Harness Initialized',
          description: 'Harness listening for client discovery inputs and pitch decks.',
          type: 'system',
          timestamp: DateTime.now(),
        ),
      ],
      lastSynthesized: DateTime.now(),
      version: 1,
    );
  }

  factory ClientAgenticHarnessModel.fromJson(Map<String, dynamic> json) {
    return ClientAgenticHarnessModel(
      clientId: json['clientId'] as String? ?? '',
      brandVoice: json['brandVoice'] as String? ?? 'Professional, consultative, and conversion-driven.',
      coreValueProps: List<String>.from(json['coreValueProps'] as List? ?? []),
      targetAudienceProfile: Map<String, String>.from(json['targetAudienceProfile'] as Map? ?? {}),
      competitiveMoats: List<String>.from(json['competitiveMoats'] as List? ?? []),
      learnedRules: List<String>.from(json['learnedRules'] as List? ?? []),
      knowledgeDigest: json['knowledgeDigest'] as String? ?? '',
      evolutionLog: (json['evolutionLog'] as List? ?? [])
          .map((e) => HarnessLearningEvent.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      lastSynthesized: json['lastSynthesized'] != null
          ? DateTime.tryParse(json['lastSynthesized'] as String) ?? DateTime.now()
          : DateTime.now(),
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'brandVoice': brandVoice,
      'coreValueProps': coreValueProps,
      'targetAudienceProfile': targetAudienceProfile,
      'competitiveMoats': competitiveMoats,
      'learnedRules': learnedRules,
      'knowledgeDigest': knowledgeDigest,
      'evolutionLog': evolutionLog.map((e) => e.toJson()).toList(),
      'lastSynthesized': lastSynthesized.toIso8601String(),
      'version': version,
    };
  }

  ClientAgenticHarnessModel copyWith({
    String? clientId,
    String? brandVoice,
    List<String>? coreValueProps,
    Map<String, String>? targetAudienceProfile,
    List<String>? competitiveMoats,
    List<String>? learnedRules,
    String? knowledgeDigest,
    List<HarnessLearningEvent>? evolutionLog,
    DateTime? lastSynthesized,
    int? version,
  }) {
    return ClientAgenticHarnessModel(
      clientId: clientId ?? this.clientId,
      brandVoice: brandVoice ?? this.brandVoice,
      coreValueProps: coreValueProps ?? this.coreValueProps,
      targetAudienceProfile: targetAudienceProfile ?? this.targetAudienceProfile,
      competitiveMoats: competitiveMoats ?? this.competitiveMoats,
      learnedRules: learnedRules ?? this.learnedRules,
      knowledgeDigest: knowledgeDigest ?? this.knowledgeDigest,
      evolutionLog: evolutionLog ?? this.evolutionLog,
      lastSynthesized: lastSynthesized ?? this.lastSynthesized,
      version: version ?? this.version,
    );
  }

  @override
  List<Object?> get props => [
        clientId,
        brandVoice,
        coreValueProps,
        targetAudienceProfile,
        competitiveMoats,
        learnedRules,
        knowledgeDigest,
        evolutionLog,
        lastSynthesized,
        version,
      ];
}
