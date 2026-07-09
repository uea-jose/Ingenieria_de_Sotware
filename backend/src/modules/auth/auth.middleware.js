import jwt from "jsonwebtoken";

import { obtenerUsuarioPorId } from "./auth.service.js";

function obtenerToken(req) {
  const authorization = req.headers.authorization;

  if (!authorization || !authorization.startsWith("Bearer ")) {
    return null;
  }

  return authorization.slice("Bearer ".length);
}

export async function requiereAutenticacion(req, res, next) {
  try {
    const token = obtenerToken(req);

    if (!token) {
      return res.status(401).json({
        error: "Token no enviado.",
      });
    }

    const payload = jwt.verify(token, process.env.JWT_SECRET);
    const usuario = await obtenerUsuarioPorId(payload.id);

    if (!usuario) {
      return res.status(401).json({
        error: "Usuario no autorizado.",
      });
    }

    req.usuario = usuario;
    return next();
  } catch (error) {
    return res.status(401).json({
      error: "Token invalido o expirado.",
    });
  }
}

export function requiereRol(...rolesPermitidos) {
  return (req, res, next) => {
    if (!req.usuario || !rolesPermitidos.includes(req.usuario.rol)) {
      return res.status(403).json({
        error: "No tienes permisos para esta accion.",
      });
    }

    return next();
  };
}
