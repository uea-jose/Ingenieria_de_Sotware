import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';
import '../../models/order.dart';

/// Read-only view of the delivery snapshot captured when a sale was
/// created (see `model Venta` in backend/prisma/schema.prisma). Uses the
/// six nullable columns `direccionEntrega`, `ciudadEntrega`,
/// `referenciaEntrega`, `telefonoContacto`, `latitudEntrega`,
/// `longitudEntrega` verbatim.
///
/// Shared by the customer-facing `/mis-pedidos` view and the admin
/// panel `/admin/ventas`, so the same visual shows up on both sides.
///
/// The parent should gate rendering with [Order.tieneSnapshotEntrega]
/// (pre-migration orders have all six columns set to `null` and rendering
/// this block would show an empty card).
class DeliverySnapshotBlock extends StatelessWidget {
  const DeliverySnapshotBlock({required this.order, super.key});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final direccion = order.direccionEntrega;
    final ciudad = order.ciudadEntrega;
    final referencia = order.referenciaEntrega;
    final telefono = order.telefonoContacto;
    final lat = order.latitudEntrega;
    final lng = order.longitudEntrega;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgPage,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              SizedBox(width: 6),
              Text(
                'Dirección de entrega',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (direccion != null && direccion.isNotEmpty)
            Text(
              [
                direccion,
                if (ciudad != null && ciudad.isNotEmpty) ciudad,
              ].join(' · '),
              style: const TextStyle(fontSize: 13),
            ),
          if (referencia != null && referencia.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Referencia: $referencia',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          if (telefono != null && telefono.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.phone,
                  size: 13,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  telefono,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
          if (lat != null && lng != null) ...[
            const SizedBox(height: 4),
            Text(
              // 6 decimales de coordenada ≈ 11 cm — suficiente para trazar
              // ruta sin exponer un enlace externo aquí.
              'Coordenadas: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
