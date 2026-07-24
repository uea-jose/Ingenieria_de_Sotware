import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_design_tokens.dart';
import '../../data/api/api_service.dart';
import '../../data/storage/cart_storage.dart';
import '../../models/brand.dart';
import '../../models/cart_validation.dart';
import '../../models/catalog_data.dart';
import '../../models/category.dart';
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
import '../product_detail/product_detail_page.dart';
import 'demo_home_catalog.dart';
import 'home_commercial_sections.dart';
import 'home_search_box.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<CatalogData> _catalogFuture;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _heroController = PageController();
  Timer? _heroTimer;
  Timer? _searchDebounce;
  int _heroIndex = 0;
  int _highlightedSuggestion = 0;
  int? _selectedCategoryId;
  int? _selectedBrandId;
  String _searchText = '';
  List<String> _suggestionTerms = const [];
  List<Product> _searchSuggestions = const [];
  List<Product> _currentProductsForSearch = const [];
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
      colors: [AppColors.bgSoftPink, AppColors.bgLavender, AppColors.bgBlue],
      accentColor: AppColors.primary,
    ),
    HeroSlide(
      eyebrow: 'Promociones vigentes',
      title: 'Descubre ofertas para renovar tu estilo',
      description:
          'Encuentra productos con descuentos, stock visible y categorias faciles de explorar.',
      offer: 'Ofertas destacadas',
      buttonText: 'Explorar promociones',
      colors: [AppColors.bgPeach, AppColors.bgSoftPink, AppColors.bgLavender],
      accentColor: AppColors.accentPeach,
    ),
    HeroSlide(
      eyebrow: 'Compra segura',
      title: 'Una tienda clara, rapida y confiable',
      description:
          'Diseno centrado en el usuario: menos friccion, mejor lectura y acciones predecibles.',
      offer: 'Experiencia simple',
      buttonText: 'Comenzar',
      colors: [AppColors.bgMint, AppColors.bgBlue, AppColors.bgLavender],
      accentColor: AppColors.accentMint,
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
      if (_searchFocusNode.hasFocus) return;
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
    _searchDebounce?.cancel();
    _searchFocusNode.dispose();
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
    final context = _catalogKey.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
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

  Future<void> _openProductDetail(Product product) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ProductDetailPage(
          productId: product.id,
          initialProduct: product,
          cartCount: _cartCount,
          onAddToCart: _addToCart,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
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

  CatalogData _catalogForDisplay(CatalogData data) {
    final demo = buildDemoCatalog();
    if (data.products.isEmpty) return demo;

    if (data.products.length >= 8) return data;

    return CatalogData(
      products: _mergeProducts(data.products, demo.products),
      categories: _mergeCategories(data.categories, demo.categories),
      brands: _mergeBrands(data.brands, demo.brands),
    );
  }

  List<Product> _mergeProducts(List<Product> real, List<Product> demo) {
    final ids = real.map((product) => product.id).toSet();
    return [...real, ...demo.where((product) => !ids.contains(product.id))];
  }

  List<Category> _mergeCategories(List<Category> real, List<Category> demo) {
    final ids = real.map((category) => category.id).toSet();
    return [...real, ...demo.where((category) => !ids.contains(category.id))];
  }

  List<Brand> _mergeBrands(List<Brand> real, List<Brand> demo) {
    final ids = real.map((brand) => brand.id).toSet();
    return [...real, ...demo.where((brand) => !ids.contains(brand.id))];
  }

  void _handleSearchChanged(String value, List<Product> products) {
    _searchDebounce?.cancel();
    setState(() => _searchText = value);
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _searchSuggestions = _findSuggestions(value, products);
        _suggestionTerms = _findSuggestionTerms(value, products);
        _highlightedSuggestion = 0;
      });
    });
  }

  List<Product> _findSuggestions(String value, List<Product> products) {
    final query = value.trim().toLowerCase();
    if (query.isEmpty) return const [];

    return products
        .where((product) {
          final text = [
            product.name,
            product.brand.name,
            product.category.name,
            product.description,
            product.code,
          ].join(' ').toLowerCase();
          return product.active && text.contains(query);
        })
        .take(6)
        .toList();
  }

  List<String> _findSuggestionTerms(String value, List<Product> products) {
    final query = value.trim().toLowerCase();
    if (query.isEmpty) return const [];

    final terms = <String>{
      for (final product in products) ...[
        product.brand.name,
        product.category.name,
        product.name,
        if (product.description.toLowerCase().contains('hombre'))
          'Perfumes para hombre',
        if (product.description.toLowerCase().contains('mujer'))
          'Perfumes para mujer',
        if (product.description.toLowerCase().contains('unisex'))
          'Perfumes unisex',
      ],
      'Perfumes',
      'Sets y regalos',
    }.where((term) => term.trim().isNotEmpty).toList();

    terms.sort((a, b) {
      final aStarts = a.toLowerCase().startsWith(query);
      final bStarts = b.toLowerCase().startsWith(query);
      if (aStarts != bStarts) return aStarts ? -1 : 1;
      return a.length.compareTo(b.length);
    });

    return terms
        .where((term) => term.toLowerCase().contains(query))
        .take(10)
        .toList();
  }

  KeyEventResult _handleSearchKeys(KeyEvent event) {
    if (event is! KeyDownEvent || _searchText.trim().isEmpty) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _searchFocusNode.unfocus();
      setState(() {
        _searchSuggestions = const [];
        _suggestionTerms = const [];
      });
      return KeyEventResult.handled;
    }

    if (_searchSuggestions.isEmpty) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _highlightedSuggestion =
            (_highlightedSuggestion + 1) % _searchSuggestions.length;
      });
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _highlightedSuggestion =
            (_highlightedSuggestion - 1 + _searchSuggestions.length) %
            _searchSuggestions.length;
      });
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _selectSuggestion(_searchSuggestions[_highlightedSuggestion]);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _selectSuggestion(Product product) {
    _searchController.value = TextEditingValue(
      text: product.name,
      selection: TextSelection.collapsed(offset: product.name.length),
    );
    setState(() {
      _searchText = product.name;
      _searchSuggestions = const [];
      _suggestionTerms = const [];
    });
    _searchFocusNode.unfocus();
    _scrollToCatalog();
    _showSnackBar('${product.name} seleccionado en la portada.');
  }

  void _selectSuggestionTerm(String term) {
    _searchController.value = TextEditingValue(
      text: term,
      selection: TextSelection.collapsed(offset: term.length),
    );
    setState(() {
      _searchText = term;
      _searchSuggestions = _findSuggestions(term, _currentProductsForSearch);
      _suggestionTerms = _findSuggestionTerms(term, _currentProductsForSearch);
      _highlightedSuggestion = 0;
    });
    _searchFocusNode.requestFocus();
  }

  void _closeSearchPanel() {
    _searchFocusNode.unfocus();
    setState(() {
      _searchSuggestions = const [];
      _suggestionTerms = const [];
      _highlightedSuggestion = 0;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchText = '';
      _searchSuggestions = const [];
      _suggestionTerms = const [];
      _highlightedSuggestion = 0;
    });
  }

  void _applyLocalShortcut(String value) {
    _searchController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    setState(() {
      _searchText = value;
      _searchSuggestions = const [];
      _suggestionTerms = const [];
      _selectedCategoryId = null;
      _selectedBrandId = null;
    });
    _scrollToCatalog();
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

          final hasBackendError = snapshot.hasError;
          final data = _catalogForDisplay(snapshot.data ?? CatalogData.empty());
          _currentProductsForSearch = data.products;
          final products = _applyFilters(data.products);
          final featuredProducts = data.products.take(4).toList();
          final bestSellers = data.products.skip(4).take(4).isEmpty
              ? featuredProducts
              : data.products.skip(4).take(4).toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: TopNavigation(
                  onCatalogPressed: _scrollToCatalog,
                  onCartPressed: () => _openCartPanel(data.products),
                  cartCount: _cartCount,
                  searchBox: HomeSearchBox(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    query: _searchText,
                    suggestionTerms: _suggestionTerms,
                    suggestions: _searchSuggestions,
                    highlightedIndex: _highlightedSuggestion,
                    onChanged: (value) =>
                        _handleSearchChanged(value, data.products),
                    onClear: _clearSearch,
                    onClose: _closeSearchPanel,
                    onSubmitted: (_) => _scrollToCatalog(),
                    onTermSelected: _selectSuggestionTerm,
                    onSuggestionSelected: _selectSuggestion,
                    onViewAll: _scrollToCatalog,
                    onQuickView: (product) {
                      _selectSuggestion(product);
                      _showSnackBar(
                        'Vista rapida de ${product.name} preparada para el siguiente modulo.',
                      );
                    },
                    onKeyboardNavigation: _handleSearchKeys,
                  ),
                ),
              ),
              if (hasBackendError)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1280),
                        child: ErrorView(
                          message: 'Mostrando catalogo de demostracion.',
                          details:
                              'El backend no respondio. La portada usa productos simulados locales.',
                          onRetry: _reloadCatalog,
                        ),
                      ),
                    ),
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
                child: CategoryShortcuts(onSelected: _applyLocalShortcut),
              ),
              SliverToBoxAdapter(
                child: ProductShowcaseSection(
                  title: 'Productos destacados',
                  subtitle:
                      'Perfumes de muestra y catalogo real en una misma experiencia.',
                  products: featuredProducts,
                  onAddToCart: _addToCart,
                  onViewDetails: _openProductDetail,
                ),
              ),
              SliverToBoxAdapter(
                child: PromoBannerSection(
                  onPressed: () => _applyLocalShortcut('Oferta'),
                ),
              ),
              SliverToBoxAdapter(
                child: ProductShowcaseSection(
                  title: 'Mas vendidos',
                  subtitle:
                      'Opciones populares para comparar rapido sin salir de la portada.',
                  products: bestSellers,
                  onAddToCart: _addToCart,
                  onViewDetails: _openProductDetail,
                ),
              ),
              SliverToBoxAdapter(
                child: BrandShowcaseSection(
                  brands: data.brands,
                  onTap: _applyLocalShortcut,
                ),
              ),
              SliverToBoxAdapter(
                child: OccasionSection(onTap: _applyLocalShortcut),
              ),
              const SliverToBoxAdapter(child: BenefitsSection()),
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
                ProductGrid(
                  products: products,
                  onAddToCart: _addToCart,
                  onViewDetails: _openProductDetail,
                ),
              SliverToBoxAdapter(
                child: HomeFooter(onExplore: _scrollToCatalog),
              ),
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
          product.category.name.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query) ||
          product.code.toLowerCase().contains(query);
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
      color: AppColors.bgPage,
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
                        ? AppColors.primary
                        : AppColors.borderSoft,
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
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                  height: 1.02,
                                ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            slide.description,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
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
                                  foregroundColor: AppColors.surface,
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
                                  color: AppColors.textPrimary,
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
            color: AppColors.surface.withValues(alpha: 0.54),
            shape: BoxShape.circle,
          ),
        ),
        Transform.rotate(
          angle: -0.12,
          child: Container(
            width: 155,
            height: 285,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.block),
              boxShadow: AppShadows.hover,
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
                  color: AppColors.primary,
                  size: 44,
                ),
                const SizedBox(height: 22),
                const Text(
                  'AROMAS',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                const Text(
                  'STORE',
                  style: TextStyle(
                    color: AppColors.textSecondary,
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
      color: AppColors.bgLavender,
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
        Icon(icon, color: AppColors.primary),
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
                style: const TextStyle(color: AppColors.textSecondary),
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
      color: AppColors.bgPage,
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: AppColors.borderSoft),
          boxShadow: AppShadows.base,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.bgMint,
                borderRadius: BorderRadius.circular(AppRadii.search),
              ),
              child: Icon(icon, color: AppColors.primary),
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
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      height: 1.25,
                      color: AppColors.textSecondary,
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
