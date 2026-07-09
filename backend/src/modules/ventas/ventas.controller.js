import { crearVenta, obtenerVentas } from "./ventas.service.js";

export async function registrarVenta(req, res, next) {
  try {
    const resultado = await crearVenta({
      clienteId: req.body.clienteId,
      items: req.body.items,
      usuario: req.usuario,
    });

    res.status(201).json(resultado);
  } catch (error) {
    next(error);
  }
}

export async function listarVentas(req, res, next) {
  try {
    const ventas = await obtenerVentas();

    res.json({
      datos: ventas,
      total: ventas.length,
    });
  } catch (error) {
    next(error);
  }
}
