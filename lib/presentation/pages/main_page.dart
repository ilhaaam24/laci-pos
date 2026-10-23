import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/style/app_colors.dart';
import '../../domain/entities/user_entity.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/cart/cart_bloc.dart';
import '../blocs/business/business_bloc.dart';
import 'kasir/kasir_page.dart';
import 'checkout/checkout_page.dart';
import 'report/report_page.dart';
import 'settings/settings_page.dart';
import '../blocs/shift/shift_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/shift_entity.dart';
import 'kasir/widgets/close_shift_dialog.dart';
import 'kasir/widgets/open_shift_dialog.dart';
import 'kasir/widgets/shift_control_sheet.dart';
import '../../core/di/injection.dart';
import '../../core/services/staff_auth_service.dart';
import 'kasir/widgets/staff_pin_dialog.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  static final GlobalKey<MainPageState> globalKey = GlobalKey<MainPageState>();

  static final GlobalKey<ScaffoldState> scaffoldKey =
      GlobalKey<ScaffoldState>();

  static void openDrawer() {
    scaffoldKey.currentState?.openDrawer();
  }

  static void switchToKasir() {
    globalKey.currentState?.switchToKasir();
  }

  @override
  State<MainPage> createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  final GlobalKey _ordersTabKey = GlobalKey();

  void switchToKasir() {
    if (mounted) {
      setState(() {
        _currentIndex = 0;
      });
    }
  }

  void _navigateToOrders() {
    KasirPageState.stopActiveScanner();
    setState(() {
      _currentIndex = 1;
    });
  }

  void _openDrawer() {
    KasirPageState.stopActiveScanner();
    MainPage.openDrawer();
  }

  List<(_PageItem, Widget)> _getFilteredPages(UserRole role) {
    final List<(_PageItem, Widget)> allPages = [
      (
        _PageItem(
          icon: 'assets/icons/chasier.svg',
          activeIcon: 'assets/icons/chasier.svg',
          label: 'Kasir',
          visible: role.canAccessPOS,
        ),
        KasirPage(
          key: KasirPage.globalKey,
          onOpenOrders: _navigateToOrders,
          onOpenDrawer: _openDrawer,
          ordersTabKey: _ordersTabKey,
        ),
      ),
      (
        _PageItem(
          icon: 'assets/icons/order.svg',
          activeIcon: 'assets/icons/order.svg',
          label: 'Pesanan',
          visible: role.canAccessPOS,
        ),
        CheckoutPage(
          onBackToKasir: () => setState(() => _currentIndex = 0),
          onOpenDrawer: _openDrawer,
        ),
      ),
      (
        _PageItem(
          icon: 'assets/icons/report.svg',
          activeIcon: 'assets/icons/report.svg',
          label: 'Laporan',
          visible: role.canAccessReports,
        ),
        ReportPage(onOpenDrawer: _openDrawer),
      ),
      (
        _PageItem(
          icon: 'assets/icons/setting.svg',
          activeIcon: 'assets/icons/setting.svg',
          label: 'Pengaturan',
          visible: role.canAccessSettings,
        ),
        SettingsPage(onOpenDrawer: _openDrawer),
      ),
    ];

    return allPages.where((element) => element.$1.visible).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! Authenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role = state.user.role;
        final filteredPages = _getFilteredPages(role);

        if (_currentIndex >= filteredPages.length) {
          _currentIndex = 0;
        }

        final isTablet = MediaQuery.of(context).size.width >= 720;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          key: MainPage.scaffoldKey,
          drawer: isTablet
              ? _buildTabletDrawer(context, state.user, filteredPages, isDark)
              : null,
          body: IndexedStack(
            index: _currentIndex,
            children: filteredPages.map((e) => e.$2).toList(),
          ),
          bottomNavigationBar: isTablet
              ? null
              : Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFF1F5F9),
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: BottomNavigationBar(
                    currentIndex: _currentIndex,
                    onTap: (index) {
                      if (_currentIndex != index) {
                        KasirPageState.stopActiveScanner();
                      }
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    type: BottomNavigationBarType.fixed,
                    backgroundColor: isDark
                        ? const Color(0xFF1E293B)
                        : Colors.white,
                    elevation: 0,
                    selectedItemColor: AppColors.primary,
                    unselectedItemColor: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    showSelectedLabels: true,
                    showUnselectedLabels: true,
                    selectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                    items: filteredPages.map((e) {
                      final item = e.$1;
                      final isOrders = item.label == 'Pesanan';

                      Widget iconWidget = SvgPicture.asset(
                        item.icon,
                        height: 28,
                      );
                      Widget activeIconWidget = SvgPicture.asset(
                        item.icon,
                        height: 28,
                      );

                      if (isOrders) {
                        final ordersBadgeWidget =
                            BlocBuilder<CartBloc, CartState>(
                              builder: (context, cartState) {
                                final count = cartState.items.fold(
                                  0,
                                  (sum, i) => sum + i.quantity,
                                );
                                return Badge(
                                  isLabelVisible: count > 0,
                                  label: Text(
                                    '$count',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  backgroundColor: AppColors.primary,
                                  child: SvgPicture.asset(
                                    item.icon,
                                    height: 28,
                                  ),
                                );
                              },
                            );

                        iconWidget = KeyedSubtree(
                          key: _ordersTabKey,
                          child: ordersBadgeWidget,
                        );
                        activeIconWidget = ordersBadgeWidget;
                      }

                      return BottomNavigationBarItem(
                        icon: iconWidget,
                        activeIcon: activeIconWidget,
                        label: item.label,
                      );
                    }).toList(),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildTabletDrawer(
    BuildContext context,
    UserEntity user,
    List<(_PageItem, Widget)> filteredPages,
    bool isDark,
  ) {
    return Drawer(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 1. Drawer Header: Business Info
            BlocBuilder<BusinessBloc, BusinessState>(
              builder: (context, bState) {
                final bInfo = bState.businessInfo;
                final businessName =
                    bInfo?.businessName.isNotEmpty == true &&
                        bInfo?.businessName != 'Toko Saya'
                    ? bInfo!.businessName
                    : 'Laci POS';
                final logoUrl = bInfo?.logoUrl;
                final hasLogo = logoUrl != null && logoUrl.isNotEmpty;

                return Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFF1F5F9),
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: hasLogo
                              ? (isDark
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFFF1F5F9))
                              : AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: hasLogo
                              ? CachedNetworkImage(
                                  imageUrl: logoUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) => Icon(
                                    Icons.storefront_rounded,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                    size: 22,
                                  ),
                                )
                              : SvgPicture.asset("assets/icons/logo.svg"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              businessName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  width: 6.5,
                                  height: 6.5,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Sistem Kasir POS',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
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
            ),

            const SizedBox(height: 10),

            // 2. Navigation Items List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                itemCount: filteredPages.length,
                itemBuilder: (context, index) {
                  final item = filteredPages[index].$1;
                  final isSelected = _currentIndex == index;
                  final isOrders = item.label == 'Pesanan';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: InkWell(
                      onTap: () {
                        if (_currentIndex != index) {
                          KasirPageState.stopActiveScanner();
                        }
                        setState(() {
                          _currentIndex = index;
                        });
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFF1F5F9))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            isOrders
                                ? BlocBuilder<CartBloc, CartState>(
                                    builder: (context, cartState) {
                                      final count = cartState.items.fold(
                                        0,
                                        (sum, i) => sum + i.quantity,
                                      );
                                      return Badge(
                                        isLabelVisible: count > 0,
                                        label: Text(
                                          '$count',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        backgroundColor: AppColors.primary,
                                        child: SvgPicture.asset(
                                          item.icon,
                                          height: 24,
                                        ),
                                      );
                                    },
                                  )
                                : SvgPicture.asset(item.icon, height: 24),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? (isDark
                                            ? Colors.white
                                            : AppColors.textPrimary)
                                      : (isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF334155)),
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.chevron_right_rounded,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Shift Quick Access in Drawer
            BlocBuilder<ShiftBloc, ShiftState>(
              builder: (context, shiftState) {
                final isOpen = shiftState.hasActiveShift;
                final shift = shiftState.activeShift;
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
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
                      Icon(
                        isOpen
                            ? Icons.point_of_sale_rounded
                            : Icons.storefront_outlined,
                        size: 22,
                        color: isOpen
                            ? AppColors.primary
                            : (isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isOpen ? 'Shift Aktif' : 'Shift Kasir',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isOpen
                                  ? (shift != null
                                        ? 'Buka pukul ${DateFormat('HH:mm').format(shift.startTime)}'
                                        : 'Siap transaksi')
                                  : 'Shift belum dibuka',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          if (isOpen) {
                            final action = await ShiftControlSheet.show(
                              context,
                            );
                            if (action == 'close_shift' && context.mounted) {
                              final shiftState = context
                                  .read<ShiftBloc>()
                                  .state;
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
                                      totalTransactions:
                                          active.totalTransactions,
                                      totalCashIn: 0,
                                      totalCashOut: 0,
                                      cashMovements: const [],
                                    );
                                final closeResult = await CloseShiftDialog.show(
                                  context,
                                  shift: active,
                                  summary: summary,
                                );
                                if (closeResult != null &&
                                    closeResult.isClosed &&
                                    context.mounted) {
                                  final curFmt = NumberFormat.currency(
                                    locale: 'id_ID',
                                    symbol: 'Rp ',
                                    decimalDigits: 0,
                                  );
                                  await StaffPinDialog.show(
                                    context,
                                    isLockMode: true,
                                    title: 'Shift Selesai • Masuk Kasir Baru',
                                    subtitle:
                                        'Masukkan 4 digit PIN kasir berikutnya',
                                    pendingHandoverAmount:
                                        closeResult.remainingCashInDrawer,
                                    pendingHandoverNote:
                                        'Serah terima dari ${active.userName}: Ditinggalkan ${curFmt.format(closeResult.remainingCashInDrawer)} di laci (Setor: ${curFmt.format(closeResult.depositedCash)})',
                                  );
                                }
                              }
                            }
                          } else {
                            OpenShiftDialog.show(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 34),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          isOpen ? 'Kelola' : 'Buka',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // 3. User Profile Footer
            Builder(
              builder: (context) {
                final staffService = getIt<StaffAuthService>();

                return ValueListenableBuilder<UserEntity?>(
                  valueListenable: staffService.activeStaffNotifier,
                  builder: (context, activeStaff, _) {
                    final effectiveUser = activeStaff ?? user;
                    final displayName =
                        (effectiveUser.name != null &&
                            effectiveUser.name!.isNotEmpty)
                        ? effectiveUser.name!
                        : effectiveUser.email;
                    final isStaffActive = activeStaff != null;

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFF1F5F9),
                            width: 1.0,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: isStaffActive
                                ? AppColors.primary
                                : const Color(0xFF004D40),
                            backgroundImage: effectiveUser.photoUrl != null
                                ? NetworkImage(effectiveUser.photoUrl!)
                                : null,
                            child: effectiveUser.photoUrl == null
                                ? Text(
                                    displayName.isNotEmpty
                                        ? displayName[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  displayName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Row(
                                  children: [
                                    Text(
                                      effectiveUser.role.name.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                    if (isStaffActive) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: const Text(
                                          'PIN STAF',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.lock_person_rounded,
                              size: 20,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                            tooltip: 'Kunci / Ganti Staf',
                            onPressed: () {
                              Navigator.pop(context);
                              StaffPinDialog.show(context);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PageItem {
  final String icon;
  final String? activeIcon;
  final String label;
  final bool visible;

  _PageItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.visible,
  });
}
