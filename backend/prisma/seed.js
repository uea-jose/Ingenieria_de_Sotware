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
