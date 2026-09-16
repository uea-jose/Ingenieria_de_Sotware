// Reverse geocoding wrapper for Aromas Store.
//
// The frontend never talks to Nominatim directly: it hits our own
// GET /api/ubicacion/reverse endpoint, and this service handles:
//   1. Input validation (lat/lon numbers within valid ranges).
//   2. In-memory caching by 4-decimal-rounded key (~11 m precision)
//      with a 24-hour TTL. Cache is capped in size to avoid unbounded
//      growth during long-lived server processes.
//   3. Global rate limiting to 1 request per second, as required by
//      the Nominatim usage policy.
//   4. A stable, tipado DTO the frontend can consume without ever
//      seeing the raw Nominatim payload:
//        { direccion, ciudad, provincia, pais, latitud, longitud,
//          fuente, atribucion, latitudSolicitada, longitudSolicitada }
//
// Attribution note: cada respuesta incluye `atribucion:"© OpenStreetMap"`
// para que el frontend pueda mostrar la línea de atribución exigida por
// los Términos de Uso de OSM/Nominatim.

const NOMINATIM_URL = "https://nominatim.openstreetmap.org/reverse";
const USER_AGENT = "AromasStore/1.0 (https://github.com/uea-jose/Ingenieria_de_Sotware)";
const CACHE_TTL_MS = 24 * 60 * 60 * 1000; // 24 h
const CACHE_MAX_ENTRIES = 500;
const MIN_REQUEST_INTERVAL_MS = 1000; // Nominatim: <= 1 req/s
const NOMINATIM_TIMEOUT_MS = 8000;

const cache = new Map(); // key -> { expiresAt, data }
let lastRequestAt = 0;
let pendingWait = Promise.resolve();

function toFiniteNumber(value) {
  if (value === undefined || value === null || value === "") return null;
  const n = Number(value);
  return Number.isFinite(n) ? n : null;
}

function validarCoordenadas(lat, lon) {
  const latitud = toFiniteNumber(lat);
  const longitud = toFiniteNumber(lon);

  if (latitud === null || longitud === null) {
    const error = new Error("lat y lon deben ser numeros validos.");
    error.status = 400;
    throw error;
  }

  if (latitud < -90 || latitud > 90) {
    const error = new Error("lat debe estar entre -90 y 90.");
    error.status = 400;
    throw error;
  }

  if (longitud < -180 || longitud > 180) {
    const error = new Error("lon debe estar entre -180 y 180.");
    error.status = 400;
    throw error;
  }

  return { latitud, longitud };
}

function claveCache(lat, lon) {
  // 4 decimales ≈ 11 metros; suficiente para agrupar llamadas del
  // mismo lugar sin explotar el cache.
  return `${lat.toFixed(4)},${lon.toFixed(4)}`;
}

function guardarEnCache(key, data) {
  if (cache.size >= CACHE_MAX_ENTRIES) {
    // FIFO eviction: quita la entrada más antigua.
    const firstKey = cache.keys().next().value;
    if (firstKey) cache.delete(firstKey);
  }
  cache.set(key, { expiresAt: Date.now() + CACHE_TTL_MS, data });
}

function leerDeCache(key) {
  const entry = cache.get(key);
  if (!entry) return null;
  if (entry.expiresAt < Date.now()) {
    cache.delete(key);
    return null;
  }
  return entry.data;
}

// Serial global rate limiter. Encadena las peticiones para que no
// haya más de una por segundo, incluso con múltiples clientes
// llamando al endpoint en paralelo.
async function esperarTurno() {
  const seat = pendingWait.then(async () => {
    const now = Date.now();
    const gap = now - lastRequestAt;
    if (gap < MIN_REQUEST_INTERVAL_MS) {
      await new Promise((r) => setTimeout(r, MIN_REQUEST_INTERVAL_MS - gap));
    }
    lastRequestAt = Date.now();
  });
  pendingWait = seat.catch(() => {});
  return seat;
}

async function llamarNominatim(latitud, longitud) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), NOMINATIM_TIMEOUT_MS);

  const url = new URL(NOMINATIM_URL);
  url.searchParams.set("lat", String(latitud));
  url.searchParams.set("lon", String(longitud));
  url.searchParams.set("format", "jsonv2");
  url.searchParams.set("addressdetails", "1");
  url.searchParams.set("accept-language", "es");

  try {
    const response = await fetch(url, {
      method: "GET",
      headers: {
        "User-Agent": USER_AGENT,
        Accept: "application/json",
      },
      signal: controller.signal,
    });

    if (!response.ok) {
      const error = new Error(
        `Nominatim respondio con HTTP ${response.status}.`,
      );
      error.status = response.status >= 500 ? 502 : 502;
      throw error;
    }

    return await response.json();
  } catch (err) {
    if (err.name === "AbortError") {
      const timeoutError = new Error("Nominatim tardo demasiado en responder.");
      timeoutError.status = 504;
      throw timeoutError;
    }
    if (err.status) throw err;
    const wrapped = new Error(`No se pudo contactar Nominatim: ${err.message}`);
    wrapped.status = 502;
    throw wrapped;
  } finally {
    clearTimeout(timer);
  }
}

function normalizarRespuesta(raw, solicitud) {
  const address = raw?.address ?? {};

  // Prefer más específico → menos específico para "direccion".
  const road =
    address.road ||
    address.pedestrian ||
    address.footway ||
    address.residential ||
    address.path ||
    "";
  const houseNumber = address.house_number ? ` ${address.house_number}` : "";
  const neighbourhood =
    address.neighbourhood ||
    address.suburb ||
    address.quarter ||
    address.city_district ||
    "";

  const direccionArmada = [road + houseNumber, neighbourhood]
    .map((part) => (part || "").trim())
    .filter((part) => part.length > 0)
    .join(", ");

  const ciudad =
    address.city ||
    address.town ||
    address.village ||
    address.municipality ||
    address.county ||
    "";
  const provincia = address.state || address.region || "";
  const pais = address.country || "";

  // Fallback: si el reverse no armó ninguna calle, usamos el
  // display_name recortado antes de la coma para dar al usuario
  // algo con qué empezar (siempre podrá editarlo).
  const direccionFinal =
    direccionArmada ||
    (raw?.display_name ? String(raw.display_name).split(",")[0] : "");

  const latitud =
    toFiniteNumber(raw?.lat) ?? solicitud.latitud;
  const longitud =
    toFiniteNumber(raw?.lon) ?? solicitud.longitud;

  return {
    direccion: direccionFinal,
    ciudad,
    provincia,
    pais,
    latitud,
    longitud,
    latitudSolicitada: solicitud.latitud,
    longitudSolicitada: solicitud.longitud,
    fuente: "nominatim",
    atribucion: "© OpenStreetMap contributors — https://www.openstreetmap.org/copyright",
  };
}

/**
 * Reverse-geocode a lat/lon pair. Returns a stable DTO for the frontend.
 * Thin wrapper around Nominatim + cache + rate limiter.
 */
export async function reverseGeocode({ lat, lon }) {
  const { latitud, longitud } = validarCoordenadas(lat, lon);
  const key = claveCache(latitud, longitud);

  const cached = leerDeCache(key);
  if (cached) {
    return { ...cached, cache: true };
  }

  await esperarTurno();
  const raw = await llamarNominatim(latitud, longitud);
  const dto = normalizarRespuesta(raw, { latitud, longitud });

  guardarEnCache(key, dto);
  return { ...dto, cache: false };
}

// ── Solo para tests ─────────────────────────────────────────────
export function _resetCacheParaTests() {
  cache.clear();
  lastRequestAt = 0;
  pendingWait = Promise.resolve();
}
