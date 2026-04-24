import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/style/app_colors.dart';
import '../blocs/cart/cart_bloc.dart';
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
  final List<Widget> _pages = [
    const KasirPage(),
    const CheckoutPage(),
    const ReportPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _pages.length,
      child: Builder(
        builder: (context) {
          final tabController = DefaultTabController.of(context);

          return Scaffold(
            body: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: _pages,
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
              child: AnimatedBuilder(
                animation: tabController,
                builder: (context, _) {
                  return BottomNavigationBar(
                    currentIndex: tabController.index,
                    onTap: (index) {
                      tabController.animateTo(index);
                    },
                    type: BottomNavigationBarType.fixed,
                    backgroundColor: AppColors.surface,
                    selectedItemColor: AppColors.primary,
                    unselectedItemColor: AppColors.textDisabled,
                    selectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    items: [
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.storefront_outlined),
                        activeIcon: Icon(Icons.storefront),
                        label: 'Kasir',
                      ),
                      BottomNavigationBarItem(
                        icon: BlocBuilder<CartBloc, CartState>(
                          builder: (context, state) {
                            return Badge(
                              label: Text('${state.items.length}'),
                              isLabelVisible: state.items.isNotEmpty,
                              child: const Icon(Icons.shopping_cart_outlined),
                            );
                          },
                        ),
                        activeIcon: const Icon(Icons.shopping_cart),
                        label: 'Checkout',
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.bar_chart_outlined),
                        activeIcon: Icon(Icons.bar_chart),
                        label: 'Laporan',
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.settings_outlined),
                        activeIcon: Icon(Icons.settings),
                        label: 'Pengaturan',
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
