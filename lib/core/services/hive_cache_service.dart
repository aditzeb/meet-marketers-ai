import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Web-safe local storage caching service using Hive / IndexedDB.
class HiveCacheService {
  static final HiveCacheService instance = HiveCacheService._internal();
  HiveCacheService._internal();

  static const String clientsBoxName = 'mm_clients_cache';
  static const String draftsBoxName = 'mm_drafts_cache';
  static const String deliverablesBoxName = 'mm_deliverables_cache';
  static const String userBoxName = 'mm_user_session';
  static const String vettedKnowledgeBoxName = 'mm_vetted_knowledge';

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await Hive.initFlutter();
      await Hive.openBox(clientsBoxName);
      await Hive.openBox(draftsBoxName);
      await Hive.openBox(deliverablesBoxName);
      await Hive.openBox(userBoxName);
      await Hive.openBox(vettedKnowledgeBoxName);
      _isInitialized = true;
      debugPrint('HiveCacheService initialized successfully.');
    } catch (e) {
      debugPrint('HiveCacheService init warning: $e');
    }
  }

  // ── User Session ─────────────────────────────────────────────────────────
  Future<void> saveUserSession(Map<String, dynamic> userData) async {
    final box = Hive.box(userBoxName);
    await box.put('current_user', userData);
  }

  Map<String, dynamic>? getUserSession() {
    final box = Hive.box(userBoxName);
    final data = box.get('current_user');
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  Future<void> clearUserSession() async {
    final box = Hive.box(userBoxName);
    await box.delete('current_user');
  }

  // ── Client Draft Caching ──────────────────────────────────────────────────
  Future<void> saveClientData(String clientId, Map<String, dynamic> clientJson) async {
    final box = Hive.box(clientsBoxName);
    await box.put(clientId, clientJson);
  }

  Map<String, dynamic>? getClientData(String clientId) {
    final box = Hive.box(clientsBoxName);
    final data = box.get(clientId);
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  List<Map<String, dynamic>> getAllClientsData() {
    final box = Hive.box(clientsBoxName);
    final list = <Map<String, dynamic>>[];
    for (var key in box.keys) {
      final item = box.get(key);
      if (item is Map) {
        list.add(Map<String, dynamic>.from(item));
      }
    }
    return list;
  }

  // ── Draft Text Buffer ─────────────────────────────────────────────────────
  Future<void> saveDraftBuffer(String key, String content) async {
    final box = Hive.box(draftsBoxName);
    await box.put(key, content);
  }

  String? getDraftBuffer(String key) {
    final box = Hive.box(draftsBoxName);
    return box.get(key) as String?;
  }

  // ── Deliverables Cache ────────────────────────────────────────────────────
  Future<void> saveDeliverable(String key, Map<String, dynamic> json) async {
    final box = Hive.box(deliverablesBoxName);
    await box.put(key, json);
  }

  Map<String, dynamic>? getDeliverable(String key) {
    final box = Hive.box(deliverablesBoxName);
    final data = box.get(key);
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  // ── Step 4: Vetted Reference Flywheel Caching ────────────────────────────
  Future<void> saveVettedDeliverable(String clientId, String deliverableType, String content) async {
    if (content.trim().isEmpty) return;
    try {
      final box = Hive.box(vettedKnowledgeBoxName);
      final key = '${clientId}_$deliverableType';
      await box.put(key, {
        'clientId': clientId,
        'type': deliverableType,
        'content': content.trim(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Warning saving vetted deliverable: $e');
    }
  }

  List<String> getVettedHistory(String clientId) {
    try {
      final box = Hive.box(vettedKnowledgeBoxName);
      final list = <String>[];
      for (var key in box.keys) {
        if (key.toString().startsWith(clientId)) {
          final item = box.get(key);
          if (item is Map && item['content'] != null) {
            final contentStr = item['content'].toString();
            if (contentStr.isNotEmpty) {
              list.add(contentStr);
            }
          }
        }
      }
      return list;
    } catch (e) {
      return [];
    }
  }
}
