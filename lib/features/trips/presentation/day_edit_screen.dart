import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/busy_button.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/form_error.dart';
import '../../../data/models/trip_day.dart';
import '../application/trip_editor_controller.dart';
import 'widgets/photo_grid_editor.dart';

class DayEditScreen extends StatefulWidget {
  const DayEditScreen({super.key, required this.controller, required this.day});

  final TripEditorController controller;
  final TripDay day;

  @override
  State<DayEditScreen> createState() => _DayEditScreenState();
}

class _DayEditScreenState extends State<DayEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.day.title);
  late final _story = TextEditingController(text: widget.day.story);
  late List<String> _photos = List.of(widget.day.photoUrls);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _story.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await widget.controller.saveDay(
      widget.day.id,
      title: _title.text.trim(),
      story: _story.text.trim(),
      photoUrls: _photos,
    );
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

  Future<void> _delete() async {
    final ok = await confirmDialog(
      context,
      title: 'Delete Day ${widget.day.dayNumber}?',
      message:
          'Everything planned on this day will be deleted too. This cannot be undone.',
      confirmLabel: 'Delete day',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    final err = await widget.controller.deleteDay(widget.day.id);
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

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text('Day ${widget.day.dayNumber}')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        AppTextField(
                          controller: _title,
                          label: 'Day title',
                          helperText: 'e.g. Arrival & Exploring',
                          maxLength: 80,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppTextField(
                          controller: _story,
                          label: 'What happened today?',
                          maxLength: 2000,
                          maxLines: 6,
                          keyboardType: TextInputType.multiline,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Photos', style: text.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  PhotoGridEditor(
                    tripId: widget.controller.tripId,
                    urls: _photos,
                    onChanged: (urls) => setState(() => _photos = urls),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FormError(_error),
                  BusyButton(label: 'Save day', busy: _busy, onPressed: _save),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: _busy ? null : _delete,
                    child: const Text('Delete this day'),
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
