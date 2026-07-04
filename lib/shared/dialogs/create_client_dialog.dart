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
      barrierColor: Colors.black.withOpacity(0.4),
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
        borderRadius: BorderRadius.circular(ClinicSageRadius.lg),
        side: const BorderSide(color: ClinicSageColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ClinicSageColors.tertiaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.domain_add, size: 20, color: ClinicSageColors.tertiary),
                    ),
                    const SizedBox(width: 12),
                    Text('Create Client Workspace', style: theme.textTheme.headlineSmall),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Set up a dedicated workspace for your new account.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 24),

                // Name
                TextFormField(
                  controller: _nameController,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Client name required' : null,
                  decoration: const InputDecoration(
                    labelText: 'Client Name',
                    hintText: 'e.g. Apex Dynamics',
                    prefixIcon: Icon(Icons.business, size: 18, color: ClinicSageColors.secondary),
                  ),
                ),
                const SizedBox(height: 16),

                // Industry
                TextFormField(
                  controller: _industryController,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Industry required' : null,
                  decoration: const InputDecoration(
                    labelText: 'Industry',
                    hintText: 'e.g. SaaS, Fintech, Healthcare',
                    prefixIcon: Icon(Icons.category_outlined, size: 18, color: ClinicSageColors.secondary),
                  ),
                ),
                const SizedBox(height: 16),

                // Website URL
                TextFormField(
                  controller: _websiteController,
                  decoration: const InputDecoration(
                    labelText: 'Website URL (Optional)',
                    hintText: 'https://clientwebsite.com',
                    prefixIcon: Icon(Icons.language, size: 18, color: ClinicSageColors.secondary),
                  ),
                ),
                const SizedBox(height: 32),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _onSubmit,
                      icon: _isLoading
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.add, size: 16),
                      label: Text(_isLoading ? 'Creating...' : 'Create Workspace'),
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
