import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enum_labels.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/info_chip.dart';
import '../../../data/models/trip.dart';
import '../../../data/models/trip_day.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/supabase_providers.dart';
import '../../../providers/trip_providers.dart';
import '../application/trip_editor_controller.dart';
import 'day_edit_screen.dart';
import 'widgets/day_card.dart';
import 'widgets/trip_status_chip.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../data/models/itinerary_item.dart';
import 'widgets/day_picker_dialog.dart';
import 'reorder_days_screen.dart';
import 'trip_details_screen.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/enums.dart';
import 'widgets/item_details_view.dart';
import 'widgets/item_flow.dart';

enum _EditorMenu { details, reorder, delete }

class TripEditorScreen extends ConsumerStatefulWidget {
  const TripEditorScreen({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<TripEditorScreen> createState() => _TripEditorScreenState();
}

class _TripEditorScreenState extends ConsumerState<TripEditorScreen> {
  late final TripEditorController _c;
  late final ProviderContainer _container;

  @override
  void initState() {
    super.initState();
    _container = ProviderScope.containerOf(context, listen: false);
    _c = TripEditorController(
      tripId: widget.tripId,
      trips: ref.read(tripRepositoryProvider),
      days: ref.read(dayRepositoryProvider),
      items: ref.read(itemRepositoryProvider),
      storage: ref.read(storageRepositoryProvider),
    )..load();
  }

  @override
  void dispose() {
    // refresh "My trips" after the tree has finished closing this screen
    if (_c.dirty) {
      Future.microtask(() => _container.invalidate(myTripsProvider));
    }
    _c.dispose();
    super.dispose();
  }

  void _toast(String? error) {
    if (error == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  void _editDay(TripDay day) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DayEditScreen(controller: _c, day: day),
      ),
    );
  }

  // ACTIONS
  void _openDetails() {
    final trip = _c.trip;
    if (trip == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => TripDetailsScreen(controller: _c, trip: trip),
      ),
    );
  }

  void _openReorder() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ReorderDaysScreen(controller: _c),
      ),
    );
  }

  Future<void> _deleteDraft() async {
    final ok = await confirmDialog(
      context,
      title: 'Delete this draft?',
      message:
          'The trip, its days, items and photos will be deleted for good. '
          'Any co-creators lose it too.',
      confirmLabel: 'Delete draft',
      destructive: true,
    );
    if (!ok || !mounted) return;

    final err = await _c.deleteDraft();
    if (!mounted) return;
    if (err != null) return _toast(err);
    if (context.canPop()) context.pop();
  }
  // ACTIONS

  Future<void> _addItem(TripDay day) => openItemForm(context, controller: _c, day: day);

  Future<void> _editItem(ItineraryItem item) {
    final day = _c.days.firstWhere((d) => d.id == item.dayId);
    return openItemForm(context, controller: _c, day: day, existing: item);
  }

  void _viewItem(ItineraryItem item) =>
      showItemDetails(context, item, travellers: _c.trip!.travellers);

  Future<void> _deleteItem(ItineraryItem item) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete "${item.title}"?',
      message: 'This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    _toast(await _c.deleteItem(item.id));
  }

  Future<void> _moveItem(ItineraryItem item) async {
    final target = await showDayPicker(
      context,
      days: _c.days,
      excludeDayId: item.dayId,
    );
    if (target == null) return;
    _toast(await _c.moveItem(item.id, target));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final trip = _c.trip;

        if (trip == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Trip')),
            body: Center(
              child: _c.loading
                  ? const CircularProgressIndicator()
                  : Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _c.loadError ?? "Couldn't load this trip.",
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            width: 200,
                            child: FilledButton(
                              onPressed: _c.load,
                              child: const Text('Try again'),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trip.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  _c.saving ? 'Saving…' : 'All changes saved',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
              ],
            ),
            actions: [
              // MENU
              if (_c.editable)
                PopupMenuButton<_EditorMenu>(
                  tooltip: 'Trip options',
                  onSelected: (action) {
                    switch (action) {
                      case _EditorMenu.details:
                        _openDetails();
                      case _EditorMenu.reorder:
                        _openReorder();
                      case _EditorMenu.delete:
                        _deleteDraft();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: _EditorMenu.details,
                      child: Text('Trip details'),
                    ),
                    if (_c.days.length > 1)
                      const PopupMenuItem(
                        value: _EditorMenu.reorder,
                        child: Text('Reorder days'),
                      ),
                    if (trip.status == TripStatus.draft &&
                        trip.ownerId == ref.read(currentUserProvider)?.id)
                      const PopupMenuItem(
                        value: _EditorMenu.delete,
                        child: Text('Delete draft'),
                      ),
                  ],
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _c.load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _TripHeader(
                  trip: trip,
                  onTap: _c.editable ? _openDetails : null,
                ),
                const SizedBox(height: AppSpacing.md),
                if (_c.editable && _c.missingDays > 0) ...[
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Your dates cover ${trip.days} days but the trip has '
                            '${_c.days.length}.',
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          FilledButton(
                            onPressed: () async =>
                                _toast(await _c.syncDaysToDates()),
                            child: Text(
                              'Add ${_c.missingDays} missing day${_c.missingDays == 1 ? '' : 's'}',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                // READONLY
                if (!_c.editable) ...[
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline_rounded),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              trip.status == TripStatus.published
                                  ? 'This trip is published, so it can’t be edited here. '
                                        'Editing published trips arrives in a later week.'
                                  : 'This trip is waiting for approval and can’t be edited right now.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                for (final day in _c.days)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: DayCard(
                      key: ValueKey(day.id),
                      day: day,
                      items: _c.itemsByDay[day.id] ?? const [],
                      travellers: trip.travellers,
                      onViewItem: _viewItem,
                      editable: _c.editable,
                      onEditDay: () => _editDay(day),
                      // ITEM HANDLERS
                      onAddItem: _c.editable ? () => _addItem(day) : null,
                      onEditItem: _c.editable ? _editItem : null,
                      onMoveItem: _c.editable && _c.days.length > 1
                          ? _moveItem
                          : null,
                      onDeleteItem: _c.editable ? _deleteItem : null,
                      onReorderItems: _c.editable
                          ? (oldIndex, newIndex) async => _toast(
                              await _c.reorderItems(day.id, oldIndex, newIndex),
                            )
                          : null,
                    ),
                  ),
                if (_c.editable)
                  OutlinedButton.icon(
                    onPressed: () async => _toast(await _c.addDay()),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add a day'),
                  ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TripHeader extends StatelessWidget {
  const _TripHeader({required this.trip, required this.onTap});

  final Trip trip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final cover = trip.coverPhotoUrl;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (cover != null && cover.isNotEmpty)
              AspectRatio(aspectRatio: 16 / 9, child: AppNetworkImage(cover)),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          trip.title,
                          style: text.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      TripStatusChip(trip.status),
                    ],
                  ),
                  if (trip.destinations.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(trip.destinations.join(' · ')),
                  ],
                  if (trip.description.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      trip.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      InfoChip(icon: trip.type.icon, label: trip.type.label),
                      InfoChip(
                        icon: Icons.people_alt_rounded,
                        label: trip.travellers == 1
                            ? '1 traveller'
                            : '${trip.travellers} travellers',
                      ),
                      if (trip.startDate != null && trip.endDate != null)
                        InfoChip(
                          icon: Icons.calendar_today_rounded,
                          label: Dates.range(trip.startDate!, trip.endDate!),
                        ),
                    ],
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
