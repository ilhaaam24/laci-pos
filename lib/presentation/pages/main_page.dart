import 'package:flutter/material.dart';
import '../../core/style/app_colors.dart';
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
                        icon: Icon(Icons.point_of_sale),
                        activeIcon: Icon(Icons.point_of_sale),
                        label: 'Kasir',
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.assignment_outlined),
                        activeIcon: Icon(Icons.assignment),
                        label: 'Orders',
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.bar_chart),
                        activeIcon: Icon(Icons.bar_chart),
                        label: 'Insights',
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.menu),
                        activeIcon: Icon(Icons.menu),

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
