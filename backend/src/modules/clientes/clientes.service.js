import bcrypt from "bcrypt";

import prisma from "../../config/prisma.js";

const SALT_ROUNDS = 10;

function validarRegistroCliente(datos) {
  const camposObligatorios = ["nombres", "apellidos", "correo", "contrasena"];
  const faltantes = camposObligatorios.filter((campo) => !datos[campo]);

  if (faltantes.length > 0) {
    const error = new Error(`Campos obligatorios faltantes: ${faltantes.join(", ")}.`);
    error.status = 400;
    throw error;
  }

  if (!datos.correo.includes("@")) {
    const error = new Error("El correo no tiene un formato valido.");
    error.status = 400;
    throw error;
  }

  if (datos.contrasena.length < 8) {
    const error = new Error("La contrasena debe tener al menos 8 caracteres.");
    error.status = 400;
    throw error;
  }
}

function limpiarCliente(cliente) {
  return {
    id: cliente.id,
    usuarioId: cliente.usuarioId,
    nombres: cliente.nombres,
    apellidos: cliente.apellidos,
    correo: cliente.correo,
    telefono: cliente.telefono,
    cedula: cliente.cedula,
    direccion: cliente.direccion,
    ciudad: cliente.ciudad,
  };
}

export async function registrarCliente(datos) {
  validarRegistroCliente(datos);

  const correo = datos.correo.trim().toLowerCase();

  const usuarioExistente = await prisma.usuario.findUnique({
    where: { correo },
  });

  if (usuarioExistente) {
    const error = new Error("Ya existe una cuenta registrada con este correo.");
    error.status = 409;
    throw error;
  }

  const cedula = datos.cedula?.trim() || null;

  if (cedula) {
    const clienteExistente = await prisma.cliente.findUnique({
      where: { cedula },
    });

    if (clienteExistente) {
      const error = new Error("Ya existe un cliente registrado con esta cedula.");
      error.status = 409;
      throw error;
    }
  }

  const rolCliente = await prisma.rol.upsert({
    where: { nombre: "Cliente" },
    update: {},
    create: {
      nombre: "Cliente",
      descripcion: "Compra perfumes, consulta catalogo y gestiona sus pedidos.",
    },
  });

  const contrasenaHash = await bcrypt.hash(datos.contrasena, SALT_ROUNDS);

  const resultado = await prisma.$transaction(async (tx) => {
    const usuario = await tx.usuario.create({
      data: {
        nombres: datos.nombres.trim(),
        apellidos: datos.apellidos.trim(),
        correo,
        contrasenaHash,
        activo: true,
        rolId: rolCliente.id,
      },
      include: { rol: true },
    });

    const cliente = await tx.cliente.create({
      data: {
        usuarioId: usuario.id,
        nombres: datos.nombres.trim(),
        apellidos: datos.apellidos.trim(),
        correo,
        telefono: datos.telefono?.trim() || null,
        cedula,
        direccion: datos.direccion?.trim() || null,
        ciudad: datos.ciudad?.trim() || null,
      },
    });

    return { usuario, cliente };
  });

  return {
    usuario: {
      id: resultado.usuario.id,
      nombres: resultado.usuario.nombres,
      apellidos: resultado.usuario.apellidos,
      correo: resultado.usuario.correo,
      rol: resultado.usuario.rol.nombre,
      activo: resultado.usuario.activo,
    },
    cliente: limpiarCliente(resultado.cliente),
  };
}

export async function obtenerClientes() {
  return prisma.cliente.findMany({
    orderBy: { id: "asc" },
    include: {
      usuario: {
        select: {
          id: true,
          correo: true,
          activo: true,
          rol: {
            select: {
              nombre: true,
            },
          },
        },
      },
    },
  });
}
