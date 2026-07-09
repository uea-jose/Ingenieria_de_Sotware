import {
  actualizarCategoria,
  cambiarEstadoCategoria,
  crearCategoria,
  obtenerCategoriaPorId,
  obtenerCategorias,
} from "./categorias.service.js";

export async function listarCategorias(req, res, next) {
  try {
    const categorias = await obtenerCategorias();

    res.json({
      datos: categorias,
      total: categorias.length,
    });
  } catch (error) {
    next(error);
  }
}

export async function verCategoria(req, res, next) {
  try {
    const categoria = await obtenerCategoriaPorId(req.params.id);

    res.json({
      dato: categoria,
    });
  } catch (error) {
    next(error);
  }
}

export async function registrarCategoria(req, res, next) {
  try {
    const categoria = await crearCategoria(req.body);

    res.status(201).json({
      dato: categoria,
    });
  } catch (error) {
    next(error);
  }
}

export async function editarCategoria(req, res, next) {
  try {
    const categoria = await actualizarCategoria(req.params.id, req.body);

    res.json({
      dato: categoria,
    });
  } catch (error) {
    next(error);
  }
}

export async function actualizarEstadoCategoria(req, res, next) {
  try {
    const categoria = await cambiarEstadoCategoria(req.params.id, req.body.activo);

    res.json({
      dato: categoria,
    });
  } catch (error) {
    next(error);
  }
}
