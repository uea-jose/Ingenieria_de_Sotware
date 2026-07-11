import 'package:flutter/material.dart';

class EmptyCatalogView extends StatelessWidget {
  const EmptyCatalogView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: const Column(
            children: [
              Icon(
                Icons.search_off_outlined,
                size: 52,
                color: Color(0xFF6D6A62),
              ),
              SizedBox(height: 12),
              Text(
                'No encontramos productos con esos filtros.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
              ),
              SizedBox(height: 8),
              Text(
                'Prueba limpiar filtros o buscar por otra marca.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
