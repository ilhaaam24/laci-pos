import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/style/app_colors.dart';
import '../blocs/cart/cart_bloc.dart';
import 'kasir/kasir_page.dart';
import 'checkout/checkout_page.dart';
import 'products/products_page.dart';
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
    const ProductsPage(),
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
                    items: [
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.receipt_outlined),
                        activeIcon: Icon(Icons.receipt),
                        label: 'Register',
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.assignment_outlined),
                        activeIcon: Icon(Icons.assignment),
                        label: 'Orders',
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.inventory_2_outlined),
                        activeIcon: Icon(Icons.inventory_2),
                        label: 'Inventory',
                      ),
                      BottomNavigationBarItem(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: tabController.index == 3
                              ? BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                )
                              : null,
                          child: Icon(
                            Icons.bar_chart,
                            color: tabController.index == 3
                                ? Colors.white
                                : AppColors.textDisabled,
                          ),
                        ),
                        label: 'Insights',
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.menu),
                        label: 'Menu',
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
