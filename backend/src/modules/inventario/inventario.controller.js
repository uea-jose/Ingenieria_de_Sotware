import {
  obtenerAlertasInventario,
  obtenerInventario,
  obtenerMovimientosInventario,
  registrarMovimientoInventario,
} from "./inventario.service.js";

export async function listarInventario(req, res, next) {
  try {
    const inventario = await obtenerInventario();

    res.json({
      datos: inventario,
      total: inventario.length,
    });
  } catch (error) {
    next(error);
  }
}

export async function listarAlertas(req, res, next) {
  try {
    const alertas = await obtenerAlertasInventario();

    res.json({
      datos: alertas,
      total: alertas.length,
    });
  } catch (error) {
    next(error);
  }
}

export async function listarMovimientos(req, res, next) {
  try {
    const movimientos = await obtenerMovimientosInventario();

    res.json({
      datos: movimientos,
      total: movimientos.length,
    });
  } catch (error) {
    next(error);
  }
}

export async function crearMovimiento(req, res, next) {
  try {
    const resultado = await registrarMovimientoInventario({
      productoId: req.body.productoId,
      tipo: req.body.tipo,
      cantidad: req.body.cantidad,
      motivo: req.body.motivo,
      usuario: req.usuario,
    });

    res.status(201).json(resultado);
  } catch (error) {
    next(error);
  }
}
