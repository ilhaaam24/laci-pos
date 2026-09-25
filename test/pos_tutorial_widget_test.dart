import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laci/core/style/app_colors.dart';
import 'package:laci/presentation/pages/kasir/widgets/pos_tutorial.dart';

void main() {
  testWidgets('PosTutorialTooltipCard renders correctly on mobile constraints', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    bool nextClicked = false;
    bool skipClicked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PosTutorialTooltipCard(
              step: 1,
              totalSteps: 6,
              title: '1. Buka & Kontrol Shift',
              description: 'Mulai hari kerja dengan mencatat modal awal di laci.',
              icon: Icons.lock_open_rounded,
              accentColor: AppColors.primary,
              isFirst: true,
              isLast: false,
              onNext: () => nextClicked = true,
              onSkip: () => skipClicked = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Langkah 1 dari 6'), findsOneWidget);
    expect(find.text('1. Buka & Kontrol Shift'), findsOneWidget);
    expect(
      find.text('Mulai hari kerja dengan mencatat modal awal di laci.'),
      findsOneWidget,
    );
    expect(find.text('Lewati'), findsOneWidget);
    expect(find.text('Lanjut'), findsOneWidget);
    expect(find.text('Kembali'), findsNothing); // isFirst is true

    await tester.tap(find.text('Lanjut'));
    expect(nextClicked, isTrue);

    await tester.tap(find.text('Lewati'));
    expect(skipClicked, isTrue);
  });

  testWidgets('PosTutorialTooltipCard renders last step with Selesai & Kembali', (
    tester,
  ) async {
    bool previousClicked = false;
    bool finishClicked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PosTutorialTooltipCard(
              step: 6,
              totalSteps: 6,
              title: '6. Keranjang & Pembayaran',
              description: 'Periksa pesanan dan selesaikan transaksi.',
              icon: Icons.shopping_bag_outlined,
              accentColor: AppColors.primary,
              isFirst: false,
              isLast: true,
              onNext: () => finishClicked = true,
              onPrevious: () => previousClicked = true,
              onSkip: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Langkah 6 dari 6'), findsOneWidget);
    expect(find.text('Kembali'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);

    await tester.tap(find.text('Kembali'));
    expect(previousClicked, isTrue);

    await tester.tap(find.text('Selesai'));
    expect(finishClicked, isTrue);
  });

  testWidgets('PosTutorialTooltipCard renders correctly on tablet constraints', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PosTutorialTooltipCard(
              step: 4,
              totalSteps: 6,
              title: '4. Filter Kategori & Tampilan',
              description: 'Pilih kategori menu dan ubah tampilan.',
              icon: Icons.category_outlined,
              accentColor: const Color(0xFF8B5CF6),
              isFirst: false,
              isLast: false,
              onNext: () {},
              onPrevious: () {},
              onSkip: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Langkah 4 dari 6'), findsOneWidget);
    expect(find.text('4. Filter Kategori & Tampilan'), findsOneWidget);
    expect(find.byIcon(Icons.category_outlined), findsOneWidget);
    expect(find.text('Kembali'), findsOneWidget);
    expect(find.text('Lanjut'), findsOneWidget);
    expect(find.text('Lewati'), findsOneWidget);
  });

  testWidgets('PosTutorial.show runs and displays tutorial on tablet screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      PosTutorial.resetForTesting();
    });

    final shiftKey = GlobalKey();
    final staffKey = GlobalKey();
    final searchKey = GlobalKey();
    final categoryKey = GlobalKey();
    final catalogKey = GlobalKey();
    final tabletCartKey = GlobalKey();

    late BuildContext scaffoldContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) {
              scaffoldContext = ctx;
              return Row(
                children: [
                  // 1. Category Sidebar (tablet left, width 92)
                  Container(
                    key: categoryKey,
                    width: 92,
                    height: 768,
                    color: Colors.blueGrey,
                  ),
                  // 2. Middle column
                  Expanded(
                    child: Column(
                      children: [
                        // Header
                        SizedBox(
                          height: 50,
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  key: searchKey,
                                  height: 38,
                                  color: Colors.grey,
                                ),
                              ),
                              Container(
                                key: staffKey,
                                width: 80,
                                height: 38,
                                color: Colors.orange,
                              ),
                              Container(
                                key: shiftKey,
                                width: 80,
                                height: 38,
                                color: Colors.green,
                              ),
                            ],
                          ),
                        ),
                        // Catalog
                        Expanded(
                          child: Container(
                            key: catalogKey,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 3. Tablet Cart Panel (tablet right, width 380)
                  Container(
                    key: tabletCartKey,
                    width: 380,
                    height: 768,
                    color: Colors.amber,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final started = PosTutorial.show(
      context: scaffoldContext,
      targets: PosTutorialTargets(
        shiftBadgeKey: shiftKey,
        staffSwitchBadgeKey: staffKey,
        searchBarKey: searchKey,
        categoryBarKey: categoryKey,
        productCatalogKey: catalogKey,
        tabletCartPanelKey: tabletCartKey,
      ),
    );

    expect(started, isTrue);

    // 1. Advance timer for postFrame (Future.delayed(Duration.zero))
    await tester.pump(const Duration(milliseconds: 20));
    // 2. Build overlay entry & initState of AnimatedFocusLight
    await tester.pump(const Duration(milliseconds: 20));
    // 3. Advance timer for _runFocus (Future.delayed(Duration.zero))
    await tester.pump(const Duration(milliseconds: 20));
    // 4. Complete focus animation (250ms)
    await tester.pump(const Duration(milliseconds: 350));
    // 5. Build contents with showContent = true
    await tester.pump(const Duration(milliseconds: 20));

    // First step should be visible
    expect(find.byType(PosTutorialTooltipCard), findsOneWidget);
    expect(find.text('1. Buka & Kontrol Shift'), findsOneWidget);
    expect(find.text('Lanjut'), findsOneWidget);

    Future<void> advanceStep() async {
      await tester.tap(find.text('Lanjut'));
      await tester.pump(); // execute onTap callback
      await tester.pump(const Duration(milliseconds: 250)); // reverse animation completes
      await tester.pump(const Duration(milliseconds: 300)); // forward animation completes
      await tester.pump(); // build next step content
    }

    // Step 2
    await advanceStep();
    expect(find.text('2. Ganti Kasir / Staf & PIN'), findsOneWidget);

    // Step 3
    await advanceStep();
    expect(find.text('3. Cari Cepat & Scan Barcode'), findsOneWidget);

    // Step 4: Category bar on tablet (vertical left sidebar)
    await advanceStep();
    expect(find.text('4. Filter Kategori & Tampilan'), findsOneWidget);

    // Verify it is on screen (render object is within 1024x768)
    final cardCenter = tester.getCenter(find.byType(PosTutorialTooltipCard));
    expect(cardCenter.dx, greaterThan(0));
    expect(cardCenter.dx, lessThan(1024));
    expect(cardCenter.dy, greaterThan(0));
    expect(cardCenter.dy, lessThan(768));

    // Step 5: Product catalog step
    await advanceStep();
    expect(find.text('5. Pilih Menu ke Pesanan'), findsOneWidget);
    final cardCenterStep5 = tester.getCenter(find.byType(PosTutorialTooltipCard));
    expect(cardCenterStep5.dx, greaterThan(0));
    expect(cardCenterStep5.dx, lessThan(1024));
    expect(cardCenterStep5.dy, greaterThan(0));
    expect(cardCenterStep5.dy, lessThan(768));

    // Step 6: Tablet cart panel step
    await advanceStep();
    expect(find.text('6. Keranjang & Pembayaran'), findsOneWidget);
    final cardCenterStep6 = tester.getCenter(find.byType(PosTutorialTooltipCard));
    expect(cardCenterStep6.dx, greaterThan(0));
    expect(cardCenterStep6.dx, lessThan(1024));
    expect(cardCenterStep6.dy, greaterThan(0));
    expect(cardCenterStep6.dy, lessThan(768));

    // Last step has "Selesai"
    expect(find.text('Selesai'), findsOneWidget);
    await tester.tap(find.text('Selesai'));
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('PosTutorial.show runs and displays tutorial on mobile screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      PosTutorial.resetForTesting();
    });

    final shiftKey = GlobalKey();
    final staffKey = GlobalKey();
    final searchKey = GlobalKey();
    final categoryKey = GlobalKey();
    final catalogKey = GlobalKey();
    final ordersTabKey = GlobalKey();

    late BuildContext scaffoldContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) {
              scaffoldContext = ctx;
              return Column(
                children: [
                  // 1. Header (Staff & Shift)
                  SizedBox(
                    height: 50,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(key: staffKey, width: 40, height: 36),
                        SizedBox(key: shiftKey, width: 40, height: 36),
                      ],
                    ),
                  ),
                  // 2. Search bar
                  Container(key: searchKey, height: 42),
                  // 3. Category bar (horizontal)
                  Container(key: categoryKey, height: 44),
                  // 4. Catalog
                  Expanded(
                    child: Container(key: catalogKey),
                  ),
                  // 5. Orders bottom tab
                  SizedBox(
                    height: 56,
                    child: Center(
                      child: SizedBox(key: ordersTabKey, width: 60, height: 40),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final started = PosTutorial.show(
      context: scaffoldContext,
      targets: PosTutorialTargets(
        shiftBadgeKey: shiftKey,
        staffSwitchBadgeKey: staffKey,
        searchBarKey: searchKey,
        categoryBarKey: categoryKey,
        productCatalogKey: catalogKey,
        ordersTabKey: ordersTabKey,
      ),
    );

    expect(started, isTrue);

    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.byType(PosTutorialTooltipCard), findsOneWidget);
    expect(find.text('1. Buka & Kontrol Shift'), findsOneWidget);

    Future<void> advanceStep() async {
      await tester.tap(find.text('Lanjut'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
    }

    // Step 2
    await advanceStep();
    expect(find.text('2. Ganti Kasir / Staf & PIN'), findsOneWidget);

    // Step 3
    await advanceStep();
    expect(find.text('3. Cari Cepat & Scan Barcode'), findsOneWidget);

    // Step 4
    await advanceStep();
    expect(find.text('4. Filter Kategori & Tampilan'), findsOneWidget);

    // Step 5
    await advanceStep();
    expect(find.text('5. Pilih Menu ke Pesanan'), findsOneWidget);

    // Step 6 (orders_tab)
    await advanceStep();
    expect(find.text('6. Keranjang & Pembayaran'), findsOneWidget);

    final cardCenterMobile = tester.getCenter(find.byType(PosTutorialTooltipCard));
    expect(cardCenterMobile.dx, greaterThan(0));
    expect(cardCenterMobile.dx, lessThan(360));
    expect(cardCenterMobile.dy, greaterThan(0));
    expect(cardCenterMobile.dy, lessThan(640));

    expect(find.text('Selesai'), findsOneWidget);
    await tester.tap(find.text('Selesai'));
    await tester.pump(const Duration(milliseconds: 300));
  });
}
