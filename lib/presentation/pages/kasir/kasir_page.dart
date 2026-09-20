import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

import '../../blocs/product/product_bloc.dart';
import '../../blocs/category/category_bloc.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/business/business_bloc.dart';
import '../../blocs/customer/customer_bloc.dart';
import '../../blocs/promo/promo_bloc.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../domain/entities/customer_entity.dart';
import '../../../domain/entities/promo_entity.dart';
import '../../../core/style/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../widgets/barcode_scanner_page.dart';
import '../checkout/checkout_page.dart';
import '../customer/add_edit_customer_page.dart';
import 'widgets/product_customization_sheet.dart';

class KasirPage extends StatefulWidget {
  final VoidCallback? onOpenOrders;
  final VoidCallback? onOpenDrawer;

  const KasirPage({super.key, this.onOpenOrders, this.onOpenDrawer});

  @override
  State<KasirPage> createState() => _KasirPageState();
}

class _KasirPageState extends State<KasirPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String _selectedCategoryId = 'all';
  bool _isGridView = true;

  // Tablet POS state
  String _orderType = 'Dine In'; // 'Dine In' | 'Take Away'
  String? _tableNumber;
  PromoEntity? _selectedPromo;

  @override
  void initState() {
    super.initState();
    context.read<CategoryBloc>().add(LoadCategories());
    context.read<ProductBloc>().add(LoadProducts());
    context.read<CustomerBloc>().add(LoadCustomers());
    context.read<PromoBloc>().add(LoadPromos());
    final bState = context.read<BusinessBloc>().state;
    if (bState.businessInfo == null) {
      context.read<BusinessBloc>().add(LoadBusinessInfo());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onProductSelected(Product product) {
    if (product.stock <= 0) {
      AppToast.showWarning(context, 'Stok ${product.name} telah habis');
      return;
    }

    if (product.hasVariants || product.hasModifiers) {
      ProductCustomizationSheet.show(
        context: context,
        product: product,
        onAddToCart: ({
          required variant,
          required modifiers,
          required notes,
          required quantity,
        }) {
          context.read<CartBloc>().add(
            AddToCart(
              product,
              selectedVariant: variant,
              selectedModifiers: modifiers,
              notes: notes,
              quantity: quantity,
            ),
          );
        },
      );
    } else {
      context.read<CartBloc>().add(AddToCart(product));
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final isTablet = MediaQuery.of(context).size.width >= 720;

    return Material(
      color: const Color(0xFFF8FAFC),
      child: SafeArea(
        child: isTablet
            ? _buildTabletLayout(currencyFormatter)
            : _buildPhoneLayout(currencyFormatter),
      ),
    );
  }

  // Mobile / Phone Layout
  Widget _buildPhoneLayout(NumberFormat currencyFormatter) {
    return Stack(
      children: [
        Column(
          children: [
            _buildTopHeader(),
            _buildSearchBar(),
            _buildCategoryAndFilterBar(),
            Expanded(
              child: _isGridView
                  ? _buildProductGrid(currencyFormatter)
                  : _buildProductList(currencyFormatter),
            ),
          ],
        ),
        _buildFloatingCartBanner(currencyFormatter),
      ],
    );
  }

  // 1. Top Header: Business Logo, Online Status Dot, Store & Role Info, User Avatar
  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: BlocBuilder<BusinessBloc, BusinessState>(
              builder: (context, bState) {
                final businessInfo = bState.businessInfo;
                final businessName =
                    businessInfo?.businessName.isNotEmpty == true &&
                        businessInfo?.businessName != 'Toko Saya'
                    ? businessInfo!.businessName
                    : 'Laci POS';
                final logoUrl = businessInfo?.logoUrl;
                final hasLogo = logoUrl != null && logoUrl.isNotEmpty;

                return Row(
                  children: [
                    // Business Logo / App Icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: hasLogo
                            ? const Color(0xFFF1F5F9)
                            : AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: hasLogo
                            ? CachedNetworkImage(
                                imageUrl: logoUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Center(
                                      child: Icon(
                                        Icons.storefront_rounded,
                                        color: Color(0xFF64748B),
                                        size: 20,
                                      ),
                                    ),
                              )
                            : SvgPicture.asset("assets/icons/logo.svg"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // App Name & Store Subtitle
                    Expanded(
                      child: BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, aState) {
                          final roleName = (aState is Authenticated)
                              ? _capitalize(aState.user.role.name)
                              : 'Kasir';

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      businessName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                        letterSpacing: -0.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(
                                        0xFF10B981,
                                      ), // Emerald online dot
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 1),
                              Text(
                                businessName != 'Laci POS'
                                    ? 'Laci POS • $roleName'
                                    : roleName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          // User Avatar
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is Authenticated && state.user.photoUrl != null) {
                return CircleAvatar(
                  radius: 17,
                  backgroundColor: const Color(0xFF004D40),
                  backgroundImage: NetworkImage(state.user.photoUrl!),
                );
              }
              return const CircleAvatar(
                radius: 17,
                backgroundColor: Color(0xFF004D40),
                child: Icon(Icons.person, color: Colors.white, size: 18),
              );
            },
          ),
        ],
      ),
    );
  }

  // 2. Full-width Search Input with Scanner Action
  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.search,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                size: 20,
              ),
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 13.5,
                ),
                decoration: InputDecoration(
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                  hintText: 'Cari menu, SKU, atau varian...',
                  hintStyle: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontSize: 13.5,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              IconButton(
                icon: Icon(
                  Icons.clear,
                  size: 18,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              ),
            IconButton(
              icon: const Icon(
                Icons.qr_code_scanner_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              onPressed: _openBarcodeSearch,
            ),
          ],
        ),
      ),
    );
  }

  // 3. Category Horizontal Pills & Grid/List View Toggle
  Widget _buildCategoryAndFilterBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: BlocBuilder<CategoryBloc, CategoryState>(
              builder: (context, state) {
                List<Category> categories = [];
                if (state.isSuccess) {
                  categories = state.categories;
                }

                return SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length + 1,
                    itemBuilder: (context, index) {
                      final isAll = index == 0;
                      final category = isAll ? null : categories[index - 1];
                      final id = isAll ? 'all' : category!.id;
                      final name = isAll ? 'Semua' : category!.name;
                      final isSelected = _selectedCategoryId == id;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => setState(() => _selectedCategoryId = id),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark ? Colors.white : AppColors.darkCharcoal)
                                  : (isDark ? const Color(0xFF1E293B) : Colors.white),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? (isDark ? Colors.white : AppColors.darkCharcoal)
                                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              name,
                              style: TextStyle(
                                color: isSelected
                                    ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                                    : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          // Grid vs List Toggle
          Container(
            height: 38,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                _buildViewToggleButton(
                  icon: Icons.grid_view_rounded,
                  isActive: _isGridView,
                  onTap: () => setState(() => _isGridView = true),
                ),
                const SizedBox(width: 2),
                _buildViewToggleButton(
                  icon: Icons.format_list_bulleted_rounded,
                  isActive: !_isGridView,
                  onTap: () => setState(() => _isGridView = false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggleButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? const Color(0xFF334155) : AppColors.bgInput)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 18,
            color: isActive ? AppColors.primary : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  // 4. Product 2-Column Grid matching reference mockup
  Widget _buildProductGrid(NumberFormat formatter) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state.isLoading && state.products.isEmpty) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        if (state.isSuccess) {
          final filteredProducts = _filterProducts(state.products);

          if (filteredProducts.isEmpty) {
            return _buildEmptyState();
          }

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.68,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
            ),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              return _buildGridProductCard(product, formatter);
            },
          );
        }

        return const SizedBox();
      },
    );
  }

  // 5. Product List View (Toggled alternative)
  Widget _buildProductList(NumberFormat formatter) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state.isLoading && state.products.isEmpty) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        if (state.isSuccess) {
          final filteredProducts = _filterProducts(state.products);

          if (filteredProducts.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
            itemCount: filteredProducts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              return _buildListProductCard(product, formatter);
            },
          );
        }

        return const SizedBox();
      },
    );
  }

  List<Product> _filterProducts(List<Product> products) {
    return products.where((p) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch =
          p.name.toLowerCase().contains(query) ||
          (p.sku?.toLowerCase().contains(query) ?? false);
      final matchesCategory =
          _selectedCategoryId == 'all' || p.categoryId == _selectedCategoryId;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  // Individual Product Card (Grid View)
  Widget _buildGridProductCard(Product product, NumberFormat formatter) {
    final isOutOfStock = product.stock <= 0;
    final isLowStock = !isOutOfStock && product.stock <= 5;

    return Container(
      decoration: BoxDecoration(
        color: isOutOfStock ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOutOfStock
              ? const Color(0xFFE2E8F0)
              : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _onProductSelected(product),
          child: Opacity(
            opacity: isOutOfStock ? 0.62 : 1.0,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image Container with Stock Badge
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      children: [
                        ColorFiltered(
                          colorFilter: isOutOfStock
                              ? const ColorFilter.mode(
                                  Colors.grey,
                                  BlendMode.saturation,
                                )
                              : const ColorFilter.mode(
                                  Colors.transparent,
                                  BlendMode.multiply,
                                ),
                          child:
                              product.imageUrl != null &&
                                  product.imageUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: product.imageUrl!,
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    height: 140,
                                    color: const Color(0xFFF1F5F9),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      _buildImageFallback(),
                                )
                              : _buildImageFallback(),
                        ),
                        // Stock Badge Pill (Top-Left)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: isOutOfStock
                                  ? const Color(0xFFFEE2E2)
                                  : Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                              border: isOutOfStock
                                  ? Border.all(color: const Color(0xFFFECACA))
                                  : null,
                            ),
                            child: Text(
                              isOutOfStock
                                  ? 'Habis'
                                  : 'Sisa ${product.stock > 1000 ? '∞' : product.stock}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isOutOfStock
                                    ? const Color(0xFFDC2626)
                                    : (isLowStock
                                          ? const Color(0xFFDC2626)
                                          : const Color(0xFF334155)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Product Name
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: isOutOfStock
                          ? const Color(0xFF64748B)
                          : const Color(0xFF0F172A),
                      height: 1.25,
                    ),
                  ),
                  const Spacer(),
                  // Bottom Row: Price & Circular Plus Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          formatter.format(product.price).trim(),
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: isOutOfStock
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        onTap: () => _onProductSelected(product),
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: isOutOfStock
                                ? const Color(0xFFE2E8F0)
                                : AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              isOutOfStock
                                  ? Icons.block_rounded
                                  : ((product.hasVariants ||
                                          product.hasModifiers)
                                      ? Icons.tune_rounded
                                      : Icons.add),
                              color: isOutOfStock
                                  ? const Color(0xFF94A3B8)
                                  : Colors.white,
                              size: isOutOfStock ? 16 : 19,
                            ),
                          ),
                        ),
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

  // Individual Product Card (List View alternative)
  Widget _buildListProductCard(Product product, NumberFormat formatter) {
    final isOutOfStock = product.stock <= 0;
    final isLowStock = !isOutOfStock && product.stock <= 5;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isOutOfStock ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _onProductSelected(product),
        child: Opacity(
          opacity: isOutOfStock ? 0.62 : 1.0,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: ColorFiltered(
                    colorFilter: isOutOfStock
                        ? const ColorFilter.mode(
                            Colors.grey,
                            BlendMode.saturation,
                          )
                        : const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.multiply,
                          ),
                    child:
                        product.imageUrl != null && product.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) =>
                                _buildImageFallback(),
                          )
                        : _buildImageFallback(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: isOutOfStock
                            ? const Color(0xFF64748B)
                            : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isOutOfStock
                            ? const Color(0xFFFEE2E2)
                            : (isLowStock
                                  ? const Color(0xFFFEE2E2)
                                  : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(6),
                        border: isOutOfStock
                            ? Border.all(color: const Color(0xFFFECACA))
                            : null,
                      ),
                      child: Text(
                        isOutOfStock
                            ? 'Habis'
                            : 'Sisa ${product.stock > 1000 ? '∞' : product.stock}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isOutOfStock
                              ? const Color(0xFFDC2626)
                              : (isLowStock
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF64748B)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatter.format(product.price).trim(),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isOutOfStock
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _onProductSelected(product),
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isOutOfStock
                        ? const Color(0xFFE2E8F0)
                        : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      isOutOfStock
                          ? Icons.block_rounded
                          : ((product.hasVariants || product.hasModifiers)
                              ? Icons.tune_rounded
                              : Icons.add),
                      color: isOutOfStock
                          ? const Color(0xFF94A3B8)
                          : Colors.white,
                      size: isOutOfStock ? 16 : 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageFallback() {
    return Container(
      height: 140,
      width: double.infinity,
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: Icon(
          Icons.fastfood_outlined,
          color: Color(0xFF94A3B8),
          size: 36,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset("assets/icons/product.svg", height: 64),
          const SizedBox(height: 12),
          const Text(
            'Tidak ada menu ditemukan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // 6. Floating Cart Banner (Pill container at bottom)
  Widget _buildFloatingCartBanner(NumberFormat formatter) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        if (state.items.isEmpty) return const SizedBox();

        final totalQuantity = state.items.fold(
          0,
          (sum, item) => sum + item.quantity,
        );

        return Positioned(
          bottom: 12,
          left: 16,
          right: 16,
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.textSecondary, width: 0.2),
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                // Left: Shopping bag in primary teal container with amber badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SvgPicture.asset("assets/icons/cart.svg", height: 38),
                    Positioned(
                      top: -3,
                      right: -3,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF59E0B), // Amber badge
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$totalQuantity',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Middle: Text
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$totalQuantity ITEM TERPILIH',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      formatter.format(state.totalAmount).trim(),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Right: "Lihat Pesanan ->" Button
                InkWell(
                  onTap: () {
                    if (widget.onOpenOrders != null) {
                      widget.onOpenOrders!();
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CheckoutPage()),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Text(
                          'Lihat Pesanan',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(width: 5),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.textPrimary,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openBarcodeSearch() async {
    final scannedCode = await BarcodeScannerPage.scan(
      context,
      title: 'Pindai Barcode / SKU',
      instruction: 'Arahkan kamera ke barcode produk',
    );

    if (scannedCode == null || scannedCode.trim().isEmpty) return;
    final code = scannedCode.trim();

    if (!mounted) return;

    // Search product by SKU or ID
    final productState = context.read<ProductBloc>().state;
    final products = productState.products;

    final matched = products.where(
      (p) =>
          (p.sku != null &&
              p.sku!.trim().toLowerCase() == code.toLowerCase()) ||
          p.id.toLowerCase() == code.toLowerCase(),
    );

    if (matched.isNotEmpty) {
      final product = matched.first;
      if (product.stock <= 0) {
        AppToast.showWarning(
          context,
          'Produk ${product.name} ditemukan, namun stok habis',
        );
      } else {
        _onProductSelected(product);
      }
      setState(() {
        _searchQuery = product.name;
      });
      _searchController.text = product.name;
    } else {
      setState(() {
        _searchQuery = code;
      });
      _searchController.text = code;
      AppToast.showWarning(
        context,
        'Produk dengan SKU/Barcode "$code" tidak ditemukan',
      );
    }
  }

  Widget _buildTabletLayout(NumberFormat currencyFormatter) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, catState) {
        List<Category> categories = [];
        if (catState.isSuccess) {
          categories = catState.categories;
        }

        return Row(
          children: [
            _buildTabletCategorySidebar(categories),
            Expanded(
              child: Container(
                color: const Color(0xFFF8FAFC),
                child: Column(
                  children: [
                    _buildTabletHeader(),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE2E8F0),
                    ),
                    Expanded(
                      child: _isGridView
                          ? _buildTabletProductGrid(currencyFormatter)
                          : _buildProductList(currencyFormatter),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Right Sidebar: Order Details / Cart Panel
            _buildTabletCartPanel(currencyFormatter),
          ],
        );
      },
    );
  }

  // 1. Left Sidebar: Vertical Category Navigation
  Widget _buildTabletCategorySidebar(List<Category> categories) {
    return Container(
      width: 92,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Column(
        children: [
          SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              if (widget.onOpenDrawer != null) {
                widget.onOpenDrawer!();
              } else {
                context
                    .findRootAncestorStateOfType<ScaffoldState>()
                    ?.openDrawer();
              }
            },
            child: SvgPicture.asset(
              "assets/icons/humberger_menu.svg",
              height: 36,
            ),
          ),
          const SizedBox(width: 8),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: categories.length + 1,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemBuilder: (context, index) {
                final isAll = index == 0;
                final cat = isAll ? null : categories[index - 1];
                final id = isAll ? 'all' : cat!.id;
                final name = isAll ? 'All Menu' : cat!.name;
                final isSelected = _selectedCategoryId == id;
                final icon = isAll
                    ? Icons.restaurant_menu_rounded
                    : _getCategoryIcon(name);

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: InkWell(
                    onTap: () => setState(() => _selectedCategoryId = id),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.grey.shade100
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icon,
                                size: 26,
                                color: isSelected
                                    ? AppColors.primary
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.textPrimary
                                      : const Color(0xFF334155),
                                  height: 1.15,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Category Icon Mapper
  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('burger')) return Icons.lunch_dining_rounded;
    if (lower.contains('ayam') ||
        lower.contains('chicken') ||
        lower.contains('wings') ||
        lower.contains('drumstick')) {
      return Icons.kebab_dining_rounded;
    }
    if (lower.contains('minum') ||
        lower.contains('drink') ||
        lower.contains('beverage') ||
        lower.contains('cola') ||
        lower.contains('sprite') ||
        lower.contains('jus') ||
        lower.contains('tea') ||
        lower.contains('teh')) {
      return Icons.local_drink_rounded;
    }
    if (lower.contains('kopi') ||
        lower.contains('coffee') ||
        lower.contains('cappuccino') ||
        lower.contains('latte') ||
        lower.contains('espresso')) {
      return Icons.coffee_rounded;
    }
    if (lower.contains('dessert') ||
        lower.contains('es') ||
        lower.contains('ice') ||
        lower.contains('sundae') ||
        lower.contains('manis') ||
        lower.contains('cake') ||
        lower.contains('kue')) {
      return Icons.icecream_rounded;
    }
    if (lower.contains('snack') ||
        lower.contains('cemilan') ||
        lower.contains('roti') ||
        lower.contains('fries') ||
        lower.contains('kentang')) {
      return Icons.cookie_rounded;
    }
    if (lower.contains('nasi') ||
        lower.contains('rice') ||
        lower.contains('mie') ||
        lower.contains('noodle') ||
        lower.contains('makan')) {
      return Icons.rice_bowl_rounded;
    }
    return Icons.fastfood_rounded;
  }

  Widget _buildTabletHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          BlocBuilder<BusinessBloc, BusinessState>(
            builder: (context, bState) {
              final businessInfo = bState.businessInfo;
              final businessName =
                  businessInfo?.businessName.isNotEmpty == true &&
                      businessInfo?.businessName != 'Toko Saya'
                  ? businessInfo!.businessName
                  : 'Laci POS';
              final logoUrl = businessInfo?.logoUrl;
              final hasLogo = logoUrl != null && logoUrl.isNotEmpty;

              return Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: hasLogo
                          ? CachedNetworkImage(
                              imageUrl: logoUrl,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Icon(
                                Icons.storefront_rounded,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                                size: 18,
                              ),
                            )
                          : SvgPicture.asset("assets/icons/logo.svg"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            businessName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            width: 6.5,
                            height: 6.5,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Mode Kasir POS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 18),

          // Center Search Box with Barcode Scan
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(
                      Icons.search_rounded,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                      size: 18,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        fillColor: Colors.transparent,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        hintText: 'Cari produk atau SKU...',
                        hintStyle: TextStyle(
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: Icon(
                        Icons.clear,
                        size: 16,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    ),
                  IconButton(
                    icon: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    onPressed: _openBarcodeSearch,
                    tooltip: 'Pindai Barcode / SKU',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),

          // View Mode Toggle (Grid vs List)
          Container(
            height: 38,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                _buildViewToggleButton(
                  icon: Icons.grid_view_rounded,
                  isActive: _isGridView,
                  onTap: () => setState(() => _isGridView = true),
                ),
                const SizedBox(width: 2),
                _buildViewToggleButton(
                  icon: Icons.format_list_bulleted_rounded,
                  isActive: !_isGridView,
                  onTap: () => setState(() => _isGridView = false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Tablet Product Grid (ClaPos Style)
  Widget _buildTabletProductGrid(NumberFormat formatter) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, pState) {
        if (pState.isLoading && pState.products.isEmpty) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        if (pState.isSuccess) {
          final filteredProducts = _filterProducts(pState.products);

          if (filteredProducts.isEmpty) {
            return _buildEmptyState();
          }

          return BlocBuilder<CartBloc, CartState>(
            builder: (context, cartState) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = (constraints.maxWidth / 165)
                      .floor()
                      .clamp(2, 6);

                  return GridView.builder(
                    padding: const EdgeInsets.all(14),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.78,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final cartQty = cartState.items
                          .where((i) => i.productId == product.id)
                          .fold(0, (sum, i) => sum + i.quantity);

                      return _buildTabletGridProductCard(
                        product,
                        formatter,
                        cartQty,
                      );
                    },
                  );
                },
              );
            },
          );
        }

        return const SizedBox();
      },
    );
  }

  // Tablet Grid Product Card
  Widget _buildTabletGridProductCard(
    Product product,
    NumberFormat formatter,
    int cartQty,
  ) {
    final isOutOfStock = product.stock <= 0;
    final isLowStock = !isOutOfStock && product.stock <= 5;
    final inCart = cartQty > 0;

    return Container(
      decoration: BoxDecoration(
        color: isOutOfStock ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: inCart
              ? AppColors.darkCharcoal.withValues(alpha: 0.15)
              : const Color(0xFFE2E8F0),
          width: inCart ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _onProductSelected(product),
          child: Opacity(
            opacity: isOutOfStock ? 0.62 : 1.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image Container with Stock Pill
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            children: [
                              ColorFiltered(
                                colorFilter: isOutOfStock
                                    ? const ColorFilter.mode(
                                        Colors.grey,
                                        BlendMode.saturation,
                                      )
                                    : const ColorFilter.mode(
                                        Colors.transparent,
                                        BlendMode.multiply,
                                      ),
                                child:
                                    product.imageUrl != null &&
                                        product.imageUrl!.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: product.imageUrl!,
                                        height: 105,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorWidget: (context, url, error) =>
                                            _buildImageFallback(),
                                      )
                                    : _buildImageFallback(),
                              ),
                              Positioned(
                                top: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isOutOfStock
                                        ? const Color(0xFFFEE2E2)
                                        : Colors.white.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isOutOfStock
                                        ? 'Habis'
                                        : 'Sisa ${product.stock > 1000 ? '∞' : product.stock}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isOutOfStock
                                          ? const Color(0xFFDC2626)
                                          : (isLowStock
                                                ? const Color(0xFFDC2626)
                                                : const Color(0xFF334155)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Product Title
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isOutOfStock
                                ? const Color(0xFF64748B)
                                : const Color(0xFF0F172A),
                            height: 1.2,
                          ),
                        ),
                        const Spacer(),

                        // Price & Cart Quantity Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                formatter.format(product.price).trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: isOutOfStock
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            if (inCart)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'x $cartQty',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              )
                            else if (product.hasVariants ||
                                product.hasModifiers)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Opsi',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
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

  // 4. Tablet Order Details / Cart Panel (ClaPos Style)
  Widget _buildTabletCartPanel(NumberFormat formatter) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, cartState) {
        final subtotal = cartState.totalAmount;
        final tax = subtotal > 0 ? subtotal * 0.1 : 0.0;
        double discount = 0.0;
        if (_selectedPromo != null && subtotal >= _selectedPromo!.minPurchase) {
          if (_selectedPromo!.type == PromoType.percentage) {
            discount = subtotal * (_selectedPromo!.value / 100.0);
          } else {
            discount = _selectedPromo!.value;
          }
        }
        final grandTotal = (subtotal + tax - discount).clamp(
          0.0,
          double.infinity,
        );

        return Container(
          width: 350,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              left: BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
          ),
          child: Column(
            children: [
              // 1. Quick Action Grid (2x2)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionButton(
                            icon: "assets/icons/customer.svg",
                            label: cartState.customer?.name ?? 'Customer',
                            isActive: cartState.customer != null,
                            onTap: () =>
                                _showCustomerPicker(cartState.customer),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildQuickActionButton(
                            icon: "assets/icons/tables.svg",
                            label:
                                _tableNumber != null && _tableNumber!.isNotEmpty
                                ? 'Meja $_tableNumber'
                                : 'Tables',
                            isActive:
                                _tableNumber != null &&
                                _tableNumber!.isNotEmpty,
                            onTap: _showTableDialog,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionButton(
                            icon: "assets/icons/discount.svg",
                            label: _selectedPromo != null
                                ? _selectedPromo!.name
                                : 'Discount',
                            isActive: _selectedPromo != null,
                            onTap: _showPromoPicker,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildQuickActionButton(
                            icon: "assets/icons/save_bill.svg",
                            label: 'Save Bill',
                            isActive: false,
                            onTap: _showSaveBill,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

              // 2. Order Details Header & Type Toggle
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Order Details',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          _buildOrderTypeToggle('Dine In'),
                          _buildOrderTypeToggle('Take Away'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Cart Items List (Scrollable)
              Expanded(
                child: cartState.items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset("assets/icons/order.svg"),
                              const SizedBox(height: 12),
                              const Text(
                                'Belum Ada Pesanan',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Sentuh menu di sebelah kiri untuk menambahkan pesanan',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        itemCount: cartState.items.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 12, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, index) {
                          final item = cartState.items[index];
                          final itemTotal = item.subtotal;

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.displayName,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    if (item.selectedModifiers.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        '+ ${item.modifiersDisplay}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                    if (item.notes != null &&
                                        item.notes!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Catatan: ${item.notes!.trim()}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 2),
                                    Text(
                                      '${formatter.format(item.unitPrice)} x ${item.quantity}',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formatter.format(itemTotal).trim(),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          onTap: () =>
                                              context.read<CartBloc>().add(
                                                DecreaseQuantity(
                                                  item.id,
                                                ),
                                              ),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 6,
                                            ),
                                            child: Icon(
                                              Icons.remove,
                                              size: 14,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${item.quantity}',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () =>
                                              context.read<CartBloc>().add(
                                                IncrementQuantity(
                                                  item.id,
                                                ),
                                              ),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 6,
                                            ),
                                            child: Icon(
                                              Icons.add,
                                              size: 14,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
              ),

              // 4. Clear All Order Text Link
              if (cartState.items.isNotEmpty) ...[
                GestureDetector(
                  onTap: () => context.read<CartBloc>().add(ClearCart()),
                  child: const Text(
                    'Hapus Keranjang',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // 5. Order Summary Box
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Subtotal',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            formatter.format(subtotal).trim(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tax (10%)',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            formatter.format(tax).trim(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      if (discount > 0) ...[
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Voucher / Diskon',
                              style: TextStyle(
                                color: Color(0xFF059669),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '- ${formatter.format(discount).trim()}',
                              style: const TextStyle(
                                color: Color(0xFF059669),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            formatter.format(grandTotal).trim(),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 6. Process Transaction Button
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      if (cartState.items.isEmpty) {
                        AppToast.showWarning(context, 'Keranjang masih kosong');
                        return;
                      }
                      if (widget.onOpenOrders != null) {
                        widget.onOpenOrders!();
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CheckoutPage(),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'Proses Transaksi',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Quick Action Button Component (ClaPos 2x2)
  Widget _buildQuickActionButton({
    required String icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.4)
                : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(icon, height: 28),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? AppColors.primary : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Order Type Toggle Button (Dine In / Take Away)
  Widget _buildOrderTypeToggle(String type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _orderType == type;
    return InkWell(
      onTap: () => setState(() => _orderType = type),
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF334155) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: isSelected
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
              : null,
        ),
        child: Text(
          type,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? AppColors.primary
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  // Dialog: Customer Picker
  void _showCustomerPicker(Customer? currentCustomer) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    context.read<CustomerBloc>().add(LoadCustomers());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (contextSheet) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (contextSheet, scrollController) {
          final searchCtrl = TextEditingController();
          return StatefulBuilder(
            builder: (contextSheet, setStateSheet) {
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF475569)
                            : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pilih Pelanggan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          TextButton(
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.primary,
                            ),
                            onPressed: () {
                              Navigator.pop(contextSheet);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AddEditCustomerPage(),
                                ),
                              );
                            },
                            child: const Icon(
                              Icons.add,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                      child: TextField(
                        controller: searchCtrl,
                        onChanged: (_) => setStateSheet(() {}),
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 13.5,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Cari nama atau no. telepon...',
                          hintStyle: TextStyle(
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                            fontSize: 13.5,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            size: 20,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.person_off_outlined,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'Pelanggan Umum (Tanpa Nama)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      subtitle: Text(
                        'Pesanan tidak dicatat atas nama tertentu',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      trailing: currentCustomer == null
                          ? const Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                              size: 20,
                            )
                          : null,
                      onTap: () {
                        context.read<CartBloc>().add(SetCartCustomer(null));
                        Navigator.pop(contextSheet);
                      },
                    ),
                    Divider(
                      height: 1,
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                    Expanded(
                      child: BlocBuilder<CustomerBloc, CustomerState>(
                        builder: (context, state) {
                          if (state.isLoading && state.customers.isEmpty) {
                            return const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          }
                          final q = searchCtrl.text.toLowerCase();
                          final customers = state.customers.where((c) {
                            return c.name.toLowerCase().contains(q) ||
                                (c.phone?.contains(q) ?? false);
                          }).toList();

                          if (customers.isEmpty) {
                            return Center(
                              child: Text(
                                'Pelanggan tidak ditemukan',
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            controller: scrollController,
                            itemCount: customers.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                            ),
                            itemBuilder: (context, i) {
                              final cust = customers[i];
                              final isSelected = currentCustomer?.id == cust.id;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                  child: Text(
                                    cust.name.isNotEmpty
                                        ? cust.name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF334155),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  cust.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                                subtitle: Text(
                                  cust.phone ?? 'Tidak ada nomor telepon',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: AppColors.primary,
                                        size: 20,
                                      )
                                    : null,
                                onTap: () {
                                  context.read<CartBloc>().add(
                                    SetCartCustomer(cust),
                                  );
                                  Navigator.pop(contextSheet);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Dialog: Table / Order Notes
  void _showTableDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctrl = TextEditingController(text: _tableNumber ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Nomor Meja / Catatan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: 'Misal: Meja 05 atau Area Outdoor',
            hintStyle: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              fontSize: 14,
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Batal',
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          if (_tableNumber != null && _tableNumber!.isNotEmpty)
            OutlinedButton(
              onPressed: () {
                setState(() => _tableNumber = null);
                Navigator.pop(ctx);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFCA5A5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Hapus',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            onPressed: () {
              setState(
                () => _tableNumber = ctrl.text.trim().isNotEmpty
                    ? ctrl.text.trim()
                    : null,
              );
              Navigator.pop(ctx);
            },
            child: const Text(
              'Simpan',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Dialog: Promo Picker
  void _showPromoPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    context.read<PromoBloc>().add(LoadPromos());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.85,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF475569)
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pilih Promo & Diskon',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      if (_selectedPromo != null)
                        TextButton(
                          onPressed: () {
                            setState(() => _selectedPromo = null);
                            Navigator.pop(ctx);
                          },
                          child: const Text(
                            'Hapus Diskon',
                            style: TextStyle(color: Color(0xFFDC2626)),
                          ),
                        ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
                Expanded(
                  child: BlocBuilder<PromoBloc, PromoState>(
                    builder: (context, state) {
                      if (state.isLoading) {
                        return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }
                      final promos = state.promos
                          .where((p) => p.isActive)
                          .toList();
                      if (promos.isEmpty) {
                        return Center(
                          child: Text(
                            'Belum ada promo aktif',
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: promos.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final promo = promos[i];
                          final isSelected = _selectedPromo?.id == promo.id;
                          return InkWell(
                            onTap: () {
                              setState(() => _selectedPromo = promo);
                              Navigator.pop(ctx);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark
                                        ? const Color(0xFF064E3B).withValues(alpha: 0.3)
                                        : const Color(0xFFF0FDF4))
                                    : (isDark
                                        ? const Color(0xFF0F172A)
                                        : Colors.white),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark
                                          ? const Color(0xFF334155)
                                          : const Color(0xFFE2E8F0)),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary
                                          : (isDark
                                              ? const Color(0xFF1E293B)
                                              : const Color(0xFFF1F5F9)),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.discount_outlined,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF64748B)),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          promo.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13.5,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          promo.type == PromoType.percentage
                                              ? 'Diskon ${promo.value}%'
                                              : 'Potongan Rp ${NumberFormat('#,###').format(promo.value)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark
                                                ? const Color(0xFF94A3B8)
                                                : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Action: Save Bill
  void _showSaveBill() {
    final cartState = context.read<CartBloc>().state;
    if (cartState.items.isEmpty) {
      AppToast.showWarning(context, 'Keranjang masih kosong');
      return;
    }
    AppToast.showSuccess(
      context,
      'Pesanan berhasil disimpan sebagai draft tagihan',
    );
  }
}
