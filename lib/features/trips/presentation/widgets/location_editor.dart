import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/urls.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/models/place_ref.dart';

/// Place name, address and an optional Google Maps link. Search and map pins
/// arrive in Week 7 and write into the same [PlaceRef]. Coordinates already
/// on the place are kept as they are.
class LocationEditor extends StatefulWidget {
  const LocationEditor({
    super.key,
    required this.initial,
    required this.onChanged,
    this.nameLabel = 'Place name',
  });

  final PlaceRef? initial;
  final ValueChanged<PlaceRef?> onChanged;
  final String nameLabel;

  @override
  State<LocationEditor> createState() => _LocationEditorState();
}

class _LocationEditorState extends State<LocationEditor> {
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _address = TextEditingController(text: widget.initial?.address ?? '');
  late final _maps = TextEditingController(text: widget.initial?.mapsUrl ?? '');

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _maps.dispose();
    super.dispose();
  }

  void _emit() {
    final name = _name.text.trim();
    final address = _address.text.trim();
    final maps = _maps.text.trim();

    if (name.isEmpty && address.isEmpty && maps.isEmpty) {
      widget.onChanged(null);
      return;
    }
    final old = widget.initial;
    widget.onChanged(PlaceRef(
      name: name.isNotEmpty ? name : (address.isNotEmpty ? address : 'Map link'),
      address: address.isEmpty ? null : address,
      mapsUrl: maps.isEmpty ? null : (Urls.normalise(maps) ?? maps),
      latitude: old?.latitude,
      longitude: old?.longitude,
      placeId: old?.placeId,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextField(
          controller: _name,
          label: widget.nameLabel,
          maxLength: 120,
          textInputAction: TextInputAction.next,
          onChanged: (_) => _emit(),
        ),
        const SizedBox(height: AppSpacing.xs),
        AppTextField(
          controller: _address,
          label: 'Address or area (optional)',
          maxLength: 200,
          textInputAction: TextInputAction.next,
          onChanged: (_) => _emit(),
        ),
        const SizedBox(height: AppSpacing.xs),
        AppTextField(
          controller: _maps,
          label: 'Google Maps link (optional)',
          keyboardType: TextInputType.url,
          autocorrect: false,
          validator: Validators.optionalUrl,
          onChanged: (_) => _emit(),
        ),
      ],
    );
  }
}