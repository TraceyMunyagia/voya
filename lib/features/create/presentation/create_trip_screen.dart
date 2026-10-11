import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/enums.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/error_text.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/busy_button.dart';
import '../../../core/widgets/form_error.dart';
import '../../../providers/supabase_providers.dart';
import '../../../providers/trip_providers.dart';
import '../../trips/presentation/widgets/date_range_field.dart';
import '../../trips/presentation/widgets/destinations_field.dart';
import '../../trips/presentation/widgets/travellers_stepper.dart';
import '../../trips/presentation/widgets/trip_type_picker.dart';

class CreateTripScreen extends ConsumerStatefulWidget {
  const CreateTripScreen({super.key});

  @override
  ConsumerState<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends ConsumerState<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  List<String> _destinations = [];
  TripType _type = TripType.solo;
  int _travellers = 1;
  DateTimeRange? _range;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final trip = await ref
          .read(tripRepositoryProvider)
          .create(
            title: _title.text.trim(),
            destinations: _destinations,
            type: _type,
            travellers: _travellers,
            startDate: _range?.start,
            endDate: _range?.end,
          );

      // One day per date in the range, otherwise just Day 1. If this fails the
      // editor still opens and offers "Add day", so it is not fatal.
      try {
        final days = _range == null
            ? 1
            : Dates.dayCount(_range!.start, _range!.end);
        await ref.read(dayRepositoryProvider).syncToCount(trip.id, days);
      } catch (_) {}

      ref.invalidate(myTripsProvider);
      if (mounted) context.pushReplacement(Routes.tripEdit(trip.id));
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('New trip')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Just the basics. You'll add days, photos and costs next. "
                    'Your trip stays private until you publish it.',
                    style: text.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Form(
                    key: _formKey,
                    child: AppTextField(
                      controller: _title,
                      label: 'Trip name',
                      helperText: 'e.g. Diani Girls Trip',
                      maxLength: 120,
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                          Validators.required(v, 'Enter a trip name'),
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
                    start: _range?.start,
                    end: _range?.end,
                    onChanged: (r) => setState(() => _range = r),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FormError(_error),
                  BusyButton(
                    label: 'Create draft',
                    busy: _busy,
                    onPressed: _submit,
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
