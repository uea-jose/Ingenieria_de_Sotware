-- CreateEnum
CREATE TYPE "GeneroPerfume" AS ENUM ('MASCULINO', 'FEMENINO', 'UNISEX');

-- CreateEnum
CREATE TYPE "SegmentoReferencia" AS ENUM ('DISENADOR', 'NICHO');

-- CreateEnum
CREATE TYPE "EstadoPublicacion" AS ENUM ('BORRADOR', 'PUBLICADO', 'OCULTO');

-- CreateEnum
CREATE TYPE "DisponibilidadProducto" AS ENUM ('DISPONIBLE', 'STOCK_BAJO', 'AGOTADO', 'BAJO_PEDIDO');

-- AlterTable
ALTER TABLE "productos" ADD COLUMN     "acordesCopiadosEn" TIMESTAMP(3),
ADD COLUMN     "descripcionCorta" VARCHAR(280),
ADD COLUMN     "destacado" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "disponibilidad" "DisponibilidadProducto" NOT NULL DEFAULT 'DISPONIBLE',
ADD COLUMN     "estadoPublicacion" "EstadoPublicacion" NOT NULL DEFAULT 'BORRADOR',
ADD COLUMN     "referenciaId" INTEGER,
ADD COLUMN     "slug" VARCHAR(180),
ADD COLUMN     "versionPerfilReferenciaCopiado" INTEGER NOT NULL DEFAULT 1;

-- CreateTable
CREATE TABLE "acordes" (
    "id" SERIAL NOT NULL,
    "nombre" VARCHAR(100) NOT NULL,
    "slug" VARCHAR(120) NOT NULL,
    "colorHex" CHAR(7) NOT NULL,
    "colorTextoHex" CHAR(7) NOT NULL DEFAULT '#111111',
    "origenColor" VARCHAR(80) NOT NULL DEFAULT 'catalogo_maestro',
    "alias" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "activo" BOOLEAN NOT NULL DEFAULT true,
    "creadoEn" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actualizadoEn" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "acordes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "referencias_perfume" (
    "id" SERIAL NOT NULL,
    "marcaId" INTEGER NOT NULL,
    "nombre" VARCHAR(180) NOT NULL,
    "slug" VARCHAR(180) NOT NULL,
    "genero" "GeneroPerfume" NOT NULL,
    "segmento" "SegmentoReferencia" NOT NULL DEFAULT 'DISENADOR',
    "aliasCatalogo" VARCHAR(180),
    "catalogoFuente" VARCHAR(255),
    "paginaFuente" INTEGER,
    "entradaFuente" INTEGER,
    "versionPerfil" INTEGER NOT NULL DEFAULT 1,
    "perfilActualizadoEn" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "activo" BOOLEAN NOT NULL DEFAULT true,
    "creadoEn" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actualizadoEn" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "referencias_perfume_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "referencias_perfume_acordes" (
    "referenciaId" INTEGER NOT NULL,
    "acordeId" INTEGER NOT NULL,
    "intensidad" SMALLINT NOT NULL,
    "ordenVisual" SMALLINT NOT NULL,
    "metodoFuente" VARCHAR(80) NOT NULL DEFAULT 'estimacion_visual_catalogo',
    "confianza" DECIMAL(3,2) NOT NULL DEFAULT 0.75,
    "creadoEn" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actualizadoEn" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "referencias_perfume_acordes_pkey" PRIMARY KEY ("referenciaId","acordeId")
);

-- CreateTable
CREATE TABLE "productos_acordes" (
    "productoId" INTEGER NOT NULL,
    "acordeId" INTEGER NOT NULL,
    "intensidad" SMALLINT NOT NULL,
    "ordenVisual" SMALLINT NOT NULL,
    "copiadoDeReferencia" BOOLEAN NOT NULL DEFAULT true,
    "creadoEn" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actualizadoEn" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "productos_acordes_pkey" PRIMARY KEY ("productoId","acordeId")
);

-- CreateTable
CREATE TABLE "presentaciones_producto" (
    "id" SERIAL NOT NULL,
    "productoId" INTEGER NOT NULL,
    "etiqueta" VARCHAR(120) NOT NULL,
    "volumenMl" DECIMAL(7,2),
    "precio" DECIMAL(12,2) NOT NULL,
    "precioPromocional" DECIMAL(12,2),
    "moneda" CHAR(3) NOT NULL DEFAULT 'COP',
    "principal" BOOLEAN NOT NULL DEFAULT false,
    "activo" BOOLEAN NOT NULL DEFAULT true,
    "creadoEn" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actualizadoEn" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "presentaciones_producto_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "imagenes_producto" (
    "id" SERIAL NOT NULL,
    "productoId" INTEGER NOT NULL,
    "rutaStorage" VARCHAR(500) NOT NULL,
    "textoAlternativo" VARCHAR(240) NOT NULL,
    "ordenVisual" SMALLINT NOT NULL,
    "principal" BOOLEAN NOT NULL DEFAULT false,
    "activo" BOOLEAN NOT NULL DEFAULT true,
    "creadoEn" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actualizadoEn" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "imagenes_producto_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "acordes_nombre_key" ON "acordes"("nombre");

-- CreateIndex
CREATE UNIQUE INDEX "acordes_slug_key" ON "acordes"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "referencias_perfume_slug_key" ON "referencias_perfume"("slug");

-- CreateIndex
CREATE INDEX "referencias_perfume_marcaId_activo_genero_idx" ON "referencias_perfume"("marcaId", "activo", "genero");

-- CreateIndex
CREATE UNIQUE INDEX "referencias_perfume_marcaId_nombre_key" ON "referencias_perfume"("marcaId", "nombre");

-- CreateIndex
CREATE INDEX "referencias_perfume_acordes_acordeId_intensidad_idx" ON "referencias_perfume_acordes"("acordeId", "intensidad");

-- CreateIndex
CREATE UNIQUE INDEX "referencias_perfume_acordes_referenciaId_ordenVisual_key" ON "referencias_perfume_acordes"("referenciaId", "ordenVisual");

-- CreateIndex
CREATE INDEX "productos_acordes_acordeId_intensidad_idx" ON "productos_acordes"("acordeId", "intensidad");

-- CreateIndex
CREATE UNIQUE INDEX "productos_acordes_productoId_ordenVisual_key" ON "productos_acordes"("productoId", "ordenVisual");

-- CreateIndex
CREATE INDEX "presentaciones_producto_productoId_activo_idx" ON "presentaciones_producto"("productoId", "activo");

-- CreateIndex
CREATE UNIQUE INDEX "presentaciones_producto_productoId_etiqueta_key" ON "presentaciones_producto"("productoId", "etiqueta");

-- CreateIndex
CREATE UNIQUE INDEX "imagenes_producto_rutaStorage_key" ON "imagenes_producto"("rutaStorage");

-- CreateIndex
CREATE INDEX "imagenes_producto_productoId_activo_ordenVisual_idx" ON "imagenes_producto"("productoId", "activo", "ordenVisual");

-- CreateIndex
CREATE UNIQUE INDEX "imagenes_producto_productoId_ordenVisual_key" ON "imagenes_producto"("productoId", "ordenVisual");

-- CreateIndex
CREATE UNIQUE INDEX "productos_slug_key" ON "productos"("slug");

-- CreateIndex
CREATE INDEX "productos_referenciaId_idx" ON "productos"("referenciaId");

-- CreateIndex
CREATE INDEX "productos_estadoPublicacion_disponibilidad_destacado_idx" ON "productos"("estadoPublicacion", "disponibilidad", "destacado");

-- AddForeignKey
ALTER TABLE "productos" ADD CONSTRAINT "productos_referenciaId_fkey" FOREIGN KEY ("referenciaId") REFERENCES "referencias_perfume"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "referencias_perfume" ADD CONSTRAINT "referencias_perfume_marcaId_fkey" FOREIGN KEY ("marcaId") REFERENCES "marcas"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "referencias_perfume_acordes" ADD CONSTRAINT "referencias_perfume_acordes_referenciaId_fkey" FOREIGN KEY ("referenciaId") REFERENCES "referencias_perfume"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "referencias_perfume_acordes" ADD CONSTRAINT "referencias_perfume_acordes_acordeId_fkey" FOREIGN KEY ("acordeId") REFERENCES "acordes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "productos_acordes" ADD CONSTRAINT "productos_acordes_productoId_fkey" FOREIGN KEY ("productoId") REFERENCES "productos"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "productos_acordes" ADD CONSTRAINT "productos_acordes_acordeId_fkey" FOREIGN KEY ("acordeId") REFERENCES "acordes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "presentaciones_producto" ADD CONSTRAINT "presentaciones_producto_productoId_fkey" FOREIGN KEY ("productoId") REFERENCES "productos"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "imagenes_producto" ADD CONSTRAINT "imagenes_producto_productoId_fkey" FOREIGN KEY ("productoId") REFERENCES "productos"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Restricciones de dominio que Prisma no representa en el esquema.
ALTER TABLE "acordes"
ADD CONSTRAINT "acordes_colorHex_formato" CHECK ("colorHex" ~ '^#[0-9A-Fa-f]{6}$'),
ADD CONSTRAINT "acordes_colorTextoHex_formato" CHECK ("colorTextoHex" ~ '^#[0-9A-Fa-f]{6}$');

ALTER TABLE "referencias_perfume"
ADD CONSTRAINT "referencias_perfume_version_positiva" CHECK ("versionPerfil" > 0),
ADD CONSTRAINT "referencias_perfume_pagina_positiva" CHECK ("paginaFuente" IS NULL OR "paginaFuente" > 0),
ADD CONSTRAINT "referencias_perfume_entrada_positiva" CHECK ("entradaFuente" IS NULL OR "entradaFuente" > 0);

ALTER TABLE "referencias_perfume_acordes"
ADD CONSTRAINT "referencias_perfume_acordes_intensidad_rango" CHECK ("intensidad" BETWEEN 1 AND 100),
ADD CONSTRAINT "referencias_perfume_acordes_orden_positivo" CHECK ("ordenVisual" > 0),
ADD CONSTRAINT "referencias_perfume_acordes_confianza_rango" CHECK ("confianza" BETWEEN 0 AND 1);

ALTER TABLE "productos_acordes"
ADD CONSTRAINT "productos_acordes_intensidad_rango" CHECK ("intensidad" BETWEEN 1 AND 100),
ADD CONSTRAINT "productos_acordes_orden_positivo" CHECK ("ordenVisual" > 0);

ALTER TABLE "presentaciones_producto"
ADD CONSTRAINT "presentaciones_producto_volumen_positivo" CHECK ("volumenMl" IS NULL OR "volumenMl" > 0),
ADD CONSTRAINT "presentaciones_producto_precio_positivo" CHECK ("precio" > 0),
ADD CONSTRAINT "presentaciones_producto_precio_promocional_valido"
CHECK (
  "precioPromocional" IS NULL
  OR ("precioPromocional" > 0 AND "precioPromocional" < "precio")
);

ALTER TABLE "imagenes_producto"
ADD CONSTRAINT "imagenes_producto_orden_positivo" CHECK ("ordenVisual" > 0),
ADD CONSTRAINT "imagenes_producto_ruta_relativa"
CHECK ("rutaStorage" !~* '^https?://' AND "rutaStorage" !~ '^/');

CREATE UNIQUE INDEX "presentaciones_producto_una_principal_idx"
ON "presentaciones_producto" ("productoId")
WHERE "principal" AND "activo";

CREATE UNIQUE INDEX "imagenes_producto_una_principal_idx"
ON "imagenes_producto" ("productoId")
WHERE "principal" AND "activo";
