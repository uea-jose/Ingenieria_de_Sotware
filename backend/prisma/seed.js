import "dotenv/config";

import { PrismaClient } from "@prisma/client";
import { PrismaPg } from "@prisma/adapter-pg";
import bcrypt from "bcrypt";

const adapter = new PrismaPg({
  connectionString: process.env.DATABASE_URL,
});

const prisma = new PrismaClient({ adapter });

async function seedRoles() {
  const roles = {};

  const rolesData = [
    {
      nombre: "Administrador",
      descripcion: "Gestiona usuarios, catalogo, inventario y reportes.",
    },
    {
      nombre: "Vendedor",
      descripcion: "Registra clientes, ventas, pagos y facturas.",
    },
    {
      nombre: "Bodeguero",
      descripcion: "Controla stock, ubicaciones y reposicion de productos.",
    },
    {
      nombre: "Cliente",
      descripcion: "Compra perfumes, consulta catalogo y gestiona sus pedidos.",
    },
  ];

  for (const rol of rolesData) {
    roles[rol.nombre] = await prisma.rol.upsert({
      where: { nombre: rol.nombre },
      update: rol,
      create: rol,
    });
  }

  return roles;
}

async function seedUsuarios(roles) {
  const contrasenaHash = await bcrypt.hash("Admin12345", 10);

  await prisma.usuario.upsert({
    where: { correo: "admin@aromasstore.com" },
    update: {
      nombres: "Administrador",
      apellidos: "Aromas Store",
      contrasenaHash,
      activo: true,
      rolId: roles.Administrador.id,
    },
    create: {
      nombres: "Administrador",
      apellidos: "Aromas Store",
      correo: "admin@aromasstore.com",
      contrasenaHash,
      activo: true,
      rolId: roles.Administrador.id,
    },
  });
}

async function seedCategorias() {
  const categorias = {};

  const categoriasData = [
    {
      nombre: "Perfumes",
      descripcion: "Fragancias personales en presentacion liquida.",
    },
    {
      nombre: "Esencias",
      descripcion: "Concentrados aromaticos para uso personal o ambiental.",
    },
    {
      nombre: "Aceites",
      descripcion: "Aceites aromaticos y cosmeticos.",
    },
    {
      nombre: "Velas aromaticas",
      descripcion: "Velas decorativas con fragancia para espacios interiores.",
    },
    {
      nombre: "Difusores",
      descripcion: "Productos para aromatizar ambientes.",
    },
    {
      nombre: "Sets de regalo",
      descripcion: "Combos y presentaciones especiales.",
    },
  ];

  for (const categoria of categoriasData) {
    categorias[categoria.nombre] = await prisma.categoria.upsert({
      where: { nombre: categoria.nombre },
      update: { ...categoria, activo: true },
      create: { ...categoria, activo: true },
    });
  }

  return categorias;
}

async function seedMarcas() {
  const marcas = {};

  const marcasData = [
    ["Aromas Store", "Ecuador", "Marca propia de la tienda."],
    ["Eau Royal", "Ecuador", "Linea premium ficticia del proyecto."],
    ["Paco Rabanne", "Espana", "Casa de moda y fragancias de lujo."],
    ["Carolina Herrera", "Estados Unidos", "Marca de moda y perfumeria."],
    ["Lacoste", "Francia", "Marca francesa de moda y fragancias."],
    ["Victoria's Secret", "Estados Unidos", "Marca de belleza y cuidado personal."],
    ["Bvlgari", "Italia", "Casa italiana de lujo y fragancias."],
    ["Valentino", "Italia", "Casa de moda reconocida por fragancias como Born in Roma."],
    ["Jean Paul Gaultier", "Francia", "Casa francesa de moda y perfumeria."],
    ["Armaf", "Emiratos Arabes Unidos", "Marca conocida por fragancias arabes y clones populares."],
    ["Giorgio Armani", "Italia", "Casa italiana de moda y fragancias."],
    ["Arabiyat", "Emiratos Arabes Unidos", "Marca de perfumeria arabe."],
    ["Hugo Boss", "Alemania", "Marca alemana de moda y fragancias."],
    ["Lolita Lempicka", "Francia", "Marca francesa de fragancias."],
    ["Yves Saint Laurent", "Francia", "Casa francesa de lujo y perfumeria."],
    ["Chanel", "Francia", "Casa francesa de lujo y fragancias."],
    ["Lancôme", "Francia", "Casa francesa de perfumeria y cosmetica."],
    ["Afnan", "Emiratos Arabes Unidos", "Casa de perfumeria oriental."],
    ["Al Haramain", "Emiratos Arabes Unidos", "Casa de perfumeria arabe."],
    ["Antonio Banderas", "Espana", "Linea de fragancias del actor y diseñador."],
    ["Calvin Klein", "Estados Unidos", "Casa de moda y fragancias."],
    ["Dior", "Francia", "Casa francesa de lujo y perfumeria."],
    ["Initio", "Francia", "Casa de perfumeria de nicho."],
    ["Katy Perry", "Estados Unidos", "Linea de fragancias de celebridad."],
    ["Lattafa", "Emiratos Arabes Unidos", "Casa de perfumeria arabe."],
    ["Mancera", "Francia", "Casa de perfumeria de nicho."],
    ["Montale", "Francia", "Casa de perfumeria de nicho."],
    ["Montblanc", "Alemania", "Marca de lujo y fragancias."],
    ["Paris Hilton", "Estados Unidos", "Linea de fragancias de celebridad."],
    ["Britney Spears", "Estados Unidos", "Linea de fragancias de celebridad."],
    ["Tiziana Terenzi", "Italia", "Casa italiana de perfumeria de nicho."],
  ];

  for (const [nombre, paisOrigen, descripcion] of marcasData) {
    const marca = { nombre, paisOrigen, descripcion, activo: true };

    marcas[nombre] = await prisma.marca.upsert({
      where: { nombre },
      update: marca,
      create: marca,
    });
  }

  return marcas;
}

async function seedAcordes() {
  const acordes = {};
  const acordesData = [
    ["Acuático", "acuatico", "#45C5D8", "#111111"],
    ["Afrutado", "afrutado", "#FF4A2F", "#111111"],
    ["Ahumado", "ahumado", "#827487", "#000000"],
    ["Almizclado", "almizclado", "#B4A8C7", "#111111"],
    ["Animálico", "animalico", "#76513D", "#FFFFFF"],
    ["Amaderado", "amaderado", "#8A4B13", "#FFFFFF"],
    ["Ámbar", "ambar", "#C05519", "#FFFFFF"],
    ["Aromático", "aromatico", "#129E91", "#111111"],
    ["Atalcado", "atalcado", "#E8D8C5", "#111111"],
    ["Café", "cafe", "#6F3A24", "#FFFFFF"],
    ["Canela", "canela", "#D56310", "#111111"],
    ["Cuero", "cuero", "#684137", "#FFFFFF"],
    ["Cítrico", "citrico", "#F4F83C", "#111111"],
    ["Dulce", "dulce", "#EF3942", "#FFFFFF"],
    ["Especiado cálido", "especiado-calido", "#D74325", "#FFFFFF"],
    ["Floral", "floral", "#F54C8B", "#111111"],
    ["Floral blanco", "floral-blanco", "#EAF1F9", "#111111"],
    ["Fresco", "fresco", "#63D7DF", "#111111"],
    ["Fresco especiado", "fresco-especiado", "#60CB00", "#111111"],
    ["Marino", "marino", "#155EC7", "#FFFFFF"],
    ["Metálico", "metalico", "#9CB1B8", "#111111"],
    ["Miel", "miel", "#EBAF17", "#111111"],
    ["Nardo", "nardo", "#DDF5EA", "#111111"],
    ["Oud", "oud", "#6B364E", "#FFFFFF"],
    ["Ron", "ron", "#B52216", "#FFFFFF"],
    ["Verde", "verde", "#07870A", "#FFFFFF"],
    ["Vodka", "vodka", "#F2F6F5", "#111111"],
    ["Amargo", "amargo", "#C0E741", "#111111"],
    ["Iris", "iris", "#B7A7D7", "#111111"],
    ["Violeta", "violeta", "#9C1DFF", "#FFFFFF"],
    ["Musgoso", "musgoso", "#5B6B32", "#FFFFFF"],
    ["Tropical", "tropical", "#F6AF09", "#111111"],
    ["Lavanda", "lavanda", "#9B7DB8", "#111111"],
    ["Jabonoso", "jabonoso", "#E3F6FC", "#111111"],
    ["Floral amarillo", "floral-amarillo", "#FFDC10", "#111111"],
    ["Pachulí", "pachuli", "#63652E", "#FFFFFF"],
    ["Lactónico", "lactonico", "#FBF9F2", "#111111"],
    ["Terrosos", "terrosos", "#544838", "#FFFFFF"],
    ["Herbal", "herbal", "#6CA47F", "#111111"],
    ["Avainillado", "avainillado", "#FFFEC0", "#111111"],
    ["Rosas", "rosas", "#FE016B", "#111111"],
  ];

  for (const [nombre, slug, colorHex, colorTextoHex] of acordesData) {
    acordes[slug] = await prisma.acorde.upsert({
      where: { slug },
      update: {
        nombre,
        colorHex,
        colorTextoHex,
        origenColor: "catalogo_maestro",
        activo: true,
      },
      create: {
        nombre,
        slug,
        colorHex,
        colorTextoHex,
        origenColor: "catalogo_maestro",
        activo: true,
      },
    });
  }

  return acordes;
}

async function seedReferencias(marcas, acordes) {
  const referencias = [
    {
      marca: "Carolina Herrera", nombre: "212 VIP Men", slug: "212-vip-men",
      genero: "MASCULINO", segmento: "DISENADOR", aliasCatalogo: "VICARO",
      catalogoFuente: "CATALOGO_PERFUMERIA-masculina.pdf", paginaFuente: 2, entradaFuente: 1,
      perfil: [
        ["fresco-especiado", 100], ["aromatico", 93], ["vodka", 89],
        ["amaderado", 80], ["verde", 75],
      ],
    },
    {
      marca: "Giorgio Armani", nombre: "Acqua Di Gio", slug: "acqua-di-gio",
      genero: "MASCULINO", segmento: "DISENADOR", aliasCatalogo: "ACQUA FRESCA",
      catalogoFuente: "CATALOGO_PERFUMERIA-masculina.pdf", paginaFuente: 2, entradaFuente: 2,
      perfil: [
        ["citrico", 100], ["aromatico", 70], ["marino", 63],
        ["fresco-especiado", 56], ["floral", 53],
      ],
    },
    {
      marca: "Antonio Banderas", nombre: "Blue Seduction", slug: "blue-seduction",
      genero: "MASCULINO", segmento: "DISENADOR", aliasCatalogo: "SENDOA",
      catalogoFuente: "CATALOGO_PERFUMERIA-masculina.pdf", paginaFuente: 2, entradaFuente: 3,
      perfil: [
        ["aromatico", 100], ["afrutado", 90], ["marino", 88],
        ["acuatico", 86], ["fresco-especiado", 75],
      ],
    },
    {
      marca: "Chanel", nombre: "Bleu", slug: "bleu",
      genero: "MASCULINO", segmento: "DISENADOR", aliasCatalogo: "BLUNEL",
      catalogoFuente: "CATALOGO_PERFUMERIA-masculina.pdf", paginaFuente: 2, entradaFuente: 4,
      perfil: [
        ["citrico", 100], ["amaderado", 83], ["fresco-especiado", 83],
        ["aromatico", 74], ["ambar", 70],
      ],
    },
    {
      marca: "Hugo Boss", nombre: "Boss Bottled", slug: "boss-bottled",
      genero: "MASCULINO", segmento: "DISENADOR", aliasCatalogo: "BRANDON",
      catalogoFuente: "CATALOGO_PERFUMERIA-masculina.pdf", paginaFuente: 2, entradaFuente: 5,
      perfil: [
        ["amaderado", 100], ["afrutado", 92], ["avainillado", 83],
        ["especiado-calido", 82], ["canela", 73],
      ],
    },
    {
      marca: "Carolina Herrera", nombre: "212 Men", slug: "212-men",
      genero: "MASCULINO", segmento: "DISENADOR", aliasCatalogo: "ADRIAN",
      catalogoFuente: "CATALOGO_PERFUMERIA-masculina.pdf", paginaFuente: 2, entradaFuente: 6,
      perfil: [
        ["citrico", 100], ["verde", 92], ["fresco-especiado", 84],
        ["aromatico", 78], ["amaderado", 75],
      ],
    },
    {
      marca: "Hugo Boss", nombre: "Hugo Red", slug: "hugo-red",
      genero: "MASCULINO", segmento: "DISENADOR", aliasCatalogo: "BOSMAN RED",
      catalogoFuente: "CATALOGO_PERFUMERIA-masculina.pdf", paginaFuente: 2, entradaFuente: 7,
      perfil: [
        ["afrutado", 100], ["dulce", 89], ["verde", 81],
        ["aromatico", 80], ["metalico", 79],
      ],
    },
    {
      marca: "Paco Rabanne", nombre: "Invictus", slug: "invictus",
      genero: "MASCULINO", segmento: "DISENADOR", aliasCatalogo: "INVICTO II",
      catalogoFuente: "CATALOGO_PERFUMERIA-masculina.pdf", paginaFuente: 2, entradaFuente: 8,
      perfil: [
        ["citrico", 100], ["marino", 87], ["aromatico", 85],
        ["fresco-especiado", 73], ["amaderado", 65],
      ],
    },
    {
      marca: "Jean Paul Gaultier", nombre: "Ultra Male", slug: "ultra-male",
      genero: "MASCULINO", segmento: "DISENADOR", aliasCatalogo: "ULTRAMAN",
      catalogoFuente: "CATALOGO_PERFUMERIA-masculina.pdf", paginaFuente: 3, entradaFuente: 9,
      perfil: [
        ["avainillado", 100], ["afrutado", 83], ["dulce", 82],
        ["aromatico", 80], ["canela", 74],
      ],
    },
    {
      marca: "Montblanc", nombre: "Legend", slug: "legend",
      genero: "MASCULINO", segmento: "DISENADOR", aliasCatalogo: "LEGADO",
      catalogoFuente: "CATALOGO_PERFUMERIA-masculina.pdf", paginaFuente: 3, entradaFuente: 10,
      perfil: [
        ["afrutado", 100], ["dulce", 93], ["aromatico", 84],
        ["lavanda", 77], ["fresco-especiado", 74],
      ],
    },
    {
      marca: "Carolina Herrera", nombre: "212 VIP", slug: "212-vip",
      genero: "FEMENINO", segmento: "DISENADOR", aliasCatalogo: "CAROLA",
      catalogoFuente: "CATALOGO PERFUMERIA FEMENINA.pdf", paginaFuente: 2, entradaFuente: 1,
      perfil: [
        ["avainillado", 100], ["ron", 88], ["dulce", 88],
        ["tropical", 70], ["afrutado", 66],
      ],
    },
    {
      marca: "Carolina Herrera", nombre: "212 VIP Rosé", slug: "212-vip-rose",
      genero: "FEMENINO", segmento: "DISENADOR", aliasCatalogo: "CAROLA ROSE",
      catalogoFuente: "CATALOGO PERFUMERIA FEMENINA.pdf", paginaFuente: 2, entradaFuente: 2,
      perfil: [
        ["floral", 100], ["almizclado", 80], ["afrutado", 70],
        ["amaderado", 70], ["atalcado", 58],
      ],
    },
    {
      marca: "Carolina Herrera", nombre: "Carolina Herrera", slug: "carolina-herrera",
      genero: "FEMENINO", segmento: "DISENADOR", aliasCatalogo: "CAROL",
      catalogoFuente: "CATALOGO PERFUMERIA FEMENINA.pdf", paginaFuente: 2, entradaFuente: 3,
      perfil: [
        ["floral-blanco", 100], ["nardo", 64], ["verde", 63],
        ["animalico", 61], ["amaderado", 58],
      ],
    },
    {
      marca: "Carolina Herrera", nombre: "Good Girl", slug: "good-girl",
      genero: "FEMENINO", segmento: "DISENADOR", aliasCatalogo: "GODINA",
      catalogoFuente: "CATALOGO PERFUMERIA FEMENINA.pdf", paginaFuente: 2, entradaFuente: 4,
      perfil: [
        ["dulce", 100], ["floral-blanco", 99], ["especiado-calido", 94],
        ["avainillado", 93], ["ambar", 73],
      ],
    },
    {
      marca: "Paris Hilton", nombre: "Can Can", slug: "can-can",
      genero: "FEMENINO", segmento: "DISENADOR", aliasCatalogo: "MUSIC HALL",
      catalogoFuente: "CATALOGO PERFUMERIA FEMENINA.pdf", paginaFuente: 2, entradaFuente: 5,
      perfil: [
        ["afrutado", 100], ["dulce", 85], ["ambar", 80],
        ["atalcado", 73], ["citrico", 72],
      ],
    },
    {
      marca: "Britney Spears", nombre: "Fantasy", slug: "fantasy",
      genero: "FEMENINO", segmento: "DISENADOR", aliasCatalogo: "FANTAZIA",
      catalogoFuente: "CATALOGO PERFUMERIA FEMENINA.pdf", paginaFuente: 2, entradaFuente: 6,
      perfil: [
        ["dulce", 100], ["afrutado", 78], ["tropical", 61],
        ["fresco", 57], ["cafe", 53],
      ],
    },
    {
      marca: "Dior", nombre: "J'adore", slug: "jadore",
      genero: "FEMENINO", segmento: "DISENADOR", aliasCatalogo: "DIORE",
      catalogoFuente: "CATALOGO PERFUMERIA FEMENINA.pdf", paginaFuente: 2, entradaFuente: 7,
      perfil: [
        ["floral-blanco", 100], ["floral", 88], ["afrutado", 84],
        ["dulce", 69], ["fresco", 68],
      ],
    },
    {
      marca: "Paco Rabanne", nombre: "Lady Million", slug: "lady-million",
      genero: "FEMENINO", segmento: "DISENADOR", aliasCatalogo: "GOLD",
      catalogoFuente: "CATALOGO PERFUMERIA FEMENINA.pdf", paginaFuente: 2, entradaFuente: 8,
      perfil: [
        ["floral-blanco", 100], ["dulce", 78], ["miel", 75],
        ["citrico", 66], ["afrutado", 64],
      ],
    },
    {
      marca: "Lancôme", nombre: "La Vie Est Belle", slug: "la-vie-est-belle",
      genero: "FEMENINO", segmento: "DISENADOR", aliasCatalogo: "BELLE EPOQUE",
      catalogoFuente: "CATALOGO PERFUMERIA FEMENINA.pdf", paginaFuente: 3, entradaFuente: 9,
      perfil: [
        ["dulce", 100], ["avainillado", 84], ["afrutado", 70],
        ["pachuli", 64], ["amaderado", 63],
      ],
    },
    {
      marca: "Katy Perry", nombre: "Meow", slug: "meow",
      genero: "FEMENINO", segmento: "DISENADOR", aliasCatalogo: "CHOUPETTE",
      catalogoFuente: "CATALOGO PERFUMERIA FEMENINA.pdf", paginaFuente: 3, entradaFuente: 10,
      perfil: [
        ["avainillado", 100], ["floral-blanco", 91], ["afrutado", 82],
        ["dulce", 82], ["atalcado", 72],
      ],
    },
    {
      marca: "Lattafa", nombre: "Yara", slug: "yara",
      genero: "FEMENINO", segmento: "NICHO", aliasCatalogo: "PINK DUNE",
      catalogoFuente: "CATALOGO PERFUMERIA FEMENINA.pdf", paginaFuente: 34, entradaFuente: 17,
      perfil: [
        ["dulce", 100], ["avainillado", 97], ["atalcado", 94],
        ["tropical", 70], ["afrutado", 68],
      ],
    },
    {
      marca: "Armaf", nombre: "Club de Nuit Intense", slug: "club-de-nuit-intense",
      genero: "MASCULINO", segmento: "NICHO", aliasCatalogo: "SPLENDID AVENTURE",
      catalogoFuente: "CATALOGO PERFUMERIA FEMENINA.pdf", paginaFuente: 34, entradaFuente: 18,
      perfil: [
        ["citrico", 100], ["afrutado", 75], ["cuero", 68],
        ["ahumado", 62], ["amaderado", 61],
      ],
    },
    {
      marca: "Afnan", nombre: "9pm", slug: "9pm",
      genero: "MASCULINO", segmento: "NICHO", aliasCatalogo: "AT NIGHTFALL",
      catalogoFuente: "CATALOGO PERFUMERIA FEMENINA.pdf", paginaFuente: 34, entradaFuente: 19,
      perfil: [
        ["avainillado", 100], ["ambar", 69], ["especiado-calido", 66],
        ["afrutado", 62], ["canela", 61],
      ],
    },
    {
      marca: "Lattafa", nombre: "Shaheen Gold", slug: "shaheen-gold",
      genero: "MASCULINO", segmento: "NICHO", aliasCatalogo: "ORO PRIVADO",
      catalogoFuente: "CATALOGO PERFUMERIA FEMENINA.pdf", paginaFuente: 34, entradaFuente: 20,
      perfil: [
        ["dulce", 100], ["afrutado", 98], ["avainillado", 84],
        ["lavanda", 70], ["citrico", 69],
      ],
    },
    {
      marca: "Mancera", nombre: "Instant Crush", slug: "instant-crush",
      genero: "UNISEX", segmento: "NICHO", aliasCatalogo: "SENSUAL ROMANCE",
      catalogoFuente: "CATALOGO PERFUMERIA FEMENINA.pdf", paginaFuente: 34, entradaFuente: 21,
      perfil: [
        ["amaderado", 100], ["especiado-calido", 99], ["avainillado", 78],
        ["ambar", 77], ["atalcado", 74],
      ],
    },
    {
      marca: "Initio", nombre: "Oud for Greatness", slug: "oud-for-greatness",
      genero: "UNISEX", segmento: "NICHO", aliasCatalogo: "BOLD MAJESTY",
      catalogoFuente: "CATALOGO PERFUMERIA FEMENINA.pdf", paginaFuente: 34, entradaFuente: 23,
      perfil: [
        ["especiado-calido", 100], ["fresco-especiado", 96], ["oud", 95],
        ["lavanda", 70], ["pachuli", 67],
      ],
    },
    {
      marca: "Al Haramain", nombre: "Amber Oud Rouge", slug: "amber-oud-rouge",
      genero: "UNISEX", segmento: "NICHO", aliasCatalogo: "MOLINO ROJO",
      catalogoFuente: "CATALOGO PERFUMERIA FEMENINA.pdf", paginaFuente: 34, entradaFuente: 24,
      perfil: [
        ["especiado-calido", 100], ["ambar", 95], ["almizclado", 90],
        ["amaderado", 84], ["animalico", 82],
      ],
    },
    {
      marca: "Montale", nombre: "Starry Night", slug: "starry-night",
      genero: "UNISEX", segmento: "NICHO", aliasCatalogo: "WARM SILLAGE",
      catalogoFuente: "CATALOGO PERFUMERIA FEMENINA.pdf", paginaFuente: 35, entradaFuente: 25,
      perfil: [
        ["atalcado", 100], ["citrico", 93], ["almizclado", 86],
        ["rosas", 82], ["pachuli", 75],
      ],
    },
    {
      marca: "Montale", nombre: "Intense Cafe", slug: "intense-cafe",
      genero: "UNISEX", segmento: "NICHO", aliasCatalogo: "COSY EXPRESSO",
      catalogoFuente: "CATALOGO PERFUMERIA FEMENINA.pdf", paginaFuente: 35, entradaFuente: 26,
      perfil: [
        ["rosas", 100], ["avainillado", 90], ["cafe", 80],
        ["floral", 80], ["atalcado", 71],
      ],
    },
    {
      marca: "Tiziana Terenzi", nombre: "Cassiopea", slug: "cassiopea",
      genero: "UNISEX", segmento: "NICHO", aliasCatalogo: "UNREAL JOURNEY",
      catalogoFuente: "CATALOGO PERFUMERIA FEMENINA.pdf", paginaFuente: 35, entradaFuente: 27,
      perfil: [
        ["afrutado", 100], ["dulce", 99], ["aromatico", 98],
        ["tropical", 90], ["fresco", 89],
      ],
    },
  ];

  for (const item of referencias) {
    const referencia = await prisma.referenciaPerfume.upsert({
      where: { slug: item.slug },
      update: {
        marcaId: marcas[item.marca].id,
        nombre: item.nombre,
        genero: item.genero,
        segmento: item.segmento,
        aliasCatalogo: item.aliasCatalogo,
        catalogoFuente: item.catalogoFuente,
        paginaFuente: item.paginaFuente,
        entradaFuente: item.entradaFuente,
        activo: true,
      },
      create: {
        marcaId: marcas[item.marca].id,
        nombre: item.nombre,
        slug: item.slug,
        genero: item.genero,
        segmento: item.segmento,
        aliasCatalogo: item.aliasCatalogo,
        catalogoFuente: item.catalogoFuente,
        paginaFuente: item.paginaFuente,
        entradaFuente: item.entradaFuente,
        activo: true,
      },
    });

    await prisma.referenciaPerfumeAcorde.deleteMany({
      where: { referenciaId: referencia.id },
    });

    await prisma.referenciaPerfumeAcorde.createMany({
      data: item.perfil.map(([slug, intensidad], index) => ({
        referenciaId: referencia.id,
        acordeId: acordes[slug].id,
        intensidad,
        ordenVisual: index + 1,
      })),
    });
  }
}

async function seedProductos(categorias, marcas) {
  const productos = [
    {
      nombre: "Royal Vanilla",
      codigo: "AS-PERF-001",
      descripcion: "Perfume con notas de vainilla, madera y almizcle.",
      precio: 59.99,
      volumenMl: 100,
      categoriaId: categorias.Perfumes.id,
      marcaId: marcas["Eau Royal"].id,
      stock: 25,
    },
    {
      nombre: "Citrus Bloom",
      codigo: "AS-PERF-002",
      descripcion: "Fragancia fresca con notas citricas y florales.",
      precio: 49.99,
      volumenMl: 100,
      categoriaId: categorias.Perfumes.id,
      marcaId: marcas["Aromas Store"].id,
      stock: 40,
    },
    {
      nombre: "Amber Night",
      codigo: "AS-PERF-003",
      descripcion: "Perfume intenso con ambar, especias y madera.",
      precio: 69.99,
      volumenMl: 100,
      categoriaId: categorias.Perfumes.id,
      marcaId: marcas["Eau Royal"].id,
      stock: 18,
    },
    {
      nombre: "Vela Lavanda Relax",
      codigo: "AS-CAND-001",
      descripcion: "Vela aromatica de lavanda para ambientes relajantes.",
      precio: 14.99,
      volumenMl: null,
      categoriaId: categorias["Velas aromaticas"].id,
      marcaId: marcas["Aromas Store"].id,
      stock: 60,
    },
  ];

  for (const productoData of productos) {
    const { stock, ...productoCampos } = productoData;

    const producto = await prisma.producto.upsert({
      where: { codigo: productoCampos.codigo },
      update: productoCampos,
      create: productoCampos,
    });

    await prisma.inventario.upsert({
      where: { productoId: producto.id },
      update: {
        stock,
        stockMinimo: 5,
        ubicacion: "Bodega principal",
      },
      create: {
        productoId: producto.id,
        stock,
        stockMinimo: 5,
        ubicacion: "Bodega principal",
      },
    });
  }
}

async function main() {
  const roles = await seedRoles();
  await seedUsuarios(roles);
  const categorias = await seedCategorias();
  const marcas = await seedMarcas();
  const acordes = await seedAcordes();
  await seedReferencias(marcas, acordes);
  await seedProductos(categorias, marcas);

  console.log("Seed completado correctamente.");
  console.log("Usuario admin: admin@aromasstore.com");
  console.log("Contrasena admin: Admin12345");
}

main()
  .catch((error) => {
    console.error("Seed fallido", error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
