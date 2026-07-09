import { obtenerPagos, registrarPago } from "./pagos.service.js";

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
