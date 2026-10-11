import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../constants/enum_labels.dart';
import '../constants/enums.dart';
import '../theme/app_colors.dart';
import '../utils/money.dart';
import 'info_chip.dart';

/// `KSh 1,500 · per person`, or a green "Free" chip.
class CostChip extends StatelessWidget {
  const CostChip({
    super.key,
    required this.amount,
    this.currency = AppConstants.defaultCurrency,
    this.basis,
    this.emphasised = false,
  });

  final double amount;
  final String currency;
  final CostBasis? basis;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    if (basis == CostBasis.free) {
      return const InfoChip(
        label: 'Free',
        icon: Icons.volunteer_activism_outlined,
        color: AppColors.success,
      );
    }
    final suffix = basis == null ? '' : ' · ${basis!.label}';
    return InfoChip(
      label: '${Money.format(amount, currency: currency)}$suffix',
      icon: Icons.payments_outlined,
      emphasised: emphasised,
    );
  }
}
