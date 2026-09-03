import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/pdf_extractor_service.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/proposal_provider.dart';

/// Modal dialog to intake Lead details (Website, Social Media URLs & Pitch Deck PDF) and launch automated AI proposal generation
class CreateLeadDialog extends ConsumerStatefulWidget {
  const CreateLeadDialog({super.key});

  @override
  ConsumerState<CreateLeadDialog> createState() => _CreateLeadDialogState();
}

class _CreateLeadDialogState extends ConsumerState<CreateLeadDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _industryCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _linkedinCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();
  final _youtubeCtrl = TextEditingController();

  String? _pitchDeckFileName;
  Uint8List? _pitchDeckBytes;
  String? _extractedPitchDeckText;
  bool _isExtracting = false;

  String? _logoFileName;
  Uint8List? _logoBytes;
  String? _logoDataUrl;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _industryCtrl.dispose();
    _websiteCtrl.dispose();
    _instagramCtrl.dispose();
    _linkedinCtrl.dispose();
    _facebookCtrl.dispose();
    _youtubeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPitchDeck() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;
        if (bytes != null && bytes.isNotEmpty) {
          setState(() {
            _pitchDeckFileName = file.name;
            _pitchDeckBytes = bytes;
            _isExtracting = true;
          });

          // Extract text from PDF using Flutter engine
          final text = PdfExtractorService.instance.extractTextFromBytes(bytes);

          setState(() {
            _extractedPitchDeckText = text;
            _isExtracting = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isExtracting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not read pitch deck: $e')),
        );
      }
    }
  }

  void _removePitchDeck() {
    setState(() {
      _pitchDeckFileName = null;
      _pitchDeckBytes = null;
      _extractedPitchDeckText = null;
      _isExtracting = false;
    });
  }

  Future<void> _pickLogo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'svg'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;
        if (bytes != null && bytes.isNotEmpty) {
          final mime = file.name.endsWith('.png')
              ? 'image/png'
              : (file.name.endsWith('.webp')
                  ? 'image/webp'
                  : (file.name.endsWith('.svg') ? 'image/svg+xml' : 'image/jpeg'));
          final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
          setState(() {
            _logoFileName = file.name;
            _logoBytes = bytes;
            _logoDataUrl = dataUrl;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not read logo image: $e')),
        );
      }
    }
  }

  void _removeLogo() {
    setState(() {
      _logoFileName = null;
      _logoBytes = null;
      _logoDataUrl = null;
    });
  }

  Future<void> _handleGenerate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final socialUrls = <String, String>{};
    if (_instagramCtrl.text.trim().isNotEmpty) socialUrls['instagram'] = _instagramCtrl.text.trim();
    if (_linkedinCtrl.text.trim().isNotEmpty) socialUrls['linkedin'] = _linkedinCtrl.text.trim();
    if (_facebookCtrl.text.trim().isNotEmpty) socialUrls['facebook'] = _facebookCtrl.text.trim();
    if (_youtubeCtrl.text.trim().isNotEmpty) socialUrls['youtube'] = _youtubeCtrl.text.trim();

    try {
      final proposal = await ref.read(proposalProvider.notifier).createAndGenerateProposal(
        leadCompanyName: _nameCtrl.text.trim(),
        industry: _industryCtrl.text.trim(),
        websiteUrl: _websiteCtrl.text.trim(),
        socialUrls: socialUrls,
        pitchDeckFileName: _pitchDeckFileName,
        pitchDeckBytes: _pitchDeckBytes,
        extractedPitchDeckText: _extractedPitchDeckText,
        companyLogoUrl: _logoDataUrl,
      );

      if (mounted) {
        Navigator.of(context).pop();
        context.go(AppRoutes.proposalDetailPath(proposal.id));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating proposal: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final proposalState = ref.watch(proposalProvider);

    return Dialog(
      backgroundColor: ClinicSageColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: ClinicSageGradients.brandVibrant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.auto_awesome, size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New Lead · Automated Proposal Generation',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Key in the lead’s channels and pitch deck to synthesize a complete 13-section proposal.',
                            style: theme.textTheme.bodySmall?.copyWith(color: ClinicSageColors.secondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (_isSubmitting) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.25)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B5CF6)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                proposalState.generationStage.isNotEmpty
                                    ? proposalState.generationStage
                                    : 'Generating Strategic Proposal with OpenRouter AI...',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                            Text(
                              '${(proposalState.generationProgress * 100).round()}%',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: proposalState.generationProgress,
                            minHeight: 6,
                            backgroundColor: ClinicSageColors.border,
                            valueColor: const AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  // Company Name
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Lead / Company Name *',
                      hintText: 'e.g. Meet Ventures',
                      prefixIcon: Icon(Icons.business_outlined, size: 18),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Company name is required' : null,
                  ),
                  const SizedBox(height: 14),

                  // Industry & Website
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _industryCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Industry *',
                            hintText: 'e.g. Venture Capital & Innovation',
                            prefixIcon: Icon(Icons.category_outlined, size: 18),
                          ),
                          validator: (val) => (val == null || val.trim().isEmpty) ? 'Industry is required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _websiteCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Website URL *',
                            hintText: 'https://whitesails.com.sg',
                            prefixIcon: Icon(Icons.language_outlined, size: 18),
                          ),
                          validator: (val) => (val == null || val.trim().isEmpty) ? 'Website URL is required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Company Pitch Deck (PDF) Upload & Extraction ──────
                  Text(
                    'COMPANY PITCH DECK (PDF) — STRATEGIC EXTRACTION',
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w700,
                      color: ClinicSageColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (_pitchDeckFileName == null)
                    InkWell(
                      onTap: _isExtracting ? null : _pickPitchDeck,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: ClinicSageColors.neutral,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: ClinicSageColors.border, style: BorderStyle.solid),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.upload_file_outlined, color: Color(0xFF8B5CF6), size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Upload Lead Pitch Deck (PDF)',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                  Text(
                                    'Flutter engine extracts business model & USPs to ground the proposal generation',
                                    style: TextStyle(fontSize: 11.5, color: ClinicSageColors.secondary),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _pickPitchDeck,
                              icon: const Icon(Icons.add, size: 14),
                              label: const Text('Select PDF', style: TextStyle(fontSize: 11)),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf, color: Color(0xFF10B981), size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _pitchDeckFileName!,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_isExtracting)
                                  const Row(
                                    children: [
                                      SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5)),
                                      SizedBox(width: 6),
                                      Text('Extracting PDF text with Flutter engine...', style: TextStyle(fontSize: 11)),
                                    ],
                                  )
                                else
                                  Text(
                                    '✓ Extracted ${(_extractedPitchDeckText ?? '').length} characters of brand intelligence',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _removePitchDeck,
                            icon: const Icon(Icons.close, size: 18, color: ClinicSageColors.secondary),
                            tooltip: 'Remove Pitch Deck',
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // ── Company / Brand Logo Upload ──────
                  Text(
                    'COMPANY LOGO — BRAND BLENDING IN AI VISUALS & PDF',
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w700,
                      color: ClinicSageColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (_logoFileName == null)
                    InkWell(
                      onTap: _pickLogo,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: ClinicSageColors.neutral,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: ClinicSageColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.image_outlined, color: Color(0xFF10B981), size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Upload Company Logo (PNG, JPG, WEBP, SVG)',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                  Text(
                                    'AI blends logo into generated visuals, video posters & 13-page proposal PDF',
                                    style: TextStyle(fontSize: 11.5, color: ClinicSageColors.secondary),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _pickLogo,
                              icon: const Icon(Icons.add_photo_alternate_outlined, size: 14),
                              label: const Text('Select Logo', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                side: const BorderSide(color: Color(0xFF10B981)),
                                foregroundColor: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              width: 44,
                              height: 44,
                              color: Colors.white,
                              child: _logoBytes != null
                                  ? Image.memory(_logoBytes!, fit: BoxFit.contain)
                                  : const Icon(Icons.image, color: Color(0xFF10B981)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _logoFileName!,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF065F46)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Text(
                                  '✓ Logo active for AI visual synthesis & PDF branding',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF047857)),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _removeLogo,
                            icon: const Icon(Icons.close, size: 18, color: Color(0xFFDC2626)),
                            tooltip: 'Remove Logo',
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Social Media URLs Header
                  Text(
                    'SOCIAL MEDIA PRESENCE (FOR AUDIT & CONTEXT)',
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w700,
                      color: ClinicSageColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _instagramCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Instagram URL',
                            hintText: 'https://instagram.com/whitesails',
                            prefixIcon: Icon(Icons.camera_alt_outlined, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _linkedinCtrl,
                          decoration: const InputDecoration(
                            labelText: 'LinkedIn URL',
                            hintText: 'https://linkedin.com/company/whitesails',
                            prefixIcon: Icon(Icons.work_outline, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _facebookCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Facebook URL',
                            hintText: 'https://facebook.com/whitesails',
                            prefixIcon: Icon(Icons.thumb_up_outlined, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _youtubeCtrl,
                          decoration: const InputDecoration(
                            labelText: 'YouTube / TikTok URL',
                            hintText: 'https://youtube.com/@whitesails',
                            prefixIcon: Icon(Icons.smart_display_outlined, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ClinicSageColors.tertiary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onPressed: _handleGenerate,
                        icon: const Icon(Icons.auto_awesome, size: 16),
                        label: const Text('Generate Proposal with AI'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
