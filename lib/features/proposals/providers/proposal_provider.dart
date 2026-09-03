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
  }) async {
    state = state.copyWith(
      isGenerating: true,
      generationProgress: 0.15,
      generationStage: 'Ingesting $leadCompanyName digital footprint ($websiteUrl)...',
    );

    await Future.delayed(const Duration(milliseconds: 300));
    state = state.copyWith(
      generationProgress: 0.40,
      generationStage: 'Gemini 2.5 Flash formulating SWOT, 4Ps & PEST matrices...',
    );

    final proposal = await GeminiService.instance.generateProposal(
      leadCompanyName: leadCompanyName,
      industry: industry,
      websiteUrl: websiteUrl,
      socialUrls: socialUrls,
      amId: _amId,
    );

    state = state.copyWith(
      generationProgress: 0.70,
      generationStage: 'Synthesizing Creative Direction, Reel Storyboard & Copywriting...',
    );

    await Future.delayed(const Duration(milliseconds: 300));
    state = state.copyWith(
      generationProgress: 0.90,
      generationStage: 'Formulating SEO Health Audit & Strategic Recommendations...',
    );

    await Future.delayed(const Duration(milliseconds: 300));
    // Save to Firestore
    await FirebaseService.instance.saveProposal(_amId, proposal);

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
}

final proposalProvider = StateNotifierProvider<ProposalNotifier, ProposalState>((ref) {
  return ProposalNotifier(ref);
});
