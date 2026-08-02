import prisma from "../../config/prisma.js";

export async function obtenerAcordes() {
  return prisma.acorde.findMany({
    where: { activo: true },
    orderBy: [{ nombre: "asc" }, { id: "asc" }],
    select: {
      id: true,
      nombre: true,
      slug: true,
      colorHex: true,
      colorTextoHex: true,
      origenColor: true,
      alias: true,
      activo: true,
    },
  });
}
