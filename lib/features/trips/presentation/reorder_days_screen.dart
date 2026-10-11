import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/list_utils.dart';
import '../../../core/widgets/busy_button.dart';
import '../../../core/widgets/form_error.dart';
import '../../../data/models/trip_day.dart';
import '../application/trip_editor_controller.dart';

/// Drag days into a new order. The day numbers are renumbered on save;
/// each day keeps its title, story, photos and items.
class ReorderDaysScreen extends StatefulWidget {
  const ReorderDaysScreen({super.key, required this.controller});

  final TripEditorController controller;

  @override
  State<ReorderDaysScreen> createState() => _ReorderDaysScreenState();
}

class _ReorderDaysScreenState extends State<ReorderDaysScreen> {
  late final List<TripDay> _days = List.of(widget.controller.days);
  bool _busy = false;
  String? _error;

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await widget.controller.reorderDays(
      _days.map((d) => d.id).toList(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reorder days')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: _days.length,
                onReorder: (oldIndex, newIndex) => setState(
                  () => ReorderUtils.move(_days, oldIndex, newIndex),
                ),
                itemBuilder: (context, i) {
                  final d = _days[i];
                  final count = widget.controller.itemsByDay[d.id]?.length ?? 0;
                  return Card(
                    key: ValueKey(d.id),
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${i + 1}')),
                      title: Text(
                        d.title.isEmpty ? 'Day ${d.dayNumber}' : d.title,
                      ),
                      subtitle: Text('$count item${count == 1 ? '' : 's'}'),
                      trailing: const Icon(Icons.drag_handle_rounded),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FormError(_error),
                  BusyButton(
                    label: 'Save order',
                    busy: _busy,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
