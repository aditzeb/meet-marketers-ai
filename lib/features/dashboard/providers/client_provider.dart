import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_service.dart';
import '../../../data/models/client_model.dart';
import '../../auth/providers/auth_provider.dart';

class ClientState {
  final List<ClientModel> clients;
  final String? activeClientId;
  final bool isLoading;
  final String searchQuery;

  const ClientState({
    this.clients = const [],
    this.activeClientId,
    this.isLoading = false,
    this.searchQuery = '',
  });

  List<ClientModel> get filteredClients {
    if (searchQuery.trim().isEmpty) return clients;
    final q = searchQuery.toLowerCase();
    return clients.where((c) => c.name.toLowerCase().contains(q) || c.industry.toLowerCase().contains(q)).toList();
  }

  ClientModel get activeClient {
    if (clients.isEmpty) {
      return ClientModel(
        id: 'client-meet-ventures',
        name: 'Meet Ventures',
        industry: 'Investment',
        websiteUrl: 'https://www.meetventures.com/',
        createdAt: DateTime.now(),
        lastActivity: DateTime.now(),
      );
    }
    if (activeClientId != null) {
      final match = clients.where((c) => c.id == activeClientId).firstOrNull;
      if (match != null) return match;
    }
    return clients.first;
  }

  ClientModel getClient(String clientId) {
    final match = clients.where((c) => c.id == clientId).firstOrNull;
    if (match != null) return match;
    return activeClient;
  }

  ClientState copyWith({
    List<ClientModel>? clients,
    String? activeClientId,
    bool? isLoading,
    String? searchQuery,
  }) {
    return ClientState(
      clients: clients ?? this.clients,
      activeClientId: activeClientId ?? this.activeClientId,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ClientNotifier extends StateNotifier<ClientState> {
  final Ref ref;

  ClientNotifier(this.ref) : super(const ClientState()) {
    loadClients();
  }

  Future<void> loadClients() async {
    state = state.copyWith(isLoading: true);
    final am = ref.read(authProvider).user;
    final amId = am?.id ?? 'am-default';

    final clients = await FirebaseService.instance.getClients(amId);
    state = ClientState(
      clients: clients,
      activeClientId: clients.isNotEmpty ? clients.first.id : 'client-meet-ventures',
      isLoading: false,
      searchQuery: state.searchQuery,
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setActiveClient(String clientId) {
    state = state.copyWith(activeClientId: clientId);
  }

  Future<ClientModel> createClient(String name, String industry, String? websiteUrl) async {
    final am = ref.read(authProvider).user;
    final amId = am?.id ?? 'am-default';

    final newClient = await FirebaseService.instance.createClient(
      amId,
      name,
      industry,
      websiteUrl: websiteUrl,
    );

    final updatedList = [newClient, ...state.clients];
    state = state.copyWith(
      clients: updatedList,
      activeClientId: newClient.id,
    );

    return newClient;
  }

  Future<void> updateClient(ClientModel updatedClient) async {
    final am = ref.read(authProvider).user;
    final amId = am?.id ?? 'am-default';

    await FirebaseService.instance.updateClient(amId, updatedClient);

    final newList = state.clients.map((c) => c.id == updatedClient.id ? updatedClient : c).toList();
    state = state.copyWith(clients: newList, activeClientId: updatedClient.id);
  }

  Future<void> deleteClient(String clientId) async {
    final am = ref.read(authProvider).user;
    final amId = am?.id ?? 'am-default';

    await FirebaseService.instance.deleteClient(amId, clientId);

    final newList = state.clients.where((c) => c.id != clientId).toList();
    final newActiveId = state.activeClientId == clientId
        ? (newList.isNotEmpty ? newList.first.id : null)
        : state.activeClientId;

    state = state.copyWith(
      clients: newList,
      activeClientId: newActiveId,
    );
  }
}

final clientProvider = StateNotifierProvider<ClientNotifier, ClientState>((ref) {
  return ClientNotifier(ref);
});
