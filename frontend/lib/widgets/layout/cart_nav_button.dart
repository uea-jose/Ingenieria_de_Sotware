import 'package:flutter/material.dart';

import 'header_action_button.dart';

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
    return HeaderActionButton(
      tooltip: count > 0 ? 'Carrito, $count productos' : 'Carrito',
      semanticLabel: count > 0
          ? 'Abrir carrito con $count productos'
          : 'Abrir carrito',
      icon: Icons.shopping_bag_outlined,
      badgeCount: count,
      onPressed: onPressed,
    );
  }
}
