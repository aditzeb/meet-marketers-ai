import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/client_model.dart';
import '../../dashboard/providers/client_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/pdf_extractor_service.dart';
import '../../../data/models/client_agentic_harness_model.dart';
import '../../../core/services/client_agentic_harness_service.dart';

import '../../../shared/widgets/workspace_phase_header.dart';

/// Phase 1: Client Inputs Ingestion View
/// 5-section desktop layout for collecting all client discovery assets.
class ClientInputsScreen extends ConsumerStatefulWidget {
  final String clientId;
  const ClientInputsScreen({super.key, required this.clientId});

  @override
  ConsumerState<ClientInputsScreen> createState() => _ClientInputsScreenState();
}

class _ClientInputsScreenState extends ConsumerState<ClientInputsScreen> {
  bool _isSaving = false;
  bool _isPitchDeckUploaded = false;
  bool _isDragOver = false;
  String? _pitchDeckFileName;
  String? _extractedPdfContent;
  bool _isExtractingPdf = false;
  bool _isUploadingStorage = false;

  List<String> _uploadedImages = [];
  bool _isImagesDragOver = false;

  List<String> _uploadedDocuments = [];
  bool _isDocsDragOver = false;

  // Controllers
  final _websiteController = TextEditingController();
  final Map<String, TextEditingController> _questionnaireControllers = {
    for (final key in QuestionnaireKeys.labels.keys) key: TextEditingController(),
  };

  // Dynamic Lists
  List<String> _competitors = [''];
  List<String> _roleModels = [''];

  // Agentic Harness State
  ClientAgenticHarnessModel? _harness;
  bool _isSynthesizingHarness = false;
  final _ruleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadClientData();
    });
  }

  @override
  void didUpdateWidget(ClientInputsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clientId != widget.clientId) {
      _loadClientData();
    }
  }

  void _loadClientData() {
    final client = ref.read(clientProvider).getClient(widget.clientId);
    if (client == null) return;

    // Reset website controller specifically to this client (blank if none)
    _websiteController.text = client.websiteUrl ?? '';

    // Reset questionnaire controllers to this client's answers (blank if not present)
    for (var key in QuestionnaireKeys.labels.keys) {
      _questionnaireControllers[key]?.text = client.questionnaireAnswers[key] ?? '';
    }

    // Reset all dynamic lists and upload state to this client
    setState(() {
      _competitors = client.competitors.isNotEmpty ? List.from(client.competitors) : [''];
      _roleModels = client.targetRoleModels.isNotEmpty ? List.from(client.targetRoleModels) : [''];
      if (client.pitchDeckStoragePath != null && client.pitchDeckStoragePath!.isNotEmpty) {
        _isPitchDeckUploaded = true;
        _pitchDeckFileName = client.pitchDeckStoragePath!.split('/').last;
      } else {
        _isPitchDeckUploaded = false;
        _pitchDeckFileName = null;
      }
      _uploadedImages = List.from(client.imageStoragePaths);
      _uploadedDocuments = List.from(client.documentStoragePaths);
      _extractedPdfContent = client.extractedPdfContent;
      _isExtractingPdf = false;
      _isUploadingStorage = false;
    });

    final am = ref.read(authProvider).user;
    final amId = am?.id ?? 'am-default';
    ClientAgenticHarnessService.instance.getHarness(amId, widget.clientId).then((harness) {
      if (mounted) {
        setState(() => _harness = harness);
      }
    });
  }

  @override
  void dispose() {
    _websiteController.dispose();
    _ruleController.dispose();
    for (final c in _questionnaireControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientState = ref.watch(clientProvider);
    final client = clientState.getClient(widget.clientId);

    if (client == null) {
      return Scaffold(
        backgroundColor: ClinicSageColors.neutral,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_outlined, size: 48, color: ClinicSageColors.secondary),
              const SizedBox(height: 16),
              const Text('Client workspace not found in Firestore.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ClinicSageColors.tertiary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => context.go(AppRoutes.dashboard),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Return to Dashboard'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ClinicSageColors.neutral,
      body: Column(
        children: [
          // ── Unified Workspace Navigation Header ──────────
          WorkspacePhaseHeader(client: client, activePhaseIndex: 1),

          // ── Top Bar ──────────────────────────────────────
          _InputsTopBar(
            client: client,
            isSaving: _isSaving || _isUploadingStorage,
            onSave: () => _onSave(client),
          ),
          // ── Scrollable Content ────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(ClinicSageSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Section 1: Website URL ────────────────
                  _Section(
                    number: '01',
                    title: 'Website URL',
                    subtitle: 'The primary URL that the AI will crawl and ingest for brand context.',
                    child: TextFormField(
                      controller: _websiteController,
                      decoration: const InputDecoration(
                        hintText: 'https://client.com',
                        prefixIcon: Icon(Icons.link, size: 18, color: ClinicSageColors.secondary),
                      ),
                    ),
                  ),
                  const SizedBox(height: ClinicSageSpacing.lg),

                  // ── Section 2: Pitch Deck Upload ───────────
                  _Section(
                    number: '02',
                    title: 'Pitch Deck',
                    subtitle: 'Upload the client\'s pitch deck (PDF). Drag and drop or click to browse.',
                    child: _PitchDeckDropZone(
                      isUploaded: _isPitchDeckUploaded,
                      isDragOver: _isDragOver,
                      fileName: _pitchDeckFileName,
                      extractedPdfContent: _extractedPdfContent,
                      isExtracting: _isExtractingPdf,
                      onDragOver: (over) => setState(() => _isDragOver = over),
                      onUpload: _onUploadPitchDeck,
                      onClear: () => setState(() {
                        _isPitchDeckUploaded = false;
                        _pitchDeckFileName = null;
                        _extractedPdfContent = null;
                      }),
                    ),
                  ),
                  const SizedBox(height: ClinicSageSpacing.lg),

                  // ── Section 3: Photos & Images ────────────
                  _Section(
                    number: '03',
                    title: 'Photos & Images',
                    subtitle: 'Upload brand images, logos, product photos, or visual references (PNG, JPG, WEBP, SVG) for AI visual context.',
                    child: _ImagesDropZone(
                      images: _uploadedImages,
                      isDragOver: _isImagesDragOver,
                      onDragOver: (over) => setState(() => _isImagesDragOver = over),
                      onUpload: _onUploadImages,
                      onRemove: _onRemoveImage,
                    ),
                  ),
                  const SizedBox(height: ClinicSageSpacing.lg),

                  // ── Section 4: Reference Documents ────────
                  _Section(
                    number: '04',
                    title: 'Reference Documents',
                    subtitle: 'Upload Word documents (.docx, .doc), PDFs, or brand guidelines for deeper AI background.',
                    child: _DocumentsDropZone(
                      documents: _uploadedDocuments,
                      isDragOver: _isDocsDragOver,
                      onDragOver: (over) => setState(() => _isDocsDragOver = over),
                      onUpload: _onUploadDocuments,
                      onRemove: _onRemoveDocument,
                    ),
                  ),
                  const SizedBox(height: ClinicSageSpacing.lg),

                  // ── Section 5: Discovery Questionnaire ─────
                  _Section(
                    number: '05',
                    title: 'Discovery Questionnaire',
                    subtitle: 'Answers collected from the client intake session. Fill in each field.',
                    child: _QuestionnaireGrid(controllers: _questionnaireControllers),
                  ),
                  const SizedBox(height: ClinicSageSpacing.lg),

                  // ── Section 6: Competitor Analysis ────────
                  _Section(
                    number: '06',
                    title: 'Competitor Analysis',
                    subtitle: 'List the client\'s key competitors for USP gap analysis.',
                    child: _DynamicListInput(
                      items: _competitors,
                      hint: 'e.g. Competitor Name / Domain',
                      addLabel: 'Add Competitor',
                      onChanged: () => setState(() {}),
                      onItemChanged: (index, value) => _competitors[index] = value,
                      onAdd: () => setState(() => _competitors.add('')),
                      onRemove: (index) => setState(() => _competitors.removeAt(index)),
                    ),
                  ),
                  const SizedBox(height: ClinicSageSpacing.lg),

                  // ── Section 7: Target Role Models ─────────
                  _Section(
                    number: '07',
                    title: 'Target Role Models',
                    subtitle: 'Brands or creators the client aspires to emulate in content and positioning.',
                    child: _DynamicListInput(
                      items: _roleModels,
                      hint: 'e.g. Brand Name or @handle',
                      addLabel: 'Add Role Model',
                      onChanged: () => setState(() {}),
                      onItemChanged: (index, value) => _roleModels[index] = value,
                      onAdd: () => setState(() => _roleModels.add('')),
                      onRemove: (index) => setState(() => _roleModels.removeAt(index)),
                    ),
                  ),
                  // ── Section 8: Client Agentic Brain & Learning Harness ─────────
                  _Section(
                    number: '08',
                    title: 'Client Agentic Brain & Learning Harness',
                    subtitle: 'Persistent AI memory that continuously learns from client inputs, pitch decks, and account manager directives.',
                    child: _AgenticHarnessView(
                      harness: _harness,
                      isSynthesizing: _isSynthesizingHarness,
                      ruleController: _ruleController,
                      onSync: _onSynthesizeHarness,
                      onAddRule: _onAddRule,
                      onDeleteRule: _onDeleteRule,
                    ),
                  ),
                  const SizedBox(height: ClinicSageSpacing.xl),

                  // ── Generate CTA ───────────────────────────
                  _GenerateCTA(clientId: widget.clientId, clientName: client.name),
                  const SizedBox(height: ClinicSageSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onSave(ClientModel client) async {
    setState(() => _isSaving = true);

    final qAnswers = <String, String>{};
    for (var entry in _questionnaireControllers.entries) {
      if (entry.value.text.trim().isNotEmpty) {
        qAnswers[entry.key] = entry.value.text.trim();
      }
    }

    final updatedClient = client.copyWith(
      websiteUrl: _websiteController.text.trim(),
      questionnaireAnswers: qAnswers,
      competitors: _competitors.where((c) => c.trim().isNotEmpty).toList(),
      targetRoleModels: _roleModels.where((r) => r.trim().isNotEmpty).toList(),
      pitchDeckStoragePath: _pitchDeckFileName != null ? 'pitch_decks/$_pitchDeckFileName' : null,
      imageStoragePaths: _uploadedImages,
      documentStoragePaths: _uploadedDocuments,
      extractedPdfContent: _extractedPdfContent,
      lastActivity: DateTime.now(),
    );

    // Save to State & Firestore
    await ref.read(clientProvider.notifier).updateClient(updatedClient);

    final am = ref.read(authProvider).user;
    final amId = am?.id ?? 'am-default';

    await FirebaseService.instance.saveDeliverable(
      amId,
      updatedClient.id,
      'discovery_inputs',
      updatedClient.toJson(),
    );

    // Trigger Agentic Harness synthesis in background to continuously learn from inputs
    ClientAgenticHarnessService.instance.synthesizeHarness(
      client: updatedClient,
      amId: amId,
      trigger: 'inputs_save',
    ).then((updatedHarness) {
      if (mounted) {
        setState(() => _harness = updatedHarness);
      }
    });

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.cloud_done, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text('Inputs saved to Firebase for ${updatedClient.name}! Agentic Brain updating...'),
            ],
          ),
          backgroundColor: ClinicSageColors.tertiary,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _onSynthesizeHarness() async {
    final client = ref.read(clientProvider).getClient(widget.clientId);
    if (client == null) return;

    setState(() => _isSynthesizingHarness = true);
    final am = ref.read(authProvider).user;
    final amId = am?.id ?? 'am-default';

    try {
      final updated = await ClientAgenticHarnessService.instance.synthesizeHarness(
        client: client,
        amId: amId,
        trigger: 'manual_sync',
      );
      if (mounted) {
        setState(() {
          _harness = updated;
          _isSynthesizingHarness = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.psychology, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Agentic Brain synchronized & updated with client context!'),
              ],
            ),
            backgroundColor: ClinicSageColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isSynthesizingHarness = false);
    }
  }

  Future<void> _onAddRule() async {
    final ruleText = _ruleController.text.trim();
    if (ruleText.isEmpty) return;

    final am = ref.read(authProvider).user;
    final amId = am?.id ?? 'am-default';

    final updated = await ClientAgenticHarnessService.instance.addCustomRule(
      amId: amId,
      clientId: widget.clientId,
      rule: ruleText,
    );

    if (mounted) {
      setState(() {
        _harness = updated;
        _ruleController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Learned directive: "$ruleText"'),
          backgroundColor: ClinicSageColors.tertiary,
        ),
      );
    }
  }

  Future<void> _onDeleteRule(String rule) async {
    final am = ref.read(authProvider).user;
    final amId = am?.id ?? 'am-default';

    final updated = await ClientAgenticHarnessService.instance.deleteRule(
      amId: amId,
      clientId: widget.clientId,
      rule: rule,
    );

    if (mounted) {
      setState(() => _harness = updated);
    }
  }

  void _onUploadPitchDeck() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final fileName = file.name;
        final bytes = file.bytes;

        setState(() {
          _isPitchDeckUploaded = true;
          _pitchDeckFileName = fileName;
          _isExtractingPdf = true;
          _isDragOver = false;
        });

        // 1. Extract text from PDF using Flutter engine
        String extracted = '';
        if (bytes != null && bytes.isNotEmpty) {
          extracted = PdfExtractorService.instance.extractTextFromBytes(bytes);
        }

        // 2. Upload to Firebase Storage
        if (bytes != null && bytes.isNotEmpty) {
          await FirebaseService.instance.uploadFile(
            clientId: widget.clientId,
            folder: 'pitch_decks',
            fileName: fileName,
            bytes: bytes,
            contentType: 'application/pdf',
          );
        }

        if (mounted) {
          setState(() {
            _isExtractingPdf = false;
            _extractedPdfContent = extracted;
            _pitchDeckFileName = fileName;
          });

          // Auto-save immediately to client state & Firestore
          final currentClient = ref.read(clientProvider).getClient(widget.clientId);
          if (currentClient != null) {
            _onSave(currentClient);
          }

          final wordCount = extracted.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      extracted.isNotEmpty
                          ? 'Uploaded to Firebase Storage & extracted $wordCount words for AI generation!'
                          : 'Uploaded $fileName to Firebase Storage!',
                    ),
                  ),
                ],
              ),
              backgroundColor: ClinicSageColors.tertiary,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Pitch deck upload error: $e');
      if (mounted) {
        setState(() {
          _isExtractingPdf = false;
          _isPitchDeckUploaded = true;
          _pitchDeckFileName = 'pitch_deck_ingested.pdf';
          _isDragOver = false;
        });
      }
    }
  }

  void _onUploadImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'svg', 'gif'],
        allowMultiple: true,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() => _isUploadingStorage = true);
        for (final f in result.files) {
          final fileName = f.name;
          final bytes = f.bytes;
          String fileRef = fileName;
          if (bytes != null && bytes.isNotEmpty) {
            final ext = f.extension?.toLowerCase() ?? 'png';
            final url = await FirebaseService.instance.uploadFile(
              clientId: widget.clientId,
              folder: 'images',
              fileName: fileName,
              bytes: bytes,
              contentType: 'image/$ext',
            );
            if (url != null) fileRef = url;
          }
          if (!_uploadedImages.contains(fileRef)) {
            _uploadedImages.add(fileRef);
          }
        }
        if (mounted) {
          setState(() {
            _isUploadingStorage = false;
            _isImagesDragOver = false;
          });
          final currentClient = ref.read(clientProvider).getClient(widget.clientId);
          if (currentClient != null) {
            _onSave(currentClient);
          }
        }
      }
    } catch (e) {
      debugPrint('Images upload error: $e');
      if (mounted) {
        setState(() {
          _isUploadingStorage = false;
          _isImagesDragOver = false;
        });
      }
    }
  }

  void _onRemoveImage(int index) {
    setState(() {
      _uploadedImages.removeAt(index);
    });
  }

  void _onUploadDocuments() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'rtf'],
        allowMultiple: true,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() => _isUploadingStorage = true);
        for (final f in result.files) {
          final fileName = f.name;
          final bytes = f.bytes;
          String fileRef = fileName;

          // If document is a PDF, extract text using Flutter engine as well
          if (f.extension?.toLowerCase() == 'pdf' && bytes != null && bytes.isNotEmpty) {
            final docText = PdfExtractorService.instance.extractTextFromBytes(bytes);
            if (docText.isNotEmpty) {
              _extractedPdfContent = (_extractedPdfContent != null && _extractedPdfContent!.isNotEmpty)
                  ? '$_extractedPdfContent\n\n--- Document: $fileName ---\n$docText'
                  : '--- Document: $fileName ---\n$docText';
            }
          }

          if (bytes != null && bytes.isNotEmpty) {
            final ext = f.extension?.toLowerCase() ?? 'bin';
            final contentType = ext == 'pdf' ? 'application/pdf' : 'application/octet-stream';
            final url = await FirebaseService.instance.uploadFile(
              clientId: widget.clientId,
              folder: 'documents',
              fileName: fileName,
              bytes: bytes,
              contentType: contentType,
            );
            if (url != null) fileRef = url;
          }

          if (!_uploadedDocuments.contains(fileRef)) {
            _uploadedDocuments.add(fileRef);
          }
        }
        if (mounted) {
          setState(() {
            _isUploadingStorage = false;
            _isDocsDragOver = false;
          });
          final currentClient = ref.read(clientProvider).getClient(widget.clientId);
          if (currentClient != null) {
            _onSave(currentClient);
          }
        }
      }
    } catch (e) {
      debugPrint('Documents upload error: $e');
      if (mounted) {
        setState(() {
          _isUploadingStorage = false;
          _isDocsDragOver = false;
        });
      }
    }
  }

  void _onRemoveDocument(int index) {
    setState(() {
      _uploadedDocuments.removeAt(index);
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Action Bar
// ─────────────────────────────────────────────────────────────────────────────
class _InputsTopBar extends StatelessWidget {
  final ClientModel client;
  final bool isSaving;
  final VoidCallback onSave;

  const _InputsTopBar({required this.client, required this.isSaving, required this.onSave});

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
              gradient: ClinicSageGradients.tertiary,
              borderRadius: BorderRadius.circular(8),
              boxShadow: ClinicSageShadows.aiGlow,
            ),
            child: const Icon(Icons.description_outlined, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(client.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              Text('Client Inputs · Phase 1 of 4', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
            ],
          ),
          const Spacer(),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(ClinicSageRadius.md),
            child: InkWell(
              onTap: isSaving ? null : onSave,
              borderRadius: BorderRadius.circular(ClinicSageRadius.md),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: isSaving
                      ? LinearGradient(colors: [ClinicSageColors.tertiary.withOpacity(0.4), ClinicSageColors.tertiary.withOpacity(0.4)])
                      : ClinicSageGradients.tertiary,
                  borderRadius: BorderRadius.circular(ClinicSageRadius.md),
                  boxShadow: isSaving ? [] : ClinicSageShadows.button,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    isSaving
                        ? const SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.cloud_upload_outlined, size: 14, color: Colors.white),
                    const SizedBox(width: 7),
                    Text(
                      isSaving ? 'Saving...' : 'Save Draft',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final Widget child;

  const _Section({required this.number, required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: ClinicSageGradients.tertiary,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: ClinicSageShadows.aiGlow,
                  ),
                  child: Center(
                    child: Text(
                      number,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(subtitle, style: theme.textTheme.labelSmall?.copyWith(height: 1.6)),
              ],
            ),
          ),
        ),
        const SizedBox(width: ClinicSageSpacing.lg),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: ClinicSageColors.surface,
              borderRadius: BorderRadius.circular(ClinicSageRadius.lg),
              border: Border.all(color: ClinicSageColors.border),
              boxShadow: ClinicSageShadows.card,
            ),
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _PitchDeckDropZone extends StatelessWidget {
  final bool isUploaded;
  final bool isDragOver;
  final String? fileName;
  final String? extractedPdfContent;
  final bool isExtracting;
  final ValueChanged<bool> onDragOver;
  final VoidCallback onUpload;
  final VoidCallback onClear;

  const _PitchDeckDropZone({
    required this.isUploaded,
    required this.isDragOver,
    required this.fileName,
    this.extractedPdfContent,
    this.isExtracting = false,
    required this.onDragOver,
    required this.onUpload,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isUploaded) {
      final wordCount = (extractedPdfContent != null && extractedPdfContent!.isNotEmpty)
          ? extractedPdfContent!.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length
          : 0;

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ClinicSageColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ClinicSageColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ClinicSageColors.statusVettedBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.picture_as_pdf, size: 24, color: ClinicSageColors.tertiary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fileName ?? 'pitch_deck.pdf', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      Text(
                        isExtracting
                            ? 'Extracting text using Flutter Engine...'
                            : 'Saved in Firebase Storage · $wordCount words extracted for AI',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isExtracting ? ClinicSageColors.primary : ClinicSageColors.tertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isExtracting)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: ClinicSageColors.tertiary),
                  )
                else
                  TextButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.close, size: 14),
                    label: const Text('Remove'),
                    style: TextButton.styleFrom(foregroundColor: ClinicSageColors.secondary),
                  ),
              ],
            ),
            if (wordCount > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: ClinicSageColors.tertiaryLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: ClinicSageColors.tertiary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 13, color: ClinicSageColors.tertiary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Flutter Engine Extracted $wordCount words: Ready for automated AI content ingestion',
                        style: theme.textTheme.labelSmall?.copyWith(color: ClinicSageColors.tertiary, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }

    return DragTarget<Object>(
      onWillAcceptWithDetails: (_) {
        onDragOver(true);
        return true;
      },
      onLeave: (_) => onDragOver(false),
      onAcceptWithDetails: (_) {
        onDragOver(false);
        onUpload();
      },
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: onUpload,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: isDragOver ? ClinicSageColors.tertiaryLight : ClinicSageColors.neutral,
              borderRadius: BorderRadius.circular(ClinicSageRadius.md),
              border: Border.all(
                color: isDragOver ? ClinicSageColors.tertiary : ClinicSageColors.border,
                width: isDragOver ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.upload_file_outlined,
                  size: 32,
                  color: isDragOver ? ClinicSageColors.tertiary : ClinicSageColors.secondary,
                ),
                const SizedBox(height: 12),
                Text(
                  isDragOver ? 'Drop to upload' : 'Drag & drop PDF here',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'or click to browse — PDF files only',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuestionnaireGrid extends StatelessWidget {
  final Map<String, TextEditingController> controllers;
  const _QuestionnaireGrid({required this.controllers});

  @override
  Widget build(BuildContext context) {
    final entries = QuestionnaireKeys.labels.entries.toList();

    return Column(
      children: [
        for (int i = 0; i < entries.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: ClinicSageSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: _QuestionField(
                    label: entries[i].value,
                    controller: controllers[entries[i].key]!,
                    isMultiline: _isMultiline(entries[i].key),
                  ),
                ),
                if (i + 1 < entries.length) ...[
                  const SizedBox(width: ClinicSageSpacing.md),
                  Expanded(
                    child: _QuestionField(
                      label: entries[i + 1].value,
                      controller: controllers[entries[i + 1].key]!,
                      isMultiline: _isMultiline(entries[i + 1].key),
                    ),
                  ),
                ] else
                  const Expanded(child: SizedBox()),
              ],
            ),
          ),
      ],
    );
  }

  bool _isMultiline(String key) {
    return [
      QuestionnaireKeys.targetCustomer,
      QuestionnaireKeys.keyDifferentiator,
      QuestionnaireKeys.mainSalesChannel,
    ].contains(key);
  }
}

class _QuestionField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isMultiline;

  const _QuestionField({required this.label, required this.controller, this.isMultiline = false});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: isMultiline ? 3 : 1,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _DynamicListInput extends StatelessWidget {
  final List<String> items;
  final String hint;
  final String addLabel;
  final VoidCallback onChanged;
  final Function(int, String) onItemChanged;
  final VoidCallback onAdd;
  final Function(int) onRemove;

  const _DynamicListInput({
    required this.items,
    required this.hint,
    required this.addLabel,
    required this.onChanged,
    required this.onItemChanged,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...items.asMap().entries.map((entry) {
          final i = entry.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: ClinicSageSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: ClinicSageColors.neutral,
                    border: Border.all(color: ClinicSageColors.border),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    initialValue: items[i],
                    onChanged: (v) => onItemChanged(i, v),
                    decoration: InputDecoration(hintText: hint),
                  ),
                ),
                const SizedBox(width: 8),
                if (items.length > 1)
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    color: ClinicSageColors.secondary,
                    onPressed: () => onRemove(i),
                    tooltip: 'Remove',
                  ),
              ],
            ),
          );
        }),
        const SizedBox(height: ClinicSageSpacing.sm),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 16),
          label: Text(addLabel),
        ),
      ],
    );
  }
}

class _GenerateCTA extends StatelessWidget {
  final String clientId;
  final String clientName;
  const _GenerateCTA({required this.clientId, required this.clientName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: ClinicSageGradients.brandVibrant,
        borderRadius: BorderRadius.circular(ClinicSageRadius.lg),
        boxShadow: ClinicSageShadows.cardHover,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ready to generate deliverables for $clientName?',
                  style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Inputs will be vectorized and orchestrated via OpenRouter AI to create campaign-ready assets.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(ClinicSageRadius.md),
                child: InkWell(
                  onTap: () => GoRouter.of(context).go(AppRoutes.clientContentPath(clientId)),
                  borderRadius: BorderRadius.circular(ClinicSageRadius.md),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: ClinicSageGradients.tertiary,
                      borderRadius: BorderRadius.circular(ClinicSageRadius.md),
                      boxShadow: ClinicSageShadows.button,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
                        SizedBox(width: 7),
                        Text('Generate Content', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => GoRouter.of(context).go(AppRoutes.clientStrategyPath(clientId)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                ),
                child: const Text('Generate Strategy', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImagesDropZone extends StatelessWidget {
  final List<String> images;
  final bool isDragOver;
  final ValueChanged<bool> onDragOver;
  final VoidCallback onUpload;
  final Function(int) onRemove;

  const _ImagesDropZone({
    required this.images,
    required this.isDragOver,
    required this.onDragOver,
    required this.onUpload,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (images.isNotEmpty) ...[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: images.asMap().entries.map((entry) {
              final index = entry.key;
              final fileName = entry.value;
              final ext = fileName.contains('.') ? fileName.split('.').last.toUpperCase() : 'IMG';

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: ClinicSageColors.neutral,
                  borderRadius: BorderRadius.circular(ClinicSageRadius.md),
                  border: Border.all(color: ClinicSageColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: ClinicSageColors.tertiaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.image_outlined, size: 18, color: ClinicSageColors.tertiary),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          fileName,
                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '$ext Reference Image',
                          style: theme.textTheme.labelSmall?.copyWith(color: ClinicSageColors.secondary, fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => onRemove(index),
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.close, size: 14, color: ClinicSageColors.secondary),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: ClinicSageSpacing.md),
        ],
        DragTarget<Object>(
          onWillAcceptWithDetails: (_) {
            onDragOver(true);
            return true;
          },
          onLeave: (_) => onDragOver(false),
          onAcceptWithDetails: (_) {
            onDragOver(false);
            onUpload();
          },
          builder: (context, candidateData, rejectedData) {
            return GestureDetector(
              onTap: onUpload,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: isDragOver ? ClinicSageColors.tertiaryLight : ClinicSageColors.neutral,
                  borderRadius: BorderRadius.circular(ClinicSageRadius.md),
                  border: Border.all(
                    color: isDragOver ? ClinicSageColors.tertiary : ClinicSageColors.border,
                    width: isDragOver ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 30,
                        color: isDragOver ? ClinicSageColors.tertiary : ClinicSageColors.secondary,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isDragOver
                            ? 'Drop images to upload'
                            : (images.isEmpty ? 'Drag & drop brand photos or images here' : 'Click to add more photos & images'),
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PNG, JPG, WEBP, SVG files allowed for visual brand context',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _DocumentsDropZone extends StatelessWidget {
  final List<String> documents;
  final bool isDragOver;
  final ValueChanged<bool> onDragOver;
  final VoidCallback onUpload;
  final Function(int) onRemove;

  const _DocumentsDropZone({
    required this.documents,
    required this.isDragOver,
    required this.onDragOver,
    required this.onUpload,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (documents.isNotEmpty) ...[
          Column(
            children: documents.asMap().entries.map((entry) {
              final index = entry.key;
              final fileName = entry.value;
              final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';

              IconData iconData = Icons.description_outlined;
              Color iconBg = ClinicSageColors.tertiaryLight;
              Color iconColor = ClinicSageColors.tertiary;
              String typeLabel = 'Document File';

              if (ext == 'pdf') {
                iconData = Icons.picture_as_pdf_outlined;
                iconBg = const Color(0xFFFDE8E8);
                iconColor = const Color(0xFFE53E3E);
                typeLabel = 'PDF Document';
              } else if (ext == 'doc' || ext == 'docx') {
                iconData = Icons.description_outlined;
                iconBg = const Color(0xFFEBF8FF);
                iconColor = const Color(0xFF3182CE);
                typeLabel = 'Word Document';
              } else if (ext == 'txt' || ext == 'rtf') {
                iconData = Icons.article_outlined;
                iconBg = const Color(0xFFF0FFF4);
                iconColor = const Color(0xFF38A169);
                typeLabel = 'Text Reference';
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: ClinicSageColors.neutral,
                    borderRadius: BorderRadius.circular(ClinicSageRadius.md),
                    border: Border.all(color: ClinicSageColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(iconData, size: 20, color: iconColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fileName,
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              typeLabel,
                              style: theme.textTheme.labelSmall?.copyWith(color: ClinicSageColors.secondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        color: ClinicSageColors.secondary,
                        onPressed: () => onRemove(index),
                        tooltip: 'Remove document',
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: ClinicSageSpacing.md),
        ],
        DragTarget<Object>(
          onWillAcceptWithDetails: (_) {
            onDragOver(true);
            return true;
          },
          onLeave: (_) => onDragOver(false),
          onAcceptWithDetails: (_) {
            onDragOver(false);
            onUpload();
          },
          builder: (context, candidateData, rejectedData) {
            return GestureDetector(
              onTap: onUpload,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: isDragOver ? ClinicSageColors.tertiaryLight : ClinicSageColors.neutral,
                  borderRadius: BorderRadius.circular(ClinicSageRadius.md),
                  border: Border.all(
                    color: isDragOver ? ClinicSageColors.tertiary : ClinicSageColors.border,
                    width: isDragOver ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.note_add_outlined,
                        size: 30,
                        color: isDragOver ? ClinicSageColors.tertiary : ClinicSageColors.secondary,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isDragOver
                            ? 'Drop Word files / PDFs to upload'
                            : (documents.isEmpty
                                ? 'Drag & drop Word documents or PDFs here'
                                : 'Click to add more Word documents or PDFs'),
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'DOCX, DOC, PDF, TXT files for AI reference background',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Agentic Harness & Brain Interactive Panel
class _AgenticHarnessView extends StatelessWidget {
  final ClientAgenticHarnessModel? harness;
  final bool isSynthesizing;
  final TextEditingController ruleController;
  final VoidCallback onSync;
  final VoidCallback onAddRule;
  final ValueChanged<String> onDeleteRule;

  const _AgenticHarnessView({
    required this.harness,
    required this.isSynthesizing,
    required this.ruleController,
    required this.onSync,
    required this.onAddRule,
    required this.onDeleteRule,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final version = harness?.version ?? 1;
    final lastTime = harness?.lastSynthesized != null
        ? '${harness!.lastSynthesized.hour.toString().padLeft(2, '0')}:${harness!.lastSynthesized.minute.toString().padLeft(2, '0')}'
        : 'Just now';

    return Container(
      decoration: BoxDecoration(
        color: ClinicSageColors.surface,
        borderRadius: BorderRadius.circular(ClinicSageRadius.lg),
        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Status Header ────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF8B5CF6).withOpacity(0.18),
                  const Color(0xFF6366F1).withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(ClinicSageRadius.lg),
                topRight: Radius.circular(ClinicSageRadius.lg),
              ),
              border: Border(
                bottom: BorderSide(color: const Color(0xFF8B5CF6).withOpacity(0.2)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.4)),
                  ),
                  child: const Icon(Icons.psychology_rounded, color: Color(0xFFA78BFA), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Client Agentic Brain (v$version)',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline, size: 11, color: Color(0xFF34D399)),
                                SizedBox(width: 4),
                                Text(
                                  'Continuous Learning Active',
                                  style: TextStyle(
                                    color: Color(0xFF34D399),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Autonomous OpenRouter Memory Engine • Ingests every questionnaire answer, pitch deck, and edit • Last updated: $lastTime',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: ClinicSageColors.secondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: isSynthesizing ? null : onSync,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ClinicSageRadius.md)),
                  ),
                  icon: isSynthesizing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.sync_rounded, size: 16),
                  label: Text(
                    isSynthesizing ? 'Synthesizing...' : 'Sync & Re-synthesize',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // ── Body Sections ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Brand Voice & Tone DNA
                _HarnessBlock(
                  icon: Icons.record_voice_over_rounded,
                  title: 'Brand Voice & Tone DNA',
                  subtitle: 'Synthesized stylistic identity enforced across all Content Studio copy and proposals.',
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: ClinicSageColors.surface,
                      borderRadius: BorderRadius.circular(ClinicSageRadius.md),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Text(
                      harness?.brandVoice.isNotEmpty == true
                          ? harness!.brandVoice
                          : 'No custom voice synthesized yet. Upload pitch deck or fill discovery answers to generate.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Core Value Propositions & Moats
                _HarnessBlock(
                  icon: Icons.shield_outlined,
                  title: 'Core Value Propositions & Competitive Moats',
                  subtitle: 'Key pillars and defensive advantages the AI highlights in strategy and deliverables.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (harness?.coreValueProps.isNotEmpty == true) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: harness!.coreValueProps.map((vp) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, size: 14, color: Color(0xFF818CF8)),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      vp,
                                      style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (harness?.competitiveMoats.isNotEmpty == true) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: harness!.competitiveMoats.map((moat) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.25)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.verified_outlined, size: 14, color: Color(0xFF34D399)),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      moat,
                                      style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      if ((harness?.coreValueProps.isEmpty ?? true) && (harness?.competitiveMoats.isEmpty ?? true))
                        Text(
                          'Pillars will be extracted automatically when you click "Sync & Re-synthesize" or save inputs.',
                          style: theme.textTheme.bodySmall?.copyWith(color: ClinicSageColors.secondary),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Strict Learned Rules & Custom Directives
                _HarnessBlock(
                  icon: Icons.gavel_rounded,
                  title: 'Strict Learned Rules & Directives (Custom Instructions)',
                  subtitle: 'Every AI task (copy, video script, strategy) will strictly adhere to these rules.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Active rules list
                      if (harness?.learnedRules.isNotEmpty == true) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: harness!.learnedRules.map((rule) {
                            return Chip(
                              backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
                              ),
                              avatar: const Icon(Icons.lock_clock, size: 14, color: Color(0xFFA78BFA)),
                              label: Text(
                                rule,
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              deleteIcon: const Icon(Icons.close, size: 14, color: ClinicSageColors.secondary),
                              onDeleted: () => onDeleteRule(rule),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Add rule input
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: ruleController,
                              style: const TextStyle(fontSize: 13, color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Teach rule, e.g. "Always highlight our APAC network and JETRO partnership"',
                                hintStyle: TextStyle(fontSize: 12, color: ClinicSageColors.secondary.withOpacity(0.7)),
                                prefixIcon: const Icon(Icons.add_task_rounded, size: 16, color: Color(0xFFA78BFA)),
                                filled: true,
                                fillColor: ClinicSageColors.surface,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(ClinicSageRadius.md),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                ),
                              ),
                              onSubmitted: (_) => onAddRule(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: onAddRule,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.25),
                              foregroundColor: const Color(0xFFA78BFA),
                              elevation: 0,
                              side: BorderSide(color: const Color(0xFF8B5CF6).withOpacity(0.4)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ClinicSageRadius.md)),
                            ),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Teach Directive', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Knowledge Digest & Evolution Log
                if (harness?.knowledgeDigest.isNotEmpty == true && harness!.knowledgeDigest != 'No discovery inputs ingested yet.') ...[
                  _HarnessBlock(
                    icon: Icons.auto_stories_rounded,
                    title: 'Synthesized Client Knowledge Digest',
                    subtitle: 'Dense, fact-based summary of business model, traction, and proprietary strengths.',
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: ClinicSageColors.surface,
                        borderRadius: BorderRadius.circular(ClinicSageRadius.md),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Text(
                        harness!.knowledgeDigest,
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.85), height: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 5. Recent Learning Events
                if (harness?.evolutionLog.isNotEmpty == true) ...[
                  _HarnessBlock(
                    icon: Icons.history_rounded,
                    title: 'Recent Learning Milestones',
                    subtitle: 'Audit trail of events where the Agentic Brain evolved from user inputs and uploads.',
                    child: Column(
                      children: harness!.evolutionLog.take(4).map((evt) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF8B5CF6),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      evt.title,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                                    ),
                                    Text(
                                      evt.description,
                                      style: TextStyle(fontSize: 11, color: ClinicSageColors.secondary.withOpacity(0.8)),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${evt.timestamp.hour.toString().padLeft(2, '0')}:${evt.timestamp.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 10, color: ClinicSageColors.secondary),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HarnessBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _HarnessBlock({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFFA78BFA)),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: ClinicSageColors.secondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

