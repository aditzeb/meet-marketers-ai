import 'package:flutter_test/flutter_test.dart';
import 'package:meet_marketers_ai/data/models/client_agentic_harness_model.dart';
import 'package:meet_marketers_ai/core/services/client_agentic_harness_service.dart';

void main() {
  group('ClientAgenticHarnessModel Tests', () {
    test('ClientAgenticHarnessModel initial factory creates valid default memory', () {
      final harness = ClientAgenticHarnessModel.initial('client-123');
      expect(harness.clientId, equals('client-123'));
      expect(harness.version, equals(1));
      expect(harness.brandVoice, isNotEmpty);
      expect(harness.evolutionLog, isNotEmpty);
      expect(harness.evolutionLog.first.type, equals('system'));
    });

    test('toJson and fromJson preserves all fields, rules, and evolution events', () {
      final now = DateTime.now();
      final original = ClientAgenticHarnessModel(
        clientId: 'client-abc',
        brandVoice: 'Bold, visionary, enterprise B2B tone',
        coreValueProps: const [
          'APAC Venture Network of 130+ VCs',
          'Access to \$105B in global dry powder',
        ],
        targetAudienceProfile: const {
          'icp': 'Series A to C tech founders',
          'decisionMaker': 'CEO & Managing Partner',
        },
        competitiveMoats: const [
          'Exclusive Enterprise Singapore and JETRO co-incubation',
        ],
        learnedRules: const [
          'Always emphasize APAC cross-border expansion',
          'Do not mention retail crypto',
        ],
        knowledgeDigest: 'Meet Ventures specializes in SEA market access and cross-border fundraising.',
        evolutionLog: [
          HarnessLearningEvent(
            id: 'e1',
            title: 'Pitch Deck Ingestion',
            description: 'Analyzed 18-slide institutional presentation.',
            type: 'pitch_deck_upload',
            timestamp: now,
          ),
        ],
        lastSynthesized: now,
        version: 3,
      );

      final json = original.toJson();
      final restored = ClientAgenticHarnessModel.fromJson(json);

      expect(restored.clientId, equals('client-abc'));
      expect(restored.brandVoice, equals('Bold, visionary, enterprise B2B tone'));
      expect(restored.coreValueProps.length, equals(2));
      expect(restored.targetAudienceProfile['icp'], equals('Series A to C tech founders'));
      expect(restored.competitiveMoats.first, contains('Enterprise Singapore'));
      expect(restored.learnedRules.length, equals(2));
      expect(restored.knowledgeDigest, contains('Meet Ventures specializes'));
      expect(restored.evolutionLog.length, equals(1));
      expect(restored.evolutionLog.first.title, equals('Pitch Deck Ingestion'));
      expect(restored.version, equals(3));
    });
  });

  group('ClientAgenticHarnessService & Prompt Context Injection Tests', () {
    test('buildContextInjection formats dense markdown block for AI prompts', () {
      final harness = ClientAgenticHarnessModel(
        clientId: 'meet-ventures-sg',
        brandVoice: 'Authoritative, institutional, VC-grade',
        coreValueProps: const ['\$105B Network Dry Powder', 'Direct JETRO partnership'],
        targetAudienceProfile: const {'icp': 'Series A Founders in SEA'},
        competitiveMoats: const ['Government-backed incubation pipelines'],
        learnedRules: const ['Always cite APAC partner count: 130+ VCs'],
        knowledgeDigest: 'Institutional accelerator connecting Asian tech startups to sovereign funds.',
        lastSynthesized: DateTime.now(),
        version: 2,
      );

      final block = ClientAgenticHarnessService.instance.buildContextInjection(harness);

      expect(block, contains('CLIENT AGENTIC LEARNING HARNESS (v2)'));
      expect(block, contains('Authoritative, institutional, VC-grade'));
      expect(block, contains('\$105B Network Dry Powder'));
      expect(block, contains('Always cite APAC partner count: 130+ VCs'));
      expect(block, contains('Institutional accelerator connecting Asian tech startups'));
    });

    test('GeminiService integrates Agentic Harness context into deliverable generation', () {
      final harness = ClientAgenticHarnessModel(
        clientId: 'test-harness-id',
        brandVoice: 'High-energy, direct-response copy',
        coreValueProps: const ['Zero-risk free trial'],
        targetAudienceProfile: const {'icp': 'E-commerce store owners'},
        competitiveMoats: const ['Patent-pending conversion widget'],
        learnedRules: const ['Never use the word discount'],
        knowledgeDigest: 'SaaS boosting checkout conversion by 28%.',
        lastSynthesized: DateTime.now(),
        version: 2,
      );

      // Pre-seed cache to simulate live client session
      final contextInjection = ClientAgenticHarnessService.instance.buildContextInjection(harness);
      expect(contextInjection, contains('Never use the word discount'));
      expect(contextInjection, contains('High-energy, direct-response copy'));
    });
  });
}
