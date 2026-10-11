import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/urls.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/models/item_link.dart';

/// Up to [max] labelled links (booking page, website, Instagram, tickets...).
class LinksEditor extends StatelessWidget {
  const LinksEditor({
    super.key,
    required this.links,
    required this.onChanged,
    this.presets = const ['Booking', 'Website', 'Instagram'],
    this.max = 5,
  });

  final List<ItemLink> links;
  final ValueChanged<List<ItemLink>> onChanged;
  final List<String> presets;
  final int max;

  Future<void> _add(BuildContext context) async {
    final link = await showDialog<ItemLink>(
      context: context,
      builder: (context) => _LinkDialog(presets: presets),
    );
    if (link != null) onChanged([...links, link]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < links.length; i++)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.link_rounded),
            title: Text(links[i].label),
            subtitle: Text(links[i].url, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: IconButton(
              tooltip: 'Remove ${links[i].label} link',
              icon: const Icon(Icons.close_rounded),
              onPressed: () => onChanged([...links]..removeAt(i)),
            ),
          ),
        if (links.length < max)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _add(context),
              icon: const Icon(Icons.add_link_rounded),
              label: const Text('Add link'),
            ),
          ),
      ],
    );
  }
}

class _LinkDialog extends StatefulWidget {
  const _LinkDialog({required this.presets});

  final List<String> presets;

  @override
  State<_LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<_LinkDialog> {
  static const _other = 'Other';
  final _formKey = GlobalKey<FormState>();
  final _customLabel = TextEditingController();
  final _url = TextEditingController();
  late String _label = widget.presets.first;

  @override
  void dispose() {
    _customLabel.dispose();
    _url.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final label = _label == _other ? _customLabel.text.trim() : _label;
    Navigator.pop(context, ItemLink(label: label, url: Urls.normalise(_url.text)!));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add a link'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final p in [...widget.presets, _other])
                    ChoiceChip(
                      label: Text(p),
                      selected: p == _label,
                      onSelected: (_) => setState(() => _label = p),
                    ),
                ],
              ),
              if (_label == _other) ...[
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: _customLabel,
                  label: 'Label',
                  maxLength: 30,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a label' : null,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _url,
                label: 'Web address',
                keyboardType: TextInputType.url,
                autocorrect: false,
                onSubmitted: (_) => _submit(),
                validator: (v) =>
                    Urls.normalise(v ?? '') == null ? 'Enter a valid web address' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}