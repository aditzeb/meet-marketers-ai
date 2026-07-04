import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';
import '../../data/models/client_model.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/dashboard/providers/client_provider.dart';
import '../dialogs/create_client_dialog.dart';

/// Persistent AM Navigation Shell — wraps all authenticated screens
/// with a fixed 260px sidebar showing the real client roster.
class AppShell extends ConsumerStatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _sidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final clientState = ref.watch(clientProvider);
    final authState = ref.watch(authProvider);
    final sidebarWidth = _sidebarCollapsed ? 64.0 : 260.0;

    return Scaffold(
      backgroundColor: ClinicSageColors.neutral,
      body: Row(
        children: [
          // ── Sidebar ───────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            width: sidebarWidth,
            decoration: ClinicSageDecorations.sidebar,
            child: _sidebarCollapsed
                ? _CollapsedSidebar(onExpand: () => setState(() => _sidebarCollapsed = false))
                : _ExpandedSidebar(
                    clients: clientState.filteredClients,
                    activeClientId: clientState.activeClientId,
                    searchQuery: clientState.searchQuery,
                    userName: authState.user?.displayName ?? 'Account Manager',
                    userEmail: authState.user?.email ?? 'meet@marketers.ai',
                    onSearchChanged: (q) => ref.read(clientProvider.notifier).setSearchQuery(q),
                    onClientSelected: _onClientSelected,
                    onNewClient: _onOpenCreateClientDialog,
                    onSignOut: _onSignOut,
                    onCollapse: () => setState(() => _sidebarCollapsed = true),
                  ),
          ),

          // ── Main Content ──────────────────────────────────
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  void _onClientSelected(String clientId) {
    ref.read(clientProvider.notifier).setActiveClient(clientId);
    context.go(AppRoutes.clientInputsPath(clientId));
  }

  void _onOpenCreateClientDialog() {
    CreateClientDialog.show(
      context,
      onCreate: (name, industry, websiteUrl) async {
        final newClient = await ref.read(clientProvider.notifier).createClient(name, industry, websiteUrl);
        if (mounted) {
          context.go(AppRoutes.clientInputsPath(newClient.id));
        }
      },
    );
  }

  void _onSignOut() async {
    await ref.read(authProvider.notifier).signOut();
    if (mounted) {
      context.go(AppRoutes.auth);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expanded Sidebar
// ─────────────────────────────────────────────────────────────────────────────
class _ExpandedSidebar extends StatelessWidget {
  final List<ClientModel> clients;
  final String? activeClientId;
  final String searchQuery;
  final String userName;
  final String userEmail;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onClientSelected;
  final VoidCallback onNewClient;
  final VoidCallback onSignOut;
  final VoidCallback onCollapse;

  const _ExpandedSidebar({
    required this.clients,
    required this.activeClientId,
    required this.searchQuery,
    required this.userName,
    required this.userEmail,
    required this.onSearchChanged,
    required this.onClientSelected,
    required this.onNewClient,
    required this.onSignOut,
    required this.onCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Brand Header ──────────────────────────────────
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: ClinicSageColors.border)),
          ),
          child: ClipRect(
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: ClinicSageColors.primary,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Meet Marketers',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                IconButton(
                  onPressed: onCollapse,
                  icon: const Icon(Icons.chevron_left, size: 18),
                  color: ClinicSageColors.secondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  tooltip: 'Collapse sidebar',
                ),
              ],
            ),
          ),
        ),

        // ── Dashboard Link ────────────────────────────────
        _SidebarNavItem(
          icon: Icons.grid_view_rounded,
          label: 'Dashboard',
          onTap: () => GoRouter.of(context).go(AppRoutes.dashboard),
        ),

        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'CLIENT PORTFOLIOS',
            style: theme.textTheme.labelSmall,
          ),
        ),
        const SizedBox(height: 8),

        // ── Search ───────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            onChanged: onSearchChanged,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Search clients...',
              prefixIcon: const Icon(Icons.search, size: 16, color: ClinicSageColors.secondary),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
              filled: true,
              fillColor: ClinicSageColors.neutral,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: ClinicSageColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: ClinicSageColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: ClinicSageColors.tertiary, width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // ── Client List ───────────────────────────────────
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            itemCount: clients.length,
            itemBuilder: (context, index) {
              final client = clients[index];
              final isSelected = client.id == activeClientId;
              return _ClientListTile(
                client: client,
                isSelected: isSelected,
                onTap: () => onClientSelected(client.id),
              );
            },
          ),
        ),

        // ── New Client Button ─────────────────────────────
        Padding(
          padding: const EdgeInsets.all(12),
          child: OutlinedButton.icon(
            onPressed: onNewClient,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New Client Workspace'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 38),
            ),
          ),
        ),

        // ── AM Footer ────────────────────────────────────
        _AMFooter(
          userName: userName,
          userEmail: userEmail,
          onSignOut: onSignOut,
        ),
      ],
    );
  }
}

class _ClientListTile extends ConsumerWidget {
  final ClientModel client;
  final bool isSelected;
  final VoidCallback onTap;

  const _ClientListTile({
    required this.client,
    required this.isSelected,
    required this.onTap,
  });

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Client Project'),
        content: Text(
          'Are you sure you want to delete "${client.name}"? This will permanently delete the client and all associated deliverables directly from Firestore.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(clientProvider.notifier).deleteClient(client.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Client "${client.name}" deleted from Firestore.')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? ClinicSageColors.tertiaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected ? ClinicSageColors.tertiary : ClinicSageColors.neutral,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? ClinicSageColors.tertiary : ClinicSageColors.border,
                  ),
                ),
                child: Center(
                  child: Text(
                    client.name.isNotEmpty ? client.name.substring(0, 1) : 'C',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isSelected ? Colors.white : ClinicSageColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: ClinicSageColors.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      client.industry,
                      style: theme.textTheme.labelSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 16, color: ClinicSageColors.secondary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 120),
                onSelected: (val) {
                  if (val == 'delete') {
                    _confirmDelete(context, ref);
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 16, color: Colors.red.shade600),
                        const SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red.shade600, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? ClinicSageColors.tertiaryLight : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? ClinicSageColors.tertiary : ClinicSageColors.secondary,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? ClinicSageColors.tertiary : ClinicSageColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AMFooter extends StatelessWidget {
  final String userName;
  final String userEmail;
  final VoidCallback onSignOut;

  const _AMFooter({
    required this.userName,
    required this.userEmail,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: ClinicSageColors.border)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: ClinicSageColors.primary,
            child: Text(
              userName.isNotEmpty ? userName.substring(0, 1) : 'A',
              style: theme.textTheme.labelSmall?.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500, color: ClinicSageColors.primary), overflow: TextOverflow.ellipsis),
                Text(userEmail, style: theme.textTheme.labelSmall, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 16),
            color: ClinicSageColors.secondary,
            onPressed: onSignOut,
            tooltip: 'Sign out',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }
}

class _CollapsedSidebar extends StatelessWidget {
  final VoidCallback onExpand;
  const _CollapsedSidebar({required this.onExpand});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        IconButton(
          onPressed: onExpand,
          icon: const Icon(Icons.chevron_right, size: 20),
          color: ClinicSageColors.secondary,
          tooltip: 'Expand sidebar',
        ),
        const SizedBox(height: 8),
        Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: ClinicSageColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
        ),
      ],
    );
  }
}
