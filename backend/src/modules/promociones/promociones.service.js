import prisma from "../../config/prisma.js";

const TIPOS_PERMITIDOS = ["PORCENTAJE", "MONTO"];

function convertirId(valor, nombreCampo = "id") {
  const numero = Number.parseInt(valor, 10);

  if (Number.isNaN(numero) || numero <= 0) {
    const error = new Error(`${nombreCampo} debe ser un numero entero positivo.`);
    error.status = 400;
    throw error;
  }

  return numero;
}

function convertirDecimal(valor, nombreCampo = "valor") {
  const numero = Number.parseFloat(valor);

  if (Number.isNaN(numero) || numero <= 0) {
    const error = new Error(`${nombreCampo} debe ser un numero mayor a cero.`);
    error.status = 400;
    throw error;
  }

  return numero;
}

function convertirBooleano(valor) {
  if (valor === "true" || valor === true) {
    return true;
  }

  if (valor === "false" || valor === false) {
    return false;
  }

  const error = new Error("activo debe ser true o false.");
  error.status = 400;
  throw error;
}

function convertirFecha(valor, nombreCampo) {
  const fecha = new Date(valor);

  if (!valor || Number.isNaN(fecha.getTime())) {
    const error = new Error(`${nombreCampo} debe ser una fecha valida.`);
    error.status = 400;
    throw error;
  }

  return fecha;
}

function validarPromocion(datos, parcial = false) {
  const requeridos = ["productoId", "nombre", "tipo", "valor", "fechaInicio", "fechaFin"];

  if (!parcial) {
    const faltantes = requeridos.filter((campo) => datos[campo] === undefined || datos[campo] === null || datos[campo] === "");

    if (faltantes.length > 0) {
      const error = new Error(`Campos obligatorios faltantes: ${faltantes.join(", ")}.`);
      error.status = 400;
      throw error;
    }
  }

  if (datos.nombre !== undefined && !datos.nombre.trim()) {
    const error = new Error("nombre no puede estar vacio.");
    error.status = 400;
    throw error;
  }

  if (datos.tipo !== undefined && !TIPOS_PERMITIDOS.includes(datos.tipo)) {
    const error = new Error(`tipo debe ser uno de: ${TIPOS_PERMITIDOS.join(", ")}.`);
    error.status = 400;
    throw error;
  }

  if (datos.valor !== undefined) {
    const valor = convertirDecimal(datos.valor, "valor");

    if (datos.tipo === "PORCENTAJE" && valor > 100) {
      const error = new Error("El valor de una promocion PORCENTAJE no puede superar 100.");
      error.status = 400;
      throw error;
    }
  }
}

function mapearPromocion(datos) {
  const data = {};

  if (datos.productoId !== undefined) {
    data.productoId = convertirId(datos.productoId, "productoId");
  }

  if (datos.nombre !== undefined) {
    data.nombre = datos.nombre.trim();
  }

  if (datos.descripcion !== undefined) {
    data.descripcion = datos.descripcion?.trim() || null;
  }

  if (datos.tipo !== undefined) {
    data.tipo = datos.tipo;
  }

  if (datos.valor !== undefined) {
    data.valor = convertirDecimal(datos.valor, "valor");
  }

  if (datos.fechaInicio !== undefined) {
    data.fechaInicio = convertirFecha(datos.fechaInicio, "fechaInicio");
  }

  if (datos.fechaFin !== undefined) {
    data.fechaFin = convertirFecha(datos.fechaFin, "fechaFin");
  }

  if (datos.activo !== undefined) {
    data.activo = convertirBooleano(datos.activo);
  }

  if (data.fechaInicio && data.fechaFin && data.fechaInicio >= data.fechaFin) {
    const error = new Error("fechaInicio debe ser menor que fechaFin.");
    error.status = 400;
    throw error;
  }

  return data;
}

async function validarProducto(productoId) {
  const producto = await prisma.producto.findUnique({
    where: { id: productoId },
  });

  if (!producto || !producto.activo) {
    const error = new Error("El producto indicado no existe o esta inactivo.");
    error.status = 400;
    throw error;
  }
}

export async function obtenerPromociones() {
  return prisma.promocion.findMany({
    orderBy: { id: "desc" },
    include: {
      producto: {
        include: {
          marca: true,
          categoria: true,
        },
      },
    },
  });
}

export async function obtenerPromocionPorId(id) {
  const promocionId = convertirId(id);
  const promocion = await prisma.promocion.findUnique({
    where: { id: promocionId },
    include: {
      producto: {
        include: {
          marca: true,
          categoria: true,
        },
      },
    },
  });

  if (!promocion) {
    const error = new Error("La promocion indicada no existe.");
    error.status = 404;
    throw error;
  }

  return promocion;
}

export async function crearPromocion(datos) {
  validarPromocion(datos);
  const data = mapearPromocion(datos);
  await validarProducto(data.productoId);

  return prisma.promocion.create({
    data: {
      ...data,
      activo: datos.activo === undefined ? true : data.activo,
    },
    include: {
      producto: {
        include: {
          marca: true,
          categoria: true,
        },
      },
    },
  });
}

export async function actualizarPromocion(id, datos) {
  const promocionId = convertirId(id);
  validarPromocion(datos, true);
  const promocionActual = await obtenerPromocionPorId(promocionId);
  const data = mapearPromocion(datos);

  if (data.productoId !== undefined) {
    await validarProducto(data.productoId);
  }

  const fechaInicio = data.fechaInicio ?? promocionActual.fechaInicio;
  const fechaFin = data.fechaFin ?? promocionActual.fechaFin;

  if (fechaInicio >= fechaFin) {
    const error = new Error("fechaInicio debe ser menor que fechaFin.");
    error.status = 400;
    throw error;
  }

  return prisma.promocion.update({
    where: { id: promocionId },
    data,
    include: {
      producto: {
        include: {
          marca: true,
          categoria: true,
        },
      },
    },
  });
}

export async function cambiarEstadoPromocion(id, activo) {
  const promocionId = convertirId(id);
  await obtenerPromocionPorId(promocionId);

  return prisma.promocion.update({
    where: { id: promocionId },
    data: { activo: convertirBooleano(activo) },
    include: {
      producto: {
        include: {
          marca: true,
          categoria: true,
        },
      },
    },
  });
}
