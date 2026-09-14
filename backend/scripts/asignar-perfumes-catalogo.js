// One-off migration helper.
//
// Replaces the placeholder products in the local database with real
// fragrances taken from the bundled reference catalog. For each target
// product it updates: nombre, imagenUrl (asset path), genero, and marcaId
// (creating the brand row if it does not exist yet). Idempotent: safe to
// run multiple times.
//
// Run from the backend folder:  node scripts/asignar-perfumes-catalogo.js

import fs from "node:fs";
import path from "node:path";
import prisma from "../src/config/prisma.js";

// ── Configuration ──────────────────────────────────────────────────────────

// Path to the catalog JSON that ships with the frontend assets.
const CATALOG_PATH = path.resolve(
  process.cwd(),
  "..",
  "frontend",
  "assets",
  "perfumery",
  "catalog.json",
);

// Map current product IDs (from your database) → the real fragrance we want
// them to become. `catalogAlias` matches the `name` or `catalogAlias` field
// inside catalog.json; `brand` narrows the match. Add/remove entries here to
// re-run for other products.
const ASSIGNMENTS = [
  {
    productId: 1, // Royal Vanilla   → La Vie Est Belle (Lancome, Mujer)
    catalogName: "La Vie Est Belle",
    catalogBrand: "Lancome",
  },
  {
    productId: 2, // Citrus Bloom    → Acqua Di Gio (Giorgio Armani, Hombre)
    catalogName: "Acqua Di Gio",
    catalogBrand: "Giorgio Armani",
  },
  {
    productId: 3, // Amber Night     → Sauvage (Dior, Hombre)
    catalogName: "Sauvage",
    catalogBrand: "Dior",
  },
  {
    productId: 4, // Vela Lavanda    → Coco Mademoiselle (Chanel, Mujer)
    catalogName: "Coco Mademoiselle",
    catalogBrand: "Chanel",
  },
  {
    productId: 9, // Producto Prueba → Bleu (Chanel, Hombre)
    catalogName: "Bleu",
    catalogBrand: "Chanel",
  },
  {
    productId: 23, // Auditoria      → Good Girl (Carolina Herrera, Mujer)
    catalogName: "Good Girl",
    catalogBrand: "Carolina Herrera",
  },
];

// ── Helpers ────────────────────────────────────────────────────────────────

function normalize(value) {
  return String(value || "")
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, " ")
    .trim();
}

function findReference(catalog, wantedName, wantedBrand) {
  const wName = normalize(wantedName);
  const wBrand = normalize(wantedBrand);
  return catalog.references.find((ref) => {
    const names = [ref.name, ref.catalogAlias].filter(Boolean).map(normalize);
    return names.some((n) => n.includes(wName)) &&
      normalize(ref.brand).includes(wBrand);
  });
}

function mapGender(catalogGender) {
  switch ((catalogGender || "").toLowerCase()) {
    case "masculine":
      return "MASCULINO";
    case "feminine":
      return "FEMENINO";
    default:
      return "UNISEX";
  }
}

async function ensureBrand(brandName) {
  const existing = await prisma.marca.findFirst({
    where: { nombre: brandName },
  });
  if (existing) return existing;
  return prisma.marca.create({
    data: { nombre: brandName, activo: true },
  });
}

// ── Main ───────────────────────────────────────────────────────────────────

async function main() {
  const catalog = JSON.parse(fs.readFileSync(CATALOG_PATH, "utf-8"));
  console.log(
    `Catalogo cargado: ${catalog.references.length} referencias.\n`,
  );

  for (const assignment of ASSIGNMENTS) {
    const ref = findReference(
      catalog,
      assignment.catalogName,
      assignment.catalogBrand,
    );
    if (!ref) {
      console.warn(
        `  ✗ No se encontró "${assignment.catalogName}" (${assignment.catalogBrand}) en el catalogo — se salta producto id=${assignment.productId}.`,
      );
      continue;
    }

    const product = await prisma.producto.findUnique({
      where: { id: assignment.productId },
    });
    if (!product) {
      console.warn(
        `  ✗ Producto id=${assignment.productId} no existe en la BD — se salta.`,
      );
      continue;
    }

    const brand = await ensureBrand(ref.brand);
    const imagenUrl = `assets/perfumery${ref.imagePath}`;
    const genero = mapGender(ref.gender);
    const nombre = ref.name;

    await prisma.producto.update({
      where: { id: product.id },
      data: {
        nombre,
        imagenUrl,
        genero,
        marcaId: brand.id,
      },
    });

    console.log(
      `  ✓ id=${product.id}  "${product.nombre}"  →  "${nombre}"  (${ref.brand}, ${genero})`,
    );
  }

  console.log("\nListo. Recarga la tienda para ver los cambios.");
}

main()
  .catch((error) => {
    console.error("Error:", error);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
