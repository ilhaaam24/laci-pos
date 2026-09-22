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
import 'kasir/widgets/open_shift_dialog.dart';
import 'kasir/widgets/shift_control_sheet.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  static final GlobalKey<ScaffoldState> scaffoldKey =
      GlobalKey<ScaffoldState>();

  static void openDrawer() {
    scaffoldKey.currentState?.openDrawer();
  }

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  void _navigateToOrders() {
    setState(() {
      _currentIndex = 1;
    });
  }

  void _openDrawer() {
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
        KasirPage(onOpenOrders: _navigateToOrders, onOpenDrawer: _openDrawer),
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
                        iconWidget = BlocBuilder<CartBloc, CartState>(
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
                              child: SvgPicture.asset(item.icon, height: 28),
                            );
                          },
                        );

                        activeIconWidget = BlocBuilder<CartBloc, CartState>(
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
                              child: SvgPicture.asset(item.icon, height: 28),
                            );
                          },
                        );
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
                    vertical: 6,
                  ),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isOpen
                        ? (isDark
                              ? const Color(0xFF064E3B).withValues(alpha: 0.4)
                              : const Color(0xFFECFDF5))
                        : (isDark
                              ? const Color(0xFF78350F).withValues(alpha: 0.4)
                              : const Color(0xFFFFFBEB)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isOpen
                          ? (isDark
                                ? const Color(0xFF059669)
                                : const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.3))
                          : (isDark
                                ? const Color(0xFFD97706)
                                : const Color(
                                    0xFFF59E0B,
                                  ).withValues(alpha: 0.3)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isOpen
                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                              : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isOpen
                              ? Icons.lock_open_rounded
                              : Icons.lock_clock_rounded,
                          color: isOpen
                              ? (isDark
                                    ? const Color(0xFF34D399)
                                    : const Color(0xFF059669))
                              : (isDark
                                    ? const Color(0xFFFBBF24)
                                    : const Color(0xFFD97706)),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isOpen
                                  ? 'Shift Kasir Aktif'
                                  : 'Shift Belum Dibuka',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isOpen
                                    ? (isDark
                                          ? const Color(0xFF6EE7B7)
                                          : const Color(0xFF065F46))
                                    : (isDark
                                          ? const Color(0xFFFCD34D)
                                          : const Color(0xFF92400E)),
                              ),
                            ),
                            Text(
                              isOpen
                                  ? 'Kasir: ${shift?.userName ?? 'Kasir'}'
                                  : 'Buka shift untuk catat laci',
                              style: TextStyle(
                                fontSize: 11,
                                color: isOpen
                                    ? (isDark
                                          ? const Color(0xFFA7F3D0)
                                          : const Color(0xFF047857))
                                    : (isDark
                                          ? const Color(0xFFFDE68A)
                                          : const Color(0xFFB45309)),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          if (isOpen) {
                            ShiftControlSheet.show(context);
                          } else {
                            OpenShiftDialog.show(context);
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          isOpen ? 'Kelola' : 'Buka',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isOpen
                                ? (isDark
                                      ? const Color(0xFF34D399)
                                      : const Color(0xFF059669))
                                : (isDark
                                      ? const Color(0xFFFBBF24)
                                      : AppColors.white),
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
                final displayName = (user.name != null && user.name!.isNotEmpty)
                    ? user.name!
                    : user.email;

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
                        backgroundColor: const Color(0xFF004D40),
                        backgroundImage: user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: user.photoUrl == null
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
                            Text(
                              user.role.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
