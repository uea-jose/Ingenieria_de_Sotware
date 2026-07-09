import { obtenerClientes, registrarCliente } from "./clientes.service.js";

export async function crearCliente(req, res, next) {
  try {
    const resultado = await registrarCliente(req.body);

    res.status(201).json(resultado);
  } catch (error) {
    next(error);
  }
}

export async function listarClientes(req, res, next) {
  try {
    const clientes = await obtenerClientes();

    res.json({
      datos: clientes,
      total: clientes.length,
    });
  } catch (error) {
    next(error);
  }
}
