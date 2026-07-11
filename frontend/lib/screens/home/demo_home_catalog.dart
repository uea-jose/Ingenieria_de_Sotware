import '../../models/brand.dart';
import '../../models/catalog_data.dart';
import '../../models/category.dart';
import '../../models/inventory.dart';
import '../../models/product.dart';

const _perfumes = Category(
  id: 901,
  name: 'Perfumes',
  description: 'Fragancias para mujer, hombre y unisex.',
  active: true,
);

const _sets = Category(
  id: 902,
  name: 'Sets y regalos',
  description: 'Presentaciones especiales para regalar.',
  active: true,
);

const _pacoRabanne = Brand(
  id: 901,
  name: 'Paco Rabanne',
  country: 'Espana',
  description: 'Fragancias intensas y memorables.',
  active: true,
);
const _giorgioArmani = Brand(
  id: 902,
  name: 'Giorgio Armani',
  country: 'Italia',
  description: 'Perfumeria elegante y contemporanea.',
  active: true,
);
const _dior = Brand(
  id: 903,
  name: 'Dior',
  country: 'Francia',
  description: 'Fragancias sofisticadas.',
  active: true,
);
const _chanel = Brand(
  id: 904,
  name: 'Chanel',
  country: 'Francia',
  description: 'Iconos clasicos de perfumeria.',
  active: true,
);
const _versace = Brand(
  id: 905,
  name: 'Versace',
  country: 'Italia',
  description: 'Aromas expresivos y modernos.',
  active: true,
);
const _carolinaHerrera = Brand(
  id: 906,
  name: 'Carolina Herrera',
  country: 'Estados Unidos',
  description: 'Fragancias urbanas y elegantes.',
  active: true,
);

const _brands = [
  _pacoRabanne,
  _giorgioArmani,
  _dior,
  _chanel,
  _versace,
  _carolinaHerrera,
];

CatalogData buildDemoCatalog() {
  return CatalogData(
    products: demoProducts,
    categories: const [_perfumes, _sets],
    brands: _brands,
  );
}

const demoProducts = [
  Product(
    id: 9901,
    name: 'One Million Elixir',
    code: 'DEMO-PR-001',
    description: 'Fragancia intensa con notas dulces, amaderadas y especiadas.',
    price: 129.99,
    imageUrl: null,
    active: true,
    categoryId: 901,
    brandId: 901,
    brand: _pacoRabanne,
    category: _perfumes,
    inventory: Inventory(stock: 12, minimumStock: 3, location: 'Demo'),
  ),
  Product(
    id: 9902,
    name: 'Invictus Victory',
    code: 'DEMO-PR-002',
    description: 'Fragancia fresca y poderosa con matices amaderados.',
    price: 119.99,
    imageUrl: null,
    active: true,
    categoryId: 901,
    brandId: 901,
    brand: _pacoRabanne,
    category: _perfumes,
    inventory: Inventory(stock: 9, minimumStock: 3, location: 'Demo'),
  ),
  Product(
    id: 9903,
    name: 'Phantom Parfum',
    code: 'DEMO-PR-003',
    description: 'Aroma moderno con lavanda, vainilla y notas amaderadas.',
    price: 109.99,
    imageUrl: null,
    active: true,
    categoryId: 901,
    brandId: 901,
    brand: _pacoRabanne,
    category: _perfumes,
    inventory: Inventory(stock: 7, minimumStock: 3, location: 'Demo'),
  ),
  Product(
    id: 9904,
    name: 'One Million Parfum',
    code: 'DEMO-PR-004',
    description: 'Fragancia calida con notas de cuero, ambar y flores blancas.',
    price: 124.99,
    imageUrl: null,
    active: true,
    categoryId: 901,
    brandId: 901,
    brand: _pacoRabanne,
    category: _perfumes,
    inventory: Inventory(stock: 5, minimumStock: 3, location: 'Demo'),
  ),
  Product(
    id: 9905,
    name: 'Acqua di Gio Eau de Toilette',
    code: 'DEMO-GA-001',
    description:
        'Fragancia fresca de inspiracion marina y citrica para hombre.',
    price: 95.00,
    imageUrl: null,
    active: true,
    categoryId: 901,
    brandId: 902,
    brand: _giorgioArmani,
    category: _perfumes,
    inventory: Inventory(stock: 15, minimumStock: 4, location: 'Demo'),
  ),
  Product(
    id: 9906,
    name: 'Armani Code Eau de Parfum',
    code: 'DEMO-GA-002',
    description: 'Aroma elegante con salida citrica y fondo amaderado.',
    price: 110.00,
    imageUrl: null,
    active: true,
    categoryId: 901,
    brandId: 902,
    brand: _giorgioArmani,
    category: _perfumes,
    inventory: Inventory(stock: 10, minimumStock: 3, location: 'Demo'),
  ),
  Product(
    id: 9907,
    name: 'My Way Eau de Parfum',
    code: 'DEMO-GA-003',
    description: 'Fragancia luminosa para mujer con flores blancas y vainilla.',
    price: 105.00,
    imageUrl: null,
    active: true,
    categoryId: 901,
    brandId: 902,
    brand: _giorgioArmani,
    category: _perfumes,
    inventory: Inventory(stock: 8, minimumStock: 3, location: 'Demo'),
  ),
  Product(
    id: 9908,
    name: 'Si Passione',
    code: 'DEMO-GA-004',
    description: 'Perfume para mujer con notas frutales y florales.',
    price: 115.00,
    imageUrl: null,
    active: true,
    categoryId: 901,
    brandId: 902,
    brand: _giorgioArmani,
    category: _perfumes,
    inventory: Inventory(stock: 6, minimumStock: 3, location: 'Demo'),
  ),
  Product(
    id: 9909,
    name: 'Sauvage Eau de Parfum',
    code: 'DEMO-DI-001',
    description:
        'Fragancia para hombre intensa con bergamota y notas especiadas.',
    price: 118.00,
    imageUrl: null,
    active: true,
    categoryId: 901,
    brandId: 903,
    brand: _dior,
    category: _perfumes,
    inventory: Inventory(stock: 11, minimumStock: 3, location: 'Demo'),
  ),
  Product(
    id: 9910,
    name: 'Bleu de Chanel',
    code: 'DEMO-CH-001',
    description: 'Aroma unisex amaderado aromatico, limpio y elegante.',
    price: 132.00,
    imageUrl: null,
    active: true,
    categoryId: 901,
    brandId: 904,
    brand: _chanel,
    category: _perfumes,
    inventory: Inventory(stock: 4, minimumStock: 3, location: 'Demo'),
  ),
  Product(
    id: 9911,
    name: 'Eros Flame',
    code: 'DEMO-VE-001',
    description:
        'Fragancia para hombre vibrante con citricos, pimienta y maderas.',
    price: 89.99,
    imageUrl: null,
    active: true,
    categoryId: 901,
    brandId: 905,
    brand: _versace,
    category: _perfumes,
    inventory: Inventory(stock: 13, minimumStock: 3, location: 'Demo'),
  ),
  Product(
    id: 9912,
    name: 'Good Girl Blush',
    code: 'DEMO-CHER-001',
    description:
        'Fragancia para mujer floral ambarada para ocasiones especiales.',
    price: 102.00,
    imageUrl: null,
    active: true,
    categoryId: 902,
    brandId: 906,
    brand: _carolinaHerrera,
    category: _sets,
    inventory: Inventory(stock: 2, minimumStock: 3, location: 'Demo'),
  ),
];
