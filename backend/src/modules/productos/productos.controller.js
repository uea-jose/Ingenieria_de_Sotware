import {
  actualizarProducto,
  cambiarEstadoProducto,
  crearProducto,
  obtenerProductoPorId,
  obtenerProductos,
} from "./productos.service.js";
import {
  guardarAcordesDeProducto,
  obtenerAcordesDeProducto,
  restaurarAcordesDeProducto,
} from "./productos.acordes.service.js";

export async function listarProductos(req, res, next) {
  try {
    const { productos, filtrosAplicados } = await obtenerProductos(req.query);

    res.json({
      datos: productos,
      total: productos.length,
      filtros: filtrosAplicados,
    });
  } catch (error) {
    next(error);
  }
}

export async function verProducto(req, res, next) {
  try {
    const producto = await obtenerProductoPorId(req.params.id);

    res.json({
      dato: producto,
    });
  } catch (error) {
    next(error);
  }
}

export async function registrarProducto(req, res, next) {
  try {
    const producto = await crearProducto(req.body);

    res.status(201).json({
      dato: producto,
    });
  } catch (error) {
    next(error);
  }
}

export async function editarProducto(req, res, next) {
  try {
    const producto = await actualizarProducto(req.params.id, req.body);

    res.json({
      dato: producto,
    });
  } catch (error) {
    next(error);
  }
}

export async function actualizarEstadoProducto(req, res, next) {
  try {
    const producto = await cambiarEstadoProducto(req.params.id, req.body.activo);

    res.json({
      dato: producto,
    });
  } catch (error) {
    next(error);
  }
}

export async function verAcordesProducto(req, res, next) {
  try {
    const resultado = await obtenerAcordesDeProducto(req.params.id);

    res.json({
      datos: resultado.acordes,
      total: resultado.acordes.length,
      producto: resultado.producto,
    });
  } catch (error) {
    next(error);
  }
}

export async function editarAcordesProducto(req, res, next) {
  try {
    const resultado = await guardarAcordesDeProducto(req.params.id, req.body);

    res.json({
      datos: resultado.acordes,
      total: resultado.acordes.length,
      producto: resultado.producto,
    });
  } catch (error) {
    next(error);
  }
}

export async function restaurarAcordesProducto(req, res, next) {
  try {
    const resultado = await restaurarAcordesDeProducto(req.params.id);

    res.json({
      datos: resultado.acordes,
      total: resultado.acordes.length,
      producto: resultado.producto,
    });
  } catch (error) {
    next(error);
  }
}
