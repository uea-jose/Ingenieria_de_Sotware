import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';
import '../../core/validators.dart';

/// Real-time checklist for the 4 password rules enforced by
/// [Validators.password]. Renders one small row per rule with an icon
/// that flips from ○ (unmet) to ✓ (met) as the user types.
///
/// The widget is stateless — the caller passes the current password on
/// every rebuild. Trigger those rebuilds however you prefer:
///
/// ```dart
/// TextFormField(
///   controller: _passwordController,
///   onChanged: (_) => setState(() {}),
///   ...
/// ),
/// PasswordStrengthMeter(password: _passwordController.text),
/// ```
///
/// The rules come from [PasswordChecks] so they never drift from the
/// server-side validator or the submit-time [Validators.password] one.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({required this.password, super.key});

  final String password;

  @override
  Widget build(BuildContext context) {
    final rules = <_Rule>[
      _Rule(
        label: 'Al menos ${PasswordChecks.minLength} caracteres',
        met: PasswordChecks.hasMinLength(password),
      ),
      _Rule(
        label: 'Una letra mayúscula (A-Z)',
        met: PasswordChecks.hasUppercase(password),
      ),
      _Rule(
        label: 'Un número (0-9)',
        met: PasswordChecks.hasDigit(password),
      ),
      _Rule(
        label: r'Un carácter especial (! @ # $ % ...)',
        met: PasswordChecks.hasSpecialChar(password),
      ),
    ];

    return Semantics(
      container: true,
      label: 'Requisitos de contraseña',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final rule in rules) _MeterRow(rule: rule),
        ],
      ),
    );
  }
}

class _Rule {
  const _Rule({required this.label, required this.met});
  final String label;
  final bool met;
}

class _MeterRow extends StatelessWidget {
  const _MeterRow({required this.rule});

  final _Rule rule;

  @override
  Widget build(BuildContext context) {
    final color = rule.met ? AppColors.success : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            rule.met
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: color,
            size: 14,
            semanticLabel: rule.met ? 'Cumplido' : 'Falta',
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              rule.label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: rule.met ? FontWeight.w700 : FontWeight.w500,
                decoration: rule.met ? TextDecoration.lineThrough : null,
                decorationColor: color.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
