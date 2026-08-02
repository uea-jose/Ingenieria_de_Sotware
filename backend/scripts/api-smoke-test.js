const baseUrl = process.env.API_BASE_URL || "http://localhost:3000";

const adminCredentials = {
  correo: process.env.TEST_ADMIN_EMAIL || "admin@aromasstore.com",
  contrasena: process.env.TEST_ADMIN_PASSWORD || "Admin12345",
};

const checks = [];

async function request(path, options = {}) {
  const response = await fetch(`${baseUrl}${path}`, {
    headers: {
      "Content-Type": "application/json",
      ...(options.headers || {}),
    },
    ...options,
  });

  const text = await response.text();
  let body = null;

  if (text) {
    try {
      body = JSON.parse(text);
    } catch {
      body = text;
    }
  }

  if (!response.ok) {
    const message = typeof body === "string" ? body : JSON.stringify(body);
    throw new Error(`${response.status} ${response.statusText}: ${message}`);
  }

  return body;
}

async function check(name, callback) {
  try {
    await callback();
    checks.push({ name, status: "OK" });
    console.log(`OK  ${name}`);
  } catch (error) {
    checks.push({ name, status: "ERROR", error: error.message });
    console.error(`ERR ${name}`);
    console.error(`    ${error.message}`);
  }
}

async function main() {
  console.log(`Probando API en ${baseUrl}`);

  let token = "";

  await check("Sistema activo", async () => {
    await request("/api/health");
  });

  await check("Indice de endpoints", async () => {
    const data = await request("/api");
    if (!Array.isArray(data.endpoints)) {
      throw new Error("La respuesta no incluye listado de endpoints.");
    }
  });

  await check("Swagger JSON", async () => {
    const data = await request("/api/docs.json");
    if (!data.openapi || !data.paths) {
      throw new Error("Swagger no devuelve una especificacion OpenAPI valida.");
    }
  });

  await check("Login administrador JWT", async () => {
    const data = await request("/api/auth/login", {
      method: "POST",
      body: JSON.stringify(adminCredentials),
    });

    if (!data.token) {
      throw new Error("El login no devolvio token.");
    }

    token = data.token;
  });

  const authHeaders = () => ({ Authorization: `Bearer ${token}` });

  await check("Perfil autenticado", async () => {
    await request("/api/auth/me", { headers: authHeaders() });
  });

  await check("Auditoria protegida", async () => {
    const data = await request("/api/auditoria/logs", { headers: authHeaders() });
    if (!Array.isArray(data.datos)) {
      throw new Error("Auditoria no devuelve arreglo de datos.");
    }
  });

  await check("Catalogo de productos", async () => {
    const data = await request("/api/productos");
    if (!Array.isArray(data.datos)) {
      throw new Error("Productos no devuelve arreglo de datos.");
    }
  });

  await check("Categorias", async () => {
    const data = await request("/api/categorias");
    if (!Array.isArray(data.datos)) {
      throw new Error("Categorias no devuelve arreglo de datos.");
    }
  });

  await check("Marcas", async () => {
    const data = await request("/api/marcas");
    if (!Array.isArray(data.datos)) {
      throw new Error("Marcas no devuelve arreglo de datos.");
    }
  });

  await check("Catalogo maestro de acordes", async () => {
    const data = await request("/api/acordes");
    if (!Array.isArray(data.datos) || data.datos.length < 15) {
      throw new Error("Acordes no devuelve el catálogo maestro esperado.");
    }

    if (!data.datos.every((item) => /^#[0-9A-F]{6}$/i.test(item.colorHex))) {
      throw new Error("Uno o más acordes no tienen un color HEX válido.");
    }
  });

  await check("Referencias y perfil maestro", async () => {
    const marcas = await request("/api/marcas");
    const armaf = marcas.datos.find((item) => item.nombre === "Armaf");

    if (!armaf) {
      throw new Error("No se encontró la marca Armaf.");
    }

    const referencias = await request(
      `/api/marcas/${armaf.id}/referencias`,
    );
    const clubDeNuit = referencias.datos.find(
      (item) => item.slug === "club-de-nuit-intense",
    );

    if (!clubDeNuit) {
      throw new Error("No se encontró la referencia Club de Nuit Intense.");
    }

    const perfil = await request(
      `/api/referencias/${clubDeNuit.id}/acordes`,
    );

    if (!Array.isArray(perfil.datos) || perfil.datos.length === 0) {
      throw new Error("La referencia no devuelve su perfil maestro.");
    }
  });

  await check("Perfil editable de producto", async () => {
    const productos = await request("/api/productos");
    const producto = productos.datos[0];

    if (!producto) {
      throw new Error("No existe un producto para consultar.");
    }

    const perfil = await request(`/api/productos/${producto.id}/acordes`);
    if (!Array.isArray(perfil.datos)) {
      throw new Error("El perfil del producto no devuelve un arreglo.");
    }
  });

  await check("Promociones", async () => {
    const data = await request("/api/promociones");
    if (!Array.isArray(data.datos)) {
      throw new Error("Promociones no devuelve arreglo de datos.");
    }
  });

  await check("Validacion de carrito", async () => {
    const data = await request("/api/carrito/validar", {
      method: "POST",
      body: JSON.stringify({
        items: [{ productoId: 1, cantidad: 1 }],
      }),
    });

    if (typeof data.valido !== "boolean") {
      throw new Error("Carrito no devuelve estado valido.");
    }
  });

  await check("Clientes protegidos", async () => {
    await request("/api/clientes", { headers: authHeaders() });
  });

  await check("Ventas protegidas", async () => {
    await request("/api/ventas", { headers: authHeaders() });
  });

  await check("Pagos protegidos", async () => {
    await request("/api/pagos", { headers: authHeaders() });
  });

  await check("Inventario protegido", async () => {
    await request("/api/inventario", { headers: authHeaders() });
  });

  await check("Alertas de inventario", async () => {
    await request("/api/inventario/alertas", { headers: authHeaders() });
  });

  await check("Movimientos de inventario", async () => {
    await request("/api/inventario/movimientos", { headers: authHeaders() });
  });

  await check("Facturas protegidas", async () => {
    await request("/api/facturas", { headers: authHeaders() });
  });

  const failed = checks.filter((item) => item.status === "ERROR");
  console.log("");
  console.log(`Resultado: ${checks.length - failed.length}/${checks.length} pruebas correctas.`);

  if (failed.length > 0) {
    process.exitCode = 1;
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
