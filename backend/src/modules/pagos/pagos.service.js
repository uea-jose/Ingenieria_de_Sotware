import prisma from "../../config/prisma.js";

const METODOS_PERMITIDOS = ["EFECTIVO", "TARJETA", "TRANSFERENCIA", "OTRO"];
const ESTADOS_PERMITIDOS = ["PENDIENTE", "PAGADO", "FALLIDO"];
const UMBRAL_ALERTA_STOCK = 3;

function validarPago({ ventaId, metodo, estado, monto }) {
  if (!Number.isInteger(ventaId) || ventaId <= 0) {
    const error = new Error("ventaId es obligatorio y debe ser un numero entero.");
    error.status = 400;
    throw error;
  }

  if (!METODOS_PERMITIDOS.includes(metodo)) {
    const error = new Error(`metodo debe ser uno de: ${METODOS_PERMITIDOS.join(", ")}.`);
    error.status = 400;
    throw error;
  }

  if (!ESTADOS_PERMITIDOS.includes(estado)) {
    const error = new Error(`estado debe ser uno de: ${ESTADOS_PERMITIDOS.join(", ")}.`);
    error.status = 400;
    throw error;
  }

  const montoNumero = Number(monto);

  if (Number.isNaN(montoNumero) || montoNumero <= 0) {
    const error = new Error("monto debe ser un numero mayor a cero.");
    error.status = 400;
    throw error;
  }

  return montoNumero;
}

function compararMontos(monto, totalVenta) {
  return Math.round(monto * 100) === Math.round(Number(totalVenta) * 100);
}

async function obtenerVentaPendiente(tx, ventaId) {
  const venta = await tx.venta.findUnique({
    where: { id: ventaId },
    include: {
      detalles: {
        include: {
          producto: {
            include: {
              inventario: true,
            },
          },
        },
      },
      pagos: true,
    },
  });

  if (!venta) {
    const error = new Error("La venta indicada no existe.");
    error.status = 404;
    throw error;
  }

  if (venta.estado !== "PENDIENTE") {
    const error = new Error(`La venta no esta pendiente. Estado actual: ${venta.estado}.`);
    error.status = 409;
    throw error;
  }

  const yaTienePagoAprobado = venta.pagos.some((pago) => pago.estado === "PAGADO");

  if (yaTienePagoAprobado) {
    const error = new Error("La venta ya tiene un pago aprobado.");
    error.status = 409;
    throw error;
  }

  return venta;
}

/**
 * Descuenta el inventario por cada detalle de la venta y crea el
 * MovimientoInventario correspondiente. Devuelve el array de alertas
 * de stock bajo (opcional en la respuesta).
 *
 * Exportado para ser reutilizado desde ventas.service.js cuando el
 * cliente paga con TARJETA (pago simulado aprobado automáticamente en
 * la misma transacción de creación de la venta).
 *
 * @param {import('@prisma/client').Prisma.TransactionClient} tx
 * @param {object} venta - Venta ya cargada con `detalles.producto.inventario`.
 * @param {number|null} usuarioId - Usuario que dispara la operación.
 */
export async function descontarInventario(tx, venta, usuarioId) {
  const alertasStock = [];

  for (const detalle of venta.detalles) {
    const inventario = detalle.producto.inventario;

    if (!inventario || inventario.stock < detalle.cantidad) {
      const stockDisponible = inventario?.stock ?? 0;
      const error = new Error(
        `${detalle.producto.nombre} no tiene stock suficiente. Disponible: ${stockDisponible}.`,
      );
      error.status = 409;
      throw error;
    }

    const inventarioActualizado = await tx.inventario.update({
      where: { productoId: detalle.productoId },
      data: {
        stock: {
          decrement: detalle.cantidad,
        },
      },
    });

    await tx.movimientoInventario.create({
      data: {
        productoId: detalle.productoId,
        tipo: "SALIDA",
        cantidad: detalle.cantidad,
        motivo: `Salida automatica por venta #${venta.id}`,
        usuarioId,
        ventaId: venta.id,
      },
    });

    if (inventarioActualizado.stock < UMBRAL_ALERTA_STOCK) {
      alertasStock.push({
        productoId: detalle.productoId,
        nombre: detalle.producto.nombre,
        stockDisponible: inventarioActualizado.stock,
        mensaje: `${detalle.producto.nombre} quedo con stock bajo (${inventarioActualizado.stock} unidades).`,
      });
    }
  }

  return alertasStock;
}

export async function registrarPago({ ventaId, metodo, estado, monto, usuario }) {
  const montoNumero = validarPago({ ventaId, metodo, estado, monto });

  const resultado = await prisma.$transaction(async (tx) => {
    const venta = await obtenerVentaPendiente(tx, ventaId);

    if (estado === "PAGADO" && !compararMontos(montoNumero, venta.total)) {
      const error = new Error("El monto pagado debe coincidir con el total de la venta.");
      error.status = 400;
      throw error;
    }

    const pago = await tx.pago.create({
      data: {
        ventaId,
        metodo,
        estado,
        monto: montoNumero,
        fechaPago: estado === "PAGADO" ? new Date() : null,
      },
    });

    let ventaActualizada = venta;
    let alertasStock = [];

    if (estado === "PAGADO") {
      alertasStock = await descontarInventario(tx, venta, usuario.id);

      ventaActualizada = await tx.venta.update({
        where: { id: ventaId },
        data: { estado: "PAGADA" },
        include: {
          cliente: true,
          detalles: {
            include: {
              producto: {
                include: {
                  inventario: true,
                  marca: true,
                  categoria: true,
                },
              },
            },
          },
          pagos: true,
        },
      });
    }

    return {
      pago,
      venta: ventaActualizada,
      alertasStock,
    };
  });

  return {
    ...resultado,
    mensaje:
      estado === "PAGADO"
        ? "Pago aprobado. Venta marcada como PAGADA e inventario descontado."
        : "Pago registrado sin descontar inventario.",
  };
}

export async function obtenerPagos() {
  return prisma.pago.findMany({
    orderBy: { id: "desc" },
    include: {
      venta: {
        include: {
          cliente: true,
        },
      },
    },
  });
}

/**
 * Confirma (aprueba) un Pago PENDIENTE existente sin re-preguntar el
 * método. Se usa desde `POST /api/pagos/:id/confirmar` cuando el
 * administrador o vendedor confirma una transferencia o registra un
 * cobro contra entrega.
 *
 * Reglas:
 * - El pago debe existir y estar en estado PENDIENTE.
 * - La venta asociada debe estar en estado PENDIENTE (no doble confirmar).
 * - No se cambia el método: se lee del propio pago.
 * - Efectos: pago → PAGADO (con fechaPago=now), inventario descontado,
 *   venta → PAGADA. Devuelve alertasStock (mismo shape que registrarPago).
 */
export async function confirmarPago({ pagoId, usuario }) {
  if (!Number.isInteger(pagoId) || pagoId <= 0) {
    const error = new Error("pagoId debe ser un numero entero positivo.");
    error.status = 400;
    throw error;
  }

  const resultado = await prisma.$transaction(async (tx) => {
    const pago = await tx.pago.findUnique({
      where: { id: pagoId },
    });

    if (!pago) {
      const error = new Error("El pago indicado no existe.");
      error.status = 404;
      throw error;
    }

    if (pago.estado !== "PENDIENTE") {
      const error = new Error(
        `El pago no esta pendiente. Estado actual: ${pago.estado}.`,
      );
      error.status = 409;
      throw error;
    }

    // Carga la venta con detalles + inventario para descontar stock.
    const venta = await tx.venta.findUnique({
      where: { id: pago.ventaId },
      include: {
        detalles: {
          include: {
            producto: {
              include: { inventario: true },
            },
          },
        },
      },
    });

    if (!venta) {
      const error = new Error("La venta asociada al pago no existe.");
      error.status = 404;
      throw error;
    }

    if (venta.estado !== "PENDIENTE") {
      const error = new Error(
        `La venta no esta pendiente. Estado actual: ${venta.estado}.`,
      );
      error.status = 409;
      throw error;
    }

    const alertasStock = await descontarInventario(tx, venta, usuario.id);

    const pagoActualizado = await tx.pago.update({
      where: { id: pagoId },
      data: {
        estado: "PAGADO",
        fechaPago: new Date(),
      },
    });

    const ventaActualizada = await tx.venta.update({
      where: { id: venta.id },
      data: { estado: "PAGADA" },
      include: {
        cliente: true,
        detalles: {
          include: {
            producto: {
              include: {
                inventario: true,
                marca: true,
                categoria: true,
              },
            },
          },
        },
        pagos: true,
        factura: true,
      },
    });

    return {
      pago: pagoActualizado,
      venta: ventaActualizada,
      alertasStock,
    };
  });

  const metodo = resultado.pago.metodo;
  return {
    ...resultado,
    mensaje:
      metodo === "TRANSFERENCIA"
        ? "Transferencia confirmada. Venta marcada como PAGADA e inventario descontado."
        : metodo === "EFECTIVO"
        ? "Cobro en efectivo registrado. Venta marcada como PAGADA e inventario descontado."
        : "Pago confirmado. Venta marcada como PAGADA e inventario descontado.",
  };
}
