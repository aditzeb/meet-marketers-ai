import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/proposal_provider.dart';

/// Modal dialog to intake Lead details (Website & Social Media URLs) and launch automated AI proposal generation
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
        width: 580,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
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
                          'Key in the lead’s website and social channels to synthesize a complete 13-section proposal.',
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
                                  : 'Generating Strategic Proposal with Gemini AI...',
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
                    hintText: 'e.g. White Sails Yacht Singapore',
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
                          hintText: 'e.g. Yacht Charter & Tourism',
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
                const SizedBox(height: 18),

                // Social Media URLs Header
                Text(
                  'SOCIAL MEDIA PRESENCE (FOR AUDIT & CONTEXT)',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w700,
                    color: ClinicSageColors.secondary,
                  ),
                ),
                const SizedBox(height: 10),

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
    );
  }
}
