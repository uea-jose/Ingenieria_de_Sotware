import { validarCarrito } from "./carrito.service.js";

export async function validar(req, res, next) {
  try {
    const resultado = await validarCarrito(req.body.items);

    res.json(resultado);
  } catch (error) {
    next(error);
  }
}
