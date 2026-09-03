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
  final String role; // 'admin' or 'accountManager'
  final List<String> assignedClientIds;

  const AccountManagerModel({
    required this.id,
    required this.displayName,
    required this.email,
    this.avatarUrl,
    required this.createdAt,
    required this.lastLoginAt,
    this.totalClients = 0,
    this.role = 'pending',
    this.assignedClientIds = const [],
  });

  bool get isSuperAdmin => email.toLowerCase().trim() == 'aditya@herbalties.com';
  bool get isAdmin => isSuperAdmin || role.toLowerCase() == 'admin';
  bool get isAccountManager => !isAdmin && !isPending && role.toLowerCase() == 'accountmanager';
  bool get isPending => !isAdmin && (role.toLowerCase() == 'pending' || role.toLowerCase() == 'unassigned');
  bool get hasActiveRole => !isPending && (isAdmin || role.toLowerCase() == 'accountmanager');

  bool canAccessClient(String clientId) => hasActiveRole && (isAdmin || assignedClientIds.contains(clientId));

  factory AccountManagerModel.fromJson(String id, Map<String, dynamic> json) {
    final email = (json['email'] as String? ?? '').trim();
    String role = (json['role'] as String? ?? 'pending').trim();
    if (email.toLowerCase() == 'aditya@herbalties.com') {
      role = 'admin';
    }

    return AccountManagerModel(
      id: id,
      displayName: json['displayName'] as String? ?? '',
      email: email,
      avatarUrl: json['avatarUrl'] as String?,
      createdAt: _parseTimestamp(json['createdAt']),
      lastLoginAt: _parseTimestamp(json['lastLoginAt']),
      totalClients: json['totalClients'] as int? ?? 0,
      role: role,
      assignedClientIds: (json['assignedClientIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  Map<String, dynamic> toJson() {
    final cleanEmail = email.trim();
    final effectiveRole = cleanEmail.toLowerCase() == 'aditya@herbalties.com' ? 'admin' : role;

    return {
      'displayName': displayName,
      'email': cleanEmail,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'totalClients': totalClients,
      'role': effectiveRole,
      'assignedClientIds': assignedClientIds,
    };
  }

  AccountManagerModel copyWith({
    String? displayName,
    String? email,
    String? avatarUrl,
    DateTime? lastLoginAt,
    int? totalClients,
    String? role,
    List<String>? assignedClientIds,
  }) {
    return AccountManagerModel(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      totalClients: totalClients ?? this.totalClients,
      role: role ?? this.role,
      assignedClientIds: assignedClientIds ?? this.assignedClientIds,
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
  List<Object?> get props => [
        id,
        displayName,
        email,
        avatarUrl,
        createdAt,
        lastLoginAt,
        totalClients,
        role,
        assignedClientIds,
      ];
}
