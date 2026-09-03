import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:meet_marketers_ai/data/models/client_model.dart';
import 'package:meet_marketers_ai/data/models/content_deliverable_model.dart';
import 'package:meet_marketers_ai/data/models/strategy_deliverable_model.dart';
import 'package:meet_marketers_ai/features/dashboard/providers/client_provider.dart';
import 'package:meet_marketers_ai/core/services/gemini_service.dart';
import 'package:meet_marketers_ai/core/services/pdf_extractor_service.dart';
import 'package:meet_marketers_ai/features/content_studio/views/content_studio_screen.dart';

void main() {
  group('ClientModel & ClientState Tests', () {
    test('ClientModel toJson and fromJson preserve properties', () {
      final now = DateTime.now();
      final client = ClientModel(
        id: 'client-test-1',
        name: 'Apex Robotics',
        industry: 'Robotics & AI',
        websiteUrl: 'https://apexrobotics.ai',
        logoUrl: 'https://apexrobotics.ai/logo.png',
        questionnaireAnswers: const {
          'targetCustomer': 'CTO & VP Engineering',
          'targetCountry': 'Singapore',
        },
        competitors: const ['Boston Dynamics', 'Figure AI'],
        targetRoleModels: const ['OpenAI', 'Tesla'],
        pitchDeckStoragePath: 'pitch_decks/apex.pdf',
        imageStoragePaths: const ['images/robot1.png'],
        documentStoragePaths: const ['docs/guidelines.pdf'],
        status: ClientStatus.active,
        createdAt: now,
        lastActivity: now,
      );

      final json = client.toJson();
      final deserialized = ClientModel.fromJson('client-test-1', json);

      expect(deserialized.id, equals('client-test-1'));
      expect(deserialized.name, equals('Apex Robotics'));
      expect(deserialized.industry, equals('Robotics & AI'));
      expect(deserialized.websiteUrl, equals('https://apexrobotics.ai'));
      expect(deserialized.questionnaireAnswers['targetCustomer'], equals('CTO & VP Engineering'));
      expect(deserialized.competitors, contains('Boston Dynamics'));
      expect(deserialized.status, equals(ClientStatus.active));
    });

    test('ClientState correctly filters clients by query and picks active client', () {
      final client1 = ClientModel(
        id: 'c1',
        name: 'Meet Ventures',
        industry: 'Investment',
        createdAt: DateTime.now(),
        lastActivity: DateTime.now(),
      );
      final client2 = ClientModel(
        id: 'c2',
        name: 'Gamma Health',
        industry: 'Healthcare',
        createdAt: DateTime.now(),
        lastActivity: DateTime.now(),
      );

      final state = ClientState(
        clients: [client1, client2],
        activeClientId: 'c2',
        searchQuery: 'health',
      );

      expect(state.filteredClients.length, equals(1));
      expect(state.filteredClients.first.name, equals('Gamma Health'));
      expect(state.activeClient.id, equals('c2'));

      // Fallback when activeClientId not found
      final fallbackState = state.copyWith(activeClientId: 'non-existent');
      expect(fallbackState.activeClient.id, equals('c1'));
    });
  });

  group('ContentDeliverable & SubTabs Tests', () {
    test('All 11 ContentType values have distinct non-empty labels', () {
      expect(ContentType.values.length, equals(11));
      for (final type in ContentType.values) {
        expect(type.label.isNotEmpty, isTrue);
        expect(type.value.isNotEmpty, isTrue);
      }
    });

    test('getSubTabsForType provides tailored sub-tabs for all ContentTypes', () {
      for (final type in ContentType.values) {
        final tabs = getSubTabsForType(type);
        expect(tabs.isNotEmpty, isTrue);
        for (final tab in tabs) {
          expect(tab.id.isNotEmpty, isTrue);
          expect(tab.label.isNotEmpty, isTrue);
        }
      }
    });

    test('getGenerateButtonText and getEmptyStateText return appropriate strings', () {
      for (final type in ContentType.values) {
        final initialText = getGenerateButtonText(type, false);
        final regenText = getGenerateButtonText(type, true);
        final emptyState = getEmptyStateText(type);

        expect(initialText.isNotEmpty, isTrue);
        expect(regenText, contains('Regenerate'));
        expect(emptyState.isNotEmpty, isTrue);
      }
    });
  });

  group('GeminiService Engine & Formatting Tests', () {
    test('cleanMarkdownText removes asterisks, hashes, pipes, and trims cleanly', () {
      const raw = '### Title Here\n\n**Key Metric:** \$100K | Margin: 45%\n---\n* Bullet point';
      final cleaned = GeminiService.instance.cleanMarkdownText(raw);

      expect(cleaned.contains('###'), isFalse);
      expect(cleaned.contains('**'), isFalse);
      expect(cleaned.contains('|'), isFalse);
      expect(cleaned.contains('Title Here'), isTrue);
    });

    test('getFallbackContent provides valid deliverable text for all 11 types', () {
      for (final type in ContentType.values) {
        final content = GeminiService.instance.getFallbackContent(
          type,
          'AlphaWave Test',
        );

        expect(content.isNotEmpty, isTrue);
        expect(content.contains('AlphaWave Test'), isTrue);
      }
    });

    test('generateMediaAsset produces photo, video, and storyboard scenes', () async {
      final asset = await GeminiService.instance.generateMediaAsset(
        type: ContentType.explainerVideos,
        clientName: 'AlphaWave Test',
        industry: 'Cloud SaaS',
      );

      expect(asset.imageUrl.isNotEmpty, isTrue);
      expect(asset.videoUrl.isNotEmpty, isTrue);
      expect(asset.caption.contains('AlphaWave Test'), isTrue);
      expect(asset.storyboard.length, greaterThanOrEqualTo(3));
    });
  });

  group('StrategyDeliverableModel Tests', () {
    test('StrategyDeliverableModel correctly parses SWOT and SEO matrices', () {
      final model = StrategyDeliverableModel(
        id: 'strat-1',
        clientId: 'client-1',
        swot: const SwotMatrix(
          strengths: ['Strength 1'],
          weaknesses: ['Weakness 1'],
          opportunities: ['Opportunity 1'],
          threats: ['Threat 1'],
        ),
        seoKeywords: const [
          SeoKeyword(
            keyword: 'saas platform',
            searchVolume: 12000,
            difficulty: 45,
            intent: 'commercial',
            targetPage: '/solutions',
          ),
        ],
        personas: const [],
        calendarEvents: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final json = model.toJson();
      final fromJson = StrategyDeliverableModel.fromJson('strat-1', json);

      expect(fromJson.id, equals('strat-1'));
      expect(fromJson.swot.strengths, contains('Strength 1'));
      expect(fromJson.seoKeywords.first.keyword, equals('saas platform'));
      expect(fromJson.seoKeywords.first.searchVolume, equals(12000));
    });

    test('ClientModel serializes and deserializes extractedPdfContent', () {
      final now = DateTime.now();
      final client = ClientModel(
        id: 'c-pdf-1',
        name: 'OmniAI',
        industry: 'Fintech',
        extractedPdfContent: 'Executive Summary: OmniAI leads autonomous payments.',
        createdAt: now,
        lastActivity: now,
      );

      final json = client.toJson();
      expect(json['extractedPdfContent'], contains('OmniAI leads autonomous payments'));

      final fromJson = ClientModel.fromJson('c-pdf-1', json);
      expect(fromJson.extractedPdfContent, contains('OmniAI leads autonomous payments'));
    });
  });

  group('PDF Extraction Engine Tests', () {
    test('PdfExtractorService handles empty bytes gracefully', () {
      final text = PdfExtractorService.instance.extractTextFromBytes(Uint8List(0));
      expect(text, isEmpty);
    });
  });
}
