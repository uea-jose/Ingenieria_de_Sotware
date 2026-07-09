import { iniciarSesion } from "./auth.service.js";

export async function login(req, res, next) {
  try {
    const resultado = await iniciarSesion(req.body);

    res.json(resultado);
  } catch (error) {
    next(error);
  }
}

export async function perfil(req, res) {
  res.json({
    usuario: req.usuario,
  });
}
