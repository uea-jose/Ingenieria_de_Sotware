-- CreateTable
CREATE TABLE IF NOT EXISTS "auditoria_logs" (
    "id" SERIAL NOT NULL,
    "fecha" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "path" VARCHAR(255) NOT NULL,
    "metodo" VARCHAR(10) NOT NULL,
    "datoIngreso" JSONB,
    "datoRespuesta" JSONB,
    "traceId" VARCHAR(80) NOT NULL,
    "guidSesion" VARCHAR(80) NOT NULL,
    "usuarioId" INTEGER,
    "clienteId" INTEGER,
    "ventaId" INTEGER,
    "productoId" INTEGER,
    "estadoHttp" INTEGER,
    "duracionMs" INTEGER,
    "resultado" VARCHAR(40) NOT NULL,
    "codigoRespuesta" VARCHAR(80),
    "mensajeRespuesta" VARCHAR(255),

    CONSTRAINT "auditoria_logs_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX IF NOT EXISTS "auditoria_logs_traceId_idx" ON "auditoria_logs"("traceId");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "auditoria_logs_guidSesion_idx" ON "auditoria_logs"("guidSesion");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "auditoria_logs_usuarioId_idx" ON "auditoria_logs"("usuarioId");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "auditoria_logs_clienteId_idx" ON "auditoria_logs"("clienteId");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "auditoria_logs_ventaId_idx" ON "auditoria_logs"("ventaId");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "auditoria_logs_productoId_idx" ON "auditoria_logs"("productoId");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "auditoria_logs_path_idx" ON "auditoria_logs"("path");
