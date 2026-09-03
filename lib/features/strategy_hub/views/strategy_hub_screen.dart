import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/clinic_card.dart';
import '../../../data/models/strategy_deliverable_model.dart';
import '../../../core/services/gemini_service.dart';
import '../../../data/models/client_model.dart';
import '../../dashboard/providers/client_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/services/firebase_service.dart';
import '../../../shared/widgets/workspace_phase_header.dart';

/// Phase 3B: Research & Strategy Hub
/// SWOT 2x2 grid, Social Media Calendar, SEO Keywords, Personas
class StrategyHubScreen extends ConsumerStatefulWidget {
  final String clientId;
  const StrategyHubScreen({super.key, required this.clientId});

  @override
  ConsumerState<StrategyHubScreen> createState() => _StrategyHubScreenState();
}

class _StrategyHubScreenState extends ConsumerState<StrategyHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isGenerating = false;
  SwotMatrix _swot = SwotMatrix.mock;
  late List<SeoKeyword> _seoKeywords;
  late List<PersonaModel> _personas;
  late List<CalendarEvent> _calendarEvents;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _seoKeywords = List.from(_mockSeoKeywords);
    _personas = List.from(_mockPersonas);
    _initCalendarEvents();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedStrategy();
    });
  }

  void _initCalendarEvents() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    _calendarEvents = [
      CalendarEvent(id: 'evt-1', title: 'Product Benefits & Value Proposition', platform: 'LinkedIn', scheduledDate: monday, contentType: 'post'),
      CalendarEvent(id: 'evt-2', title: 'Customer Transformation Story', platform: 'Instagram', scheduledDate: monday.add(const Duration(days: 1)), contentType: 'video'),
      CalendarEvent(id: 'evt-3', title: 'Industry Insights & Market Trends', platform: 'Twitter', scheduledDate: monday.add(const Duration(days: 2)), contentType: 'post'),
      CalendarEvent(id: 'evt-4', title: 'Behind the Scenes & Executive Interview', platform: 'LinkedIn', scheduledDate: monday.add(const Duration(days: 3)), contentType: 'carousel'),
      CalendarEvent(id: 'evt-5', title: 'Weekly Q&A & Thought Leadership', platform: 'YouTube', scheduledDate: monday.add(const Duration(days: 4)), contentType: 'video'),
    ];
  }

  Future<void> _loadSavedStrategy() async {
    final am = ref.read(authProvider).user;
    final amId = am?.id ?? 'am-default';

    try {
      final doc = await FirebaseService.instance.getDeliverable(amId, widget.clientId, 'strategy');
      if (doc != null) {
        final model = StrategyDeliverableModel.fromJson('strategy', doc);
        if (mounted) {
          setState(() {
            _swot = model.swot;
            if (model.seoKeywords.isNotEmpty) _seoKeywords = List.from(model.seoKeywords);
            if (model.personas.isNotEmpty) _personas = List.from(model.personas);
            if (model.calendarEvents.isNotEmpty) _calendarEvents = List.from(model.calendarEvents);
          });
        }
      } else {
        await _saveCurrentStrategy();
      }
    } catch (e) {
      debugPrint('Error loading saved strategy: $e');
    }
  }

  Future<void> _saveCurrentStrategy() async {
    final am = ref.read(authProvider).user;
    final amId = am?.id ?? 'am-default';

    final model = StrategyDeliverableModel(
      id: 'strategy',
      clientId: widget.clientId,
      swot: _swot,
      seoKeywords: _seoKeywords,
      personas: _personas,
      calendarEvents: _calendarEvents,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await FirebaseService.instance.saveDeliverable(amId, widget.clientId, 'strategy', model.toJson());
    } catch (e) {
      debugPrint('Error saving strategy to Firestore: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientState = ref.watch(clientProvider);
    final client = clientState.getClient(widget.clientId);

    return Scaffold(
      backgroundColor: ClinicSageColors.neutral,
      body: Column(
        children: [
          // ── Unified Workspace Navigation Header ──────────
          WorkspacePhaseHeader(client: client, activePhaseIndex: 2),

          // ── Top Bar ──────────────────────────────────────
          _StrategyTopBar(
            client: client,
            isGenerating: _isGenerating,
            onGenerate: () => _onGenerateAll(client),
          ),

          // ── Tabs ──────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: ClinicSageColors.surface,
              border: Border(bottom: BorderSide(color: ClinicSageColors.border)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              tabs: const [
                Tab(text: 'SWOT Analysis'),
                Tab(text: 'Social Calendar'),
                Tab(text: 'SEO Keywords'),
                Tab(text: 'Target Personas'),
              ],
            ),
          ),

          // ── Tab Views ─────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _SwotTab(
                  swot: _swot,
                  onSwotChanged: (s) {
                    setState(() => _swot = s);
                    _saveCurrentStrategy();
                  },
                ),
                _CalendarTab(events: _calendarEvents, onAddPost: _onAddCalendarEvent),
                _SeoTab(keywords: _seoKeywords),
                _PersonasTab(personas: _personas),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onGenerateAll(ClientModel client) async {
    setState(() => _isGenerating = true);
    final strategy = await GeminiService.instance.generateStrategy(
      clientId: client.id,
      clientName: client.name,
      industry: client.industry,
      extractedPdfContent: client.extractedPdfContent,
    );
    if (!mounted) return;
    setState(() {
      _isGenerating = false;
      _swot = strategy.swot;
      if (strategy.seoKeywords.isNotEmpty) {
        _seoKeywords = List.from(strategy.seoKeywords);
      }
      if (strategy.personas.isNotEmpty) {
        _personas = List.from(strategy.personas);
      }
      if (strategy.calendarEvents.isNotEmpty) {
        _calendarEvents = List.from(strategy.calendarEvents);
      }
    });

    await _saveCurrentStrategy();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✨ Strategy matrix generated with Gemini AI & saved to Firestore!')),
      );
    }
  }

  void _onAddCalendarEvent(String title, String platform, DateTime scheduledDate, String contentType) {
    setState(() {
      _calendarEvents.add(
        CalendarEvent(
          id: 'evt-${DateTime.now().millisecondsSinceEpoch}',
          title: title,
          platform: platform,
          scheduledDate: scheduledDate,
          contentType: contentType,
        ),
      );
    });
    _saveCurrentStrategy();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Bar
// ─────────────────────────────────────────────────────────────────────────────
class _StrategyTopBar extends StatelessWidget {
  final ClientModel client;
  final bool isGenerating;
  final VoidCallback onGenerate;

  const _StrategyTopBar({required this.client, required this.isGenerating, required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: ClinicSageSpacing.lg),
      decoration: const BoxDecoration(
        color: ClinicSageColors.surface,
        border: Border(bottom: BorderSide(color: ClinicSageColors.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.insights_outlined, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(client.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              Text('Strategy Hub · Phase 2 of 4', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
            ],
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: () => GoRouter.of(context).go(AppRoutes.clientContentPath(client.id)),
            child: const Text('Content Studio →'),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(ClinicSageRadius.md),
            child: InkWell(
              onTap: isGenerating ? null : onGenerate,
              borderRadius: BorderRadius.circular(ClinicSageRadius.md),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: isGenerating
                      ? LinearGradient(colors: [const Color(0xFF8B5CF6).withOpacity(0.4), const Color(0xFF8B5CF6).withOpacity(0.4)])
                      : const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)]),
                  borderRadius: BorderRadius.circular(ClinicSageRadius.md),
                  boxShadow: isGenerating
                      ? []
                      : [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.30), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    isGenerating
                        ? const SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                    const SizedBox(width: 7),
                    Text(
                      isGenerating ? 'Generating...' : 'Generate Strategy',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => GoRouter.of(context).go(AppRoutes.clientReviewPath(client.id)),
            child: const Text('Go to Review →'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: SWOT Analysis 2×2 Grid
// ─────────────────────────────────────────────────────────────────────────────
class _SwotTab extends StatelessWidget {
  final SwotMatrix swot;
  final ValueChanged<SwotMatrix> onSwotChanged;

  const _SwotTab({required this.swot, required this.onSwotChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ClinicSageSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'SWOT Analysis',
            subtitle: 'AI-generated strategic assessment. Click "Add item" to add custom factors.',
          ),
          const SizedBox(height: ClinicSageSpacing.lg),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _SwotQuadrant(
                        title: 'Strengths',
                        icon: Icons.trending_up,
                        items: swot.strengths,
                        backgroundColor: ClinicSageColors.swotStrengths,
                        accentColor: ClinicSageColors.swotStrengthsAccent,
                        label: 'INTERNAL — POSITIVE',
                        onAddItem: (text) {
                          onSwotChanged(swot.copyWith(strengths: [...swot.strengths, text]));
                        },
                      ),
                    ),
                    const SizedBox(width: ClinicSageSpacing.md),
                    Expanded(
                      child: _SwotQuadrant(
                        title: 'Weaknesses',
                        icon: Icons.trending_down,
                        items: swot.weaknesses,
                        backgroundColor: ClinicSageColors.swotWeaknesses,
                        accentColor: ClinicSageColors.swotWeaknessesAccent,
                        label: 'INTERNAL — NEGATIVE',
                        onAddItem: (text) {
                          onSwotChanged(swot.copyWith(weaknesses: [...swot.weaknesses, text]));
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: ClinicSageSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _SwotQuadrant(
                        title: 'Opportunities',
                        icon: Icons.open_in_new,
                        items: swot.opportunities,
                        backgroundColor: ClinicSageColors.swotOpportunities,
                        accentColor: ClinicSageColors.swotOpportunitiesAccent,
                        label: 'EXTERNAL — POSITIVE',
                        onAddItem: (text) {
                          onSwotChanged(swot.copyWith(opportunities: [...swot.opportunities, text]));
                        },
                      ),
                    ),
                    const SizedBox(width: ClinicSageSpacing.md),
                    Expanded(
                      child: _SwotQuadrant(
                        title: 'Threats',
                        icon: Icons.warning_amber_outlined,
                        items: swot.threats,
                        backgroundColor: ClinicSageColors.swotThreats,
                        accentColor: ClinicSageColors.swotThreatsAccent,
                        label: 'EXTERNAL — NEGATIVE',
                        onAddItem: (text) {
                          onSwotChanged(swot.copyWith(threats: [...swot.threats, text]));
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SwotQuadrant extends StatelessWidget {
  final String title;
  final String label;
  final IconData icon;
  final List<String> items;
  final Color backgroundColor;
  final Color accentColor;
  final Function(String) onAddItem;

  const _SwotQuadrant({
    required this.title,
    required this.label,
    required this.icon,
    required this.items,
    required this.backgroundColor,
    required this.accentColor,
    required this.onAddItem,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(ClinicSageRadius.lg),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  Text(label, style: theme.textTheme.labelSmall?.copyWith(
                    color: accentColor.withOpacity(0.7),
                    letterSpacing: 0.5,
                  )),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...items.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      '${e.key + 1}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    e.value,
                    style: theme.textTheme.bodySmall?.copyWith(color: ClinicSageColors.primary),
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _promptAddItem(context),
            icon: Icon(Icons.add, size: 14, color: accentColor),
            label: Text('Add factor', style: TextStyle(color: accentColor, fontSize: 12)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  void _promptAddItem(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add $title Factor'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter strategic point...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onAddItem(controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: Social Media Calendar
// ─────────────────────────────────────────────────────────────────────────────
class _CalendarTab extends StatefulWidget {
  final List<CalendarEvent> events;
  final Function(String title, String platform, DateTime scheduledDate, String contentType) onAddPost;

  const _CalendarTab({required this.events, required this.onAddPost});

  @override
  State<_CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<_CalendarTab> {
  DateTime _weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));

  List<DateTime> get _weekDays => List.generate(7, (i) => _weekStart.add(Duration(days: i)));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ClinicSageSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SectionHeader(
                  title: 'Social Media Calendar',
                  subtitle: 'AI-scheduled content plan. Click "Add Post" or generate strategy to populate.',
                ),
              ),
              const SizedBox(width: 16),
              Container(
                decoration: ClinicSageDecorations.card,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 18),
                      onPressed: () => setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7))),
                    ),
                    Text(
                      '${DateFormat('MMM d').format(_weekStart)} – ${DateFormat('MMM d, yyyy').format(_weekStart.add(const Duration(days: 6)))}',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 18),
                      onPressed: () => setState(() => _weekStart = _weekStart.add(const Duration(days: 7))),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showAddPostDialog(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Post'),
              ),
            ],
          ),
          const SizedBox(height: ClinicSageSpacing.lg),
          ClinicCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Row(
                  children: _weekDays.map((day) {
                    final isToday = DateUtils.isSameDay(day, DateTime.now());
                    return Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isToday ? ClinicSageColors.tertiaryLight : ClinicSageColors.neutral,
                          border: const Border(
                            right: BorderSide(color: ClinicSageColors.border),
                            bottom: BorderSide(color: ClinicSageColors.border),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              DateFormat('EEE').format(day),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isToday ? ClinicSageColors.tertiary : ClinicSageColors.secondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('d').format(day),
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: isToday ? ClinicSageColors.tertiary : ClinicSageColors.primary,
                                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(
                  height: 280,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _weekDays.map((day) {
                      final dayEvents = widget.events.where((e) => DateUtils.isSameDay(e.scheduledDate, day)).toList();
                      return Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            border: Border(right: BorderSide(color: ClinicSageColors.border)),
                          ),
                          child: ListView(
                            children: dayEvents.map((e) => _CalendarEventChip(event: e)).toList(),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPostDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    String platform = 'LinkedIn';
    String contentType = 'post';
    DateTime selectedDate = _weekDays.firstWhere(
      (d) => DateUtils.isSameDay(d, DateTime.now()),
      orElse: () => _weekDays.first,
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Add Calendar Post'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Post Title / Topic', hintText: 'e.g. Product Demo Highlights'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: platform,
                items: const [
                  DropdownMenuItem(value: 'LinkedIn', child: Text('LinkedIn')),
                  DropdownMenuItem(value: 'Instagram', child: Text('Instagram')),
                  DropdownMenuItem(value: 'Twitter', child: Text('Twitter / X')),
                  DropdownMenuItem(value: 'YouTube', child: Text('YouTube')),
                  DropdownMenuItem(value: 'Facebook', child: Text('Facebook')),
                ],
                onChanged: (v) {
                  if (v != null) setDlgState(() => platform = v);
                },
                decoration: const InputDecoration(labelText: 'Platform'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<DateTime>(
                initialValue: selectedDate,
                items: _weekDays.map((d) => DropdownMenuItem(
                  value: d,
                  child: Text(DateFormat('EEEE (MMM d)').format(d)),
                )).toList(),
                onChanged: (v) {
                  if (v != null) setDlgState(() => selectedDate = v);
                },
                decoration: const InputDecoration(labelText: 'Scheduled Day'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.trim().isNotEmpty) {
                  widget.onAddPost(titleCtrl.text.trim(), platform, selectedDate, contentType);
                }
                Navigator.pop(context);
              },
              child: const Text('Schedule'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarEventChip extends StatelessWidget {
  final CalendarEvent event;
  const _CalendarEventChip({required this.event});

  Color get _platformColor {
    switch (event.platform.toLowerCase()) {
      case 'linkedin':
        return const Color(0xFF0077B5);
      case 'instagram':
        return const Color(0xFFE1306C);
      case 'twitter':
      case 'x':
        return const Color(0xFF1DA1F2);
      default:
        return ClinicSageColors.tertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: _platformColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _platformColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: _platformColor, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(
                event.platform,
                style: theme.textTheme.labelSmall?.copyWith(color: _platformColor, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            event.title,
            style: theme.textTheme.labelSmall?.copyWith(color: ClinicSageColors.primary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SeoTab extends StatelessWidget {
  final List<SeoKeyword> keywords;
  const _SeoTab({required this.keywords});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ClinicSageSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'SEO Strategy Planner',
            subtitle: 'Target keywords ranked by opportunity.',
          ),
          const SizedBox(height: ClinicSageSpacing.lg),
          ClinicCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: const BoxDecoration(
                    color: ClinicSageColors.neutral,
                    border: Border(bottom: BorderSide(color: ClinicSageColors.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text('KEYWORD', style: theme.textTheme.labelSmall)),
                      Expanded(child: Text('VOLUME', style: theme.textTheme.labelSmall, textAlign: TextAlign.center)),
                      Expanded(child: Text('DIFFICULTY', style: theme.textTheme.labelSmall, textAlign: TextAlign.center)),
                      Expanded(child: Text('INTENT', style: theme.textTheme.labelSmall)),
                      Expanded(child: Text('TARGET PAGE', style: theme.textTheme.labelSmall)),
                    ],
                  ),
                ),
                ...keywords.map((kw) => _SeoKeywordRow(keyword: kw)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SeoKeywordRow extends StatelessWidget {
  final SeoKeyword keyword;
  const _SeoKeywordRow({required this.keyword});

  Color get _difficultyColor {
    if (keyword.difficulty < 30) return ClinicSageColors.tertiary;
    if (keyword.difficulty < 60) return const Color(0xFF8B7A4E);
    return const Color(0xFF8B4E4E);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ClinicSageColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(keyword.keyword, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              '${(keyword.searchVolume / 1000).toStringAsFixed(1)}K',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 4,
                    width: 60,
                    decoration: BoxDecoration(
                      color: ClinicSageColors.neutral,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Container(
                    height: 4,
                    width: 60 * (keyword.difficulty / 100).clamp(0.1, 1.0),
                    decoration: BoxDecoration(
                      color: _difficultyColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: ClinicSageColors.neutral,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: ClinicSageColors.border),
              ),
              child: Text(keyword.intent, style: theme.textTheme.labelSmall, textAlign: TextAlign.center),
            ),
          ),
          Expanded(
            child: Text(
              keyword.targetPage ?? '—',
              style: theme.textTheme.bodySmall?.copyWith(color: ClinicSageColors.tertiary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonasTab extends StatelessWidget {
  final List<PersonaModel> personas;
  const _PersonasTab({required this.personas});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ClinicSageSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Target Persona Generator',
            subtitle: 'AI-built ICP cards from discovery data.',
          ),
          const SizedBox(height: ClinicSageSpacing.lg),
          Wrap(
            spacing: ClinicSageSpacing.md,
            runSpacing: ClinicSageSpacing.md,
            children: personas.map((p) => SizedBox(width: 320, child: _PersonaCard(persona: p))).toList(),
          ),
        ],
      ),
    );
  }
}

class _PersonaCard extends StatelessWidget {
  final PersonaModel persona;
  const _PersonaCard({required this.persona});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClinicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ClinicSageColors.tertiaryLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ClinicSageColors.border),
                ),
                child: Center(
                  child: Text(
                    persona.name.isNotEmpty ? persona.name.substring(0, 1) : 'P',
                    style: theme.textTheme.headlineSmall?.copyWith(color: ClinicSageColors.tertiary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(persona.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    Text('${persona.jobTitle} · ${persona.industry}', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _PersonaSection(title: 'Goals', items: persona.goals, color: ClinicSageColors.swotStrengthsAccent),
          const SizedBox(height: 12),
          _PersonaSection(title: 'Pain Points', items: persona.painPoints, color: ClinicSageColors.swotWeaknessesAccent),
          const SizedBox(height: 12),
          _PersonaSection(title: 'Channels', items: persona.channels, color: ClinicSageColors.swotOpportunitiesAccent),
          if (persona.aiSummary != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ClinicSageColors.neutral,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                persona.aiSummary!,
                style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PersonaSection extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color color;

  const _PersonaSection({required this.title, required this.items, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 4, height: 4, margin: const EdgeInsets.only(top: 5, right: 8), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              Expanded(child: Text(item, style: theme.textTheme.bodySmall?.copyWith(color: ClinicSageColors.primary))),
            ],
          ),
        )),
      ],
    );
  }
}

final _mockSeoKeywords = [
  const SeoKeyword(keyword: 'B2B marketing automation', searchVolume: 12000, difficulty: 68, intent: 'commercial', targetPage: '/features'),
  const SeoKeyword(keyword: 'SaaS lead generation', searchVolume: 8500, difficulty: 55, intent: 'informational', targetPage: '/blog'),
  const SeoKeyword(keyword: 'marketing attribution software', searchVolume: 3200, difficulty: 42, intent: 'commercial', targetPage: '/product'),
];

final _mockPersonas = [
  const PersonaModel(
    id: 'persona-1',
    name: 'The Growth Lead',
    jobTitle: 'VP Marketing',
    industry: 'SaaS / B2B',
    goals: ['Hit 120% MQL quota', 'Reduce CAC by 20%'],
    painPoints: ['Attribution gaps', 'Sales blaming marketing'],
    channels: ['LinkedIn', 'G2 Reviews'],
    aiSummary: 'Data-driven decision maker who needs clear attribution before committing budget.',
  ),
];
