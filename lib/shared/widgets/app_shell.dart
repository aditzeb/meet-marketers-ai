import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';
import '../../data/models/client_model.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/dashboard/providers/client_provider.dart';
import '../dialogs/create_client_dialog.dart';
import 'app_logo.dart';

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
    final sidebarWidth = _sidebarCollapsed ? 64.0 : 264.0;

    return Scaffold(
      backgroundColor: ClinicSageColors.neutral,
      body: Row(
        children: [
          // ── Sidebar ───────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: sidebarWidth,
            decoration: const BoxDecoration(
              color: ClinicSageColors.surface,
              border: Border(right: BorderSide(color: ClinicSageColors.border)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 20,
                  offset: Offset(4, 0),
                ),
              ],
            ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: ClinicSageColors.border)),
          ),
          child: ClipRect(
            child: Row(
              children: [
                const AppLogo(size: 32),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meet Marketers',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        'AI Platform',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: ClinicSageColors.tertiary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onCollapse,
                  icon: const Icon(Icons.chevron_left, size: 18),
                  color: ClinicSageColors.secondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  tooltip: 'Collapse sidebar',
                ),
              ],
            ),
          ),
        ),

        // ── Navigation Links ─────────────────────────────
        const SizedBox(height: 8),
        _SidebarNavItem(
          icon: Icons.grid_view_rounded,
          label: 'Dashboard',
          isSelected: activeClientId == null && !GoRouterState.of(context).uri.toString().startsWith('/proposals'),
          onTap: () => GoRouter.of(context).go(AppRoutes.dashboard),
        ),
        _SidebarNavItem(
          icon: Icons.description_outlined,
          label: 'Proposals & Leads',
          isSelected: GoRouterState.of(context).uri.toString().startsWith('/proposals'),
          onTap: () => GoRouter.of(context).go(AppRoutes.proposals),
        ),

        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'CLIENT PORTFOLIOS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                    color: ClinicSageColors.secondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ClinicSageColors.tertiaryLight,
                  borderRadius: BorderRadius.circular(ClinicSageRadius.full),
                ),
                child: Text(
                  '${clients.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: ClinicSageColors.tertiary,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
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
              prefixIcon: const Icon(Icons.search, size: 15, color: ClinicSageColors.secondary),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              isDense: true,
              filled: true,
              fillColor: ClinicSageColors.neutral,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ClinicSageRadius.md),
                borderSide: const BorderSide(color: ClinicSageColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ClinicSageRadius.md),
                borderSide: const BorderSide(color: ClinicSageColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ClinicSageRadius.md),
                borderSide: const BorderSide(color: ClinicSageColors.tertiary, width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),

        // ── Client List ───────────────────────────────────
        Expanded(
          child: clients.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ClinicSageColors.neutral,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.people_outline, size: 24, color: ClinicSageColors.secondary),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No clients yet',
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500, color: ClinicSageColors.primary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create your first workspace below',
                        style: theme.textTheme.labelSmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
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
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(ClinicSageRadius.md),
            child: InkWell(
              onTap: onNewClient,
              borderRadius: BorderRadius.circular(ClinicSageRadius.md),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: ClinicSageGradients.tertiary,
                  borderRadius: BorderRadius.circular(ClinicSageRadius.md),
                  boxShadow: ClinicSageShadows.button,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'New Client Workspace',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
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

class _ClientListTile extends ConsumerStatefulWidget {
  final ClientModel client;
  final bool isSelected;
  final VoidCallback onTap;

  const _ClientListTile({
    required this.client,
    required this.isSelected,
    required this.onTap,
  });

  @override
  ConsumerState<_ClientListTile> createState() => _ClientListTileState();
}

class _ClientListTileState extends ConsumerState<_ClientListTile> {
  bool _isHovered = false;

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF2F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF9B1C1C)),
            ),
            const SizedBox(width: 12),
            const Text('Delete Client Project'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${widget.client.name}"? This will permanently delete the client and all associated deliverables directly from Firestore.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9B1C1C),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(clientProvider.notifier).deleteClient(widget.client.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Client "${widget.client.name}" deleted from Firestore.')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Generate a consistent accent color from client name
    final accentColors = [
      ClinicSageColors.tertiary,
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
    ];
    final accentIndex = widget.client.name.isNotEmpty ? widget.client.name.codeUnitAt(0) % accentColors.length : 0;
    final accent = accentColors[accentIndex];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(ClinicSageRadius.md),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(ClinicSageRadius.md),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? ClinicSageColors.tertiaryLight
                  : _isHovered
                      ? ClinicSageColors.neutral
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(ClinicSageRadius.md),
              border: widget.isSelected
                  ? Border.all(color: ClinicSageColors.tertiary.withOpacity(0.3), width: 1)
                  : Border.all(color: Colors.transparent),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: widget.isSelected
                        ? LinearGradient(colors: [accent, accent.withOpacity(0.7)])
                        : null,
                    color: widget.isSelected ? null : ClinicSageColors.neutral,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: widget.isSelected ? accent : ClinicSageColors.border,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.client.name.isNotEmpty ? widget.client.name.substring(0, 1).toUpperCase() : 'C',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: widget.isSelected ? Colors.white : ClinicSageColors.primary,
                        fontWeight: FontWeight.w700,
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
                        widget.client.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: ClinicSageColors.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.client.industry,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: widget.isSelected ? ClinicSageColors.tertiary : ClinicSageColors.secondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (_isHovered || widget.isSelected)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 14, color: ClinicSageColors.secondary.withOpacity(0.7)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 120),
                    onSelected: (val) {
                      if (val == 'delete') {
                        _confirmDelete(context);
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 15, color: Colors.red.shade600),
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
      ),
    );
  }
}

class _SidebarNavItem extends StatefulWidget {
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
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(ClinicSageRadius.md),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? ClinicSageColors.tertiaryLight
                    : _isHovered
                        ? ClinicSageColors.neutral
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(ClinicSageRadius.md),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    size: 17,
                    color: widget.isSelected ? ClinicSageColors.tertiary : ClinicSageColors.secondary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: widget.isSelected ? ClinicSageColors.tertiary : ClinicSageColors.primary,
                    ),
                  ),
                ],
              ),
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
        color: ClinicSageColors.surface,
        border: Border(top: BorderSide(color: ClinicSageColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: ClinicSageGradients.brandVibrant,
              borderRadius: BorderRadius.circular(ClinicSageRadius.md),
            ),
            child: Center(
              child: Text(
                userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'A',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
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
                  userName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ClinicSageColors.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  userEmail,
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'Sign out',
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              child: InkWell(
                onTap: onSignOut,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: const Icon(Icons.logout, size: 15, color: ClinicSageColors.secondary),
                ),
              ),
            ),
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
        const SizedBox(height: 14),
        Tooltip(
          message: 'Expand sidebar',
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: onExpand,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.chevron_right, size: 20, color: ClinicSageColors.secondary),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const AppLogo(size: 34),
        const SizedBox(height: 16),
        const Divider(indent: 12, endIndent: 12),
        const SizedBox(height: 8),
        Tooltip(
          message: 'Dashboard',
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () => GoRouter.of(context).go(AppRoutes.dashboard),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: const Icon(Icons.grid_view_rounded, size: 18, color: ClinicSageColors.secondary),
              ),
            ),
          ),
        ),
        Tooltip(
          message: 'Proposals & Leads',
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () => GoRouter.of(context).go(AppRoutes.proposals),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: const Icon(Icons.description_outlined, size: 18, color: ClinicSageColors.secondary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
