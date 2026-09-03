import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/account_manager_model.dart';
import '../../../data/models/client_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/client_provider.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  List<AccountManagerModel> _users = [];
  List<ClientModel> _allAgencyClients = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final users = await FirebaseService.instance.getAllUsers();
      final clients = await FirebaseService.instance.getAllAgencyClients();
      if (mounted) {
        setState(() {
          _users = users;
          _allAgencyClients = clients;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateRole(AccountManagerModel user, String newRole) async {
    try {
      await FirebaseService.instance.updateUserRoleAndAssignments(
        user.id,
        role: newRole,
        assignedClientIds: user.assignedClientIds,
      );

      final currentUser = ref.read(authProvider).user;
      if (currentUser?.id == user.id) {
        await ref.read(authProvider.notifier).reloadUser();
      }

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.displayName} role updated to ${newRole == 'admin' ? 'Admin' : 'Account Manager'}'),
            backgroundColor: ClinicSageColors.tertiary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update role: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _openAssignDialog(AccountManagerModel user) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final currentAssigned = List<String>.from(user.assignedClientIds);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: ClinicSageColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ClinicSageColors.tertiaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.assignment_ind_outlined, size: 20, color: ClinicSageColors.tertiary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Assign Client Projects', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        Text('For: ${user.displayName} (${user.email})', style: const TextStyle(fontSize: 12, color: ClinicSageColors.secondary)),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: _allAgencyClients.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text('No client workspaces found in agency. Create client projects first.'),
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Select projects this user can access:',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                              ),
                              TextButton(
                                onPressed: () {
                                  setDialogState(() {
                                    if (currentAssigned.length == _allAgencyClients.length) {
                                      currentAssigned.clear();
                                    } else {
                                      currentAssigned.clear();
                                      currentAssigned.addAll(_allAgencyClients.map((c) => c.id));
                                    }
                                  });
                                },
                                child: Text(
                                  currentAssigned.length == _allAgencyClients.length ? 'Deselect All' : 'Select All',
                                  style: const TextStyle(fontSize: 12, color: ClinicSageColors.tertiary, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 320),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _allAgencyClients.length,
                              itemBuilder: (context, index) {
                                final client = _allAgencyClients[index];
                                final isSelected = currentAssigned.contains(client.id);
                                return CheckboxListTile(
                                  activeColor: ClinicSageColors.tertiary,
                                  dense: true,
                                  title: Text(client.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  subtitle: Text(client.industry, style: const TextStyle(fontSize: 12, color: ClinicSageColors.secondary)),
                                  value: isSelected,
                                  onChanged: (val) {
                                    setDialogState(() {
                                      if (val == true) {
                                        currentAssigned.add(client.id);
                                      } else {
                                        currentAssigned.remove(client.id);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: ClinicSageColors.secondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ClinicSageColors.tertiary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    try {
                      await FirebaseService.instance.updateUserRoleAndAssignments(
                        user.id,
                        role: user.role,
                        assignedClientIds: currentAssigned,
                      );

                      final currentUser = ref.read(authProvider).user;
                      if (currentUser?.id == user.id) {
                        await ref.read(authProvider.notifier).reloadUser();
                        await ref.read(clientProvider.notifier).loadClients();
                      }

                      await _loadData();

                      if (mounted) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text('Updated project assignments for ${user.displayName} (${currentAssigned.length} assigned)'),
                            backgroundColor: ClinicSageColors.tertiary,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(content: Text('Error saving assignments: $e'), backgroundColor: Colors.redAccent),
                        );
                      }
                    }
                  },
                  child: const Text('Save Assignments'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(authProvider).user;

    final filteredUsers = _users.where((u) {
      final q = _searchQuery.toLowerCase();
      return u.displayName.toLowerCase().contains(q) || u.email.toLowerCase().contains(q);
    }).toList();

    final adminCount = _users.where((u) => u.isAdmin).length;
    final amCount = _users.where((u) => !u.isAdmin).length;

    return Scaffold(
      backgroundColor: ClinicSageColors.neutral,
      body: CustomScrollView(
        slivers: [
          // ── Top Bar ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: const BoxDecoration(
                color: ClinicSageColors.surface,
                border: Border(bottom: BorderSide(color: ClinicSageColors.border)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: ClinicSageGradients.brandVibrant,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: ClinicSageShadows.aiGlow,
                    ),
                    child: const Icon(Icons.manage_accounts_outlined, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Team & User Access Management',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Assign client projects, manage roles (Admin vs Account Manager), and enforce permissions',
                        style: theme.textTheme.labelSmall?.copyWith(fontSize: 11, color: ClinicSageColors.secondary),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20, color: ClinicSageColors.secondary),
                    tooltip: 'Refresh Users',
                    onPressed: _loadData,
                  ),
                ],
              ),
            ),
          ),

          // ── Metrics Row ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  _MetricCard(
                    title: 'Total Accounts',
                    value: '${_users.length}',
                    icon: Icons.people_outline,
                    color: const Color(0xFF6366F1),
                  ),
                  const SizedBox(width: 16),
                  _MetricCard(
                    title: 'Admins (Can Create Projects)',
                    value: '$adminCount',
                    icon: Icons.shield_outlined,
                    color: ClinicSageColors.tertiary,
                  ),
                  const SizedBox(width: 16),
                  _MetricCard(
                    title: 'Account Managers',
                    value: '$amCount',
                    icon: Icons.badge_outlined,
                    color: const Color(0xFF0EA5E9),
                  ),
                  const SizedBox(width: 16),
                  _MetricCard(
                    title: 'Agency Client Projects',
                    value: '${_allAgencyClients.length}',
                    icon: Icons.business_outlined,
                    color: const Color(0xFFF59E0B),
                  ),
                ],
              ),
            ),
          ),

          // ── Search & Filter Bar ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search by team member name or email...',
                        prefixIcon: const Icon(Icons.search, size: 18, color: ClinicSageColors.secondary),
                        filled: true,
                        fillColor: ClinicSageColors.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ClinicSageRadius.md),
                          borderSide: const BorderSide(color: ClinicSageColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ClinicSageRadius.md),
                          borderSide: const BorderSide(color: ClinicSageColors.border),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── User Cards List ──────────────────────────────────
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: ClinicSageColors.tertiary),
              ),
            )
          else if (_errorMessage != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    Text('Error loading team members: $_errorMessage'),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _loadData, child: const Text('Try Again')),
                  ],
                ),
              ),
            )
          else if (filteredUsers.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('No team accounts found matching your query.'),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final user = filteredUsers[index];
                    final isSelf = user.id == currentUser?.id;
                    final assignedClientNames = _allAgencyClients
                        .where((c) => user.assignedClientIds.contains(c.id))
                        .map((c) => c.name)
                        .toList();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: ClinicSageColors.surface,
                        borderRadius: BorderRadius.circular(ClinicSageRadius.lg),
                        border: Border.all(color: ClinicSageColors.border),
                        boxShadow: const [
                          BoxShadow(color: Color(0x04000000), blurRadius: 10, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User Avatar
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: user.isAdmin ? ClinicSageColors.tertiaryLight : const Color(0xFFE0F2FE),
                            child: Text(
                              user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: user.isAdmin ? ClinicSageColors.tertiary : const Color(0xFF0284C7),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // User Info & Assigned Projects
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      user.displayName,
                                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
                                    ),
                                    if (isSelf) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text('You', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(user.email, style: theme.textTheme.bodySmall?.copyWith(color: ClinicSageColors.secondary)),
                                const SizedBox(height: 12),

                                // Access Scope
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Client Access: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ClinicSageColors.secondary)),
                                    Expanded(
                                      child: user.isAdmin
                                          ? Row(
                                              children: [
                                                Icon(Icons.all_inclusive, size: 14, color: Colors.green.shade700),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Full Agency Access (All Projects)',
                                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green.shade700),
                                                ),
                                              ],
                                            )
                                          : assignedClientNames.isEmpty
                                              ? const Text(
                                                  'No client workspaces assigned yet',
                                                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.redAccent),
                                                )
                                              : Wrap(
                                                  spacing: 6,
                                                  runSpacing: 4,
                                                  children: assignedClientNames.map((name) {
                                                    return Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFF1F5F9),
                                                        borderRadius: BorderRadius.circular(6),
                                                        border: Border.all(color: const Color(0xFFCBD5E1)),
                                                      ),
                                                      child: Text(
                                                        name,
                                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Role Selector Dropdown
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: user.isAdmin ? ClinicSageColors.tertiaryLight : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: user.isAdmin ? ClinicSageColors.tertiary.withOpacity(0.3) : ClinicSageColors.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: user.role,
                                isDense: true,
                                icon: const Icon(Icons.arrow_drop_down, size: 18),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'admin',
                                    child: Text('Admin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ClinicSageColors.tertiary)),
                                  ),
                                  DropdownMenuItem(
                                    value: 'accountManager',
                                    child: Text('Account Manager', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                                  ),
                                ],
                                onChanged: (newRole) {
                                  if (newRole != null && newRole != user.role) {
                                    _updateRole(user, newRole);
                                  }
                                },
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Assign Projects Button (if Account Manager)
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              side: BorderSide(color: user.isAdmin ? Colors.grey.shade300 : ClinicSageColors.tertiary),
                            ),
                            onPressed: user.isAdmin ? null : () => _openAssignDialog(user),
                            icon: Icon(
                              Icons.edit_note,
                              size: 16,
                              color: user.isAdmin ? Colors.grey : ClinicSageColors.tertiary,
                            ),
                            label: Text(
                              'Assign Projects',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: user.isAdmin ? Colors.grey : ClinicSageColors.tertiary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: filteredUsers.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ClinicSageColors.surface,
          borderRadius: BorderRadius.circular(ClinicSageRadius.lg),
          border: Border.all(color: ClinicSageColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                Text(title, style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, color: ClinicSageColors.secondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
