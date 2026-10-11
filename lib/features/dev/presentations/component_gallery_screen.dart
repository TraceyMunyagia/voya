import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/media/image_processor.dart';
import '../../../core/media/image_urls.dart';
import '../../../core/media/media_picker.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/supabase_providers.dart';
import '../../../core/widgets/photo_gallery_screen.dart';
import '../../../core/widgets/photo_grid.dart';
import '../../trips/presentation/widgets/cover_photo_field.dart';
import '../../trips/presentation/widgets/photo_grid_editor.dart';
import '../../../core/constants/enums.dart';
import '../../../core/widgets/cost_chip.dart';
import '../../../core/widgets/cost_summary.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/info_chip.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/trip.dart';
import '../../../data/models/trip_member.dart';
import '../../trips/presentation/widgets/trip_card.dart';
import '../../trips/presentation/widgets/trip_card_skeleton.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/cost.dart';
import '../../../data/models/item_link.dart';
import '../../trips/presentation/widgets/cost_field.dart';
import '../../trips/presentation/widgets/links_editor.dart';
import '../../trips/presentation/widgets/rating_field.dart';
import '../../../data/models/item_photo.dart';
import '../../../data/models/place_ref.dart';
import '../../trips/presentation/widgets/captioned_photos_editor.dart';
import '../../trips/presentation/widgets/location_editor.dart';

/// Debug-only test bench for the shared widgets.
/// Reach it from Profile → ⋮ menu → Component gallery.
class ComponentGalleryScreen extends ConsumerStatefulWidget {
  const ComponentGalleryScreen({super.key});

  @override
  ConsumerState<ComponentGalleryScreen> createState() =>
      _ComponentGalleryScreenState();
}

class _ComponentGalleryScreenState
    extends ConsumerState<ComponentGalleryScreen> {
  // STATE
  String? _tripId;
  bool _busy = false;
  String? _report;
  String? _cover;
  List<String> _editorPhotos = [];
  final _uploaded = <String>[];
  bool _liked = false;
  bool _saved = false;
  bool _following = false;
  final _formAmount = TextEditingController(text: '1500');
  CostBasis _formBasis = CostBasis.perPerson;
  List<ItemLink> _formLinks = [];
  int? _formRating;
  PlaceRef? _formLocation;
  List<ItemPhoto> _formPhotos = [];
  @override
  void dispose() {
    _formAmount.dispose();
    super.dispose();
  }

  Trip _demoTrip({required int creators}) {
    const people = ['Tracey', 'Mary', 'Ann', 'Joy'];
    return Trip(
      id: 'demo',
      ownerId: 'u0',
      title: 'Diani Girls Trip',
      destinations: const ['Diani Beach', 'Wasini Island'],
      startDate: DateTime(2026, 12, 1),
      endDate: DateTime(2026, 12, 4),
      travellers: 4,
      type: TripType.friends,
      status: TripStatus.published,
      coverPhotoUrl: _cover,
      totalCost: 84500,
      costPerPerson: 21125,
      likeCount: _liked ? 129 : 128,
      commentCount: 14,
      saveCount: _saved ? 57 : 56,
      members: [
        for (var i = 0; i < creators; i++)
          TripMember(
            tripId: 'demo',
            userId: 'u$i',
            role: i == 0 ? MemberRole.owner : MemberRole.coCreator,
            profile: AppUser(
              id: 'u$i',
              username: people[i].toLowerCase(),
              displayName: people[i],
            ),
          ),
      ],
    );
  }

  /// Creates one throw-away draft trip the first time it is needed.
  Future<String> _ensureTrip() async {
    return _tripId ??=
        (await ref
                .read(tripRepositoryProvider)
                .createDraft(title: 'Gallery test'))
            .id;
  }

  String _kb(int bytes) => '${(bytes / 1024).round()} KB';

  Future<void> _testUpload() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _report = null;
    });
    try {
      final files = await MediaPicker().pick(ImageSource.gallery);
      if (files.isEmpty) return;
      final original = await files.first.readAsBytes();
      final processed = await ImageProcessor.process(original);
      final tripId = await _ensureTrip();
      final uploaded = await ref
          .read(storageRepositoryProvider)
          .uploadTripPhoto(tripId: tripId, image: processed);
      if (!mounted) return;
      setState(() {
        _uploaded.add(uploaded.url);
        _report =
            'original ${_kb(original.length)} → full ${_kb(processed.full.length)}, '
            'thumb ${_kb(processed.thumb.length)}';
      });
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Component gallery')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const _Section('Colours', _Swatches()),
          // DAY16
          _Section(
            'Photo pipeline',
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Picks a photo, compresses it to a full and a thumbnail version '
                  'and uploads both to a test trip.',
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton(
                  onPressed: _busy ? null : _testUpload,
                  child: Text(_busy ? 'Working…' : 'Pick and upload a photo'),
                ),
                if (_report != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(_report!),
                  ),
                if (_uploaded.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Image.network(
                          _uploaded.last,
                          height: 140,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Image.network(
                          ImageUrls.thumb(_uploaded.last),
                          height: 140,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                  const Text('Full (left) and thumbnail (right)'),
                ],
              ],
            ),
          ),

          _Section(
            'Form widgets: location and captioned photos',
            _tripId == null
                ? OutlinedButton(
                    onPressed: () async {
                      await _ensureTrip();
                      if (mounted) setState(() {});
                    },
                    child: const Text('Create a test trip first'),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LocationEditor(
                        initial: null,
                        onChanged: (p) => setState(() => _formLocation = p),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text('Maps link: ${_formLocation?.mapsLink ?? 'none'}'),
                      const SizedBox(height: AppSpacing.lg),
                      CaptionedPhotosEditor(
                        tripId: _tripId!,
                        photos: _formPhotos,
                        onChanged: (p) => setState(() => _formPhotos = p),
                      ),
                    ],
                  ),
          ),

          // DAY17
          _Section(
            'Photo grid and viewer',
            _uploaded.isEmpty
                ? const Text('Upload 1-5 photos in the section above first.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'All ${_uploaded.length} photo(s). Tap one to open the viewer.',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      PhotoGrid(
                        urls: _uploaded,
                        onTap: (i) => showPhotoGallery(
                          context,
                          _uploaded,
                          initialIndex: i,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Text('First photo only (single layout)'),
                      const SizedBox(height: AppSpacing.sm),
                      PhotoGrid(urls: _uploaded.take(1).toList()),
                    ],
                  ),
          ),
          // DAY18
          _Section(
            'Photo editors',
            _tripId == null
                ? OutlinedButton(
                    onPressed: () async {
                      await _ensureTrip();
                      if (mounted) setState(() {});
                    },
                    child: const Text('Create a test trip first'),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Cover photo'),
                      const SizedBox(height: AppSpacing.sm),
                      CoverPhotoField(
                        tripId: _tripId!,
                        url: _cover,
                        onChanged: (u) => setState(() => _cover = u),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Text('Photo grid editor (up to 10)'),
                      const SizedBox(height: AppSpacing.sm),
                      PhotoGridEditor(
                        tripId: _tripId!,
                        urls: _editorPhotos,
                        onChanged: (u) => setState(() => _editorPhotos = u),
                      ),
                    ],
                  ),
          ),
          // DAY19
          const _Section(
            'Chips',
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                InfoChip(label: '4 days', icon: Icons.calendar_today_rounded),
                InfoChip(label: '4 travellers', icon: Icons.people_alt_rounded),
                CostChip(amount: 1500, basis: CostBasis.perPerson),
                CostChip(amount: 2400, basis: CostBasis.perGroup),
                CostChip(amount: 1234.5, basis: CostBasis.perNight),
                CostChip(amount: 0, basis: CostBasis.free),
                CostChip(
                  amount: 21125,
                  basis: CostBasis.perPerson,
                  emphasised: true,
                ),
              ],
            ),
          ),
          const _Section(
            'Cost summary',
            CostSummary(
              total: 84500,
              perPerson: 21125,
              byCategory: {
                ItemCategory.accommodation: 30000,
                ItemCategory.transport: 15000,
                ItemCategory.meal: 14500,
                ItemCategory.activity: 20000,
                ItemCategory.other: 5000,
              },
            ),
          ),
                    _Section(
            'Form widgets: cost, links, rating (4 people, 3 nights)',
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CostField(
                  amount: _formAmount,
                  basis: _formBasis,
                  allowedBases: const [
                    CostBasis.perNight,
                    CostBasis.perPerson,
                    CostBasis.perGroup,
                    CostBasis.oneTime,
                    CostBasis.free,
                  ],
                  currency: 'KES',
                  total: Cost(
                    amount: Money.parse(_formAmount.text) ?? 0,
                    basis: _formBasis,
                  ).total(people: 4, nights: 3),
                  perPerson: Cost(
                    amount: Money.parse(_formAmount.text) ?? 0,
                    basis: _formBasis,
                  ).total(people: 4, nights: 3) / 4,
                  onChanged: () => setState(() {}),
                  onBasisChanged: (b) => setState(() => _formBasis = b),
                ),
                const SizedBox(height: AppSpacing.lg),
                LinksEditor(
                  links: _formLinks,
                  onChanged: (l) => setState(() => _formLinks = l),
                ),
                const SizedBox(height: AppSpacing.lg),
                RatingField(value: _formRating, onChanged: (r) => setState(() => _formRating = r)),
                const SizedBox(height: AppSpacing.sm),
                if (_formRating != null) RatingStars(_formRating!),
              ],
            ),
          ),
          _Section(
            'Empty state',
            EmptyState(
              icon: Icons.bookmark_border_rounded,
              title: 'Nothing saved yet',
              message: 'Save trips you love and they will show up here.',
              actionLabel: 'Explore trips',
              onAction: () {},
            ),
          ),
          // DAY20
          _Section(
            'Trip card (4 creators, set a cover in "Photo editors" to see a photo)',
            TripCard(
              trip: _demoTrip(creators: 4),
              liked: _liked,
              saved: _saved,
              onLike: () => setState(() => _liked = !_liked),
              onSave: () => setState(() => _saved = !_saved),
              onComment: () {},
              onShare: () {},
              onOpen: () {},
            ),
          ),
          _Section(
            'Trip card (1 creator, with Follow)',
            TripCard(
              trip: _demoTrip(creators: 1),
              following: _following,
              onFollow: () => setState(() => _following = !_following),
              onLike: () {},
              onSave: () {},
            ),
          ),
          const _Section('Loading skeleton', TripCardSkeleton()),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.child);

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _Swatches extends StatelessWidget {
  const _Swatches();

  static const _colors = {
    'navy': AppColors.navy,
    'coral': AppColors.coral,
    'sand': AppColors.sand,
    'offWhite': AppColors.offWhite,
    'charcoal': AppColors.charcoal,
    'success': AppColors.success,
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final e in _colors.entries)
          Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: e.value,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(e.key, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          
      ],
    );
  }
}
