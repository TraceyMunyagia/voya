import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/enum_labels.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/cost_chip.dart';
import '../../../../core/widgets/info_chip.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../data/models/app_user.dart';
import '../../../../data/models/trip.dart';
import '../../../../core/constants/enums.dart';

/// The feed card. Pure UI: state (liked / saved / following) and actions come
/// from the caller, so Weeks 9-10 only wire callbacks.
class TripCard extends StatelessWidget {
  const TripCard({
    super.key,
    required this.trip,
    this.liked = false,
    this.saved = false,
    this.following = false,
    this.onOpen,
    this.onLike,
    this.onComment,
    this.onSave,
    this.onShare,
    this.onFollow,
    this.onCreatorsTap,
  });

  final Trip trip;
  final bool liked;
  final bool saved;
  final bool following;
  final VoidCallback? onOpen;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onSave;
  final VoidCallback? onShare;

  /// The Follow button only shows when the trip has exactly one creator.
  final VoidCallback? onFollow;
  final VoidCallback? onCreatorsTap;

  @override
  Widget build(BuildContext context) {
    final creators = trip.creators;
    final days = trip.days;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            creators: creators,
            following: following,
            onFollow: creators.length == 1 ? onFollow : null,
            onTap: onCreatorsTap,
          ),
          _Cover(trip: trip, onTap: onOpen),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (days != null)
                  InfoChip(
                    icon: Icons.calendar_today_rounded,
                    label: days == 1 ? '1 day' : '$days days',
                  ),
                InfoChip(
                  icon: Icons.people_alt_rounded,
                  label: trip.travellers == 1
                      ? '1 traveller'
                      : '${trip.travellers} travellers',
                ),
                if (trip.costPerPerson > 0)
                  CostChip(
                    amount: trip.costPerPerson,
                    currency: trip.currency,
                    basis: CostBasis.perPerson,
                    emphasised: true,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                _ActionButton(
                  key: const ValueKey('like'),
                  icon: Icons.favorite_border_rounded,
                  activeIcon: Icons.favorite_rounded,
                  active: liked,
                  count: trip.likeCount,
                  label: 'Like',
                  onTap: onLike,
                ),
                _ActionButton(
                  key: const ValueKey('comment'),
                  icon: Icons.chat_bubble_outline_rounded,
                  activeIcon: Icons.chat_bubble_rounded,
                  active: false,
                  count: trip.commentCount,
                  label: 'Comments',
                  onTap: onComment,
                ),
                _ActionButton(
                  key: const ValueKey('save'),
                  icon: Icons.bookmark_border_rounded,
                  activeIcon: Icons.bookmark_rounded,
                  active: saved,
                  count: trip.saveCount,
                  label: 'Save',
                  onTap: onSave,
                ),
                const Spacer(),
                IconButton(
                  key: const ValueKey('share'),
                  tooltip: 'Share',
                  icon: const Icon(Icons.ios_share_rounded),
                  onPressed: onShare,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _creatorLabel(List<AppUser> creators) {
  if (creators.isEmpty) return 'Traveller';
  String first(AppUser u) => u.shownName.split(' ').first;
  if (creators.length == 1) return creators.first.shownName;
  if (creators.length == 2) {
    return '${first(creators[0])} & ${first(creators[1])}';
  }
  return '${first(creators[0])}, ${first(creators[1])} +${creators.length - 2}';
}

class _Header extends StatelessWidget {
  const _Header({
    required this.creators,
    required this.following,
    required this.onFollow,
    required this.onTap,
  });

  final List<AppUser> creators;
  final bool following;
  final VoidCallback? onFollow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shown = creators.take(3).toList();
    final ring = Theme.of(context).cardTheme.color ?? Colors.white;
    const step = 20.0;
    final stackWidth = shown.isEmpty ? 36.0 : 36.0 + (shown.length - 1) * step;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Row(
                children: [
                  SizedBox(
                    width: stackWidth,
                    height: 36,
                    child: Stack(
                      children: [
                        if (shown.isEmpty)
                          const UserAvatar(
                            photoUrl: null,
                            initials: '?',
                            radius: 18,
                          )
                        else
                          for (var i = 0; i < shown.length; i++)
                            Positioned(
                              left: i * step,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: ring,
                                  shape: BoxShape.circle,
                                ),
                                child: UserAvatar(
                                  photoUrl: shown[i].photoUrl,
                                  initials: shown[i].initials,
                                  radius: 16,
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      _creatorLabel(creators),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (onFollow != null)
            OutlinedButton(
              onPressed: onFollow,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              ),
              child: Text(following ? 'Following' : 'Follow'),
            ),
        ],
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.trip, required this.onTap});

  final Trip trip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final cover = trip.coverPhotoUrl;
    final destination = trip.destinations.join(' · ');

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (cover != null && cover.isNotEmpty)
              AppNetworkImage(cover, thumb: true, memCacheWidth: 900)
            else
              const ColoredBox(
                color: AppColors.navy,
                child: Center(
                  child: Icon(
                    Icons.luggage_rounded,
                    size: 56,
                    color: Colors.white38,
                  ),
                ),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                  stops: [0.45, 1],
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.md,
              top: AppSpacing.md,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(trip.type.icon, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      trip.type.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    trip.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (destination.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            destination,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.active,
    required this.count,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final bool active;
  final int count;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? AppColors.coral
        : Theme.of(context).colorScheme.onSurface;
    return Semantics(
      button: true,
      label: '$label, $count',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(active ? activeIcon : icon, color: color, size: 24),
                if (count > 0) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    NumberFormat.compact().format(count),
                    style: TextStyle(color: color, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
