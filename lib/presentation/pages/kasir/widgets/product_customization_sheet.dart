import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/style/app_colors.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../domain/entities/product_entity.dart';
import '../../../../domain/entities/product_variant.dart';

class ProductCustomizationSheet extends StatefulWidget {
  final Product product;
  final Function({
    required ProductVariant? variant,
    required List<ModifierOption> modifiers,
    required String? notes,
    required int quantity,
  })
  onAddToCart;

  const ProductCustomizationSheet({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  static Future<void> show({
    required BuildContext context,
    required Product product,
    required Function({
      required ProductVariant? variant,
      required List<ModifierOption> modifiers,
      required String? notes,
      required int quantity,
    })
    onAddToCart,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          ProductCustomizationSheet(product: product, onAddToCart: onAddToCart),
    );
  }

  @override
  State<ProductCustomizationSheet> createState() =>
      _ProductCustomizationSheetState();
}

class _ProductCustomizationSheetState extends State<ProductCustomizationSheet> {
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  ProductVariant? _selectedVariant;
  final Map<String, Set<ModifierOption>> _selectedModifiers = {};
  late TextEditingController _notesController;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();

    // Default select first variant if available
    if (widget.product.hasVariants) {
      _selectedVariant = widget.product.variants.first;
    }

    // Default select first option for required single-select groups
    for (final group in widget.product.modifierGroups) {
      if (group.isRequired &&
          !group.allowMultiple &&
          group.options.isNotEmpty) {
        _selectedModifiers[group.id] = {group.options.first};
      } else {
        _selectedModifiers[group.id] = {};
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double get _basePrice => _selectedVariant?.price ?? widget.product.price;

  double get _modifiersTotal {
    double total = 0;
    for (final set in _selectedModifiers.values) {
      for (final opt in set) {
        total += opt.price;
      }
    }
    return total;
  }

  double get _unitPrice => _basePrice + _modifiersTotal;
  double get _totalPrice => _unitPrice * _quantity;

  bool get _isValid {
    // If has variants, one must be selected
    if (widget.product.hasVariants && _selectedVariant == null) {
      return false;
    }
    // Check all required modifier groups
    for (final group in widget.product.modifierGroups) {
      if (group.isRequired) {
        final selected = _selectedModifiers[group.id];
        if (selected == null || selected.isEmpty) {
          return false;
        }
      }
    }
    return true;
  }

  void _submit() {
    if (widget.product.hasVariants && _selectedVariant == null) {
      AppToast.showWarning(context, 'Silakan pilih salah satu varian');
      return;
    }

    for (final group in widget.product.modifierGroups) {
      if (group.isRequired) {
        final selected = _selectedModifiers[group.id];
        if (selected == null || selected.isEmpty) {
          AppToast.showWarning(
            context,
            'Pilihan "${group.name}" wajib dipilih',
          );
          return;
        }
      }
    }

    final allModifiers = <ModifierOption>[];
    for (final set in _selectedModifiers.values) {
      allModifiers.addAll(set);
    }

    widget.onAddToCart(
      variant: _selectedVariant,
      modifiers: allModifiers,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      quantity: _quantity,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final dividerColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Top Bar & Header
            _buildHeader(isDark),
            Divider(height: 1, color: dividerColor),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                children: [
                  // Product Summary Banner
                  _buildProductBanner(isDark),
                  const SizedBox(height: 20),

                  // Variants Section
                  if (widget.product.hasVariants) ...[
                    _buildVariantSelection(isDark),
                    const SizedBox(height: 20),
                  ],

                  // Modifiers Groups
                  if (widget.product.hasModifiers) ...[
                    for (final group in widget.product.modifierGroups) ...[
                      _buildModifierGroup(group, isDark),
                      const SizedBox(height: 18),
                    ],
                  ],

                  // Special Instructions / Notes
                  _buildNotesSection(isDark),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Bottom Action Bar
            Divider(height: 1, color: dividerColor),
            _buildBottomActionBar(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 12, top: 12, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Kustomisasi Pesanan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close_rounded,
              size: 22,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          if (widget.product.imageUrl != null &&
              widget.product.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: widget.product.imageUrl!,
                width: 54,
                height: 54,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => _buildPlaceholderIcon(),
              ),
            )
          else
            _buildPlaceholderIcon(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _currencyFormat.format(_unitPrice),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.shopping_bag_outlined,
        color: AppColors.primary,
        size: 24,
      ),
    );
  }

  Widget _buildVariantSelection(bool isDark) {
    final chipBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Pilih Varian',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Wajib',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: widget.product.variants.map((variant) {
            final isSelected = _selectedVariant?.id == variant.id;
            return InkWell(
              onTap: () => setState(() => _selectedVariant = variant),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : chipBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : borderColor,
                    width: isSelected ? 1.6 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          variant.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: isSelected
                                ? AppColors.white
                                : (isDark ? Colors.white : const Color(0xFF1E293B)),
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.check_circle,
                            size: 14,
                            color: AppColors.white,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _currencyFormat.format(variant.price),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? AppColors.white
                            : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildModifierGroup(ModifierGroup group, bool isDark) {
    final selectedSet = _selectedModifiers[group.id] ?? {};
    final chipBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              group.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: group.isRequired
                    ? (isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2))
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                group.isRequired ? 'Wajib' : 'Opsional',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: group.isRequired
                      ? const Color(0xFFEF4444)
                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              group.allowMultiple ? '(Bisa pilih banyak)' : '(Pilih satu)',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: group.options.map((opt) {
            final isSelected = selectedSet.any((item) => item.id == opt.id);

            return InkWell(
              onTap: () {
                setState(() {
                  if (group.allowMultiple) {
                    if (isSelected) {
                      selectedSet.removeWhere((item) => item.id == opt.id);
                    } else {
                      selectedSet.add(opt);
                    }
                  } else {
                    selectedSet.clear();
                    selectedSet.add(opt);
                  }
                  _selectedModifiers[group.id] = selectedSet;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : chipBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : borderColor,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      group.allowMultiple
                          ? (isSelected
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded)
                          : (isSelected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded),
                      size: 16,
                      color: isSelected
                          ? AppColors.white
                          : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      opt.name,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected
                            ? AppColors.white
                            : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                      ),
                    ),
                    if (opt.price > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        '+${_currencyFormat.format(opt.price)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? AppColors.white
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNotesSection(bool isDark) {
    final inputBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final hintColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catatan (Opsional)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 2,
          style: TextStyle(fontSize: 13, color: textColor),
          decoration: InputDecoration(
            hintText: 'Contoh: Sedikit es, jangan terlalu manis, dll.',
            hintStyle: TextStyle(
              fontSize: 12.5,
              color: hintColor,
            ),
            filled: true,
            fillColor: inputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar(bool isDark) {
    final stepperBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final iconColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final disabledIconColor = isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // Quantity Stepper
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: stepperBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 18),
                  color: _quantity > 1 ? iconColor : disabledIconColor,
                  onPressed: _quantity > 1
                      ? () => setState(() => _quantity--)
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '$_quantity',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  color: iconColor,
                  onPressed: () => setState(() => _quantity++),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Add to Cart Button
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isValid ? _submit : null,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFCBD5E1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Tambah • ${_currencyFormat.format(_totalPrice)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
