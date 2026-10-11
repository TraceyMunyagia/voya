import 'package:flutter/material.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/busy_button.dart';
import '../../../core/widgets/form_error.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/trip.dart';
import '../application/trip_editor_controller.dart';
import 'widgets/cover_photo_field.dart';
import 'widgets/date_range_field.dart';
import 'widgets/destinations_field.dart';
import 'widgets/travellers_stepper.dart';
import 'widgets/trip_type_picker.dart';


/// Edits everything about the trip itself: name, story, cover, destinations,
/// type, travellers and dates.
class TripDetailsScreen extends StatefulWidget {
  const TripDetailsScreen({
    super.key,
    required this.controller,
    required this.trip,
  });

  final TripEditorController controller;
  final Trip trip;

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.trip.title);
  late final _description = TextEditingController(
    text: widget.trip.description,
  );
  late String? _cover = widget.trip.coverPhotoUrl;
  late List<String> _destinations = List.of(widget.trip.destinations);
  late TripType _type = widget.trip.type;
  late int _travellers = widget.trip.travellers;
  late DateTime? _start = widget.trip.startDate;
  late DateTime? _end = widget.trip.endDate;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await widget.controller.updateTrip({
      'title': _title.text.trim(),
      'description': _description.text.trim(),
      'cover_photo_url': _cover,
      'destinations': _destinations,
      'type': _type.name,
      'travellers': _travellers,
      'start_date': _start == null ? null : Dates.iso(_start!),
      'end_date': _end == null ? null : Dates.iso(_end!),
    });
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
      appBar: AppBar(title: const Text('Trip details')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Cover photo', style: text.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  CoverPhotoField(
                    tripId: widget.trip.id,
                    url: _cover,
                    onChanged: (u) => setState(() => _cover = u),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        AppTextField(
                          controller: _title,
                          label: 'Trip name',
                          maxLength: 120,
                          textInputAction: TextInputAction.next,
                          validator: (v) =>
                              Validators.required(v, 'Enter a trip name'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppTextField(
                          controller: _description,
                          label: 'The story of your trip',
                          helperText:
                              'What made it special? What should others know?',
                          maxLength: 2000,
                          maxLines: 6,
                          keyboardType: TextInputType.multiline,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DestinationsField(
                    values: _destinations,
                    onChanged: (v) => setState(() => _destinations = v),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Trip type', style: text.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  TripTypePicker(
                    value: _type,
                    onChanged: (v) => setState(() => _type = v),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TravellersStepper(
                    value: _travellers,
                    onChanged: (v) => setState(() => _travellers = v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DateRangeField(
                    start: _start,
                    end: _end,
                    onChanged: (r) => setState(() {
                      _start = r?.start;
                      _end = r?.end;
                    }),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FormError(_error),
                  BusyButton(
                    label: 'Save details',
                    busy: _busy,
                    onPressed: _save,
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
