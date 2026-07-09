import {
  actualizarMarca,
  cambiarEstadoMarca,
  crearMarca,
  obtenerMarcaPorId,
  obtenerMarcas,
} from "./marcas.service.js";

export async function listarMarcas(req, res, next) {
  try {
    const marcas = await obtenerMarcas();

    res.json({
      datos: marcas,
      total: marcas.length,
    });
  } catch (error) {
    next(error);
  }
}

export async function verMarca(req, res, next) {
  try {
    const marca = await obtenerMarcaPorId(req.params.id);

    res.json({
      dato: marca,
    });
  } catch (error) {
    next(error);
  }
}

export async function registrarMarca(req, res, next) {
  try {
    const marca = await crearMarca(req.body);

    res.status(201).json({
      dato: marca,
    });
  } catch (error) {
    next(error);
  }
}

export async function editarMarca(req, res, next) {
  try {
    const marca = await actualizarMarca(req.params.id, req.body);

    res.json({
      dato: marca,
    });
  } catch (error) {
    next(error);
  }
}

export async function actualizarEstadoMarca(req, res, next) {
  try {
    const marca = await cambiarEstadoMarca(req.params.id, req.body.activo);

    res.json({
      dato: marca,
    });
  } catch (error) {
    next(error);
  }
}
