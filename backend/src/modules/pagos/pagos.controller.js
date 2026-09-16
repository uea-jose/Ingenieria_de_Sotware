import { confirmarPago, obtenerPagos, registrarPago } from "./pagos.service.js";

export async function crearPago(req, res, next) {
  try {
    const resultado = await registrarPago({
      ventaId: req.body.ventaId,
      metodo: req.body.metodo,
      estado: req.body.estado,
      monto: req.body.monto,
      usuario: req.usuario,
    });

    res.status(201).json(resultado);
  } catch (error) {
    next(error);
  }
}

export async function listarPagos(req, res, next) {
  try {
    const pagos = await obtenerPagos();

    res.json({
      datos: pagos,
      total: pagos.length,
    });
  } catch (error) {
    next(error);
  }
}

/**
 * POST /api/pagos/:id/confirmar
 *
 * Aprueba un pago PENDIENTE preexistente sin re-preguntar el metodo.
 * Se usa desde el panel admin para "Confirmar transferencia" y
 * "Registrar cobro". El pago original fue creado por el cliente durante
 * el checkout, asi que aqui no aceptamos ningun campo del body.
 */
export async function confirmarPagoPendiente(req, res, next) {
  try {
    const pagoId = Number.parseInt(req.params.id, 10);
    const resultado = await confirmarPago({
      pagoId,
      usuario: req.usuario,
    });
    res.status(200).json(resultado);
  } catch (error) {
    next(error);
  }
}
