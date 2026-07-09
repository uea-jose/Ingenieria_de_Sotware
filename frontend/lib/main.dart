import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const apiBaseUrl = 'http://localhost:3000/api';
const cartStorageKey = 'aromas_store_cart';

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
  final Map<int, int> _cartQuantities = {};
  CartValidation? _cartValidation;
  bool _cartIsValidating = false;

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
    _restoreCart();
    _catalogFuture.then((_) {
      if (mounted && _cartQuantities.isNotEmpty) {
        _validateCart(showMessages: false);
      }
    });
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

  int get _cartCount {
    return _cartQuantities.values.fold(
      0,
      (total, quantity) => total + quantity,
    );
  }

  void _restoreCart() {
    final savedCart = html.window.localStorage[cartStorageKey];
    if (savedCart == null || savedCart.isEmpty) return;

    try {
      final decoded = jsonDecode(savedCart);
      if (decoded is! Map) return;
      for (final entry in decoded.entries) {
        final productId = int.tryParse(entry.key.toString());
        final quantity = _asInt(entry.value);
        if (productId != null && quantity > 0) {
          _cartQuantities[productId] = quantity;
        }
      }
    } catch (_) {
      html.window.localStorage.remove(cartStorageKey);
    }
  }

  void _persistCart() {
    if (_cartQuantities.isEmpty) {
      html.window.localStorage.remove(cartStorageKey);
      return;
    }

    html.window.localStorage[cartStorageKey] = jsonEncode(
      _cartQuantities.map(
        (productId, quantity) => MapEntry('$productId', quantity),
      ),
    );
  }

  Future<void> _addToCart(Product product) async {
    final stock = product.inventory?.stock ?? 0;
    if (stock <= 0) return;

    final currentQuantity = _cartQuantities[product.id] ?? 0;
    if (currentQuantity >= stock) {
      _showSnackBar('${product.name} solo tiene $stock unidades disponibles.');
      return;
    }

    setState(() {
      _cartQuantities[product.id] = currentQuantity + 1;
    });

    _persistCart();
    _showSnackBar(
      currentQuantity == 0
          ? '${product.name} agregado al carrito.'
          : 'Cantidad actualizada en el carrito.',
    );
    await _validateCart(showMessages: false);
  }

  Future<void> _changeCartQuantity(Product product, int nextQuantity) async {
    final stock = product.inventory?.stock ?? 0;
    final previousQuantity = _cartQuantities[product.id] ?? 0;

    setState(() {
      if (nextQuantity <= 0) {
        _cartQuantities.remove(product.id);
      } else {
        _cartQuantities[product.id] = nextQuantity.clamp(1, stock);
      }
    });

    _persistCart();
    if (nextQuantity <= 0) {
      _showUndoRemoveSnackBar(product, previousQuantity);
    }
    await _validateCart(showMessages: false);
  }

  Future<void> _confirmClearCart() async {
    if (_cartQuantities.isEmpty) return;

    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Vaciar carrito'),
          content: const Text(
            'Esta accion quitara todos los productos del carrito. Puedes seguir comprando despues.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Vaciar carrito'),
            ),
          ],
        );
      },
    );

    if (shouldClear == true) {
      _clearCart();
      _showSnackBar('Carrito vaciado correctamente.');
    }
  }

  void _clearCart() {
    setState(() {
      _cartQuantities.clear();
      _cartValidation = null;
    });
    _persistCart();
  }

  Future<void> _startCheckout() async {
    await _validateCart(showMessages: false);
    final validation = _cartValidation;

    if (validation == null) {
      _showSnackBar('Valida el carrito antes de continuar.');
      return;
    }

    if (!validation.valid) {
      _showSnackBar(
        validation.errors.isEmpty
            ? 'Revisa el carrito antes de finalizar la compra.'
            : validation.errors.first,
      );
      return;
    }

    _showSnackBar('Carrito listo. El siguiente modulo sera checkout y pedido.');
  }

  Future<void> _validateCart({bool showMessages = true}) async {
    if (_cartQuantities.isEmpty) {
      setState(() => _cartValidation = null);
      return;
    }

    setState(() => _cartIsValidating = true);
    try {
      final validation = await ApiService.validateCart(_cartQuantities);
      if (!mounted) return;
      setState(() => _cartValidation = validation);

      if (showMessages) {
        _showSnackBar(
          validation.valid
              ? 'Carrito validado correctamente.'
              : validation.errors.join(' '),
        );
      }
    } catch (error) {
      if (!mounted) return;
      if (showMessages) {
        _showSnackBar('No se pudo validar el carrito. Verifica el backend.');
      }
    } finally {
      if (mounted) {
        setState(() => _cartIsValidating = false);
      }
    }
  }

  void _openCartPanel(List<Product> products) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, refreshPanel) {
            final productsById = {
              for (final product in products) product.id: product,
            };
            final cartProducts = _cartQuantities.keys
                .map((id) => productsById[id])
                .whereType<Product>()
                .toList();

            return CartPanel(
              products: cartProducts,
              quantities: Map<int, int>.from(_cartQuantities),
              validation: _cartValidation,
              validating: _cartIsValidating,
              onQuantityChanged: (product, quantity) async {
                await _changeCartQuantity(product, quantity);
                refreshPanel(() {});
              },
              onValidate: () async {
                await _validateCart(showMessages: true);
                refreshPanel(() {});
              },
              onClear: () async {
                await _confirmClearCart();
                refreshPanel(() {});
              },
              onCheckout: () async {
                await _startCheckout();
                refreshPanel(() {});
              },
            );
          },
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _showUndoRemoveSnackBar(Product product, int previousQuantity) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} eliminado del carrito.'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () {
            setState(() {
              _cartQuantities[product.id] = previousQuantity;
            });
            _persistCart();
            _validateCart(showMessages: false);
          },
        ),
      ),
    );
  }

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
                  onCartPressed: () => _openCartPanel(data.products),
                  cartCount: _cartCount,
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
              const SliverToBoxAdapter(child: FeaturedExperienceStrip()),
              SliverToBoxAdapter(
                child: CartPreviewBar(
                  itemCount: _cartCount,
                  validation: _cartValidation,
                  validating: _cartIsValidating,
                  onOpenCart: () => _openCartPanel(data.products),
                  onValidate: () => _validateCart(showMessages: true),
                ),
              ),
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
                  onSearchChanged: (value) =>
                      setState(() => _searchText = value),
                  onCategoryChanged: (value) =>
                      setState(() => _selectedCategoryId = value),
                  onBrandChanged: (value) =>
                      setState(() => _selectedBrandId = value),
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
                ProductGrid(products: products, onAddToCart: _addToCart),
            ],
          );
        },
      ),
    );
  }

  List<Product> _applyFilters(List<Product> products) {
    final query = _searchText.trim().toLowerCase();

    return products.where((product) {
      final matchesSearch =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.brand.name.toLowerCase().contains(query) ||
          product.category.name.toLowerCase().contains(query);
      final matchesCategory =
          _selectedCategoryId == null ||
          product.categoryId == _selectedCategoryId;
      final matchesBrand =
          _selectedBrandId == null || product.brandId == _selectedBrandId;

      return product.active && matchesSearch && matchesCategory && matchesBrand;
    }).toList();
  }
}

class TopNavigation extends StatelessWidget {
  const TopNavigation({
    required this.onCatalogPressed,
    required this.onCartPressed,
    required this.onSearchChanged,
    required this.cartCount,
    super.key,
  });

  final VoidCallback onCatalogPressed;
  final VoidCallback onCartPressed;
  final ValueChanged<String> onSearchChanged;
  final int cartCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const PremiumAnnouncementBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 760;
                    final navActions = Wrap(
                      spacing: 6,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _NavButton(label: 'Inicio', onPressed: () {}),
                        _NavButton(
                          label: 'Catalogo',
                          onPressed: onCatalogPressed,
                        ),
                        _NavButton(
                          label: 'Promociones',
                          onPressed: onCatalogPressed,
                        ),
                        CartNavButton(
                          count: cartCount,
                          onPressed: onCartPressed,
                        ),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.person_outline),
                          label: const Text('Iniciar sesion'),
                        ),
                      ],
                    );

                    return Column(
                      children: [
                        if (compact) ...[
                          const BrandMark(),
                          const SizedBox(height: 14),
                          navActions,
                        ] else
                          Row(
                            children: [
                              const BrandMark(),
                              const Spacer(),
                              navActions,
                            ],
                          ),
                        const SizedBox(height: 18),
                        Semantics(
                          textField: true,
                          label: 'Buscar perfumes, marcas o categorias',
                          child: TextField(
                            onChanged: onSearchChanged,
                            decoration: InputDecoration(
                              hintText: 'Buscar perfume, marca o categoria',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: const Icon(Icons.tune_outlined),
                              filled: true,
                              fillColor: const Color(0xFFF1F1F1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumAnnouncementBar extends StatelessWidget {
  const PremiumAnnouncementBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF102F29),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 9),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Wrap(
            spacing: 18,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: const [
              _AnnouncementItem(
                icon: Icons.local_shipping_outlined,
                text: 'Entrega local coordinada',
              ),
              _AnnouncementItem(
                icon: Icons.verified_outlined,
                text: 'Compra segura',
              ),
              _AnnouncementItem(
                icon: Icons.receipt_long_outlined,
                text: 'IVA Ecuador 15%',
              ),
              _AnnouncementItem(
                icon: Icons.inventory_2_outlined,
                text: 'Stock visible en tiempo real',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnnouncementItem extends StatelessWidget {
  const _AnnouncementItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFFE8C766)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
          child: const Icon(
            Icons.spa_outlined,
            color: Color(0xFF143B33),
            size: 28,
          ),
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

class CartNavButton extends StatelessWidget {
  const CartNavButton({
    required this.count,
    required this.onPressed,
    super.key,
  });

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        child: const Icon(Icons.shopping_bag_outlined),
      ),
      label: const Text('Carrito'),
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
                    color: i == currentIndex
                        ? const Color(0xFF145647)
                        : const Color(0xFFD8D8D8),
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
                            style: Theme.of(context).textTheme.displayMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  height: 1.02,
                                ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            slide.description,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.white, height: 1.35),
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
            color: Colors.white.withValues(alpha: 0.16),
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
                  color: Colors.black.withValues(alpha: 0.2),
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
                const Icon(
                  Icons.spa_outlined,
                  color: Color(0xFF145647),
                  size: 44,
                ),
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
                    color: accentColor.withValues(alpha: 0.8),
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
                children: [for (final item in items) Expanded(child: item)],
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

class FeaturedExperienceStrip extends StatelessWidget {
  const FeaturedExperienceStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const [
      _ExperienceCard(
        icon: Icons.workspace_premium_outlined,
        title: 'Mas vendidos',
        text: 'Fragancias con mayor salida para decidir rapido.',
      ),
      _ExperienceCard(
        icon: Icons.auto_awesome_outlined,
        title: 'Novedades',
        text: 'Productos recientes listos para destacar en portada.',
      ),
      _ExperienceCard(
        icon: Icons.percent_outlined,
        title: 'Ofertas',
        text: 'Promociones configuradas desde el backend.',
      ),
      _ExperienceCard(
        icon: Icons.notifications_active_outlined,
        title: 'Stock bajo',
        text: 'Avisos visibles cuando quedan pocas unidades.',
      ),
    ];

    return Container(
      color: const Color(0xFFFAF8F4),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 6),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (final item in items)
                    SizedBox(
                      width: compact
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 42) / 4,
                      child: item,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$title. $text',
      child: Container(
        constraints: const BoxConstraints(minHeight: 108),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8E0D5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF5EF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF145647)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      height: 1.25,
                      color: Color(0xFF68645D),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CartPreviewBar extends StatelessWidget {
  const CartPreviewBar({
    required this.itemCount,
    required this.validation,
    required this.validating,
    required this.onOpenCart,
    required this.onValidate,
    super.key,
  });

  final int itemCount;
  final CartValidation? validation;
  final bool validating;
  final VoidCallback onOpenCart;
  final Future<void> Function() onValidate;

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) return const SizedBox.shrink();

    final total = validation?.total;
    final valid = validation?.valid;

    return Container(
      color: const Color(0xFFFAF8F4),
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Card(
            elevation: 0,
            color: const Color(0xFF102F29),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Wrap(
                spacing: 14,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shopping_bag_outlined,
                        color: Color(0xFFE8C766),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$itemCount producto${itemCount == 1 ? '' : 's'} en el carrito',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (total != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          'Total: \$${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFFE8C766),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                      if (valid != null) ...[
                        const SizedBox(width: 12),
                        Icon(
                          valid
                              ? Icons.check_circle_outline
                              : Icons.warning_amber_rounded,
                          color: valid
                              ? const Color(0xFF9FE7BD)
                              : const Color(0xFFFFD66B),
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: validating ? null : () => onValidate(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                        ),
                        icon: validating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.verified_outlined),
                        label: Text(validating ? 'Validando' : 'Validar'),
                      ),
                      FilledButton.icon(
                        onPressed: onOpenCart,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE8C766),
                          foregroundColor: const Color(0xFF102F29),
                        ),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Ver carrito'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CartPanel extends StatelessWidget {
  const CartPanel({
    required this.products,
    required this.quantities,
    required this.validation,
    required this.validating,
    required this.onQuantityChanged,
    required this.onValidate,
    required this.onClear,
    required this.onCheckout,
    super.key,
  });

  final List<Product> products;
  final Map<int, int> quantities;
  final CartValidation? validation;
  final bool validating;
  final Future<void> Function(Product product, int quantity) onQuantityChanged;
  final Future<void> Function() onValidate;
  final Future<void> Function() onClear;
  final Future<void> Function() onCheckout;

  @override
  Widget build(BuildContext context) {
    final total = validation?.total ?? _localTotal;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
            children: [
              Center(
                child: Container(
                  width: 54,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8D2C8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Carrito de compras',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF111111),
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar carrito',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Revisa cantidades, disponibilidad y total antes de continuar.',
                style: TextStyle(color: Color(0xFF68645D)),
              ),
              const SizedBox(height: 18),
              if (products.isEmpty)
                const _EmptyCartMessage()
              else ...[
                for (final product in products) ...[
                  CartProductRow(
                    product: product,
                    quantity: quantities[product.id] ?? 0,
                    onQuantityChanged: (value) =>
                        onQuantityChanged(product, value),
                  ),
                  const SizedBox(height: 12),
                ],
                const Divider(height: 28),
                if (validation != null)
                  CartValidationSummary(validation: validation!),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Total estimado',
                        style: TextStyle(
                          color: Color(0xFF68645D),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF145647),
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Continuar comprando'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => onClear(),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Vaciar carrito'),
                    ),
                    FilledButton.icon(
                      onPressed: validating ? null : () => onValidate(),
                      icon: validating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.verified_outlined),
                      label: Text(validating ? 'Validando' : 'Validar carrito'),
                    ),
                    FilledButton.icon(
                      onPressed: validating ? null : () => onCheckout(),
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('Finalizar compra'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  double get _localTotal {
    return products.fold(0, (total, product) {
      final quantity = quantities[product.id] ?? 0;
      return total + (product.price * quantity);
    });
  }
}

class CartProductRow extends StatelessWidget {
  const CartProductRow({
    required this.product,
    required this.quantity,
    required this.onQuantityChanged,
    super.key,
  });

  final Product product;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    final stock = product.inventory?.stock ?? 0;
    final lineSubtotal = product.price * quantity;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E0D5)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ProductThumbnail(imageUrl: product.imageUrl),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.brand.name} · ${product.category.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF68645D)),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    Text(
                      '\$${product.price.toStringAsFixed(2)} c/u',
                      style: const TextStyle(
                        color: Color(0xFF145647),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Subtotal: \$${lineSubtotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Disponible: $stock',
                      style: const TextStyle(color: Color(0xFF68645D)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          QuantityStepper(
            quantity: quantity,
            maxQuantity: stock,
            onChanged: onQuantityChanged,
          ),
        ],
      ),
    );
  }
}

class ProductThumbnail extends StatelessWidget {
  const ProductThumbnail({required this.imageUrl, super.key});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url != null && url.isNotEmpty) {
      return SizedBox(
        width: 70,
        height: 70,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          semanticLabel: 'Imagen del producto en carrito',
          errorBuilder: (context, error, stackTrace) =>
              const CartProductPlaceholder(),
        ),
      );
    }

    return const CartProductPlaceholder();
  }
}

class CartProductPlaceholder extends StatelessWidget {
  const CartProductPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF5E9D8), Color(0xFFE0D4C2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.spa_outlined, color: Color(0xFF145647), size: 28),
    );
  }
}

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    required this.quantity,
    required this.maxQuantity,
    required this.onChanged,
    super.key,
  });

  final int quantity;
  final int maxQuantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          tooltip: 'Quitar unidad',
          onPressed: () => onChanged(quantity - 1),
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 38,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        IconButton.outlined(
          tooltip: 'Agregar unidad',
          onPressed: quantity >= maxQuantity
              ? null
              : () => onChanged(quantity + 1),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

class CartValidationSummary extends StatelessWidget {
  const CartValidationSummary({required this.validation, super.key});

  final CartValidation validation;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: validation.valid
            ? const Color(0xFFEAF5EF)
            : const Color(0xFFFFF6DB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                validation.valid
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_rounded,
                color: validation.valid
                    ? const Color(0xFF145647)
                    : const Color(0xFF684900),
              ),
              const SizedBox(width: 8),
              Text(
                validation.valid ? 'Carrito valido' : 'Revisar carrito',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Subtotal: \$${validation.subtotal.toStringAsFixed(2)}'),
          Text('IVA 15%: \$${validation.tax.toStringAsFixed(2)}'),
          const Text('Descuentos: \$0.00'),
          const Text('Envio: Por coordinar'),
          Text(
            'Total final: \$${validation.total.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          if (validation.stockAlerts.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final alert in validation.stockAlerts)
              Text(
                'Alerta: $alert',
                style: const TextStyle(color: Color(0xFF684900)),
              ),
          ],
          if (validation.errors.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final error in validation.errors)
              Text(
                'Error: $error',
                style: const TextStyle(color: Color(0xFF8A1C1C)),
              ),
          ],
        ],
      ),
    );
  }
}

class _EmptyCartMessage extends StatelessWidget {
  const _EmptyCartMessage();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(Icons.shopping_bag_outlined, size: 52, color: Color(0xFF68645D)),
          SizedBox(height: 12),
          Text(
            'Tu carrito esta vacio.',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
          SizedBox(height: 6),
          Text('Agrega productos desde el catalogo publico.'),
        ],
      ),
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
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
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
                        initialValue: selectedCategoryId,
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
                        initialValue: selectedBrandId,
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
                          if (fields[i] is Expanded)
                            (fields[i] as Expanded).child
                          else
                            fields[i],
                          if (i != fields.length - 1)
                            const SizedBox(height: 12),
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
  const ProductGrid({
    required this.products,
    required this.onAddToCart,
    super.key,
  });

  final List<Product> products;
  final ValueChanged<Product> onAddToCart;

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
              (context, index) => ProductCard(
                product: products[index],
                onAddToCart: onAddToCart,
              ),
              childCount: products.length,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
              mainAxisExtent: 486,
            ),
          );
        },
      ),
    );
  }
}

class ProductCard extends StatefulWidget {
  const ProductCard({
    required this.product,
    required this.onAddToCart,
    super.key,
  });

  final Product product;
  final ValueChanged<Product> onAddToCart;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final stock = product.inventory?.stock ?? 0;
    final stockLow = stock < 3;
    final hasStock = stock > 0;
    final statusText = stockLow ? 'Ultimas unidades' : 'Disponible';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Semantics(
        container: true,
        label:
            '${product.name}, marca ${product.brand.name}, precio ${product.price.toStringAsFixed(2)} dolares, $statusText',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0.0, _hovered ? -4.0 : 0.0, 0.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _hovered ? 0.12 : 0.05),
                blurRadius: _hovered ? 30 : 18,
                offset: Offset(0, _hovered ? 18 : 10),
              ),
            ],
          ),
          child: Card(
            elevation: 0,
            color: Colors.white,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: _hovered
                    ? const Color(0xFF145647)
                    : const Color(0xFFE6E1D8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ProductImage(imageUrl: product.imageUrl),
                    Positioned(
                      left: 14,
                      top: 14,
                      child: ProductStatusBadge(
                        text: statusText,
                        warning: stockLow,
                      ),
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Material(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: 'Guardar en favoritos',
                          onPressed: () =>
                              _showFavoriteMessage(context, product),
                          icon: const Icon(
                            Icons.favorite_border,
                            color: Color(0xFF145647),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
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
                        const SizedBox(height: 8),
                        Text(
                          product.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF58544D),
                            height: 1.25,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '\$${product.price.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF111111),
                                    ),
                              ),
                            ),
                            StockBadge(
                              stock: stock,
                              hasStock: hasStock,
                              stockLow: stockLow,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () =>
                                _showQuickViewMessage(context, product),
                            icon: const Icon(
                              Icons.visibility_outlined,
                              size: 18,
                            ),
                            label: const Text('Vista rapida'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: hasStock
                                ? () => widget.onAddToCart(product)
                                : null,
                            icon: const Icon(Icons.add_shopping_cart),
                            label: Text(
                              hasStock ? 'Agregar al carrito' : 'Sin stock',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFavoriteMessage(BuildContext context, Product product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${product.name} marcado como favorito para una siguiente iteracion.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showQuickViewMessage(BuildContext context, Product product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Vista rapida de ${product.name} preparada para el siguiente modulo.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class ProductStatusBadge extends StatelessWidget {
  const ProductStatusBadge({
    required this.text,
    required this.warning,
    super.key,
  });

  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: warning
            ? const Color(0xFFFFF1C2)
            : Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: warning ? const Color(0xFFE4B635) : const Color(0xFFE5DED2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            warning ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            size: 16,
            color: warning ? const Color(0xFF684900) : const Color(0xFF145647),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: warning
                  ? const Color(0xFF684900)
                  : const Color(0xFF145647),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
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
          errorBuilder: (context, error, stackTrace) =>
              const ProductPlaceholder(),
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
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: const Icon(
            Icons.spa_outlined,
            color: Color(0xFF145647),
            size: 42,
          ),
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
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F4),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: TopNavigationSkeleton()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 34, 24, 18),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _SkeletonBox(width: 260, height: 32),
                      SizedBox(height: 12),
                      _SkeletonBox(width: 520, height: 18),
                      SizedBox(height: 28),
                      _SkeletonBox(width: double.infinity, height: 84),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 48),
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
                    (context, index) => const _SkeletonProductCard(),
                    childCount: columns * 2,
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
          ),
        ],
      ),
    );
  }
}

class TopNavigationSkeleton extends StatelessWidget {
  const TopNavigationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Row(
                children: [
                  _SkeletonBox(width: 52, height: 52, radius: 16),
                  SizedBox(width: 14),
                  _SkeletonBox(width: 180, height: 26),
                  Spacer(),
                  _SkeletonBox(width: 360, height: 38, radius: 999),
                ],
              ),
              SizedBox(height: 18),
              _SkeletonBox(width: double.infinity, height: 54, radius: 999),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonProductCard extends StatelessWidget {
  const _SkeletonProductCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6E1D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SkeletonBox(width: double.infinity, height: 210, radius: 0),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(width: 90, height: 14),
                SizedBox(height: 12),
                _SkeletonBox(width: 210, height: 24),
                SizedBox(height: 10),
                _SkeletonBox(width: 130, height: 14),
                SizedBox(height: 72),
                _SkeletonBox(width: 120, height: 28),
                SizedBox(height: 16),
                _SkeletonBox(width: double.infinity, height: 44, radius: 999),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 10,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE9E2D8),
        borderRadius: BorderRadius.circular(radius),
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
                const Icon(
                  Icons.wifi_off_outlined,
                  size: 48,
                  color: Color(0xFF8A1C1C),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
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
                  style: const TextStyle(
                    color: Color(0xFF6D6A62),
                    fontSize: 12,
                  ),
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
              Icon(
                Icons.search_off_outlined,
                size: 52,
                color: Color(0xFF6D6A62),
              ),
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

  static Future<CartValidation> validateCart(Map<int, int> quantities) async {
    final items = quantities.entries
        .map((entry) => {'productoId': entry.key, 'cantidad': entry.value})
        .toList();
    final json = await _postJson('$apiBaseUrl/carrito/validar', {
      'items': items,
    });
    return CartValidation.fromJson(json);
  }

  static Future<Map<String, dynamic>> _getJson(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error HTTP ${response.statusCode}: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> _postJson(
    String url,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse(url),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
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

class CartValidation {
  const CartValidation({
    required this.valid,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.taxPercent,
    required this.stockAlerts,
    required this.errors,
  });

  final bool valid;
  final double subtotal;
  final double tax;
  final double total;
  final double taxPercent;
  final List<String> stockAlerts;
  final List<String> errors;

  factory CartValidation.fromJson(Map<String, dynamic> json) {
    final alerts = json['alertasStock'];
    final errors = json['errores'];

    return CartValidation(
      valid: json['valido'] == true,
      subtotal: _asDouble(json['subtotal']),
      tax: _asDouble(json['impuesto']),
      total: _asDouble(json['total']),
      taxPercent: _asDouble(json['porcentajeImpuesto']),
      stockAlerts: alerts is List
          ? alerts
                .map((alert) {
                  if (alert is Map) return _asString(alert['mensaje']);
                  return _asString(alert);
                })
                .where((message) => message.isNotEmpty)
                .toList()
          : const [],
      errors: errors is List
          ? errors
                .map(_asString)
                .where((message) => message.isNotEmpty)
                .toList()
          : const [],
    );
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
      brand: Brand.fromJson(
        (json['marca'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
      category: Category.fromJson(
        (json['categoria'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
      inventory: json['inventario'] is Map
          ? Inventory.fromJson(
              (json['inventario'] as Map).cast<String, dynamic>(),
            )
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
