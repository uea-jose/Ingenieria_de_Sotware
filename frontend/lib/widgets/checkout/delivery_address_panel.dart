import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_design_tokens.dart';
import '../../core/validators.dart';
import '../../data/location/location_service.dart';
import '../feedback/feedback_banner.dart';

/// Delivery-address block used inside CheckoutPage.
///
/// Behaviour rules approved for Aromas Store (see the GPS decision doc):
/// - The GPS prompt only fires when the user taps "Usar mi ubicación".
/// - If the browser blocks / the user rejects → the form stays usable
///   and the caller can still submit the sale with the values typed in.
/// - Address, city and phone are required (validators run inside the
///   Form ancestor). Reference is optional. Latitude/longitude are only
///   populated when the GPS flow succeeds — never faked.
/// - The widget writes into the caller's `TextEditingController`s so the
///   parent page owns the values and can flush them into `POST /ventas`.
/// - When the reverse-geocoding succeeds we surface the OpenStreetMap
///   attribution line, as required by their ToS.
class DeliveryAddressPanel extends StatefulWidget {
  const DeliveryAddressPanel({
    required this.direccionController,
    required this.ciudadController,
    required this.referenciaController,
    required this.telefonoController,
    required this.onCoordsCaptured,
    required this.onCoordsCleared,
    this.locationService,
    super.key,
  });

  final TextEditingController direccionController;
  final TextEditingController ciudadController;
  final TextEditingController referenciaController;
  final TextEditingController telefonoController;

  /// Called with the coordinates and the display name of the source
  /// when the GPS flow succeeds. The parent stores lat/lng in state
  /// and forwards them to `POST /ventas`.
  final void Function(double lat, double lng, String? atribucion)
  onCoordsCaptured;

  /// Called when the user edits the address / city fields manually —
  /// coordinates are no longer trustworthy so the parent should clear
  /// its captured lat/lng.
  final VoidCallback onCoordsCleared;

  /// Optional override for tests.
  final LocationService? locationService;

  @override
  State<DeliveryAddressPanel> createState() => _DeliveryAddressPanelState();
}

class _DeliveryAddressPanelState extends State<DeliveryAddressPanel> {
  late final LocationService _service = widget.locationService ?? LocationService();
  bool _loading = false;
  _PanelBanner? _banner;
  bool _hasCoords = false;

  @override
  void initState() {
    super.initState();
    // If the user manually edits address or city after a GPS success,
    // drop the captured coordinates: they no longer correspond to what
    // the user is going to submit.
    widget.direccionController.addListener(_onManualEdit);
    widget.ciudadController.addListener(_onManualEdit);
  }

  @override
  void dispose() {
    widget.direccionController.removeListener(_onManualEdit);
    widget.ciudadController.removeListener(_onManualEdit);
    if (widget.locationService == null) _service.dispose();
    super.dispose();
  }

  bool _lastEditWasFromGps = false;

  void _onManualEdit() {
    if (_lastEditWasFromGps) {
      _lastEditWasFromGps = false;
      return;
    }
    if (_hasCoords) {
      setState(() {
        _hasCoords = false;
        _banner = null;
      });
      widget.onCoordsCleared();
    }
  }

  Future<void> _pedirUbicacion() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _banner = null;
    });
    try {
      final (pos, geo) = await _service.obtenerYResolver();
      _lastEditWasFromGps = true;
      if (geo.direccion.isNotEmpty) {
        widget.direccionController.text = geo.direccion;
      }
      _lastEditWasFromGps = true;
      if (geo.ciudad.isNotEmpty) {
        widget.ciudadController.text = geo.ciudad;
      }
      widget.onCoordsCaptured(pos.latitude, pos.longitude, geo.atribucion);
      if (!mounted) return;
      setState(() {
        _hasCoords = true;
        _banner = _PanelBanner.success(
          'Ubicación detectada: ${geo.ciudad}, ${geo.pais}. '
          'Puedes ajustar la dirección manualmente si es necesario.',
          atribucion: geo.atribucion,
        );
      });
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() {
        _hasCoords = false;
        _banner = _bannerParaError(e);
      });
      widget.onCoordsCleared();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  _PanelBanner _bannerParaError(LocationException e) {
    switch (e.code) {
      case LocationErrorCode.serviceDisabled:
      case LocationErrorCode.permissionDeniedForever:
        return _PanelBanner.warning(e.message);
      case LocationErrorCode.permissionDenied:
        return _PanelBanner.info(e.message);
      case LocationErrorCode.timeout:
      case LocationErrorCode.network:
      case LocationErrorCode.reverseGeocodeFailed:
      case LocationErrorCode.unknown:
        return _PanelBanner.error(
          '${e.message} Puedes ingresar tu dirección manualmente.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Dirección de entrega',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Guardamos la dirección exacta con la que se creó este pedido.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _loading ? null : _pedirUbicacion,
            icon: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _hasCoords
                        ? Icons.gps_fixed
                        : Icons.my_location_outlined,
                  ),
            label: Text(
              _loading
                  ? 'Detectando...'
                  : _hasCoords
                      ? 'Actualizar ubicación'
                      : 'Usar mi ubicación',
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
          if (banner != null) ...[
            const SizedBox(height: 10),
            banner.build(context),
          ],
          const SizedBox(height: 14),
          TextFormField(
            controller: widget.direccionController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Dirección *',
              hintText: 'Calle, número, edificio',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            validator: (v) => Validators.required(v, field: 'Dirección'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: widget.ciudadController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Ciudad *',
              prefixIcon: Icon(Icons.location_city_outlined),
            ),
            validator: (v) => Validators.required(v, field: 'Ciudad'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: widget.referenciaController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Referencia (opcional)',
              hintText: 'Junto al parque, casa esquinera, etc.',
              prefixIcon: Icon(Icons.pin_drop_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: widget.telefonoController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d+]')),
              LengthLimitingTextInputFormatter(13),
            ],
            decoration: const InputDecoration(
              labelText: 'Teléfono de contacto *',
              hintText: '09XXXXXXXX o +5939XXXXXXXX',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            // Required, con formato Ecuador. Validators.phoneEcuador ya
            // valida rango si viene texto; lo forzamos requerido con
            // isRequired:true para que el checkout no acepte vacío.
            validator: (v) =>
                Validators.phoneEcuador(v, isRequired: true),
          ),
        ],
      ),
    );
  }
}

/// Small enum-like helper: chooses the [FeedbackBanner] variant + carries
/// the OSM attribution line for the success case.
class _PanelBanner {
  const _PanelBanner._({
    required this.variant,
    required this.message,
    this.atribucion,
  });

  factory _PanelBanner.success(String message, {String? atribucion}) =>
      _PanelBanner._(
        variant: FeedbackVariant.success,
        message: message,
        atribucion: atribucion,
      );
  factory _PanelBanner.warning(String message) =>
      _PanelBanner._(variant: FeedbackVariant.warning, message: message);
  factory _PanelBanner.info(String message) =>
      _PanelBanner._(variant: FeedbackVariant.info, message: message);
  factory _PanelBanner.error(String message) =>
      _PanelBanner._(variant: FeedbackVariant.error, message: message);

  final FeedbackVariant variant;
  final String message;
  final String? atribucion;

  Widget build(BuildContext context) {
    final banner = FeedbackBanner(message: message, variant: variant);
    if (variant != FeedbackVariant.success ||
        atribucion == null ||
        atribucion!.isEmpty) {
      return banner;
    }
    // Attribution line required by OpenStreetMap / Nominatim ToS when
    // we surface a reverse-geocoded result to the user.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        banner,
        const SizedBox(height: 4),
        Text(
          atribucion!,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
