import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const apiBaseUrl = 'http://localhost:3000/api';

void main() {
  runApp(const AromasStoreApp());
}

class AromasStoreApp extends StatelessWidget {
  const AromasStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aromas Store',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF145647),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFAF8F4),
        useMaterial3: true,
        fontFamily: 'Arial',
      ),
      home: const HomePage(),
    );
  }
}

class MyApp extends AromasStoreApp {
  const MyApp({super.key});
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<CatalogData> _catalogFuture;
  final _searchController = TextEditingController();
  final _heroController = PageController();
  Timer? _heroTimer;
  int _heroIndex = 0;
  int? _selectedCategoryId;
  int? _selectedBrandId;
  String _searchText = '';

  final _slides = const [
    HeroSlide(
      eyebrow: 'Fragancias seleccionadas',
      title: 'Aromas que elevan tu presencia',
      description:
          'Explora perfumes, esencias y productos aromaticos con disponibilidad clara y compra sencilla.',
      offer: 'Catalogo publico',
      buttonText: 'Ver productos',
      colors: [Color(0xFFF2D3AE), Color(0xFF113D35)],
      accentColor: Color(0xFFF0B84F),
    ),
    HeroSlide(
      eyebrow: 'Promociones vigentes',
      title: 'Descubre ofertas para renovar tu estilo',
      description:
          'Encuentra productos con descuentos, stock visible y categorias faciles de explorar.',
      offer: 'Ofertas destacadas',
      buttonText: 'Explorar promociones',
      colors: [Color(0xFFE8E1D5), Color(0xFF2B1F30)],
      accentColor: Color(0xFF9FB61D),
    ),
    HeroSlide(
      eyebrow: 'Compra segura',
      title: 'Una tienda clara, rapida y confiable',
      description:
          'Diseno centrado en el usuario: menos friccion, mejor lectura y acciones predecibles.',
      offer: 'Experiencia simple',
      buttonText: 'Comenzar',
      colors: [Color(0xFFDDE7E0), Color(0xFF0D2F4C)],
      accentColor: Color(0xFFE9C766),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _catalogFuture = ApiService.loadCatalog();
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_heroController.hasClients) return;
      final next = (_heroIndex + 1) % _slides.length;
      _heroController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _heroController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _reloadCatalog() {
    setState(() {
      _catalogFuture = ApiService.loadCatalog();
    });
  }

  void _scrollToCatalog() {
    Scrollable.ensureVisible(
      _catalogKey.currentContext!,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  final _catalogKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<CatalogData>(
        future: _catalogFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }

          if (snapshot.hasError) {
            return ErrorView(
              message: 'No se pudo cargar Aromas Store.',
              details: snapshot.error.toString(),
              onRetry: _reloadCatalog,
            );
          }

          final data = snapshot.data ?? CatalogData.empty();
          final products = _applyFilters(data.products);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: TopNavigation(
                  onCatalogPressed: _scrollToCatalog,
                  onSearchChanged: (value) {
                    _searchController.text = value;
                    setState(() => _searchText = value);
                    _scrollToCatalog();
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: HeroCarousel(
                  controller: _heroController,
                  slides: _slides,
                  currentIndex: _heroIndex,
                  onPageChanged: (index) => setState(() => _heroIndex = index),
                  onPrimaryAction: _scrollToCatalog,
                ),
              ),
              const SliverToBoxAdapter(child: TrustBar()),
              SliverToBoxAdapter(
                child: CatalogSectionHeader(
                  key: _catalogKey,
                  visibleProducts: products.length,
                  totalProducts: data.products.length,
                ),
              ),
              SliverToBoxAdapter(
                child: CatalogFilters(
                  searchController: _searchController,
                  categories: data.categories,
                  brands: data.brands,
                  selectedCategoryId: _selectedCategoryId,
                  selectedBrandId: _selectedBrandId,
                  onSearchChanged: (value) => setState(() => _searchText = value),
                  onCategoryChanged: (value) => setState(() => _selectedCategoryId = value),
                  onBrandChanged: (value) => setState(() => _selectedBrandId = value),
                  onClear: () {
                    _searchController.clear();
                    setState(() {
                      _selectedCategoryId = null;
                      _selectedBrandId = null;
                      _searchText = '';
                    });
                  },
                ),
              ),
              if (products.isEmpty)
                const SliverToBoxAdapter(child: EmptyCatalogView())
              else
                ProductGrid(products: products),
            ],
          );
        },
      ),
    );
  }

  List<Product> _applyFilters(List<Product> products) {
    final query = _searchText.trim().toLowerCase();

    return products.where((product) {
      final matchesSearch = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.brand.name.toLowerCase().contains(query) ||
          product.category.name.toLowerCase().contains(query);
      final matchesCategory =
          _selectedCategoryId == null || product.categoryId == _selectedCategoryId;
      final matchesBrand = _selectedBrandId == null || product.brandId == _selectedBrandId;

      return product.active && matchesSearch && matchesCategory && matchesBrand;
    }).toList();
  }
}

class TopNavigation extends StatelessWidget {
  const TopNavigation({
    required this.onCatalogPressed,
    required this.onSearchChanged,
    super.key,
  });

  final VoidCallback onCatalogPressed;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            children: [
              Row(
                children: [
                  const BrandMark(),
                  const Spacer(),
                  _NavButton(label: 'Inicio', onPressed: () {}),
                  _NavButton(label: 'Catalogo', onPressed: onCatalogPressed),
                  _NavButton(label: 'Promociones', onPressed: onCatalogPressed),
                  _NavButton(label: 'Carrito', onPressed: () {}),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.person_outline),
                    label: const Text('Iniciar sesion'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Buscar perfume, marca o categoria',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xFFF1F1F1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFE8C766),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.spa_outlined, color: Color(0xFF143B33), size: 28),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aromas Store',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF111111),
                  ),
            ),
            Text(
              'Fragancias y bienestar',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF575757),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF111111),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class HeroCarousel extends StatelessWidget {
  const HeroCarousel({
    required this.controller,
    required this.slides,
    required this.currentIndex,
    required this.onPageChanged,
    required this.onPrimaryAction,
    super.key,
  });

  final PageController controller;
  final List<HeroSlide> slides;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          SizedBox(
            height: 430,
            child: PageView.builder(
              controller: controller,
              onPageChanged: onPageChanged,
              itemCount: slides.length,
              itemBuilder: (context, index) {
                return HeroSlideView(
                  slide: slides[index],
                  onPressed: onPrimaryAction,
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < slides.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: i == currentIndex ? 46 : 24,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: i == currentIndex ? const Color(0xFF145647) : const Color(0xFFD8D8D8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
        ],
      ),
    );
  }
}

class HeroSlide {
  const HeroSlide({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.offer,
    required this.buttonText,
    required this.colors,
    required this.accentColor,
  });

  final String eyebrow;
  final String title;
  final String description;
  final String offer;
  final String buttonText;
  final List<Color> colors;
  final Color accentColor;
}

class HeroSlideView extends StatelessWidget {
  const HeroSlideView({
    required this.slide,
    required this.onPressed,
    super.key,
  });

  final HeroSlide slide;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: slide.colors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 820;
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 28 : 64,
                  vertical: 36,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: compact ? 1 : 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            slide.eyebrow.toUpperCase(),
                            style: TextStyle(
                              color: slide.accentColor,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            slide.title,
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  height: 1.02,
                                ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            slide.description,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  height: 1.35,
                                ),
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 14,
                            runSpacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              FilledButton(
                                onPressed: onPressed,
                                style: FilledButton.styleFrom(
                                  backgroundColor: slide.accentColor,
                                  foregroundColor: const Color(0xFF111111),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 18,
                                  ),
                                ),
                                child: Text(slide.buttonText),
                              ),
                              Text(
                                slide.offer,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(width: 40),
                      Expanded(
                        flex: 4,
                        child: HeroProductMock(accentColor: slide.accentColor),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class HeroProductMock extends StatelessWidget {
  const HeroProductMock({required this.accentColor, super.key});

  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 320,
          height: 320,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.16),
            shape: BoxShape.circle,
          ),
        ),
        Transform.rotate(
          angle: -0.12,
          child: Container(
            width: 155,
            height: 285,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(34),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 34,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 18),
                Container(
                  width: 58,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 38),
                const Icon(Icons.spa_outlined, color: Color(0xFF145647), size: 44),
                const SizedBox(height: 22),
                const Text(
                  'AROMAS',
                  style: TextStyle(
                    color: Color(0xFF111111),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                const Text(
                  'STORE',
                  style: TextStyle(
                    color: Color(0xFF777777),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.8),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(34),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class TrustBar extends StatelessWidget {
  const TrustBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0F0F0),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              final items = [
                const TrustItem(
                  title: 'Catalogo claro',
                  subtitle: 'productos con precio y stock',
                  icon: Icons.storefront_outlined,
                ),
                const TrustItem(
                  title: 'Compra segura',
                  subtitle: 'validacion de carrito',
                  icon: Icons.verified_user_outlined,
                ),
                const TrustItem(
                  title: 'Stock visible',
                  subtitle: 'alertas de disponibilidad',
                  icon: Icons.inventory_2_outlined,
                ),
                const TrustItem(
                  title: 'Promociones',
                  subtitle: 'descuentos configurables',
                  icon: Icons.local_offer_outlined,
                ),
              ];

              if (compact) {
                return Column(
                  children: [
                    for (final item in items) ...[
                      item,
                      if (item != items.last) const SizedBox(height: 10),
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  for (final item in items) Expanded(child: item),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class TrustItem extends StatelessWidget {
  const TrustItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: const Color(0xFF145647)),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF555555)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CatalogSectionHeader extends StatelessWidget {
  const CatalogSectionHeader({
    required this.visibleProducts,
    required this.totalProducts,
    super.key,
  });

  final int visibleProducts;
  final int totalProducts;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Catalogo publico',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF111111),
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Encuentra productos por marca, categoria o nombre. El stock se comunica con texto, no solo color.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF555555),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Text(
                '$visibleProducts de $totalProducts',
                style: const TextStyle(
                  color: Color(0xFF145647),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CatalogFilters extends StatelessWidget {
  const CatalogFilters({
    required this.searchController,
    required this.categories,
    required this.brands,
    required this.selectedCategoryId,
    required this.selectedBrandId,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onBrandChanged,
    required this.onClear,
    super.key,
  });

  final TextEditingController searchController;
  final List<Category> categories;
  final List<Brand> brands;
  final int? selectedCategoryId;
  final int? selectedBrandId;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<int?> onCategoryChanged;
  final ValueChanged<int?> onBrandChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFFE6E1D8)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 760;
                  final fields = [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: searchController,
                        onChanged: onSearchChanged,
                        decoration: const InputDecoration(
                          labelText: 'Buscar producto o marca',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        value: selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Categoria',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Todas'),
                          ),
                          ...categories.map(
                            (category) => DropdownMenuItem<int?>(
                              value: category.id,
                              child: Text(category.name),
                            ),
                          ),
                        ],
                        onChanged: onCategoryChanged,
                      ),
                    ),
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        value: selectedBrandId,
                        decoration: const InputDecoration(
                          labelText: 'Marca',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Todas'),
                          ),
                          ...brands.map(
                            (brand) => DropdownMenuItem<int?>(
                              value: brand.id,
                              child: Text(brand.name),
                            ),
                          ),
                        ],
                        onChanged: onBrandChanged,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: onClear,
                      icon: const Icon(Icons.filter_alt_off_outlined),
                      label: const Text('Limpiar'),
                    ),
                  ];

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < fields.length; i++) ...[
                          if (fields[i] is Expanded) (fields[i] as Expanded).child else fields[i],
                          if (i != fields.length - 1) const SizedBox(height: 12),
                        ],
                      ],
                    );
                  }

                  return Row(
                    children: [
                      fields[0],
                      const SizedBox(width: 12),
                      fields[1],
                      const SizedBox(width: 12),
                      fields[2],
                      const SizedBox(width: 12),
                      fields[3],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProductGrid extends StatelessWidget {
  const ProductGrid({required this.products, super.key});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 48),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          final columns = width >= 1180
              ? 4
              : width >= 860
                  ? 3
                  : width >= 560
                      ? 2
                      : 1;

          return SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) => ProductCard(product: products[index]),
              childCount: products.length,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
              mainAxisExtent: 430,
            ),
          );
        },
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final stock = product.inventory?.stock ?? 0;
    final stockLow = stock < 3;
    final hasStock = stock > 0;

    return Card(
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE6E1D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductImage(imageUrl: product.imageUrl),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.brand.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF145647),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF68645D)),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF111111),
                              ),
                        ),
                      ),
                      StockBadge(stock: stock, hasStock: hasStock, stockLow: stockLow),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: hasStock ? () => _showCartMessage(context, product) : null,
                      icon: const Icon(Icons.add_shopping_cart),
                      label: Text(hasStock ? 'Agregar al carrito' : 'Sin stock'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCartMessage(BuildContext context, Product product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} agregado al carrito.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class ProductImage extends StatelessWidget {
  const ProductImage({required this.imageUrl, super.key});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;

    if (url != null && url.isNotEmpty) {
      return SizedBox(
        height: 210,
        width: double.infinity,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          semanticLabel: 'Imagen del producto',
          errorBuilder: (context, error, stackTrace) => const ProductPlaceholder(),
        ),
      );
    }

    return const SizedBox(
      height: 210,
      width: double.infinity,
      child: ProductPlaceholder(),
    );
  }
}

class ProductPlaceholder extends StatelessWidget {
  const ProductPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF5E9D8), Color(0xFFE0D4C2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Container(
          width: 96,
          height: 138,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.78),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: const Icon(Icons.spa_outlined, color: Color(0xFF145647), size: 42),
        ),
      ),
    );
  }
}

class StockBadge extends StatelessWidget {
  const StockBadge({
    required this.stock,
    required this.hasStock,
    required this.stockLow,
    super.key,
  });

  final int stock;
  final bool hasStock;
  final bool stockLow;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    final String text;

    if (!hasStock) {
      background = const Color(0xFFFFE6E6);
      foreground = const Color(0xFF8A1C1C);
      text = 'Agotado';
    } else if (stockLow) {
      background = const Color(0xFFFFF1C2);
      foreground = const Color(0xFF684900);
      text = 'Stock bajo: $stock';
    } else {
      background = const Color(0xFFE4F4EA);
      foreground = const Color(0xFF145647);
      text = 'Stock: $stock';
    }

    return Semantics(
      label: text,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: foreground,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Cargando Aromas Store...'),
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({
    required this.message,
    required this.details,
    required this.onRetry,
    super.key,
  });

  final String message;
  final String details;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          elevation: 0,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_outlined, size: 48, color: Color(0xFF8A1C1C)),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Verifica que el backend este encendido en http://localhost:3000.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
                const SizedBox(height: 12),
                Text(
                  details,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF6D6A62), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EmptyCatalogView extends StatelessWidget {
  const EmptyCatalogView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: const Column(
            children: [
              Icon(Icons.search_off_outlined, size: 52, color: Color(0xFF6D6A62)),
              SizedBox(height: 12),
              Text(
                'No encontramos productos con esos filtros.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
              ),
              SizedBox(height: 8),
              Text(
                'Prueba limpiar filtros o buscar por otra marca.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ApiService {
  static Future<CatalogData> loadCatalog() async {
    final responses = await Future.wait([
      _getJson('$apiBaseUrl/productos'),
      _getJson('$apiBaseUrl/categorias'),
      _getJson('$apiBaseUrl/marcas'),
    ]);

    return CatalogData(
      products: _listFrom(responses[0]).map(Product.fromJson).toList(),
      categories: _listFrom(responses[1]).map(Category.fromJson).toList(),
      brands: _listFrom(responses[2]).map(Brand.fromJson).toList(),
    );
  }

  static Future<Map<String, dynamic>> _getJson(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error HTTP ${response.statusCode}: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static List<Map<String, dynamic>> _listFrom(Map<String, dynamic> json) {
    final value = json['datos'] ?? json['data'] ?? [];
    if (value is List) {
      return value.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }
}

class CatalogData {
  const CatalogData({
    required this.products,
    required this.categories,
    required this.brands,
  });

  final List<Product> products;
  final List<Category> categories;
  final List<Brand> brands;

  factory CatalogData.empty() {
    return const CatalogData(products: [], categories: [], brands: []);
  }
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.active,
    required this.categoryId,
    required this.brandId,
    required this.brand,
    required this.category,
    required this.inventory,
  });

  final int id;
  final String name;
  final String code;
  final String description;
  final double price;
  final String? imageUrl;
  final bool active;
  final int categoryId;
  final int brandId;
  final Brand brand;
  final Category category;
  final Inventory? inventory;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: _asInt(json['id']),
      name: _asString(json['nombre']),
      code: _asString(json['codigo']),
      description: _asString(json['descripcion']),
      price: _asDouble(json['precio']),
      imageUrl: json['imagenUrl'] as String?,
      active: json['activo'] == true,
      categoryId: _asInt(json['categoriaId']),
      brandId: _asInt(json['marcaId']),
      brand: Brand.fromJson((json['marca'] as Map?)?.cast<String, dynamic>() ?? {}),
      category: Category.fromJson((json['categoria'] as Map?)?.cast<String, dynamic>() ?? {}),
      inventory: json['inventario'] is Map
          ? Inventory.fromJson((json['inventario'] as Map).cast<String, dynamic>())
          : null,
    );
  }
}

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.description,
    required this.active,
  });

  final int id;
  final String name;
  final String description;
  final bool active;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: _asInt(json['id']),
      name: _asString(json['nombre']),
      description: _asString(json['descripcion']),
      active: json['activo'] != false,
    );
  }
}

class Brand {
  const Brand({
    required this.id,
    required this.name,
    required this.country,
    required this.description,
    required this.active,
  });

  final int id;
  final String name;
  final String country;
  final String description;
  final bool active;

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: _asInt(json['id']),
      name: _asString(json['nombre']),
      country: _asString(json['paisOrigen']),
      description: _asString(json['descripcion']),
      active: json['activo'] != false,
    );
  }
}

class Inventory {
  const Inventory({
    required this.stock,
    required this.minimumStock,
    required this.location,
  });

  final int stock;
  final int minimumStock;
  final String location;

  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      stock: _asInt(json['stock']),
      minimumStock: _asInt(json['stockMinimo']),
      location: _asString(json['ubicacion']),
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _asDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

String _asString(Object? value) {
  return value?.toString() ?? '';
}
