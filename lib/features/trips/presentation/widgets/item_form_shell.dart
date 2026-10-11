import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/busy_button.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/form_error.dart';

/// The frame around every item form: app bar (with Delete when editing),
/// scrolling body, inline error and the Save button. Each form supplies its
/// fields and two callbacks that return an error message (null = success).
class ItemFormShell extends StatefulWidget {
  const ItemFormShell({
    super.key,
    required this.title,
    required this.formKey,
    required this.children,
    required this.onSave,
    this.onDelete,
    this.deleteMessage = 'This cannot be undone.',
  });

  final String title;
  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final Future<String?> Function() onSave;
  final Future<String?> Function()? onDelete;
  final String deleteMessage;

  @override
  State<ItemFormShell> createState() => _ItemFormShellState();
}

class _ItemFormShellState extends State<ItemFormShell> {
  bool _busy = false;
  String? _error;

  Future<void> _run(Future<String?> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await action();
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _busy = false;
        _error = err;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _save() async {
    if (!widget.formKey.currentState!.validate()) {
      setState(() => _error = 'Please fix the highlighted fields.');
      return;
    }
    await _run(widget.onSave);
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(
      context,
      title: 'Delete this item?',
      message: widget.deleteMessage,
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    await _run(widget.onDelete!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (widget.onDelete != null)
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _busy ? null : _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: widget.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...widget.children,
                    FormError(_error),
                    BusyButton(label: 'Save', busy: _busy, onPressed: _save),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}