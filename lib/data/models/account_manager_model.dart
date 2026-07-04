import 'package:equatable/equatable.dart';

/// Immutable data model for an Account Manager's profile.
/// Maps to Firestore path: /account_managers/{amId}
class AccountManagerModel extends Equatable {
  final String id;
  final String displayName;
  final String email;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final int totalClients;

  const AccountManagerModel({
    required this.id,
    required this.displayName,
    required this.email,
    this.avatarUrl,
    required this.createdAt,
    required this.lastLoginAt,
    this.totalClients = 0,
  });

  factory AccountManagerModel.fromJson(String id, Map<String, dynamic> json) {
    return AccountManagerModel(
      id: id,
      displayName: json['displayName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      createdAt: _parseTimestamp(json['createdAt']),
      lastLoginAt: _parseTimestamp(json['lastLoginAt']),
      totalClients: json['totalClients'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'email': email,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'totalClients': totalClients,
    };
  }

  AccountManagerModel copyWith({
    String? displayName,
    String? email,
    String? avatarUrl,
    DateTime? lastLoginAt,
    int? totalClients,
  }) {
    return AccountManagerModel(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      totalClients: totalClients ?? this.totalClients,
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    // Firestore Timestamp
    try {
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return DateTime.now();
    }
  }

  @override
  List<Object?> get props => [id, displayName, email, avatarUrl, createdAt, lastLoginAt, totalClients];
}
