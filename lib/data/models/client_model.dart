import 'package:equatable/equatable.dart';

/// Immutable data model for a client workspace.
/// Maps to Firestore path: /account_managers/{amId}/clients/{clientId}
class ClientModel extends Equatable {
  final String id;
  final String name;
  final String industry;
  final String? websiteUrl;
  final String? logoUrl;
  final Map<String, String> questionnaireAnswers;
  final List<String> competitors;
  final List<String> targetRoleModels;
  final String? pitchDeckStoragePath;
  final ClientStatus status;
  final DateTime createdAt;
  final DateTime lastActivity;

  const ClientModel({
    required this.id,
    required this.name,
    required this.industry,
    this.websiteUrl,
    this.logoUrl,
    this.questionnaireAnswers = const {},
    this.competitors = const [],
    this.targetRoleModels = const [],
    this.pitchDeckStoragePath,
    this.status = ClientStatus.active,
    required this.createdAt,
    required this.lastActivity,
  });

  factory ClientModel.fromJson(String id, Map<String, dynamic> json) {
    return ClientModel(
      id: id,
      name: json['name'] as String? ?? '',
      industry: json['industry'] as String? ?? '',
      websiteUrl: json['websiteUrl'] as String?,
      logoUrl: json['logoUrl'] as String?,
      questionnaireAnswers: Map<String, String>.from(
        json['questionnaireAnswers'] as Map? ?? {},
      ),
      competitors: List<String>.from(json['competitors'] as List? ?? []),
      targetRoleModels: List<String>.from(json['targetRoleModels'] as List? ?? []),
      pitchDeckStoragePath: json['pitchDeckStoragePath'] as String?,
      status: ClientStatus.fromString(json['status'] as String? ?? 'active'),
      createdAt: _parseTimestamp(json['createdAt']),
      lastActivity: _parseTimestamp(json['lastActivity']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'industry': industry,
      'websiteUrl': websiteUrl,
      'logoUrl': logoUrl,
      'questionnaireAnswers': questionnaireAnswers,
      'competitors': competitors,
      'targetRoleModels': targetRoleModels,
      'pitchDeckStoragePath': pitchDeckStoragePath,
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'lastActivity': lastActivity.toIso8601String(),
    };
  }

  ClientModel copyWith({
    String? name,
    String? industry,
    String? websiteUrl,
    String? logoUrl,
    Map<String, String>? questionnaireAnswers,
    List<String>? competitors,
    List<String>? targetRoleModels,
    String? pitchDeckStoragePath,
    ClientStatus? status,
    DateTime? lastActivity,
  }) {
    return ClientModel(
      id: id,
      name: name ?? this.name,
      industry: industry ?? this.industry,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      questionnaireAnswers: questionnaireAnswers ?? this.questionnaireAnswers,
      competitors: competitors ?? this.competitors,
      targetRoleModels: targetRoleModels ?? this.targetRoleModels,
      pitchDeckStoragePath: pitchDeckStoragePath ?? this.pitchDeckStoragePath,
      status: status ?? this.status,
      createdAt: createdAt,
      lastActivity: lastActivity ?? this.lastActivity,
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
  List<Object?> get props => [
    id, name, industry, websiteUrl, logoUrl, questionnaireAnswers,
    competitors, targetRoleModels, pitchDeckStoragePath, status, createdAt, lastActivity,
  ];
}

enum ClientStatus {
  active('active'),
  onboarding('onboarding'),
  archived('archived');

  const ClientStatus(this.value);
  final String value;

  static ClientStatus fromString(String value) {
    return ClientStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ClientStatus.active,
    );
  }

  String get label {
    switch (this) {
      case ClientStatus.active:
        return 'Active';
      case ClientStatus.onboarding:
        return 'Onboarding';
      case ClientStatus.archived:
        return 'Archived';
    }
  }
}

/// Standard questionnaire fields for the discovery intake form
abstract class QuestionnaireKeys {
  static const String brandVoice = 'brandVoice';
  static const String targetAudience = 'targetAudience';
  static const String coreDifferentiator = 'coreDifferentiator';
  static const String primaryGoal = 'primaryGoal';
  static const String contentPillars = 'contentPillars';
  static const String pastWins = 'pastWins';
  static const String painPoints = 'painPoints';
  static const String budgetRange = 'budgetRange';

  static const Map<String, String> labels = {
    brandVoice: 'Brand Voice & Tone',
    targetAudience: 'Target Audience Description',
    coreDifferentiator: 'Core Differentiator / USP',
    primaryGoal: 'Primary Marketing Goal',
    contentPillars: 'Content Pillars (comma separated)',
    pastWins: 'Past Marketing Wins',
    painPoints: 'Current Pain Points',
    budgetRange: 'Approximate Budget Range',
  };
}
