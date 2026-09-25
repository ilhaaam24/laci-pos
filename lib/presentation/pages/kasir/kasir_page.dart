import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../blocs/product/product_bloc.dart';
import '../../blocs/category/category_bloc.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/business/business_bloc.dart';
import '../../blocs/customer/customer_bloc.dart';
import '../../blocs/promo/promo_bloc.dart';
import '../../blocs/shift/shift_bloc.dart';
import '../../../domain/entities/shift_entity.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../domain/entities/customer_entity.dart';
import '../../../domain/entities/promo_entity.dart';
import '../../../core/style/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../checkout/checkout_page.dart';
import '../customer/add_edit_customer_page.dart';
import 'widgets/product_customization_sheet.dart';
import 'widgets/open_shift_dialog.dart';
import 'widgets/shift_control_sheet.dart';
import 'widgets/hold_order_dialog.dart';
import 'widgets/held_orders_sheet.dart';
import '../../../core/services/held_order_service.dart';
import '../../../core/di/injection.dart';
import '../../../core/services/staff_auth_service.dart';
import '../../../core/services/tutorial_service.dart';
import '../../../domain/entities/user_entity.dart';
import 'widgets/staff_pin_dialog.dart';
import 'widgets/close_shift_dialog.dart';
import 'widgets/pos_tutorial.dart';

class KasirPage extends StatefulWidget {
  final VoidCallback? onOpenOrders;
  final VoidCallback? onOpenDrawer;
  final GlobalKey? ordersTabKey;

  static final GlobalKey<KasirPageState> globalKey =
      GlobalKey<KasirPageState>();

  const KasirPage({
    super.key,
    this.onOpenOrders,
    this.onOpenDrawer,
    this.ordersTabKey,
  });

  static void startTutorial({bool force = true}) {
    globalKey.currentState?.showTutorial(force: force);
  }

  @override
  State<KasirPage> createState() => KasirPageState();
}

class KasirPageState extends State<KasirPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String _selectedCategoryId = 'all';
  bool _isGridView = true;

  // Coach mark tutorial keys
  final GlobalKey _shiftBadgeKey = GlobalKey();
  final GlobalKey _staffSwitchBadgeKey = GlobalKey();
  final GlobalKey _searchBarKey = GlobalKey();
  final GlobalKey _categoryBarKey = GlobalKey();
  final GlobalKey _productCatalogKey = GlobalKey();
  final GlobalKey _tabletCartPanelKey = GlobalKey();

  // Tablet POS state
  String _orderType = 'Dine In'; // 'Dine In' | 'Take Away'
  String? _tableNumber;
  PromoEntity? _selectedPromo;

  // In-place Barcode Scanner Mode state
  bool _isScanMode = false;
  MobileScannerController? _embeddedScannerController;
  bool _isScannerTorchOn = false;
  DateTime? _lastScannedTime;
  String? _lastScannedBarcode;
  String? _lastScannedProductName;
  bool _lastScanSuccess = false;

  @override
  void initState() {
    super.initState();
    context.read<CategoryBloc>().add(LoadCategories());
    context.read<ProductBloc>().add(LoadProducts());
    context.read<CustomerBloc>().add(LoadCustomers());
    context.read<PromoBloc>().add(LoadPromos());
    context.read<ShiftBloc>().add(CheckActiveShift());
    final bState = context.read<BusinessBloc>().state;
    if (bState.businessInfo == null) {
      context.read<BusinessBloc>().add(LoadBusinessInfo());
    }

    // Auto-trigger coach mark tutorial on fresh installation
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final hasSeen = await TutorialService().hasSeenPosTutorial();
      if (!hasSeen && mounted) {
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) {
            showTutorial();
          }
        });
      }
    });
  }

  void showTutorial({bool force = false}) async {
    if (!force) {
      final hasSeen = await TutorialService().hasSeenPosTutorial();
      if (hasSeen) return;
    }
    if (!mounted) return;

    PosTutorial.show(
      context: context,
      targets: PosTutorialTargets(
        shiftBadgeKey: _shiftBadgeKey,
        staffSwitchBadgeKey: _staffSwitchBadgeKey,
        searchBarKey: _searchBarKey,
        categoryBarKey: _categoryBarKey,
        productCatalogKey: _productCatalogKey,
        ordersTabKey: widget.ordersTabKey,
        tabletCartPanelKey: _tabletCartPanelKey,
      ),
    );
  }

  @override
  void dispose() {
    _embeddedScannerController?.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleScanMode() {
    setState(() {
      _isScanMode = !_isScanMode;
      if (_isScanMode) {
        _searchFocusNode.unfocus();
        _embeddedScannerController ??= MobileScannerController(
          detectionSpeed: DetectionSpeed.normal,
          facing: CameraFacing.back,
          torchEnabled: false,
        );
      } else {
        _embeddedScannerController?.dispose();
        _embeddedScannerController = null;
        _isScannerTorchOn = false;
        _lastScannedProductName = null;
      }
    });
  }

  void _handleEmbeddedBarcodeDetect(BarcodeCapture capture) {
    if (!_isScanMode) return;
    for (final barcode in capture.barcodes) {
      final rawCode = barcode.rawValue?.trim();
      if (rawCode == null || rawCode.isEmpty) continue;

      final now = DateTime.now();
      if (_lastScannedBarcode == rawCode &&
          _lastScannedTime != null &&
          now.difference(_lastScannedTime!).inMilliseconds < 1500) {
        continue;
      }

      _lastScannedBarcode = rawCode;
      _lastScannedTime = now;

      final productState = context.read<ProductBloc>().state;
      final products = productState.products;

      final matched = products.where(
        (p) =>
            (p.sku != null &&
                p.sku!.trim().toLowerCase() == rawCode.toLowerCase()) ||
            p.id.toLowerCase() == rawCode.toLowerCase(),
      );

      if (matched.isNotEmpty) {
        final product = matched.first;
        if (product.trackStock && product.stock <= 0) {
          HapticFeedback.vibrate();
          setState(() {
            _lastScannedProductName = '${product.name} (Stok Habis)';
            _lastScanSuccess = false;
          });
          AppToast.showWarning(
            context,
            'Produk ${product.name} ditemukan, namun stok habis',
          );
        } else {
          HapticFeedback.lightImpact();
          _onProductSelected(product);
          setState(() {
            _lastScannedProductName = '${product.name} (+1)';
            _lastScanSuccess = true;
          });
        }
      } else {
        HapticFeedback.vibrate();
        setState(() {
          _lastScannedProductName = 'Tidak ditemukan: $rawCode';
          _lastScanSuccess = false;
        });
        AppToast.showWarning(
          context,
          'Produk dengan SKU/Barcode "$rawCode" tidak ditemukan',
        );
      }
      break;
    }
  }

  void _onProductSelected(Product product) {
    if (product.trackStock && product.stock <= 0) {
      AppToast.showWarning(context, 'Stok ${product.name} telah habis');
      return;
    }

    if (product.hasVariants || product.hasModifiers) {
      ProductCustomizationSheet.show(
        context: context,
        product: product,
        onAddToCart:
            ({
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
      if (product.trackStock) {
        final cartState = context.read<CartBloc>().state;
        final currentInCart = cartState.items
            .where((i) => i.productId == product.id)
            .fold<int>(0, (sum, i) => sum + i.quantity);

        if (currentInCart >= product.stock) {
          AppToast.showWarning(
            context,
            'Stok ${product.name} tidak mencukupi (tersedia: ${product.stock}, di keranjang: $currentInCart)',
          );
          return;
        }
      }

      context.read<CartBloc>().add(AddToCart(product));
    }
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
              child: _isScanMode
                  ? _buildEmbeddedScannerView()
                  : KeyedSubtree(
                      key: _productCatalogKey,
                      child: _isGridView
                          ? _buildProductGrid(currencyFormatter)
                          : _buildProductList(currencyFormatter),
                    ),
            ),
          ],
        ),
        _buildFloatingCartBanner(currencyFormatter),
      ],
    );
  }

  // 1. Top Header: Business Logo, Online Status Dot, Store & Role Info, Action Badges
  Widget _buildTopHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final staffService = getIt<StaffAuthService>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Row(
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

                return ValueListenableBuilder<UserEntity?>(
                  valueListenable: staffService.activeStaffNotifier,
                  builder: (context, activeStaff, _) {
                    final staffName = (activeStaff?.name?.isNotEmpty == true)
                        ? activeStaff!.name!
                        : (activeStaff?.email.split('@').first ?? '');

                    return BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, aState) {
                        final storeUser = (aState is Authenticated)
                            ? aState.user
                            : null;
                        final effectiveName = staffName.isNotEmpty
                            ? staffName
                            : (storeUser?.name ?? 'Kasir');

                        return BlocBuilder<ShiftBloc, ShiftState>(
                          builder: (context, shiftState) {
                            final isOpen = shiftState.hasActiveShift;

                            return InkWell(
                              onTap: () => StaffPinDialog.show(context),
                              borderRadius: BorderRadius.circular(10),
                              child: Row(
                                children: [
                                  // Business Logo / App Icon
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: hasLogo
                                          ? const Color(0xFFF1F5F9)
                                          : AppColors.primary,
                                      borderRadius: BorderRadius.circular(9),
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF334155)
                                            : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: hasLogo
                                          ? CachedNetworkImage(
                                              imageUrl: logoUrl,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  const Center(
                                                    child: SizedBox(
                                                      width: 14,
                                                      height: 14,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                          ),
                                                    ),
                                                  ),
                                              errorWidget:
                                                  (
                                                    context,
                                                    url,
                                                    error,
                                                  ) => const Center(
                                                    child: Icon(
                                                      Icons.storefront_rounded,
                                                      color: Color(0xFF64748B),
                                                      size: 18,
                                                    ),
                                                  ),
                                            )
                                          : SvgPicture.asset(
                                              "assets/icons/logo.svg",
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Store Name & Active Staff Subtitle
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          businessName,
                                          style: TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF0F172A),
                                            letterSpacing: -0.2,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 1),
                                        Row(
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: isOpen
                                                    ? const Color(0xFF10B981)
                                                    : const Color(0xFFF59E0B),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                isOpen
                                                    ? '$effectiveName • Shift Aktif'
                                                    : '$effectiveName • Belum Buka Shift',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  color: isDark
                                                      ? const Color(0xFF94A3B8)
                                                      : const Color(0xFF64748B),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(width: 6),
          _buildStaffSwitchBadge(isCompact: true),
          const SizedBox(width: 6),
          _buildShiftBadge(isCompact: true),
          const SizedBox(width: 6),
          _buildOpenBillBadge(isCompact: true),
        ],
      ),
    );
  }

  Widget _buildOpenBillBadge({
    bool isTablet = false,
    bool isCompact = false,
    bool isUltraCompact = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ValueListenableBuilder<int>(
      valueListenable: HeldOrderService().heldOrderCountNotifier,
      builder: (context, count, _) {
        final hasOrders = count > 0;
        final tooltipText = 'Open Bill ($count)';

        final badgeChild = isCompact
            ? Container(
                height: isUltraCompact ? 34 : 36,
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(
                  horizontal: isUltraCompact ? 6 : 8,
                ),
                decoration: BoxDecoration(
                  color: hasOrders
                      ? (isDark
                            ? const Color(0xFF78350F).withValues(alpha: 0.35)
                            : const Color(0xFFFEF3C7))
                      : (isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(isUltraCompact ? 8 : 10),
                  border: Border.all(
                    color: hasOrders
                        ? (isDark
                              ? const Color(0xFFD97706).withValues(alpha: 0.5)
                              : const Color(0xFFF59E0B))
                        : (isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      "assets/icons/bill.svg",
                      height: isUltraCompact ? 14 : 16,
                      colorFilter: hasOrders
                          ? const ColorFilter.mode(
                              Color(0xFFD97706),
                              BlendMode.srcIn,
                            )
                          : null,
                    ),
                    const SizedBox(width: 4),
                    if (hasOrders)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: isUltraCompact ? 9.5 : 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                      )
                    else
                      Text(
                        '0',
                        style: TextStyle(
                          fontSize: isUltraCompact ? 10 : 11,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                  ],
                ),
              )
            : AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 12 : 9,
                  vertical: isTablet ? 8 : 5,
                ),
                decoration: BoxDecoration(
                  color: hasOrders
                      ? (isDark
                            ? const Color(0xFF78350F)
                            : const Color(0xFFFEF3C7))
                      : (isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: hasOrders
                        ? const Color(0xFFF59E0B)
                        : (isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset("assets/icons/bill.svg", height: 20),
                    const SizedBox(width: 5),
                    Text(
                      isTablet ? 'Open Bill ($count)' : '$count Bill',
                      style: TextStyle(
                        fontSize: isTablet ? 12 : 11,
                        fontWeight: FontWeight.bold,
                        color: hasOrders
                            ? const Color(0xFFD97706)
                            : (isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              );

        return Tooltip(
          message: tooltipText,
          child: InkWell(
            onTap: () {
              final authState = context.read<AuthBloc>().state;
              final cashierName =
                  (authState is Authenticated &&
                      authState.user.name != null &&
                      authState.user.name!.isNotEmpty)
                  ? authState.user.name!
                  : 'Kasir';
              HeldOrdersSheet.show(context: context, cashierName: cashierName);
            },
            borderRadius: BorderRadius.circular(isCompact ? 10 : 20),
            child: badgeChild,
          ),
        );
      },
    );
  }

  Widget _buildStaffSwitchBadge({
    bool isTablet = false,
    bool isCompact = false,
    bool isUltraCompact = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final staffService = getIt<StaffAuthService>();

    return KeyedSubtree(
      key: _staffSwitchBadgeKey,
      child: ValueListenableBuilder<UserEntity?>(
        valueListenable: staffService.activeStaffNotifier,
        builder: (context, staff, _) {
          final displayName = (staff?.name?.isNotEmpty == true)
              ? staff!.name!
              : (staff?.email.split('@').first ?? 'Kasir');
          final initial = displayName.isNotEmpty
              ? displayName[0].toUpperCase()
              : 'K';
          final roleLabel = staff?.role.name.toUpperCase() ?? 'KASIR';

          return Tooltip(
            message:
                'Staf: $displayName ($roleLabel) • Klik untuk ganti / kunci',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  StaffPinDialog.show(context);
                },
                borderRadius: BorderRadius.circular(isCompact ? 10 : 20),
                child: isCompact
                    ? Container(
                        height: isUltraCompact ? 34 : 36,
                        alignment: Alignment.center,
                        padding: EdgeInsets.symmetric(
                          horizontal: isUltraCompact ? 5 : 7,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(
                            isUltraCompact ? 8 : 10,
                          ),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: isUltraCompact ? 9 : 10.5,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                initial,
                                style: TextStyle(
                                  fontSize: isUltraCompact ? 8.5 : 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: isUltraCompact ? 3 : 4),
                            Icon(
                              Icons.lock_outline_rounded,
                              size: isUltraCompact ? 12 : 13,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 10 : 8,
                          vertical: isTablet ? 6 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 10.5,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 80),
                              child: Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 13,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleCloseShiftFlow() async {
    final shiftState = context.read<ShiftBloc>().state;
    final active = shiftState.activeShift;
    if (active != null) {
      final summary =
          shiftState.currentSummary ??
          ShiftSummary(
            shift: active,
            startCash: active.startCash,
            totalCashSales: active.totalCashSales,
            totalQrisSales: 0,
            totalDebitSales: 0,
            totalTransferSales: 0,
            totalSales: active.totalSales,
            totalTransactions: active.totalTransactions,
            totalCashIn: 0,
            totalCashOut: 0,
            cashMovements: const [],
          );
      final closeResult = await CloseShiftDialog.show(
        context,
        shift: active,
        summary: summary,
      );
      if (closeResult != null && closeResult.isClosed && mounted) {
        final curFmt = NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 0,
        );
        await StaffPinDialog.show(
          context,
          isLockMode: true,
          title: 'Shift Selesai • Masuk Kasir Baru',
          subtitle: 'Masukkan 4 digit PIN kasir berikutnya',
          pendingHandoverAmount: closeResult.remainingCashInDrawer,
          pendingHandoverNote:
              'Serah terima dari ${active.userName}: Ditinggalkan ${curFmt.format(closeResult.remainingCashInDrawer)} di laci (Setor: ${curFmt.format(closeResult.depositedCash)})',
        );
      }
    }
  }

  Widget _buildShiftBadge({
    bool isTablet = false,
    bool isCompact = false,
    bool isUltraCompact = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return KeyedSubtree(
      key: _shiftBadgeKey,
      child: BlocBuilder<ShiftBloc, ShiftState>(
        builder: (context, shiftState) {
          final isOpen = shiftState.hasActiveShift;
          final shift = shiftState.activeShift;
          final tooltipText = isOpen
              ? 'Shift: ${shift?.userName ?? 'Aktif'} (Ketuk untuk kontrol shift)'
              : 'Shift Belum Buka (Ketuk untuk buka shift)';

          final badgeChild = isCompact
              ? Container(
                  height: isUltraCompact ? 34 : 36,
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(
                    horizontal: isUltraCompact ? 7 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: isOpen
                        ? (isDark
                              ? const Color(0xFF064E3B).withValues(alpha: 0.35)
                              : Colors.transparent)
                        : (isDark
                              ? const Color(0xFF78350F).withValues(alpha: 0.35)
                              : const Color(0xFFFFFBEB)),
                    borderRadius: BorderRadius.circular(
                      isUltraCompact ? 8 : 10,
                    ),
                    border: Border.all(
                      color: isOpen
                          ? (isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0))
                          : (isDark
                                ? const Color(0xFFD97706).withValues(alpha: 0.5)
                                : const Color(0xFFFDE68A)),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOpen
                            ? Icons.lock_open_rounded
                            : Icons.lock_outline_rounded,
                        size: isUltraCompact ? 13 : 14,
                        color: isOpen
                            ? (isDark
                                  ? const Color(0xFF34D399)
                                  : AppColors.textSecondary)
                            : (isDark
                                  ? const Color(0xFFFCD34D)
                                  : const Color(0xFFD97706)),
                      ),
                      if (!isUltraCompact) ...[
                        const SizedBox(width: 4),
                        Text(
                          isOpen ? 'Shift' : 'Buka',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isOpen
                                ? (isDark
                                      ? const Color(0xFF34D399)
                                      : AppColors.textSecondary)
                                : (isDark
                                      ? const Color(0xFFFCD34D)
                                      : const Color(0xFFD97706)),
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              : AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 12 : 9,
                    vertical: isTablet ? 8 : 5,
                  ),
                  decoration: BoxDecoration(
                    color: isOpen
                        ? AppColors.primary
                        : (isDark
                              ? const Color(0xFF78350F)
                              : const Color(0xFFFFFBEB)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isOpen
                          ? const Color(0xFF10B981).withValues(alpha: 0.5)
                          : const Color(0xFFF59E0B).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    isOpen
                        ? (isTablet
                              ? 'Shift: ${shift?.userName ?? 'Aktif'}'
                              : 'Shift Aktif')
                        : 'Buka Shift',
                    style: TextStyle(
                      fontSize: isTablet ? 12 : 11,
                      fontWeight: FontWeight.bold,
                      color: isOpen
                          ? Colors.white
                          : (isDark
                                ? const Color(0xFFFCD34D)
                                : const Color(0xFF92400E)),
                    ),
                  ),
                );

          return Tooltip(
            message: tooltipText,
            child: InkWell(
              onTap: () async {
                if (isOpen) {
                  final action = await ShiftControlSheet.show(context);
                  if (action == 'close_shift' && mounted) {
                    await _handleCloseShiftFlow();
                  }
                } else {
                  OpenShiftDialog.show(context);
                }
              },
              borderRadius: BorderRadius.circular(isCompact ? 10 : 20),
              child: badgeChild,
            ),
          );
        },
      ),
    );
  }

  // 2. Full-width Search Input with Scanner Action
  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return KeyedSubtree(
      key: _searchBarKey,
      child: Padding(
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
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
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
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
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
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
              Container(
                decoration: _isScanMode
                    ? BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      )
                    : null,
                child: IconButton(
                  icon: Icon(
                    Icons.qr_code_scanner_rounded,
                    color: _isScanMode ? Colors.white : AppColors.primary,
                    size: 22,
                  ),
                  tooltip: _isScanMode
                      ? 'Tutup Mode Scan / Kembali ke Produk'
                      : 'Buka Mode Scan Kamera Cepat',
                  onPressed: _toggleScanMode,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3. Category Horizontal Pills & Grid/List View Toggle
  Widget _buildCategoryAndFilterBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return KeyedSubtree(
      key: _categoryBarKey,
      child: Padding(
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
                            onTap: () =>
                                setState(() => _selectedCategoryId = id),
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark
                                          ? Colors.white
                                          : AppColors.darkCharcoal)
                                    : (isDark
                                          ? const Color(0xFF1E293B)
                                          : Colors.white),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? (isDark
                                            ? Colors.white
                                            : AppColors.darkCharcoal)
                                      : (isDark
                                            ? const Color(0xFF334155)
                                            : const Color(0xFFE2E8F0)),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                name,
                                style: TextStyle(
                                  color: isSelected
                                      ? (isDark
                                            ? const Color(0xFF0F172A)
                                            : Colors.white)
                                      : (isDark
                                            ? const Color(0xFFCBD5E1)
                                            : const Color(0xFF334155)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOutOfStock = product.trackStock && product.stock <= 0;
    final isLowStock =
        product.trackStock && !isOutOfStock && product.stock <= 5;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B)
            : (isOutOfStock ? const Color(0xFFF8FAFC) : Colors.white),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
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
                  AspectRatio(
                    aspectRatio: 1.25,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox.expand(
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
                                  product.imageUrl != null &&
                                      product.imageUrl!.isNotEmpty
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
                                  ? (isDark
                                        ? const Color(0xFF7F1D1D)
                                        : const Color(0xFFFEE2E2))
                                  : (isDark
                                        ? const Color(
                                            0xFF0F172A,
                                          ).withValues(alpha: 0.85)
                                        : Colors.white.withValues(alpha: 0.9)),
                              borderRadius: BorderRadius.circular(8),
                              border: isOutOfStock
                                  ? Border.all(
                                      color: isDark
                                          ? const Color(0xFFB91C1C)
                                          : const Color(0xFFFECACA),
                                    )
                                  : null,
                            ),
                            child: Text(
                              isOutOfStock
                                  ? 'Habis'
                                  : (!product.trackStock
                                        ? 'Tersedia'
                                        : 'Sisa ${product.stock > 1000 ? '∞' : product.stock}'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isOutOfStock
                                    ? const Color(0xFFF87171)
                                    : (isLowStock
                                          ? const Color(0xFFF87171)
                                          : (isDark
                                                ? const Color(0xFFCBD5E1)
                                                : const Color(0xFF334155))),
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
                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOutOfStock = product.trackStock && product.stock <= 0;
    final isLowStock =
        product.trackStock && !isOutOfStock && product.stock <= 5;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B)
            : (isOutOfStock ? const Color(0xFFF8FAFC) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
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
                            : (isDark ? Colors.white : const Color(0xFF0F172A)),
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
                            ? (isDark
                                  ? const Color(0xFF7F1D1D)
                                  : const Color(0xFFFEE2E2))
                            : (isLowStock
                                  ? (isDark
                                        ? const Color(0xFF7F1D1D)
                                        : const Color(0xFFFEE2E2))
                                  : (isDark
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xFFF1F5F9))),
                        borderRadius: BorderRadius.circular(6),
                        border: isOutOfStock
                            ? Border.all(
                                color: isDark
                                    ? const Color(0xFFB91C1C)
                                    : const Color(0xFFFECACA),
                              )
                            : null,
                      ),
                      child: Text(
                        isOutOfStock
                            ? 'Habis'
                            : (!product.trackStock
                                  ? 'Tersedia'
                                  : 'Sisa ${product.stock > 1000 ? '∞' : product.stock}'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isOutOfStock
                              ? const Color(0xFFF87171)
                              : (isLowStock
                                    ? const Color(0xFFF87171)
                                    : (isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B))),
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
                            : (isDark ? Colors.white : const Color(0xFF0F172A)),
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

        final isDark = Theme.of(context).brightness == Brightness.dark;
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
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
                width: 1,
              ),
              color: isDark ? const Color(0xFF1E293B) : AppColors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
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
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                InkWell(
                  onTap: () {
                    final shiftState = context.read<ShiftBloc>().state;
                    if (!shiftState.hasActiveShift) {
                      AppToast.showWarning(
                        context,
                        'Shift kasir belum dibuka. Masukkan modal awal terlebih dahulu.',
                      );
                      OpenShiftDialog.show(context);
                      return;
                    }
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
                    child: Row(
                      children: [
                        Text(
                          'Lihat Pesanan',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: isDark ? Colors.white : AppColors.textPrimary,
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

  Widget _buildEmbeddedScannerView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        // Viewfinder size proportional to available area
        final targetBoxSize = math.min(
          math.min(availableWidth * 0.75, availableHeight * 0.65),
          260.0,
        );
        final boxSize = targetBoxSize < 140.0 ? 140.0 : targetBoxSize;
        final isCompactWidth = availableWidth < 460;
        final isShortScreen = availableHeight < 320;

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFCBD5E1),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                // 1. MobileScanner Camera
                if (_embeddedScannerController != null)
                  MobileScanner(
                    controller: _embeddedScannerController!,
                    onDetect: _handleEmbeddedBarcodeDetect,
                  ),

                // 2. Viewfinder Overlay with styled corners
                Center(
                  child: Container(
                    width: boxSize,
                    height: boxSize,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Stack(
                      children: [
                        // Top-left corner
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: AppColors.primary,
                                  width: 3.5,
                                ),
                                left: BorderSide(
                                  color: AppColors.primary,
                                  width: 3.5,
                                ),
                              ),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        // Top-right corner
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: AppColors.primary,
                                  width: 3.5,
                                ),
                                right: BorderSide(
                                  color: AppColors.primary,
                                  width: 3.5,
                                ),
                              ),
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        // Bottom-left corner
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.primary,
                                  width: 3.5,
                                ),
                                left: BorderSide(
                                  color: AppColors.primary,
                                  width: 3.5,
                                ),
                              ),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        // Bottom-right corner
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.primary,
                                  width: 3.5,
                                ),
                                right: BorderSide(
                                  color: AppColors.primary,
                                  width: 3.5,
                                ),
                              ),
                              borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        // Subtle center horizontal guide line
                        Center(
                          child: Container(
                            height: 1.5,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            color: AppColors.primary.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Top Floating Controls Header
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Row(
                    children: [
                      // Badge Continuous Scan Active
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompactWidth ? 8 : 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isCompactWidth
                                  ? 'Scan'
                                  : (isShortScreen
                                        ? 'Scan Aktif'
                                        : 'Continuous Scan'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),

                      // Torch Button
                      Material(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            setState(() {
                              _isScannerTorchOn = !_isScannerTorchOn;
                            });
                            _embeddedScannerController?.toggleTorch();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(7),
                            child: Icon(
                              _isScannerTorchOn
                                  ? Icons.flash_on_rounded
                                  : Icons.flash_off_rounded,
                              color: _isScannerTorchOn
                                  ? Colors.amber
                                  : Colors.white,
                              size: 19,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Switch Camera Button
                      Material(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () =>
                              _embeddedScannerController?.switchCamera(),
                          child: const Padding(
                            padding: EdgeInsets.all(7),
                            child: Icon(
                              Icons.cameraswitch_outlined,
                              color: Colors.white,
                              size: 19,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Close Scanner Button -> return to product catalog
                      Material(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: _toggleScanMode,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isCompactWidth ? 8 : 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.6),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                if (!isCompactWidth && !isShortScreen) ...[
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Tutup',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 4. Bottom Scanned Product Notification Feedback Banner
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_lastScannedProductName != null)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _lastScanSuccess
                                ? const Color(
                                    0xFF065F46,
                                  ).withValues(alpha: 0.92)
                                : const Color(
                                    0xFF991B1B,
                                  ).withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _lastScanSuccess
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFFF87171),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _lastScanSuccess
                                    ? Icons.check_circle_rounded
                                    : Icons.error_outline_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _lastScannedProductName!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Hint text
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Arahkan barcode ke dalam kotak untuk memindai berturut-turut',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabletLayout(NumberFormat currencyFormatter) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8FAFC),
                child: Column(
                  children: [
                    _buildTabletHeader(),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                    Expanded(
                      child: _isScanMode
                          ? _buildEmbeddedScannerView()
                          : KeyedSubtree(
                              key: _productCatalogKey,
                              child: _isGridView
                                  ? _buildTabletProductGrid(currencyFormatter)
                                  : _buildProductList(currencyFormatter),
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Right Sidebar: Order Details / Cart Panel
            KeyedSubtree(
              key: _tabletCartPanelKey,
              child: _buildTabletCartPanel(currencyFormatter),
            ),
          ],
        );
      },
    );
  }

  // 1. Left Sidebar: Vertical Category Navigation
  Widget _buildTabletCategorySidebar(List<Category> categories) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final isShort = screenHeight < 520;

    return KeyedSubtree(
      key: _categoryBarKey,
      child: Container(
        width: isShort ? 84 : 92,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          border: Border(
            right: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: isShort ? 8 : 16),
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
                height: isShort ? 30 : 36,
              ),
            ),
            SizedBox(height: isShort ? 6 : 10),
            Expanded(
              child: ListView.builder(
                itemCount: categories.length + 1,
                padding: EdgeInsets.symmetric(vertical: isShort ? 2 : 4),
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
                    padding: EdgeInsets.symmetric(
                      horizontal: isShort ? 4 : 6,
                      vertical: isShort ? 2 : 4,
                    ),
                    child: InkWell(
                      onTap: () => setState(() => _selectedCategoryId = id),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: isShort ? 7 : 12,
                          horizontal: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark
                                    ? const Color(0xFF334155)
                                    : Colors.grey.shade100)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              size: isShort ? 22 : 26,
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B)),
                            ),
                            SizedBox(height: isShort ? 3 : 6),
                            Text(
                              name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isShort ? 10 : 11,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? (isDark
                                          ? Colors.white
                                          : AppColors.textPrimary)
                                    : (isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF334155)),
                                height: 1.15,
                              ),
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
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = isPortrait || constraints.maxWidth < 620;
        final isUltraCompact = constraints.maxWidth < 480;

        return Container(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: isUltraCompact ? 8 : (isCompact ? 10 : 16),
            vertical: isUltraCompact ? 7 : 10,
          ),
          child: Row(
            children: [
              // Center Search Box with Barcode Scan
              Expanded(
                child: KeyedSubtree(
                  key: _searchBarKey,
                  child: Container(
                    height: isUltraCompact ? 36 : 42,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(
                        isUltraCompact ? 10 : 12,
                      ),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            left: isUltraCompact ? 8 : 10,
                            right: isUltraCompact ? 4 : 8,
                          ),
                          child: Icon(
                            Icons.search_rounded,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                            size: isUltraCompact ? 16 : 18,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            onChanged: (val) =>
                                setState(() => _searchQuery = val),
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              fontSize: isUltraCompact ? 12 : 13,
                            ),
                            decoration: InputDecoration(
                              fillColor: Colors.transparent,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              hintText: isUltraCompact
                                  ? 'Cari...'
                                  : (isCompact
                                        ? 'Cari produk...'
                                        : 'Cari produk atau SKU...'),
                              hintStyle: TextStyle(
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                                fontSize: isUltraCompact ? 12 : 13,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: isUltraCompact ? 6 : 10,
                              ),
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          SizedBox(
                            width: isUltraCompact ? 24 : 28,
                            height: isUltraCompact ? 24 : 28,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                Icons.clear,
                                size: isUltraCompact ? 14 : 16,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            ),
                          ),
                        Container(
                          width: isUltraCompact ? 30 : 34,
                          height: isUltraCompact ? 30 : 34,
                          decoration: _isScanMode
                              ? BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                )
                              : null,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              _isScanMode
                                  ? Icons.close_rounded
                                  : Icons.qr_code_scanner_rounded,
                              color: _isScanMode
                                  ? Colors.white
                                  : AppColors.primary,
                              size: isUltraCompact ? 18 : 20,
                            ),
                            onPressed: _toggleScanMode,
                            tooltip: _isScanMode
                                ? 'Tutup Mode Scan / Kembali ke Produk'
                                : 'Pindai Barcode / SKU (Continuous)',
                          ),
                        ),
                        SizedBox(width: isUltraCompact ? 4 : 6),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: isUltraCompact ? 5 : 8),

              // View Mode Toggle (Grid vs List)
              isCompact
                  ? Container(
                      height: isUltraCompact ? 34 : 38,
                      width: isUltraCompact ? 34 : 38,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(
                          isUltraCompact ? 8 : 10,
                        ),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          _isGridView
                              ? Icons.format_list_bulleted_rounded
                              : Icons.grid_view_rounded,
                          size: isUltraCompact ? 16 : 18,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                        tooltip: _isGridView
                            ? 'Tampilan List'
                            : 'Tampilan Grid',
                        onPressed: () =>
                            setState(() => _isGridView = !_isGridView),
                      ),
                    )
                  : Container(
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
              SizedBox(width: isUltraCompact ? 4 : 6),
              _buildStaffSwitchBadge(
                isTablet: true,
                isCompact: isCompact,
                isUltraCompact: isUltraCompact,
              ),
              SizedBox(width: isUltraCompact ? 4 : 6),
              _buildShiftBadge(
                isTablet: true,
                isCompact: isCompact,
                isUltraCompact: isUltraCompact,
              ),
              SizedBox(width: isUltraCompact ? 4 : 6),
              _buildOpenBillBadge(
                isTablet: true,
                isCompact: isCompact,
                isUltraCompact: isUltraCompact,
              ),
            ],
          ),
        );
      },
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOutOfStock = product.trackStock && product.stock <= 0;
    final isLowStock =
        product.trackStock && !isOutOfStock && product.stock <= 5;
    final inCart = cartQty > 0;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B)
            : (isOutOfStock ? const Color(0xFFF8FAFC) : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: inCart
              ? (isDark
                    ? const Color(0xFF38BDF8)
                    : AppColors.darkCharcoal.withValues(alpha: 0.15))
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
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
                                        ? (isDark
                                              ? const Color(0xFF7F1D1D)
                                              : const Color(0xFFFEE2E2))
                                        : (isDark
                                              ? const Color(
                                                  0xFF0F172A,
                                                ).withValues(alpha: 0.85)
                                              : Colors.white.withValues(
                                                  alpha: 0.9,
                                                )),
                                    borderRadius: BorderRadius.circular(6),
                                    border: isOutOfStock
                                        ? Border.all(
                                            color: isDark
                                                ? const Color(0xFFB91C1C)
                                                : const Color(0xFFFECACA),
                                          )
                                        : null,
                                  ),
                                  child: Text(
                                    isOutOfStock
                                        ? 'Habis'
                                        : (!product.trackStock
                                              ? 'Tersedia'
                                              : 'Sisa ${product.stock > 1000 ? '∞' : product.stock}'),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isOutOfStock
                                          ? const Color(0xFFF87171)
                                          : (isLowStock
                                                ? const Color(0xFFF87171)
                                                : (isDark
                                                      ? const Color(0xFFCBD5E1)
                                                      : const Color(
                                                          0xFF334155,
                                                        ))),
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
                                : (isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A)),
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
                                      : (isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A)),
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
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
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
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;
        final isShortScreen = screenHeight < 520;
        final cartPanelWidth = screenWidth < 900 ? 315.0 : 350.0;

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
          width: cartPanelWidth,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: Border(
              left: BorderSide(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // 1. Quick Action Grid (1x4 on short screen, 2x2 on spacious tablet)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isShortScreen ? 10 : 14,
                  isShortScreen ? 8 : 12,
                  isShortScreen ? 10 : 14,
                  isShortScreen ? 6 : 8,
                ),
                child: isShortScreen
                    ? Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionButton(
                              icon: "assets/icons/customer.svg",
                              label: cartState.customer?.name ?? 'Customer',
                              isActive: cartState.customer != null,
                              onTap: () =>
                                  _showCustomerPicker(cartState.customer),
                              isCompact: true,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: _buildQuickActionButton(
                              icon: "assets/icons/tables.svg",
                              label:
                                  _tableNumber != null &&
                                      _tableNumber!.isNotEmpty
                                  ? 'Meja $_tableNumber'
                                  : 'Tables',
                              isActive:
                                  _tableNumber != null &&
                                  _tableNumber!.isNotEmpty,
                              onTap: _showTableDialog,
                              isCompact: true,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: _buildQuickActionButton(
                              icon: "assets/icons/discount.svg",
                              label: _selectedPromo != null
                                  ? _selectedPromo!.name
                                  : 'Discount',
                              isActive: _selectedPromo != null,
                              onTap: _showPromoPicker,
                              isCompact: true,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: _buildQuickActionButton(
                              icon: "assets/icons/save_bill.svg",
                              label: 'Save Bill',
                              isActive: false,
                              onTap: _showSaveBill,
                              isCompact: true,
                            ),
                          ),
                        ],
                      )
                    : Column(
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
                                      _tableNumber != null &&
                                          _tableNumber!.isNotEmpty
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

              Divider(
                height: 1,
                thickness: 1,
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),

              // 2. Order Details Header & Type Toggle
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isShortScreen ? 10 : 14,
                  isShortScreen ? 6 : 10,
                  isShortScreen ? 10 : 14,
                  isShortScreen ? 4 : 6,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order Details',
                      style: TextStyle(
                        fontSize: isShortScreen ? 13.5 : 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Container(
                      height: isShortScreen ? 28 : 32,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildOrderTypeToggle(
                            'Dine In',
                            isShortScreen: isShortScreen,
                          ),
                          _buildOrderTypeToggle(
                            'Take Away',
                            isShortScreen: isShortScreen,
                          ),
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
                          padding: EdgeInsets.all(isShortScreen ? 10 : 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                "assets/icons/order.svg",
                                height: isShortScreen ? 34 : null,
                              ),
                              SizedBox(height: isShortScreen ? 6 : 12),
                              Text(
                                'Belum Ada Pesanan',
                                style: TextStyle(
                                  fontSize: isShortScreen ? 12 : 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              if (!isShortScreen) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Sentuh menu di sebelah kiri untuk menambahkan pesanan',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.symmetric(
                          horizontal: isShortScreen ? 10 : 14,
                          vertical: isShortScreen ? 4 : 8,
                        ),
                        itemCount: cartState.items.length,
                        separatorBuilder: (context, index) => Divider(
                          height: isShortScreen ? 8 : 12,
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFF1F5F9),
                        ),
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
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
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
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 2),
                                    Text(
                                      '${formatter.format(item.unitPrice)} x ${item.quantity}',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B),
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
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF0F172A)
                                          : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF334155)
                                            : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          onTap: () => context
                                              .read<CartBloc>()
                                              .add(DecreaseQuantity(item.id)),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                            ),
                                            child: Icon(
                                              Icons.remove,
                                              size: 14,
                                              color: isDark
                                                  ? const Color(0xFF94A3B8)
                                                  : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${item.quantity}',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF0F172A),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            final cartState = context
                                                .read<CartBloc>()
                                                .state;
                                            final currentTotalQty = cartState
                                                .items
                                                .where(
                                                  (i) =>
                                                      i.productId ==
                                                          item.productId &&
                                                      (item.selectedVariant ==
                                                              null ||
                                                          i.selectedVariant?.id ==
                                                              item
                                                                  .selectedVariant
                                                                  ?.id),
                                                )
                                                .fold<int>(
                                                  0,
                                                  (sum, i) => sum + i.quantity,
                                                );

                                            if (item.maxStock != null &&
                                                currentTotalQty >=
                                                    item.maxStock!) {
                                              AppToast.showWarning(
                                                context,
                                                'Maksimal stok ${item.displayName} tercapai (${item.maxStock})',
                                              );
                                              return;
                                            }
                                            context.read<CartBloc>().add(
                                              IncrementQuantity(item.id),
                                            );
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                            ),
                                            child: Icon(
                                              Icons.add,
                                              size: 14,
                                              color:
                                                  (item.maxStock != null &&
                                                      item.quantity >=
                                                          item.maxStock!)
                                                  ? (isDark
                                                        ? const Color(
                                                            0xFF475569,
                                                          )
                                                        : const Color(
                                                            0xFFCBD5E1,
                                                          ))
                                                  : (isDark
                                                        ? const Color(
                                                            0xFF94A3B8,
                                                          )
                                                        : const Color(
                                                            0xFF64748B,
                                                          )),
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
                  child: Text(
                    'Hapus Keranjang',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                      fontSize: isShortScreen ? 11 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: isShortScreen ? 4 : 8),
              ],

              // 5. Order Summary Box
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isShortScreen ? 10 : 14,
                  isShortScreen ? 2 : 4,
                  isShortScreen ? 10 : 14,
                  isShortScreen ? 6 : 10,
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isShortScreen ? 10 : 12,
                    vertical: isShortScreen ? 6 : 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(
                      isShortScreen ? 10 : 12,
                    ),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Subtotal',
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                              fontSize: isShortScreen ? 11 : 12,
                            ),
                          ),
                          Text(
                            formatter.format(subtotal).trim(),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: isShortScreen ? 11 : 12,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isShortScreen ? 3 : 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tax (10%)',
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                              fontSize: isShortScreen ? 11 : 12,
                            ),
                          ),
                          Text(
                            formatter.format(tax).trim(),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: isShortScreen ? 11 : 12,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      if (discount > 0) ...[
                        SizedBox(height: isShortScreen ? 3 : 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Voucher / Diskon',
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF34D399)
                                    : const Color(0xFF059669),
                                fontSize: isShortScreen ? 11 : 12,
                              ),
                            ),
                            Text(
                              '- ${formatter.format(discount).trim()}',
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF34D399)
                                    : const Color(0xFF059669),
                                fontWeight: FontWeight.bold,
                                fontSize: isShortScreen ? 11 : 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: isShortScreen ? 4 : 8,
                        ),
                        child: Divider(
                          height: 1,
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: isShortScreen ? 13 : 15,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            formatter.format(grandTotal).trim(),
                            style: TextStyle(
                              fontSize: isShortScreen ? 15 : 17,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 6. Process Transaction & Hold Buttons
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isShortScreen ? 10 : 14,
                  0,
                  isShortScreen ? 10 : 14,
                  isShortScreen ? 8 : 14,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      height: isShortScreen ? 38 : 46,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFD97706),
                          side: const BorderSide(color: Color(0xFFF59E0B)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              isShortScreen ? 10 : 12,
                            ),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: isShortScreen ? 10 : 14,
                          ),
                        ),
                        onPressed: _showSaveBill,
                        child: Text(
                          'Tahan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isShortScreen ? 12 : 13,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isShortScreen ? 6 : 8),
                    Expanded(
                      child: SizedBox(
                        height: isShortScreen ? 38 : 46,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                isShortScreen ? 10 : 12,
                              ),
                            ),
                          ),
                          onPressed: () {
                            if (cartState.items.isEmpty) {
                              AppToast.showWarning(
                                context,
                                'Keranjang masih kosong',
                              );
                              return;
                            }
                            final shiftState = context.read<ShiftBloc>().state;
                            if (!shiftState.hasActiveShift) {
                              AppToast.showWarning(
                                context,
                                'Shift kasir belum dibuka. Masukkan modal awal terlebih dahulu.',
                              );
                              OpenShiftDialog.show(context);
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
                          child: Text(
                            'Proses Transaksi',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: isShortScreen ? 12.5 : 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Quick Action Button Component (ClaPos 2x2 or 1x4 compact)
  Widget _buildQuickActionButton({
    required String icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    bool isCompact = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isCompact ? 8 : 10),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 4 : 8,
          vertical: isCompact ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark
                    ? const Color(0xFF064E3B).withValues(alpha: 0.4)
                    : const Color(0xFFF0FDF4))
              : (isDark ? const Color(0xFF0F172A) : Colors.white),
          borderRadius: BorderRadius.circular(isCompact ? 8 : 10),
          border: Border.all(
            color: isActive
                ? (isDark
                      ? const Color(0xFF059669)
                      : AppColors.primary.withValues(alpha: 0.4))
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(icon, height: isCompact ? 18 : 28),
            SizedBox(height: isCompact ? 2 : 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isCompact ? 10 : 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive
                    ? (isDark ? const Color(0xFF34D399) : AppColors.primary)
                    : (isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF334155)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Order Type Toggle Button (Dine In / Take Away)
  Widget _buildOrderTypeToggle(String type, {bool isShortScreen = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _orderType == type;
    return InkWell(
      onTap: () => setState(() => _orderType = type),
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isShortScreen ? 8 : 10,
          vertical: isShortScreen ? 4 : 6,
        ),
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
            fontSize: isShortScreen ? 10.5 : 11.5,
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
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
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
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
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
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
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
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
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
            fillColor: isDark
                ? const Color(0xFF0F172A)
                : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Batal',
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
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
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
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
                                          ? const Color(
                                              0xFF064E3B,
                                            ).withValues(alpha: 0.3)
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

  // Action: Save Bill / Hold Order
  void _showSaveBill() {
    final cartState = context.read<CartBloc>().state;
    if (cartState.items.isEmpty) {
      AppToast.showWarning(context, 'Keranjang masih kosong');
      return;
    }
    final authState = context.read<AuthBloc>().state;
    final cashierName =
        (authState is Authenticated &&
            authState.user.name != null &&
            authState.user.name!.isNotEmpty)
        ? authState.user.name!
        : 'Kasir';
    HoldOrderDialog.show(
      context: context,
      cartState: cartState,
      cashierName: cashierName,
      onOrderHeld: () {
        context.read<CartBloc>().add(ClearCart());
      },
    );
  }
}
