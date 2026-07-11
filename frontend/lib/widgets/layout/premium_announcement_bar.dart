import 'package:flutter/material.dart';

class PremiumAnnouncementBar extends StatelessWidget {
  const PremiumAnnouncementBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF102F29),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 9),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Wrap(
            spacing: 18,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: const [
              _AnnouncementItem(
                icon: Icons.local_shipping_outlined,
                text: 'Entrega local coordinada',
              ),
              _AnnouncementItem(
                icon: Icons.verified_outlined,
                text: 'Compra segura',
              ),
              _AnnouncementItem(
                icon: Icons.receipt_long_outlined,
                text: 'IVA Ecuador 15%',
              ),
              _AnnouncementItem(
                icon: Icons.inventory_2_outlined,
                text: 'Stock visible en tiempo real',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnnouncementItem extends StatelessWidget {
  const _AnnouncementItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFFE8C766)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
