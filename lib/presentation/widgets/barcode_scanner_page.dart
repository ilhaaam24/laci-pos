import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/style/app_colors.dart';
import '../pages/kasir/kasir_page.dart';

class BarcodeScannerPage extends StatefulWidget {
  final String title;
  final String instruction;

  const BarcodeScannerPage({
    super.key,
    this.title = 'Pindai Barcode / SKU',
    this.instruction = 'Arahkan kamera ke barcode produk',
  });

  static Future<String?> scan(
    BuildContext context, {
    String title = 'Pindai Barcode / SKU',
    String instruction = 'Arahkan kamera ke barcode produk',
  }) async {
    // Release active camera from KasirPage if running to prevent hardware lock
    KasirPageState.stopActiveScanner();
    await Future.delayed(const Duration(milliseconds: 150));
    if (!context.mounted) return null;

    return Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            BarcodeScannerPage(title: title, instruction: instruction),
      ),
    );
  }

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isScanned = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    // Safety check to ensure KasirPage scanner has released camera session
    KasirPageState.stopActiveScanner();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onBarcodeDetect(BarcodeCapture capture) {
    if (_isScanned) return;

    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.trim().isNotEmpty) {
        _isScanned = true;
        Navigator.pop(context, code.trim());
        break;
      }
    }
  }

  void _toggleTorch() {
    setState(() => _isTorchOn = !_isTorchOn);
    _controller.toggleTorch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: _isTorchOn ? Colors.amber : Colors.white,
            ),
            tooltip: 'Flashlight',
            onPressed: _toggleTorch,
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch_outlined, color: Colors.white),
            tooltip: 'Ganti Kamera',
            onPressed: () => _controller.switchCamera(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onBarcodeDetect,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.videocam_off_outlined,
                        color: Colors.amber,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Kamera Sedang Tidak Tersedia',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Kamera sedang digunakan atau izin belum aktif.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          KasirPageState.stopActiveScanner();
                          await Future.delayed(
                            const Duration(milliseconds: 250),
                          );
                          _controller.start();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Viewfinder Frame & Corners
          _buildViewfinderOverlay(),
          // Instruction hint pill
          Positioned(
            bottom: 50,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.instruction,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewfinderOverlay() {
    const boxSize = 260.0;
    const cornerLength = 28.0;
    const cornerThickness = 3.5;
    const cornerColor = AppColors.primary;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Box outline
        Container(
          width: boxSize,
          height: boxSize,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        // Top-Left Corner
        Positioned(
          left: (MediaQuery.of(context).size.width - boxSize) / 2,
          top: (MediaQuery.of(context).size.height - boxSize) / 2 - 40,
          child: Container(
            width: cornerLength,
            height: cornerLength,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: cornerColor, width: cornerThickness),
                left: BorderSide(color: cornerColor, width: cornerThickness),
              ),
            ),
          ),
        ),
        // Top-Right Corner
        Positioned(
          right: (MediaQuery.of(context).size.width - boxSize) / 2,
          top: (MediaQuery.of(context).size.height - boxSize) / 2 - 40,
          child: Container(
            width: cornerLength,
            height: cornerLength,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: cornerColor, width: cornerThickness),
                right: BorderSide(color: cornerColor, width: cornerThickness),
              ),
            ),
          ),
        ),
        // Bottom-Left Corner
        Positioned(
          left: (MediaQuery.of(context).size.width - boxSize) / 2,
          bottom: (MediaQuery.of(context).size.height - boxSize) / 2 + 40,
          child: Container(
            width: cornerLength,
            height: cornerLength,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: cornerColor, width: cornerThickness),
                left: BorderSide(color: cornerColor, width: cornerThickness),
              ),
            ),
          ),
        ),
        // Bottom-Right Corner
        Positioned(
          right: (MediaQuery.of(context).size.width - boxSize) / 2,
          bottom: (MediaQuery.of(context).size.height - boxSize) / 2 + 40,
          child: Container(
            width: cornerLength,
            height: cornerLength,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: cornerColor, width: cornerThickness),
                right: BorderSide(color: cornerColor, width: cornerThickness),
              ),
            ),
          ),
        ),
        // Laser line guide in the middle
        Container(
          width: boxSize - 20,
          height: 2,
          decoration: BoxDecoration(
            color: cornerColor.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }
}
