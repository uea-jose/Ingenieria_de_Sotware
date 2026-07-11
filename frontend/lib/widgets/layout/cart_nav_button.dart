import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';

class CartNavButton extends StatelessWidget {
  const CartNavButton({
    required this.count,
    required this.onPressed,
    super.key,
  });

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Badge(
        isLabelVisible: count > 0,
        backgroundColor: AppColors.primary,
        textColor: AppColors.surface,
        label: Text('$count'),
        child: const Icon(Icons.shopping_bag_outlined),
      ),
      label: const Text('Carrito'),
    );
  }
}
