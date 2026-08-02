import "dotenv/config";

import { PrismaClient } from "@prisma/client";
import { PrismaPg } from "@prisma/adapter-pg";

const baseUrl = process.env.API_BASE_URL || "http://localhost:3000";
const adapter = new PrismaPg({
  connectionString: process.env.DATABASE_URL,
});
const prisma = new PrismaClient({ adapter });

let productoTemporalId = null;

async function request(path, options = {}) {
  const response = await fetch(`${baseUrl}${path}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...(options.headers || {}),
    },
  });
  const body = await response.json();

  if (!response.ok) {
    throw new Error(`${response.status}: ${JSON.stringify(body)}`);
  }

  return body;
}

function verificar(condicion, mensaje) {
  if (!condicion) {
    throw new Error(mensaje);
  }
}

async function limpiarProductoTemporal() {
  if (!productoTemporalId) return;

  await prisma.$transaction([
    prisma.inventario.deleteMany({
      where: { productoId: productoTemporalId },
    }),
    prisma.producto.deleteMany({
      where: { id: productoTemporalId },
    }),
  ]);
}

async function main() {
  const login = await request("/api/auth/login", {
    method: "POST",
    body: JSON.stringify({
      correo: process.env.TEST_ADMIN_EMAIL || "admin@aromasstore.com",
      contrasena: process.env.TEST_ADMIN_PASSWORD || "Admin12345",
    }),
  });
  const headers = { Authorization: `Bearer ${login.token}` };
  const [marcas, categorias] = await Promise.all([
    request("/api/marcas"),
    request("/api/categorias"),
  ]);
  const armaf = marcas.datos.find((item) => item.nombre === "Armaf");
  const perfumes = categorias.datos.find((item) => item.nombre === "Perfumes");

  verificar(armaf, "No se encontró Armaf.");
  verificar(perfumes, "No se encontró la categoría Perfumes.");

  const referencias = await request(`/api/marcas/${armaf.id}/referencias`);
  const referencia = referencias.datos.find(
    (item) => item.slug === "club-de-nuit-intense",
  );

  verificar(referencia, "No se encontró Club de Nuit Intense.");

  const codigo = `TEST-ACORDES-${Date.now()}`;
  const creado = await request("/api/productos", {
    method: "POST",
    headers,
    body: JSON.stringify({
      nombre: "Producto temporal de acordes",
      codigo,
      descripcion: "Se elimina al terminar la prueba.",
      precio: 1,
      volumenMl: 1,
      categoriaId: perfumes.id,
      marcaId: armaf.id,
      referenciaId: referencia.id,
      stock: 0,
      stockMinimo: 0,
    }),
  });

  productoTemporalId = creado.dato.id;

  const perfilCopiado = await request(
    `/api/productos/${productoTemporalId}/acordes`,
  );
  verificar(
    perfilCopiado.datos.length === 5,
    "El perfil maestro no se copió al crear el producto.",
  );

  const seleccion = perfilCopiado.datos.slice(0, 3);
  const guardado = await request(
    `/api/productos/${productoTemporalId}/acordes`,
    {
      method: "PUT",
      headers,
      body: JSON.stringify({
        acordes: [
          { acordeId: seleccion[0].acorde.id, intensidad: 50 },
          { acordeId: seleccion[1].acorde.id, intensidad: 90 },
          { acordeId: seleccion[2].acorde.id, intensidad: 50 },
        ],
      }),
    },
  );

  verificar(
    guardado.datos.map((item) => item.intensidad).join(",") === "90,50,50",
    "El perfil no se ordenó por intensidad descendente.",
  );
  verificar(
    guardado.datos.map((item) => item.ordenVisual).join(",") === "1,2,3",
    "ordenVisual no se recalculó consecutivamente.",
  );
  verificar(
    guardado.datos[1].acorde.id === seleccion[0].acorde.id &&
      guardado.datos[2].acorde.id === seleccion[2].acorde.id,
    "El empate no conservó el orden relativo recibido.",
  );

  const restaurado = await request(
    `/api/productos/${productoTemporalId}/restaurar-acordes`,
    {
      method: "POST",
      headers,
      body: "{}",
    },
  );

  verificar(
    restaurado.datos.length === perfilCopiado.datos.length,
    "La restauración no recuperó el perfil maestro.",
  );

  console.log("OK  Copia automática del perfil maestro");
  console.log("OK  Orden descendente y empate estable");
  console.log("OK  ordenVisual consecutivo");
  console.log("OK  Restauración del perfil maestro");
}

main()
  .catch((error) => {
    console.error(`ERROR ${error.message}`);
    process.exitCode = 1;
  })
  .finally(async () => {
    await limpiarProductoTemporal();
    await prisma.$disconnect();
  });
