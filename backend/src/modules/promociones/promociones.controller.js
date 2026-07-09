import {
  actualizarPromocion,
  cambiarEstadoPromocion,
  crearPromocion,
  obtenerPromocionPorId,
  obtenerPromociones,
} from "./promociones.service.js";

export async function listarPromociones(req, res, next) {
  try {
    const promociones = await obtenerPromociones();

    res.json({
      datos: promociones,
      total: promociones.length,
    });
  } catch (error) {
    next(error);
  }
}

export async function verPromocion(req, res, next) {
  try {
    const promocion = await obtenerPromocionPorId(req.params.id);

    res.json({
      dato: promocion,
    });
  } catch (error) {
    next(error);
  }
}

export async function registrarPromocion(req, res, next) {
  try {
    const promocion = await crearPromocion(req.body);

    res.status(201).json({
      dato: promocion,
    });
  } catch (error) {
    next(error);
  }
}

export async function editarPromocion(req, res, next) {
  try {
    const promocion = await actualizarPromocion(req.params.id, req.body);

    res.json({
      dato: promocion,
    });
  } catch (error) {
    next(error);
  }
}

export async function actualizarEstadoPromocion(req, res, next) {
  try {
    const promocion = await cambiarEstadoPromocion(req.params.id, req.body.activo);

    res.json({
      dato: promocion,
    });
  } catch (error) {
    next(error);
  }
}
