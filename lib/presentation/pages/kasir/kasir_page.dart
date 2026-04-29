import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:laci/presentation/pages/checkout/checkout_page.dart';

import '../../blocs/product/product_bloc.dart';
import '../../blocs/category/category_bloc.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../core/style/app_colors.dart';

class KasirPage extends StatefulWidget {
  const KasirPage({super.key});

  @override
  State<KasirPage> createState() => _KasirPageState();
}

class _KasirPageState extends State<KasirPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategoryId = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    context.read<CategoryBloc>().add(LoadCategories());
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildCategoryTabs(),
            Expanded(child: _buildProductGrid(currencyFormatter)),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildCartSummary(currencyFormatter),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Laci POS',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Row(
            children: [
              const SizedBox(width: 12),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is Authenticated) {
                    final user = state.user;
                    return CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary,
                      backgroundImage: user.photoUrl != null
                          ? NetworkImage(user.photoUrl!)
                          : null,
                      child: user.photoUrl == null
                          ? Text(
                              (user.name ?? user.email)
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            )
                          : null,
                    );
                  }
                  return const CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.person, color: Colors.white, size: 18),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Cari nama atau kode produk...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(Icons.tune, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        List<Category> categories = [];
        if (state.isSuccess) {
          log(state.categories.toString());
          categories = state.categories;
        }

        return Container(
          height: 50,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length + 1,
            itemBuilder: (context, index) {
              final isAll = index == 0;
              final category = isAll ? null : categories[index - 1];
              final id = isAll ? 'all' : category!.id;
              final name = isAll ? 'Semua' : category!.name;
              final isSelected = _selectedCategoryId == id;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(name),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCategoryId = id);
                  },
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.divider,
                    ),
                  ),
                  showCheckmark: false,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProductGrid(NumberFormat formatter) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state.isLoading && state.products.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.isSuccess) {
          final filteredProducts = state.products.where((p) {
            final matchesSearch = p.name.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
            final matchesCategory =
                _selectedCategoryId == 'all' ||
                p.categoryId == _selectedCategoryId;
            return matchesSearch && matchesCategory;
          }).toList();

          if (filteredProducts.isEmpty) {
            return const Center(child: Text('Tidak ada produk ditemukan'));
          }

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              return _buildProductCard(product, formatter);
            },
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildProductCard(Product product, NumberFormat formatter) {
    return InkWell(
      onTap: () {
        context.read<CartBloc>().add(AddToCart(product));
        log('Product added to cart: ${product.name}');
      },
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                  child: product.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: product.imageUrl!,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 140,
                          width: double.infinity,
                          color: AppColors.background,
                          child: const Icon(
                            Icons.image,
                            color: AppColors.textDisabled,
                            size: 40,
                          ),
                        ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: BlocBuilder<CartBloc, CartState>(
                    builder: (context, state) {
                      final cartItemIndex = state.items.indexWhere(
                        (i) => i.productId == product.id,
                      );
                      final quantity = cartItemIndex >= 0
                          ? state.items[cartItemIndex].quantity
                          : 0;

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                          if (quantity > 0)
                            Positioned(
                              top: -5,
                              right: -5,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$quantity',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox.square(dimension: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stok: ${product.stock > 1000 ? '∞' : product.stock}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatter.format(product.price),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primary,
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

  Widget _buildCartSummary(NumberFormat formatter) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        if (state.items.isEmpty) return const SizedBox();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          height: 64,
          padding: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(100),
            // boxShadow: [
            //   BoxShadow(
            //     color: AppColors.primary.withValues(alpha: 0.3),
            //     blurRadius: 10,
            //     offset: const Offset(0, 5),
            //   ),
            // ],
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CheckoutPage()),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.shopping_cart, color: Colors.white),
                      Positioned(
                        top: -8,
                        right: -8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${state.items.length}',
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${state.items.fold(0, (sum, item) => sum + item.quantity)} Items',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          formatter.format(state.totalAmount),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'Checkout',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
