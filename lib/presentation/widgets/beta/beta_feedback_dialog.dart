import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/beta/beta_feedback_models.dart';
import 'package:nle_editor/presentation/providers/beta_feedback_provider.dart';
import 'package:nle_editor/presentation/providers/device_qa_controller.dart';

class BetaFeedbackDialog extends ConsumerStatefulWidget {
  const BetaFeedbackDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const BetaFeedbackDialog(),
    );
  }

  @override
  ConsumerState<BetaFeedbackDialog> createState() => _BetaFeedbackDialogState();
}

class _BetaFeedbackDialogState extends ConsumerState<BetaFeedbackDialog> {
  final _formKey = GlobalKey<FormState>();
  BetaFeedbackType _type = BetaFeedbackType.bug;
  final _emailController = TextEditingController();
  final _descController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceDark,
      title: Row(
        children: [
          const Icon(Icons.feedback_rounded, color: AppTheme.accentPrimary),
          const SizedBox(width: 8),
          const Text('Submit Beta Feedback'),
        ],
      ),
      content: _isSubmitting
          ? const SizedBox(
              height: 120,
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.accentPrimary),
              ),
            )
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Help us improve. Describe the issue or suggestion details below.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),

                    // Feedback Type
                    DropdownButtonFormField<BetaFeedbackType>(
                      value: _type,
                      decoration: const InputDecoration(
                        labelText: 'Feedback Type',
                        labelStyle: TextStyle(color: AppTheme.textSecondary),
                        border: OutlineInputBorder(),
                      ),
                      dropdownColor: AppTheme.surfaceElevated,
                      items: BetaFeedbackType.values.map((t) {
                        return DropdownMenuItem(
                          value: t,
                          child: Text(
                            _getTypeLabel(t),
                            style: const TextStyle(color: AppTheme.textPrimary),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _type = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Your Email',
                        labelStyle: TextStyle(color: AppTheme.textSecondary),
                        border: OutlineInputBorder(),
                        hintText: 'name@example.com',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!val.contains('@')) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Description Field
                    TextFormField(
                      controller: _descController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description / Details',
                        labelStyle: TextStyle(color: AppTheme.textSecondary),
                        border: OutlineInputBorder(),
                        hintText: 'What happened? How can we reproduce it?',
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Please provide description details';
                        }
                        if (val.length < 10) {
                          return 'Please be more descriptive (at least 10 chars)';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        if (!_isSubmitting) ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentPrimary,
              foregroundColor: Colors.black,
            ),
            child: const Text('Submit'),
          ),
        ],
      ],
    );
  }

  String _getTypeLabel(BetaFeedbackType type) {
    switch (type) {
      case BetaFeedbackType.bug:
        return 'Bug Report';
      case BetaFeedbackType.exportProblem:
        return 'Export Issue';
      case BetaFeedbackType.previewProblem:
        return 'Preview/Scrubbing Issue';
      case BetaFeedbackType.performanceProblem:
        return 'Performance Lag';
      case BetaFeedbackType.suggestion:
        return 'Feature Request / Idea';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final deviceState = ref.read(deviceQaControllerProvider);
    final cap = deviceState.capabilityReport;

    final deviceContext = cap != null
        ? {
            'manufacturer': cap.manufacturer,
            'brand': cap.brand,
            'model': cap.model,
            'androidRelease': cap.androidRelease,
            'androidSdk': cap.androidSdk,
            'deviceTier': cap.deviceTier.name,
            'totalMemoryMb': cap.totalMemoryMb,
            'availableMemoryMb': cap.availableMemoryMb,
            'cpuCoreCount': cap.cpuCoreCount,
          }
        : {'platform': 'unknown'};

    final submission = BetaFeedbackSubmission(
      id: const Uuid().v4(),
      type: _type,
      email: _emailController.text,
      description: _descController.text,
      deviceContext: deviceContext,
      submittedAt: DateTime.now(),
    );

    try {
      await ref.read(betaFeedbackServiceProvider).submitFeedback(submission);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback submitted successfully. Thank you!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit feedback: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}
