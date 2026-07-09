import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";

import prisma from "../../config/prisma.js";

const JWT_EXPIRES_IN = "8h";

function getJwtSecret() {
  if (!process.env.JWT_SECRET) {
    throw new Error("JWT_SECRET no esta configurado.");
  }

  return process.env.JWT_SECRET;
}

function crearPayloadUsuario(usuario) {
  return {
    id: usuario.id,
    correo: usuario.correo,
    nombres: usuario.nombres,
    apellidos: usuario.apellidos,
    rol: usuario.rol.nombre,
  };
}

export async function iniciarSesion({ correo, contrasena } = {}) {
  if (!correo || !contrasena) {
    const error = new Error("Correo y contrasena son obligatorios.");
    error.status = 400;
    throw error;
  }

  const usuario = await prisma.usuario.findUnique({
    where: { correo },
    include: { rol: true },
  });

  if (!usuario || !usuario.activo) {
    const error = new Error("Credenciales invalidas.");
    error.status = 401;
    throw error;
  }

  const contrasenaValida = await bcrypt.compare(
    contrasena,
    usuario.contrasenaHash,
  );

  if (!contrasenaValida) {
    const error = new Error("Credenciales invalidas.");
    error.status = 401;
    throw error;
  }

  const usuarioSeguro = crearPayloadUsuario(usuario);
  const token = jwt.sign(usuarioSeguro, getJwtSecret(), {
    expiresIn: JWT_EXPIRES_IN,
  });

  return {
    token,
    usuario: usuarioSeguro,
  };
}

export async function obtenerUsuarioPorId(id) {
  const usuario = await prisma.usuario.findUnique({
    where: { id },
    include: { rol: true },
  });

  if (!usuario || !usuario.activo) {
    return null;
  }

  return crearPayloadUsuario(usuario);
}
