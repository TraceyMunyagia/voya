import 'package:flutter/material.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/info_chip.dart';

class TripStatusChip extends StatelessWidget {
  const TripStatusChip(this.status, {super.key});

  final TripStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case TripStatus.draft:
        return const InfoChip(label: 'Draft', icon: Icons.edit_note_rounded);
      case TripStatus.review:
        return const InfoChip(
          label: 'In review',
          icon: Icons.hourglass_top_rounded,
          color: Color(0xFF9A6700),
        );
      case TripStatus.published:
        return const InfoChip(
          label: 'Published',
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
        );
      case TripStatus.revision:
        return const InfoChip(
          label: 'Revision',
          icon: Icons.history_edu_rounded,
          color: Color(0xFF9A6700),
        );
    }
  }
}
