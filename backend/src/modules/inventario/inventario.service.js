import prisma from "../../config/prisma.js";

const TIPOS_PERMITIDOS = ["ENTRADA", "SALIDA", "AJUSTE"];
const UMBRAL_ALERTA_STOCK = 3;

function validarMovimiento({ productoId, tipo, cantidad, motivo }) {
  if (!Number.isInteger(productoId) || productoId <= 0) {
    const error = new Error("productoId es obligatorio y debe ser un numero entero.");
    error.status = 400;
    throw error;
  }

  if (!TIPOS_PERMITIDOS.includes(tipo)) {
    const error = new Error(`tipo debe ser uno de: ${TIPOS_PERMITIDOS.join(", ")}.`);
    error.status = 400;
    throw error;
  }

  if (!Number.isInteger(cantidad) || cantidad < 0) {
    const error = new Error("cantidad debe ser un numero entero mayor o igual a cero.");
    error.status = 400;
    throw error;
  }

  if (!motivo || !motivo.trim()) {
    const error = new Error("motivo es obligatorio.");
    error.status = 400;
    throw error;
  }
}

function calcularNuevoStock(stockActual, tipo, cantidad) {
  if (tipo === "ENTRADA") {
    return stockActual + cantidad;
  }

  if (tipo === "SALIDA") {
    return stockActual - cantidad;
  }

  return cantidad;
}

export async function obtenerInventario() {
  return prisma.inventario.findMany({
    orderBy: { id: "asc" },
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

export async function obtenerAlertasInventario() {
  const inventario = await prisma.inventario.findMany({
    where: {
      OR: [
        { stock: { lt: UMBRAL_ALERTA_STOCK } },
        { stock: { lte: prisma.inventario.fields.stockMinimo } },
      ],
    },
    orderBy: { stock: "asc" },
    include: {
      producto: {
        include: {
          marca: true,
          categoria: true,
        },
      },
    },
  });

  return inventario.map((item) => ({
    id: item.id,
    productoId: item.productoId,
    producto: item.producto.nombre,
    marca: item.producto.marca.nombre,
    categoria: item.producto.categoria.nombre,
    stock: item.stock,
    stockMinimo: item.stockMinimo,
    stockBajo: item.stock < UMBRAL_ALERTA_STOCK,
    bajoMinimo: item.stock <= item.stockMinimo,
    mensaje:
      item.stock < UMBRAL_ALERTA_STOCK
        ? `${item.producto.nombre} tiene stock menor que ${UMBRAL_ALERTA_STOCK}.`
        : `${item.producto.nombre} esta en o por debajo del stock minimo.`,
  }));
}

export async function obtenerMovimientosInventario() {
  return prisma.movimientoInventario.findMany({
    orderBy: { id: "desc" },
    include: {
      producto: {
        include: {
          marca: true,
          categoria: true,
        },
      },
      usuario: {
        select: {
          id: true,
          nombres: true,
          apellidos: true,
          correo: true,
          rol: true,
        },
      },
      venta: true,
    },
  });
}

export async function registrarMovimientoInventario({
  productoId,
  tipo,
  cantidad,
  motivo,
  usuario,
}) {
  validarMovimiento({ productoId, tipo, cantidad, motivo });

  const resultado = await prisma.$transaction(async (tx) => {
    const producto = await tx.producto.findUnique({
      where: { id: productoId },
      include: { inventario: true },
    });

    if (!producto) {
      const error = new Error("El producto indicado no existe.");
      error.status = 404;
      throw error;
    }

    if (!producto.inventario) {
      const error = new Error("El producto no tiene registro de inventario.");
      error.status = 404;
      throw error;
    }

    const stockActual = producto.inventario.stock;
    const nuevoStock = calcularNuevoStock(stockActual, tipo, cantidad);

    if (nuevoStock < 0) {
      const error = new Error(
        `No se puede registrar la salida. Stock disponible: ${stockActual}.`,
      );
      error.status = 409;
      throw error;
    }

    const inventario = await tx.inventario.update({
      where: { productoId },
      data: { stock: nuevoStock },
      include: {
        producto: {
          include: {
            marca: true,
            categoria: true,
          },
        },
      },
    });

    const movimiento = await tx.movimientoInventario.create({
      data: {
        productoId,
        tipo,
        cantidad,
        motivo: motivo.trim(),
        usuarioId: usuario.id,
      },
      include: {
        producto: true,
        usuario: {
          select: {
            id: true,
            nombres: true,
            apellidos: true,
            correo: true,
            rol: true,
          },
        },
      },
    });

    return {
      inventario,
      movimiento,
    };
  });

  const alertasStock =
    resultado.inventario.stock < UMBRAL_ALERTA_STOCK
      ? [
          {
            productoId: resultado.inventario.productoId,
            nombre: resultado.inventario.producto.nombre,
            stockDisponible: resultado.inventario.stock,
            mensaje: `${resultado.inventario.producto.nombre} tiene stock bajo (${resultado.inventario.stock} unidades).`,
          },
        ]
      : [];

  return {
    ...resultado,
    alertasStock,
    mensaje: `Movimiento ${tipo} registrado correctamente.`,
  };
}
