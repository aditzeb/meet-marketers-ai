import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../data/models/client_agentic_harness_model.dart';
import '../../data/models/client_model.dart';
import 'firebase_service.dart';
import 'gemini_service.dart';

/// Service managing client-specific agentic learning, memory persistence, and context synthesis.
class ClientAgenticHarnessService {
  static final ClientAgenticHarnessService instance = ClientAgenticHarnessService._internal();
  ClientAgenticHarnessService._internal();

  // In-memory cache keyed by clientId
  final Map<String, ClientAgenticHarnessModel> _cache = {};

  /// Synchronous fast getter from cache
  ClientAgenticHarnessModel? getCachedHarness(String clientId) => _cache[clientId];

  /// Get or initialize harness profile for a client
  Future<ClientAgenticHarnessModel> getHarness(String amId, String clientId) async {
    if (_cache.containsKey(clientId)) {
      return _cache[clientId]!;
    }

    final data = await FirebaseService.instance.getClientAgenticHarness(amId, clientId);
    if (data != null) {
      final harness = ClientAgenticHarnessModel.fromJson(data);
      _cache[clientId] = harness;
      return harness;
    }

    final initial = ClientAgenticHarnessModel.initial(clientId);
    _cache[clientId] = initial;
    await FirebaseService.instance.saveClientAgenticHarness(amId, clientId, initial.toJson());
    return initial;
  }

  /// Synthesize client inputs, pitch decks, and discovery responses into an evolving knowledge profile
  Future<ClientAgenticHarnessModel> synthesizeHarness({
    required ClientModel client,
    String amId = 'am-default',
    String trigger = 'discovery_sync',
  }) async {
    final existing = await getHarness(amId, client.id);

    // Build reflection prompt for OpenRouter
    final prompt = '''You are an elite Agentic Knowledge Extraction engine.
Synthesize the following discovery inputs, questionnaire answers, and pitch deck for client "${client.name}" (${client.industry}).

Extracted Client Information:
- Client Name: ${client.name}
- Industry: ${client.industry}
- Website: ${client.websiteUrl ?? 'N/A'}
- Discovery Questionnaire: ${jsonEncode(client.questionnaireAnswers)}
- Direct Competitors: ${client.competitors.join(', ')}
- Aspirational Role Models: ${client.targetRoleModels.join(', ')}
- Ingested Pitch Deck Excerpt:
${client.extractedPdfContent != null && client.extractedPdfContent!.isNotEmpty ? (client.extractedPdfContent!.length > 4000 ? client.extractedPdfContent!.substring(0, 4000) : client.extractedPdfContent) : 'No pitch deck uploaded yet.'}

Output a VALID JSON object with EXACTLY these keys:
{
  "brandVoice": "1-2 sentences defining tone of voice, terminology, and stylistic identity",
  "coreValueProps": ["3 to 5 bullet points defining unique selling propositions and value pillars"],
  "targetAudienceProfile": {
    "icp": "Primary ideal customer profile",
    "decisionMaker": "Key title/persona making buying decisions",
    "keyPainPoint": "Core challenge solved"
  },
  "competitiveMoats": ["2 to 4 bullet points on how this client outmaneuvers competitors"],
  "knowledgeDigest": "A dense 3-4 sentence distillation of client business model, traction, markets, and proprietary strengths"
}

OUTPUT ONLY RAW JSON. NO CODEBLOCKS, NO MARKDOWN TAGS.''';

    try {
      final responseText = await GeminiService.instance.generateSimpleText(
        prompt: prompt,
        taskType: OpenRouterTaskType.highComplexityReasoning,
        temperature: 0.2,
      );

      if (responseText != null && responseText.trim().isNotEmpty) {
        final cleanJson = GeminiService.instance.extractJsonFromText(responseText);
        final parsed = jsonDecode(cleanJson) as Map<String, dynamic>;

        final brandVoice = parsed['brandVoice'] as String? ?? existing.brandVoice;
        final coreValueProps = List<String>.from(parsed['coreValueProps'] as List? ?? existing.coreValueProps);
        final targetAudience = Map<String, String>.from(parsed['targetAudienceProfile'] as Map? ?? existing.targetAudienceProfile);
        final competitiveMoats = List<String>.from(parsed['competitiveMoats'] as List? ?? existing.competitiveMoats);
        final knowledgeDigest = parsed['knowledgeDigest'] as String? ?? existing.knowledgeDigest;

        final newEvent = HarnessLearningEvent(
          id: 'evt-${DateTime.now().millisecondsSinceEpoch}',
          title: trigger == 'pitch_deck_upload'
              ? 'Pitch Deck Ingestion & Knowledge Extraction'
              : 'Discovery Questionnaire & Strategy Reflection',
          description: 'Updated brand voice, ICP profile, and ${coreValueProps.length} value pillars.',
          type: trigger,
          timestamp: DateTime.now(),
        );

        final updated = existing.copyWith(
          brandVoice: brandVoice,
          coreValueProps: coreValueProps,
          targetAudienceProfile: targetAudience,
          competitiveMoats: competitiveMoats,
          knowledgeDigest: knowledgeDigest,
          evolutionLog: [newEvent, ...existing.evolutionLog].take(20).toList(),
          lastSynthesized: DateTime.now(),
          version: existing.version + 1,
        );

        _cache[client.id] = updated;
        await FirebaseService.instance.saveClientAgenticHarness(amId, client.id, updated.toJson());
        return updated;
      }
    } catch (e) {
      debugPrint('Agentic Harness synthesis error: $e');
    }

    // Fallback: update evolution log and retain existing
    return existing;
  }

  /// Add a custom user-taught rule or directive to the client harness
  Future<ClientAgenticHarnessModel> addCustomRule({
    required String amId,
    required String clientId,
    required String rule,
  }) async {
    final existing = await getHarness(amId, clientId);
    if (existing.learnedRules.contains(rule.trim())) {
      return existing;
    }

    final newRules = [...existing.learnedRules, rule.trim()];
    final newEvent = HarnessLearningEvent(
      id: 'rule-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Custom Directive Learned',
      description: 'Added rule: "${rule.trim()}"',
      type: 'user_rule',
      timestamp: DateTime.now(),
    );

    final updated = existing.copyWith(
      learnedRules: newRules,
      evolutionLog: [newEvent, ...existing.evolutionLog].take(20).toList(),
      lastSynthesized: DateTime.now(),
      version: existing.version + 1,
    );

    _cache[clientId] = updated;
    await FirebaseService.instance.saveClientAgenticHarness(amId, clientId, updated.toJson());
    return updated;
  }

  /// Delete a learned rule
  Future<ClientAgenticHarnessModel> deleteRule({
    required String amId,
    required String clientId,
    required String rule,
  }) async {
    final existing = await getHarness(amId, clientId);
    final newRules = existing.learnedRules.where((r) => r != rule).toList();

    final updated = existing.copyWith(
      learnedRules: newRules,
      lastSynthesized: DateTime.now(),
      version: existing.version + 1,
    );

    _cache[clientId] = updated;
    await FirebaseService.instance.saveClientAgenticHarness(amId, clientId, updated.toJson());
    return updated;
  }

  /// Formats the learned knowledge into a dense, high-signal system prompt block
  String buildContextInjection(ClientAgenticHarnessModel? harness) {
    if (harness == null || harness.version <= 1 && harness.knowledgeDigest.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();
    buffer.writeln('\n--- CLIENT AGENTIC LEARNING HARNESS (v${harness.version}) ---');
    buffer.writeln('Brand Voice & Tone DNA: ${harness.brandVoice}');
    if (harness.coreValueProps.isNotEmpty) {
      buffer.writeln('Core Value Propositions: ${harness.coreValueProps.join(' | ')}');
    }
    if (harness.targetAudienceProfile.isNotEmpty) {
      buffer.writeln('Target ICP & Buyer: ${harness.targetAudienceProfile.entries.map((e) => '${e.key}: ${e.value}').join(', ')}');
    }
    if (harness.competitiveMoats.isNotEmpty) {
      buffer.writeln('Competitive Moats: ${harness.competitiveMoats.join(' | ')}');
    }
    if (harness.learnedRules.isNotEmpty) {
      buffer.writeln('STRICT LEARNED RULES & DIRECTIVES (Must Obey):');
      for (final r in harness.learnedRules) {
        buffer.writeln('• $r');
      }
    }
    if (harness.knowledgeDigest.isNotEmpty && harness.knowledgeDigest != 'No discovery inputs ingested yet.') {
      buffer.writeln('Synthesized Client Knowledge Digest:\n${harness.knowledgeDigest}');
    }
    buffer.writeln('-------------------------------------------------------------\n');

    return buffer.toString();
  }
}
