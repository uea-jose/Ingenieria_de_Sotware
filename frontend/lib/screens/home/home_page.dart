import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/api/api_service.dart';
import '../../data/storage/cart_storage.dart';
import '../../models/cart_validation.dart';
import '../../models/catalog_data.dart';
import '../../models/product.dart';
import '../../widgets/catalog/catalog_filters.dart';
import '../../widgets/catalog/catalog_section_header.dart';
import '../../widgets/catalog/empty_catalog_view.dart';
import '../../widgets/catalog/product_grid.dart';
import '../../widgets/cart/cart_panel.dart';
import '../../widgets/cart/cart_preview_bar.dart';
import '../../widgets/feedback/error_view.dart';
import '../../widgets/feedback/loading_view.dart';
import '../../widgets/layout/top_navigation.dart';

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
    _cartQuantities.addAll(CartStorage.load());
  }

  void _persistCart() {
    CartStorage.save(_cartQuantities);
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
