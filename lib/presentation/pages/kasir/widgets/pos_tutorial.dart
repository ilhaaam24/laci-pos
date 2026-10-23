import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../../../core/services/tutorial_service.dart';
import '../../../../core/style/app_colors.dart';

/// Class containing the target GlobalKeys for POS coach mark tour.
class PosTutorialTargets {
  final GlobalKey? shiftBadgeKey;
  final GlobalKey? staffSwitchBadgeKey;
  final GlobalKey? searchBarKey;
  final GlobalKey? categoryBarKey;
  final GlobalKey? productCatalogKey;
  final GlobalKey? ordersTabKey;
  final GlobalKey? tabletCartPanelKey;

  const PosTutorialTargets({
    this.shiftBadgeKey,
    this.staffSwitchBadgeKey,
    this.searchBarKey,
    this.categoryBarKey,
    this.productCatalogKey,
    this.ordersTabKey,
    this.tabletCartPanelKey,
  });
}

/// Helper class to create and present the interactive POS tutorial coach marks.
class PosTutorial {
  static TutorialCoachMark? _currentTutorial;

  /// Reset active tutorial instance for testing teardowns.
  @visibleForTesting
  static void resetForTesting() {
    _currentTutorial = null;
  }

  /// Check whether a given key is currently mounted and visible.
  static bool _isValidKey(GlobalKey? key) {
    if (key == null) return false;
    final ctx = key.currentContext;
    if (ctx == null || !ctx.mounted) return false;
    final renderBox = ctx.findRenderObject();
    if (renderBox is! RenderBox ||
        !renderBox.hasSize ||
        renderBox.size.isEmpty) {
      return false;
    }
    return true;
  }

  /// Show the POS tutorial. Returns true if tutorial was initiated.
  static bool show({
    required BuildContext context,
    required PosTutorialTargets targets,
    VoidCallback? onFinish,
    VoidCallback? onSkip,
  }) {
    // If a tutorial is already active, do not spawn another
    if (_currentTutorial != null) return false;

    final targetFocusList = <TargetFocus>[];

    // Candidate step definitions
    final candidateSteps = [
      if (_isValidKey(targets.shiftBadgeKey))
        _StepData(
          id: 'shift_badge',
          key: targets.shiftBadgeKey!,
          shape: ShapeLightFocus.RRect,
          radius: 12,
          paddingFocus: 6,
          align: ContentAlign.bottom,
          icon: Icons.lock_open_rounded,
          accentColor: AppColors.primary,
          title: '1. Buka & Kontrol Shift',
          description:
              'Mulai hari kerja dengan mencatat modal awal di laci kasir. Ketuk di sini untuk mencatat kas masuk/keluar atau menutup shift saat pergantian jam kerja.',
        ),
      if (_isValidKey(targets.staffSwitchBadgeKey))
        _StepData(
          id: 'staff_switch_badge',
          key: targets.staffSwitchBadgeKey!,
          shape: ShapeLightFocus.RRect,
          radius: 12,
          paddingFocus: 6,
          align: ContentAlign.bottom,
          icon: Icons.badge_outlined,
          accentColor: const Color(0xFFF59E0B),
          title: '2. Ganti Kasir / Staf & PIN',
          description:
              'Ganti kasir yang bertugas atau ubah PIN keamanan staf secara cepat tanpa perlu logout dari aplikasi.',
        ),
      if (_isValidKey(targets.searchBarKey))
        _StepData(
          id: 'search_bar',
          key: targets.searchBarKey!,
          shape: ShapeLightFocus.RRect,
          radius: 12,
          paddingFocus: 6,
          align: ContentAlign.bottom,
          icon: Icons.search_rounded,
          accentColor: const Color(0xFF0EA5E9),
          title: '3. Cari Cepat & Scan Barcode',
          description:
              'Ketik nama menu atau SKU barang, atau sentuh ikon barcode untuk langsung memindai kemasan produk menggunakan kamera.',
        ),
      if (_isValidKey(targets.categoryBarKey))
        _StepData(
          id: 'category_bar',
          key: targets.categoryBarKey!,
          shape: ShapeLightFocus.RRect,
          radius: 12,
          paddingFocus: 6,
          align: ContentAlign.bottom,
          icon: Icons.category_outlined,
          accentColor: const Color(0xFF8B5CF6),
          title: '4. Filter Kategori & Tampilan',
          description:
              'Pilih kategori menu (Makanan, Minuman, dll) dan ubah tampilan antara Grid (gambar) atau List (ringkas) sesuai kebutuhan kasir.',
        ),
      if (_isValidKey(targets.productCatalogKey))
        _StepData(
          id: 'product_catalog',
          key: targets.productCatalogKey!,
          shape: ShapeLightFocus.RRect,
          radius: 16,
          paddingFocus: 6,
          align: ContentAlign.top,
          icon: Icons.touch_app_rounded,
          accentColor: const Color(0xFF10B981),
          title: '5. Pilih Menu ke Pesanan',
          description:
              'Sentuh produk untuk memasukkan ke keranjang belanja. Jika menu memiliki pilihan varian, ukuran, atau topping, jendela kustomisasi akan terbuka otomatis.',
        ),
      if (_isValidKey(targets.tabletCartPanelKey))
        _StepData(
          id: 'tablet_cart_panel',
          key: targets.tabletCartPanelKey!,
          shape: ShapeLightFocus.RRect,
          radius: 16,
          paddingFocus: 6,
          align: ContentAlign.left,
          icon: Icons.shopping_bag_outlined,
          accentColor: AppColors.primary,
          title: '6. Keranjang & Pembayaran',
          description:
              'Periksa rincian pesanan pelanggan, atur tipe Dine In/Take Away, pilih nomor meja, dan tekan tombol Bayar untuk menuntaskan transaksi.',
        )
      else if (_isValidKey(targets.ordersTabKey))
        _StepData(
          id: 'orders_tab',
          key: targets.ordersTabKey!,
          shape: ShapeLightFocus.RRect,
          radius: 14,
          paddingFocus: 6,
          align: ContentAlign.top,
          icon: Icons.shopping_bag_outlined,
          accentColor: AppColors.primary,
          title: '6. Keranjang & Pembayaran',
          description:
              'Ketuk menu Pesanan untuk melihat keranjang belanja, menerapkan diskon promo, serta memproses pembayaran tunai, QRIS, atau transfer.',
        ),
    ];

    if (candidateSteps.isEmpty) {
      return false;
    }

    final total = candidateSteps.length;
    final isTablet = MediaQuery.sizeOf(context).width >= 720;

    for (var i = 0; i < total; i++) {
      final step = candidateSteps[i];
      final isFirst = i == 0;
      final isLast = i == total - 1;

      final placement = _calculatePlacement(
        context: context,
        key: step.key,
        stepId: step.id,
        isTablet: isTablet,
      );

      final displayTitle = step.title.replaceFirst(
        RegExp(r'^\d+\.\s*'),
        '${i + 1}. ',
      );

      targetFocusList.add(
        TargetFocus(
          identify: step.id,
          keyTarget: step.key,
          shape: step.shape,
          radius: step.radius,
          paddingFocus: step.paddingFocus,
          enableOverlayTab: true,
          enableTargetTab: true,
          contents: [
            TargetContent(
              align: ContentAlign.custom,
              customPosition: CustomTargetContentPosition(
                top: placement.top,
                bottom: placement.bottom,
                left: 0,
              ),
              padding: EdgeInsets.zero,
              builder: (ctx, controller) {
                return Padding(
                  padding: placement.padding,
                  child: Align(
                    alignment: placement.alignment,
                    child: PosTutorialTooltipCard(
                      step: i + 1,
                      totalSteps: total,
                      title: displayTitle,
                      description: step.description,
                      icon: step.icon,
                      accentColor: step.accentColor,
                      isFirst: isFirst,
                      isLast: isLast,
                      onNext: () => controller.next(),
                      onPrevious: isFirst ? null : () => controller.previous(),
                      onSkip: () => controller.skip(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    _currentTutorial = TutorialCoachMark(
      focusAnimationDuration: const Duration(milliseconds: 250),
      unFocusAnimationDuration: const Duration(milliseconds: 200),
      pulseAnimationDuration: const Duration(milliseconds: 800),
      targets: targetFocusList,
      colorShadow: const Color(0xFF0F172A),
      opacityShadow: 0.65,
      paddingFocus: 8,
      hideSkip: true, // We provide custom skip button inside the card
      onFinish: () {
        _currentTutorial = null;
        TutorialService().setPosTutorialSeen(true);
        if (onFinish != null) onFinish();
      },
      onSkip: () {
        _currentTutorial = null;
        TutorialService().setPosTutorialSeen(true);
        if (onSkip != null) onSkip();
        return true;
      },
      onClickTarget: (target) {},
      onClickOverlay: (target) {},
    );

    _currentTutorial!.show(context: context);
    return true;
  }

  /// Calculates safe and responsive placement for tooltip cards relative to targets.
  static _StepPlacement _calculatePlacement({
    required BuildContext context,
    required GlobalKey key,
    required String stepId,
    required bool isTablet,
  }) {
    final screenSize = MediaQuery.sizeOf(context);
    final safePadding = MediaQuery.paddingOf(context);
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    final fallbackTop = safePadding.top + 70.0;

    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    final hasRenderBox =
        renderBox != null && renderBox.hasSize && !renderBox.size.isEmpty;

    final offset = hasRenderBox
        ? renderBox.localToGlobal(Offset.zero)
        : Offset.zero;
    final size = hasRenderBox ? renderBox.size : Size.zero;
    final targetCenterX = offset.dx + size.width / 2;
    final alignX = hasRenderBox && screenWidth > 0
        ? ((targetCenterX / screenWidth) * 2 - 1).clamp(-0.75, 0.75)
        : 0.0;

    if (isTablet) {
      switch (stepId) {
        case 'shift_badge':
        case 'staff_switch_badge':
          final top = hasRenderBox
              ? (offset.dy + size.height + 10).clamp(
                  safePadding.top + 8,
                  screenHeight - 260,
                )
              : fallbackTop;
          return _StepPlacement(
            top: top,
            alignment: Alignment(alignX, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          );

        case 'search_bar':
          final top = hasRenderBox
              ? (offset.dy + size.height + 10).clamp(
                  safePadding.top + 8,
                  screenHeight - 260,
                )
              : fallbackTop;
          return _StepPlacement(
            top: top,
            alignment: Alignment(alignX, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          );

        case 'category_bar':
          // Vertical sidebar on tablet (left side, width ~92)
          final sidebarWidth = hasRenderBox ? size.width : 92.0;
          final top = hasRenderBox
              ? (offset.dy + 90).clamp(safePadding.top + 60, screenHeight - 300)
              : (safePadding.top + 90);
          return _StepPlacement(
            top: top,
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.only(left: sidebarWidth + 16, right: 16),
          );

        case 'product_catalog':
          // Center catalog area
          final top = hasRenderBox
              ? (offset.dy + 30).clamp(safePadding.top + 70, 160.0)
              : (safePadding.top + 100);
          return _StepPlacement(
            top: top,
            alignment: Alignment(alignX, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          );

        case 'tablet_cart_panel':
          // Right cart panel on tablet (width ~380)
          final panelWidth = hasRenderBox ? size.width : 380.0;
          final top = hasRenderBox
              ? (offset.dy + 90).clamp(safePadding.top + 60, screenHeight - 300)
              : (safePadding.top + 90);
          return _StepPlacement(
            top: top,
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: panelWidth + 16, left: 16),
          );

        default:
          return _StepPlacement(
            top: fallbackTop,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          );
      }
    } else {
      // Mobile / Phone Placement
      switch (stepId) {
        case 'shift_badge':
        case 'staff_switch_badge':
        case 'search_bar':
          final top = hasRenderBox
              ? (offset.dy + size.height + 10).clamp(
                  safePadding.top + 8,
                  screenHeight - 260,
                )
              : fallbackTop;
          return _StepPlacement(
            top: top,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          );

        case 'category_bar':
          final top = hasRenderBox
              ? (offset.dy + size.height + 10).clamp(
                  safePadding.top + 8,
                  screenHeight - 260,
                )
              : (fallbackTop + 60);
          return _StepPlacement(
            top: top,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          );

        case 'product_catalog':
          final top = hasRenderBox
              ? (offset.dy + 20).clamp(safePadding.top + 80, screenHeight - 280)
              : (fallbackTop + 120);
          return _StepPlacement(
            top: top,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          );

        case 'orders_tab':
          final bottom = hasRenderBox
              ? (screenHeight - offset.dy + 10).clamp(
                  safePadding.bottom + 8,
                  screenHeight - 260,
                )
              : (safePadding.bottom + 65);
          return _StepPlacement(
            bottom: bottom,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          );

        default:
          return _StepPlacement(
            top: fallbackTop,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          );
      }
    }
  }
}

class _StepPlacement {
  final double? top;
  final double? bottom;
  final Alignment alignment;
  final EdgeInsets padding;

  const _StepPlacement({
    this.top,
    this.bottom,
    this.alignment = Alignment.center,
    this.padding = EdgeInsets.zero,
  });
}

class _StepData {
  final String id;
  final GlobalKey key;
  final ShapeLightFocus shape;
  final double radius;
  final double paddingFocus;
  final ContentAlign align;
  final IconData icon;
  final Color accentColor;
  final String title;
  final String description;

  const _StepData({
    required this.id,
    required this.key,
    required this.shape,
    required this.radius,
    required this.paddingFocus,
    required this.align,
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.description,
  });
}

/// Custom polished tooltip card used across the tutorial steps.
class PosTutorialTooltipCard extends StatelessWidget {
  final int step;
  final int totalSteps;
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback? onPrevious;
  final VoidCallback onSkip;

  const PosTutorialTooltipCard({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.isFirst,
    required this.isLast,
    required this.onNext,
    this.onPrevious,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 390),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Step pill badge and Skip button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Langkah $step dari $totalSteps',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onSkip,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text(
                    'Lewati',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title & Description with Step Icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action Buttons: Previous & Next/Finish
          Row(
            children: [
              if (!isFirst && onPrevious != null) ...[
                OutlinedButton.icon(
                  onPressed: onPrevious,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFCBD5E1),
                    side: const BorderSide(color: Color(0xFF334155)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    size: 14,
                    color: AppColors.textPrimary,
                  ),
                  label: const Text(
                    'Kembali',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              const Spacer(),
              ElevatedButton.icon(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                iconAlignment: IconAlignment.end,
                icon: isLast
                    ? Icon(Icons.check_rounded, size: 15)
                    : Icon(Icons.arrow_forward_rounded, size: 15),
                label: Text(
                  isLast ? 'Selesai' : 'Lanjut',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
