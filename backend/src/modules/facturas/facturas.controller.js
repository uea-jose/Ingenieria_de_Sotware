import {
  generarFactura,
  obtenerFacturaPorId,
  obtenerFacturas,
} from "./facturas.service.js";

export async function crearFactura(req, res, next) {
  try {
    const factura = await generarFactura({
      ventaId: req.body.ventaId,
    });

    res.status(201).json({
      dato: factura,
      mensaje: "Factura generada correctamente.",
    });
  } catch (error) {
    next(error);
  }
}

export async function listarFacturas(req, res, next) {
  try {
    const facturas = await obtenerFacturas();

    res.json({
      datos: facturas,
      total: facturas.length,
    });
  } catch (error) {
    next(error);
  }
}

export async function verFactura(req, res, next) {
  try {
    const factura = await obtenerFacturaPorId(req.params.id);

    res.json({
      dato: factura,
    });
  } catch (error) {
    next(error);
  }
}
