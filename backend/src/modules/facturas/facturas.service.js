import prisma from "../../config/prisma.js";

function convertirId(valor, nombreCampo = "id") {
  const numero = Number.parseInt(valor, 10);

  if (Number.isNaN(numero) || numero <= 0) {
    const error = new Error(`${nombreCampo} debe ser un numero entero positivo.`);
    error.status = 400;
    throw error;
  }

  return numero;
}

function generarNumeroFactura(ventaId) {
  return `FAC-${String(ventaId).padStart(6, "0")}`;
}

export async function generarFactura({ ventaId }) {
  const idVenta = convertirId(ventaId, "ventaId");

  const venta = await prisma.venta.findUnique({
    where: { id: idVenta },
    include: {
      cliente: true,
      factura: true,
      pagos: true,
      detalles: {
        include: {
          producto: true,
        },
      },
    },
  });

  if (!venta) {
    const error = new Error("La venta indicada no existe.");
    error.status = 404;
    throw error;
  }

  if (venta.estado !== "PAGADA") {
    const error = new Error("Solo se puede generar factura para ventas pagadas.");
    error.status = 409;
    throw error;
  }

  if (venta.factura) {
    const error = new Error("La venta ya tiene una factura generada.");
    error.status = 409;
    error.detalles = [`Factura existente: ${venta.factura.numeroFactura}`];
    throw error;
  }

  if (!venta.cliente) {
    const error = new Error("La venta no tiene cliente asociado.");
    error.status = 409;
    throw error;
  }

  const nombreCliente = `${venta.cliente.nombres} ${venta.cliente.apellidos}`.trim();

  return prisma.factura.create({
    data: {
      ventaId: venta.id,
      numeroFactura: generarNumeroFactura(venta.id),
      nombreCliente,
      cedulaCliente: venta.cliente.cedula,
      subtotal: venta.subtotal,
      impuesto: venta.impuesto,
      total: venta.total,
    },
    include: {
      venta: {
        include: {
          cliente: true,
          detalles: {
            include: {
              producto: {
                include: {
                  marca: true,
                  categoria: true,
                },
              },
            },
          },
          pagos: true,
        },
      },
    },
  });
}

export async function obtenerFacturas() {
  return prisma.factura.findMany({
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

export async function obtenerFacturaPorId(id) {
  const facturaId = convertirId(id);
  const factura = await prisma.factura.findUnique({
    where: { id: facturaId },
    include: {
      venta: {
        include: {
          cliente: true,
          detalles: {
            include: {
              producto: {
                include: {
                  marca: true,
                  categoria: true,
                },
              },
            },
          },
          pagos: true,
        },
      },
    },
  });

  if (!factura) {
    const error = new Error("La factura indicada no existe.");
    error.status = 404;
    throw error;
  }

  return factura;
}
