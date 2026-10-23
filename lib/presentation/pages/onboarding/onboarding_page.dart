import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../core/services/onboarding_service.dart';
import '../../../core/style/app_colors.dart';
import '../auth/login_page.dart';

class OnboardingSlideData {
  final String title;
  final String description;
  final String icon;
  final Color themeColor;
  final Color themeLightColor;
  final String badgeText;
  final IconData badgeIcon;

  const OnboardingSlideData({
    required this.title,
    required this.description,
    required this.icon,
    required this.themeColor,
    required this.themeLightColor,
    required this.badgeText,
    required this.badgeIcon,
  });
}

class OnboardingPage extends StatefulWidget {
  final VoidCallback? onComplete;

  const OnboardingPage({super.key, this.onComplete});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  static const List<OnboardingSlideData> _slides = [
    OnboardingSlideData(
      title: 'Transaksi Kasir Cepat & Praktis',
      description:
          'Catat pesanan pelanggan, hitung total otomatis, dan cetak struk via printer Bluetooth dalam hitungan detik.',
      icon: "assets/icons/onboarding_1.svg",
      themeColor: AppColors.primary,
      themeLightColor: AppColors.primaryLight,
      badgeText: 'Kasir & Struk',
      badgeIcon: Icons.print_rounded,
    ),
    OnboardingSlideData(
      title: 'Kelola Produk & Pantau Stok',
      description:
          'Atur katalog produk, varian harga, scan barcode kamera, serta pantau sisa stok toko secara akurat.',
      icon: "assets/icons/onboarding_2.svg",
      themeColor: AppColors.secondary,
      themeLightColor: AppColors.secondaryLight,
      badgeText: 'Stok Terpantau',
      badgeIcon: Icons.qr_code_scanner_rounded,
    ),
    OnboardingSlideData(
      title: 'Laporan Keuangan & Rekap Shift',
      description:
          'Pantau omset harian, laba bersih bisnis, serta serah terima kasir laci kas yang transparan.',
      icon: "assets/icons/onboarding_3.svg",
      themeColor: Color(0xFFD97706),
      themeLightColor: Color(0xFFFEF3C7),
      badgeText: 'Rekap & Omset',
      badgeIcon: Icons.trending_up_rounded,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    await OnboardingService.setOnboardingCompleted();
    if (!mounted) return;

    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  void _onNextTapped() {
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final subtextColor = isDark
        ? const Color(0xFF94A3B8)
        : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: surfaceColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Bar: Lewati (Skip) Action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: SizedBox(
                height: 36,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _currentIndex < _slides.length - 1
                      ? GestureDetector(
                          onTap: _finishOnboarding,
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            child: Text(
                              'Lewati',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: subtextColor,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(height: 24),
                ),
              ),
            ),

            // 2. Middle Slider (Illustration, Title, Subtitle)
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Hero Illustration
                                _buildIllustration(slide, isDark),

                                // Title (Centered, bold, punchy)
                                Text(
                                  slide.title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                    letterSpacing: -0.3,
                                    height: 1.25,
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Subtitle / Description (Centered, muted, 2 lines)
                                Text(
                                  slide.description,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w400,
                                    color: subtextColor,
                                    height: 1.5,
                                  ),
                                ),

                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // 3. Dot Indicator (Centered, directly below subtitle)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (index) {
                  final isActive = index == _currentIndex;
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 6,
                      width: isActive ? 22 : 6,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary
                            : (isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // 4. Bottom CTA Button (Wide, rounded, primary color)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: ElevatedButton(
                onPressed: _onNextTapped,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _currentIndex == _slides.length - 1
                      ? 'Mulai Sekarang'
                      : 'Lanjut',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration(OnboardingSlideData slide, bool isDark) {
    final circleBg = isDark
        ? slide.themeColor.withValues(alpha: 0.15)
        : slide.themeLightColor;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(color: circleBg, shape: BoxShape.circle),
        ),

        // Central Icon Card
        SvgPicture.asset(slide.icon, width: 420, height: 420),
      ],
    );
  }
}
