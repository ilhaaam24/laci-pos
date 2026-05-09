import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/style/app_colors.dart';
import '../../domain/entities/user_entity.dart';
import '../blocs/auth/auth_bloc.dart';
import 'kasir/kasir_page.dart';
import 'checkout/checkout_page.dart';
import 'report/report_page.dart';
import 'settings/settings_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  List<(_PageItem, Widget)> _getFilteredPages(UserRole role) {
    final List<(_PageItem, Widget)> allPages = [
      (
        _PageItem(
          icon: Icons.point_of_sale,
          label: 'Kasir',
          visible: role.canAccessPOS,
        ),
        const KasirPage(),
      ),
      (
        _PageItem(
          icon: Icons.assignment_outlined,
          activeIcon: Icons.assignment,
          label: 'Orders',
          visible: role.canAccessPOS, // Orders usually part of POS flow
        ),
        const CheckoutPage(),
      ),
      (
        _PageItem(
          icon: Icons.bar_chart,
          label: 'Insights',
          visible: role.canAccessReports,
        ),
        const ReportPage(),
      ),
      (
        _PageItem(
          icon: Icons.menu,
          label: 'Menu',
          visible: role.canAccessSettings,
        ),
        const SettingsPage(),
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

        // Ensure current index is within bounds if pages changed
        if (_currentIndex >= filteredPages.length) {
          _currentIndex = 0;
        }

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: filteredPages.map((e) => e.$2).toList(),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: AppColors.surface,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textDisabled,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
              items: filteredPages.map((e) {
                final item = e.$1;
                return BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  activeIcon: Icon(item.activeIcon ?? item.icon),
                  label: item.label,
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _PageItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool visible;

  _PageItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.visible,
  });
}
