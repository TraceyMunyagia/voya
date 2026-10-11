import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Profile photo, or initials on a sand circle when there is no photo.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.photoUrl,
    required this.initials,
    this.radius = 24,
  });

  final String? photoUrl;
  final String initials;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.sand,
      foregroundImage: hasPhoto ? CachedNetworkImageProvider(photoUrl!) : null,
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.navy,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }
}
