import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Modal dialog for creating a new Client Board / Workspace
class CreateClientDialog extends StatefulWidget {
  final Function(String name, String industry, String? websiteUrl) onCreate;

  const CreateClientDialog({super.key, required this.onCreate});

  static Future<void> show(
    BuildContext context, {
    required Function(String name, String industry, String? websiteUrl) onCreate,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (context) => CreateClientDialog(onCreate: onCreate),
    );
  }

  @override
  State<CreateClientDialog> createState() => _CreateClientDialogState();
}

class _CreateClientDialogState extends State<CreateClientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _industryController = TextEditingController();
  final _websiteController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _industryController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: ClinicSageColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ClinicSageRadius.xl),
        side: const BorderSide(color: ClinicSageColors.border),
      ),
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient background
            Container(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
              decoration: BoxDecoration(
                gradient: ClinicSageGradients.tertiarySubtle,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(ClinicSageRadius.xl)),
                border: const Border(bottom: BorderSide(color: ClinicSageColors.border)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: ClinicSageGradients.tertiary,
                      borderRadius: BorderRadius.circular(ClinicSageRadius.md),
                      boxShadow: ClinicSageShadows.aiGlow,
                    ),
                    child: const Icon(Icons.domain_add, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Create Client Workspace', style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 2),
                        Text(
                          'Set up a dedicated workspace for your new account.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 18),
                    color: ClinicSageColors.secondary,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ],
              ),
            ),

            // Form
            Padding(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Client Name
                    _FormLabel(label: 'Client Name', required: true),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      autofocus: true,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Client name required' : null,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Apex Dynamics',
                        prefixIcon: Icon(Icons.business, size: 18, color: ClinicSageColors.secondary),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Industry
                    _FormLabel(label: 'Industry', required: true),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _industryController,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Industry required' : null,
                      decoration: const InputDecoration(
                        hintText: 'e.g. SaaS, Fintech, Healthcare',
                        prefixIcon: Icon(Icons.category_outlined, size: 18, color: ClinicSageColors.secondary),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Website URL
                    _FormLabel(label: 'Website URL', required: false),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _websiteController,
                      decoration: const InputDecoration(
                        hintText: 'https://clientwebsite.com',
                        prefixIcon: Icon(Icons.language, size: 18, color: ClinicSageColors.secondary),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(ClinicSageRadius.md),
                          child: InkWell(
                            onTap: _isLoading ? null : _onSubmit,
                            borderRadius: BorderRadius.circular(ClinicSageRadius.md),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: _isLoading
                                    ? LinearGradient(colors: [ClinicSageColors.tertiary.withOpacity(0.5), ClinicSageColors.tertiary.withOpacity(0.5)])
                                    : ClinicSageGradients.tertiary,
                                borderRadius: BorderRadius.circular(ClinicSageRadius.md),
                                boxShadow: _isLoading ? [] : ClinicSageShadows.button,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _isLoading
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Icon(Icons.add, size: 16, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isLoading ? 'Creating...' : 'Create Workspace',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    await widget.onCreate(
      _nameController.text.trim(),
      _industryController.text.trim(),
      _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _FormLabel extends StatelessWidget {
  final String label;
  final bool required;
  const _FormLabel({required this.label, required this.required});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: ClinicSageColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 3),
          Text(
            '*',
            style: theme.textTheme.labelLarge?.copyWith(color: ClinicSageColors.tertiary),
          ),
        ] else ...[
          const SizedBox(width: 6),
          Text(
            'Optional',
            style: theme.textTheme.labelSmall?.copyWith(
              color: ClinicSageColors.secondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}
