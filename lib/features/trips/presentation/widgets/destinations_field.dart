import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_text_field.dart';

/// Type a place, tap + (or the keyboard's done key), and it becomes a chip.
class DestinationsField extends StatefulWidget {
  const DestinationsField({
    super.key,
    required this.values,
    required this.onChanged,
    this.max = AppConstants.maxDestinations,
  });

  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final int max;

  @override
  State<DestinationsField> createState() => _DestinationsFieldState();
}

class _DestinationsFieldState extends State<DestinationsField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final value = _controller.text.trim();
    if (value.isEmpty || widget.values.length >= widget.max) return;
    final exists = widget.values.any(
      (v) => v.toLowerCase() == value.toLowerCase(),
    );
    if (!exists) widget.onChanged([...widget.values, value]);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final full = widget.values.length >= widget.max;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: _controller,
          label: 'Destinations',
          helperText: full
              ? 'You can add up to ${widget.max} destinations'
              : 'Type a place and tap +, e.g. Diani',
          enabled: !full,
          textInputAction: TextInputAction.done,
          inputFormatters: [LengthLimitingTextInputFormatter(60)],
          onSubmitted: (_) => _add(),
          suffix: IconButton(
            tooltip: 'Add destination',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: full ? null : _add,
          ),
        ),
        if (widget.values.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final v in widget.values)
                InputChip(
                  label: Text(v),
                  onDeleted: () => widget.onChanged(
                    widget.values.where((e) => e != v).toList(),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
