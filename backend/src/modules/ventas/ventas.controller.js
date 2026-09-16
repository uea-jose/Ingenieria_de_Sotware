import {
  crearVenta,
  obtenerVentas,
  obtenerVentasDelCliente,
} from "./ventas.service.js";

export async function registrarVenta(req, res, next) {
  try {
    const {
      clienteId,
      items,
      metodoPago,
      // Delivery snapshot — every field is optional at the API layer
      // (the frontend enforces required for direccion/ciudad/telefono
      // when creating a new sale). Coordinates get validated inside the
      // service; textual fields are trimmed and truncated to their DB
      // column length.
      direccionEntrega,
      ciudadEntrega,
      referenciaEntrega,
      telefonoContacto,
      latitudEntrega,
      longitudEntrega,
    } = req.body ?? {};

    const resultado = await crearVenta({
      clienteId,
      items,
      metodoPago,
      entrega: {
        direccionEntrega,
        ciudadEntrega,
        referenciaEntrega,
        telefonoContacto,
        latitudEntrega,
        longitudEntrega,
      },
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

export async function listarMisVentas(req, res, next) {
  try {
    const ventas = await obtenerVentasDelCliente(req.usuario);

    res.json({
      datos: ventas,
      total: ventas.length,
    });
  } catch (error) {
    next(error);
  }
}
