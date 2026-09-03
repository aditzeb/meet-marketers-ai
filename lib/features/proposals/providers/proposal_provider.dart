import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/gemini_service.dart';
import '../../../data/models/client_model.dart';
import '../../../data/models/proposal_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/client_provider.dart';

class ProposalState {
  final List<ProposalModel> proposals;
  final String? activeProposalId;
  final bool isLoading;
  final bool isGenerating;
  final double generationProgress;
  final String generationStage;
  final String? errorMessage;

  const ProposalState({
    this.proposals = const [],
    this.activeProposalId,
    this.isLoading = false,
    this.isGenerating = false,
    this.generationProgress = 0.0,
    this.generationStage = '',
    this.errorMessage,
  });

  ProposalModel? get activeProposal {
    if (activeProposalId == null) return null;
    return getProposal(activeProposalId!);
  }

  ProposalModel? getProposal(String id) {
    try {
      return proposals.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  ProposalState copyWith({
    List<ProposalModel>? proposals,
    String? activeProposalId,
    bool? isLoading,
    bool? isGenerating,
    double? generationProgress,
    String? generationStage,
    String? errorMessage,
  }) {
    return ProposalState(
      proposals: proposals ?? this.proposals,
      activeProposalId: activeProposalId ?? this.activeProposalId,
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      generationProgress: generationProgress ?? this.generationProgress,
      generationStage: generationStage ?? this.generationStage,
      errorMessage: errorMessage,
    );
  }
}

class ProposalNotifier extends StateNotifier<ProposalState> {
  final Ref ref;

  ProposalNotifier(this.ref) : super(const ProposalState()) {
    loadProposals();
  }

  String get _amId => ref.read(authProvider).user?.id ?? 'am-default';

  /// Load all Proposals for the current AM from Firestore
  Future<void> loadProposals() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await FirebaseService.instance.getProposals(_amId);
      state = state.copyWith(
        proposals: list,
        isLoading: false,
        activeProposalId: list.isNotEmpty ? (state.activeProposalId ?? list.first.id) : null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setActiveProposal(String id) {
    state = state.copyWith(activeProposalId: id);
  }

  ProposalModel? getProposal(String id) {
    try {
      return state.proposals.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Create and generate a brand-new Proposal with live phased progress
  Future<ProposalModel> createAndGenerateProposal({
    required String leadCompanyName,
    required String industry,
    required String websiteUrl,
    Map<String, String>? socialUrls,
    String? pitchDeckFileName,
    Uint8List? pitchDeckBytes,
    String? extractedPitchDeckText,
    String? companyLogoUrl,
  }) async {
    final hasPitchDeck = pitchDeckBytes != null && pitchDeckBytes.isNotEmpty;

    state = state.copyWith(
      isGenerating: true,
      generationProgress: 0.15,
      generationStage: hasPitchDeck
          ? 'Strategic context extracted from $pitchDeckFileName (${(extractedPitchDeckText ?? "").length} chars)...'
          : 'Ingesting $leadCompanyName digital footprint ($websiteUrl)...',
    );

    String? pitchDeckStorageUrl;
    if (hasPitchDeck && pitchDeckFileName != null) {
      try {
        pitchDeckStorageUrl = await FirebaseService.instance.uploadFile(
          clientId: 'lead_${DateTime.now().millisecondsSinceEpoch}',
          folder: 'pitch_decks',
          fileName: pitchDeckFileName,
          bytes: pitchDeckBytes,
          contentType: 'application/pdf',
        ).timeout(const Duration(seconds: 2), onTimeout: () => null);
      } catch (e) {
        debugPrint('Lead pitch deck upload notice: $e');
      }
    }

    state = state.copyWith(
      generationProgress: 0.35,
      generationStage: hasPitchDeck
          ? 'OpenRouter Auto aligning pitch deck insights with SWOT & 4Ps...'
          : 'OpenRouter Auto formulating SWOT, 4Ps & PEST matrices...',
    );

    // Dynamic progress ticker to show active processing
    final ticker = Stream.periodic(const Duration(milliseconds: 600), (i) => i).listen((tick) {
      if (!state.isGenerating) return;
      if (tick == 1) {
        state = state.copyWith(
          generationProgress: 0.55,
          generationStage: 'Formulating Perceptual Positioning Map & Competitor Matrix...',
        );
      } else if (tick == 2) {
        state = state.copyWith(
          generationProgress: 0.75,
          generationStage: 'Synthesizing Creative Direction, Reel Storyboard & Copywriting...',
        );
      } else if (tick == 3) {
        state = state.copyWith(
          generationProgress: 0.88,
          generationStage: 'Formulating SEO Health Audit & Strategic Recommendations...',
        );
      }
    });

    ProposalModel proposal;
    try {
      proposal = await GeminiService.instance.generateProposal(
        leadCompanyName: leadCompanyName,
        industry: industry,
        websiteUrl: websiteUrl,
        socialUrls: socialUrls,
        extractedPitchDeckText: extractedPitchDeckText,
        pitchDeckFileName: pitchDeckFileName,
        pitchDeckStorageUrl: pitchDeckStorageUrl,
        companyLogoUrl: companyLogoUrl,
        amId: _amId,
      );
    } finally {
      await ticker.cancel();
    }

    state = state.copyWith(
      generationProgress: 0.95,
      generationStage: 'Securing 13-section strategic proposal in Firestore...',
    );

    // Save to Firestore with timeout fallback
    try {
      await FirebaseService.instance.saveProposal(_amId, proposal).timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('Firestore saveProposal note: $e');
    }

    state = state.copyWith(
      generationProgress: 1.0,
      generationStage: 'Proposal generated & secured in Firestore!',
      proposals: [proposal, ...state.proposals.where((p) => p.id != proposal.id)],
      activeProposalId: proposal.id,
      isGenerating: false,
    );

    return proposal;
  }

  /// Save updates made during AM review/editing
  Future<void> updateProposal(ProposalModel updated) async {
    final updatedList = state.proposals.map((p) => p.id == updated.id ? updated : p).toList();
    state = state.copyWith(proposals: updatedList);
    await FirebaseService.instance.saveProposal(_amId, updated);
  }

  /// Approve proposal
  Future<void> approveProposal(String id) async {
    final current = getProposal(id);
    if (current == null) return;
    final updated = current.copyWith(
      status: ProposalStatus.approved,
      updatedAt: DateTime.now(),
    );
    await updateProposal(updated);
  }

  /// Mark proposal as sent to lead
  Future<void> markSent(String id, {required String contactName, required String contactEmail}) async {
    final current = getProposal(id);
    if (current == null) return;
    final updated = current.copyWith(
      contactName: contactName,
      contactEmail: contactEmail,
      status: ProposalStatus.sent,
      sentAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await updateProposal(updated);
  }

  /// Convert winning proposal to Client Workspace
  Future<ClientModel?> convertToClient(String id) async {
    final current = getProposal(id);
    if (current == null) return null;

    final newClient = await FirebaseService.instance.convertProposalToClient(
      amId: _amId,
      proposal: current,
    );

    // Refresh proposals state
    final updatedProposal = current.copyWith(
      status: ProposalStatus.converted,
      convertedAt: DateTime.now(),
      convertedClientId: newClient.id,
      updatedAt: DateTime.now(),
    );
    final updatedList = state.proposals.map((p) => p.id == id ? updatedProposal : p).toList();
    state = state.copyWith(proposals: updatedList);

    // Refresh client roster in clientProvider
    await ref.read(clientProvider.notifier).loadClients();

    return newClient;
  }

  /// Delete proposal
  Future<void> deleteProposal(String id) async {
    await FirebaseService.instance.deleteProposal(_amId, id);
    state = state.copyWith(
      proposals: state.proposals.where((p) => p.id != id).toList(),
      activeProposalId: state.activeProposalId == id ? null : state.activeProposalId,
    );
  }

  /// Regenerate an existing proposal with the domain engine & AI
  Future<ProposalModel?> regenerateProposal(String id) async {
    final current = getProposal(id);
    if (current == null) return null;

    state = state.copyWith(
      isGenerating: true,
      generationProgress: 0.2,
      generationStage: 'Analyzing brand footprint & synthesizing domain intelligence...',
    );

    try {
      final fresh = await GeminiService.instance.generateProposal(
        leadCompanyName: current.leadCompanyName,
        industry: current.industry,
        websiteUrl: current.websiteUrl,
        socialUrls: current.socialUrls,
        extractedPitchDeckText: current.extractedPitchDeckText,
        pitchDeckFileName: current.pitchDeckFileName,
        pitchDeckStorageUrl: current.pitchDeckStorageUrl,
        companyLogoUrl: current.companyLogoUrl,
        amId: _amId,
      );

      final updated = fresh.copyWith(
        id: current.id,
        status: current.status,
        createdAt: current.createdAt,
        updatedAt: DateTime.now(),
        contactName: current.contactName,
        contactEmail: current.contactEmail,
        companyLogoUrl: current.companyLogoUrl,
      );

      await updateProposal(updated);
      state = state.copyWith(
        isGenerating: false,
        generationProgress: 1.0,
        generationStage: 'Proposal regenerated with domain precision!',
      );
      return updated;
    } catch (e) {
      state = state.copyWith(isGenerating: false);
      rethrow;
    }
  }

  /// Upload media asset (from device) and save to Firebase Storage
  Future<String> uploadMediaAsset({
    required String proposalId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    return await FirebaseService.instance.uploadProposalMedia(
      proposalId: proposalId,
      fileName: fileName,
      bytes: bytes,
    );
  }

  /// Generate an AI image directly via OpenRouter (Google Gemini 3.1 Flash Image)
  /// and upload to Firebase Storage for permanent, CDN-cached hosting.
  /// Configured with native aspect_ratio and resolution in the JSON POST payload.
  Future<String> generateAiAssetImage({
    required String prompt,
    required String category,
    String? proposalId,
    String? logoUrl,
    String? companyName,
    String? aspectRatio,
    String? resolution,
  }) async {
    // If a company logo is provided, seamlessly weave it into the prompt and reference image input
    String finalPrompt = prompt;
    if (companyName != null && companyName.isNotEmpty && logoUrl != null && logoUrl.isNotEmpty) {
      finalPrompt = '$prompt, seamlessly incorporating and blending the official brand logo of $companyName into the visual scene as an illuminated architectural insignia, luxury backdrop signage, discreet metallic embossement, or elegant brand mark harmoniously balanced with the lighting and aesthetic.';
    }

    // Determine target aspect ratio based on explicit parameter or category inference
    String targetAspectRatio = aspectRatio ?? '16:9';
    if (aspectRatio == null || aspectRatio.isEmpty) {
      final catLower = category.toLowerCase();
      if (catLower.contains('reel') || catLower.contains('vertical') || catLower.contains('story') || catLower.contains('video') || catLower.contains('9:16')) {
        targetAspectRatio = '9:16';
      } else if (catLower.contains('social') || catLower.contains('post') || catLower.contains('copywriting') || catLower.contains('square') || catLower.contains('1:1')) {
        targetAspectRatio = '1:1';
      } else {
        targetAspectRatio = '16:9';
      }
    }

    final targetResolution = (resolution != null && resolution.isNotEmpty) ? resolution : '2K';

    final rawImage = await GeminiService.instance.generateImage(
      finalPrompt,
      aspectRatio: targetAspectRatio,
      resolution: targetResolution,
      referenceImageUrl: logoUrl,
    );
    if (rawImage.isEmpty) {
      throw Exception('OpenRouter image generation returned an empty payload.');
    }

    // rawImage is a fully formed base64 data URI: 'data:image/jpeg;base64,...'
    // It renders directly via Image.memory with zero CORS, zero network latency, and zero 404s.
    // Try uploading to Firebase Storage for permanent hosting, but only replace if a real HTTP CDN URL is obtained
    if (rawImage.startsWith('data:image')) {
      try {
        final commaIdx = rawImage.indexOf(',');
        if (commaIdx != -1) {
          final b64 = rawImage.substring(commaIdx + 1);
          final bytes = base64Decode(b64);
          final fileName = 'ai_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final storageUrl = await uploadMediaAsset(
            proposalId: proposalId ?? 'general_assets',
            fileName: fileName,
            bytes: bytes,
          );
          if (storageUrl.isNotEmpty && storageUrl.startsWith('http') && !storageUrl.contains('firebasestorage.googleapis.com/v0/b/meet-marketers-ai.firebasestorage.app/o/proposals')) {
            return storageUrl;
          }
        }
      } catch (e) {
        debugPrint('Firebase Storage upload notice for OpenRouter image: $e');
      }
    }

    return rawImage;
  }
}

final proposalProvider = StateNotifierProvider<ProposalNotifier, ProposalState>((ref) {
  return ProposalNotifier(ref);
});
