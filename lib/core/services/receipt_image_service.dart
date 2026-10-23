import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

import '../../domain/entities/business_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../presentation/pages/checkout/widgets/receipt_image_widget.dart';

import 'receipt_settings_service.dart';

class ReceiptImageService {
  static final ScreenshotController _screenshotController =
      ScreenshotController();

  /// Generates a high-quality JPG image byte array from a [TransactionEntity]
  static Future<Uint8List> generateReceiptJpgBytes({
    required TransactionEntity transaction,
    BusinessInfo? businessInfo,
    ReceiptConfig? config,
    BuildContext? context,
  }) async {
    // Wrap widget in a self-contained tree so off-screen rendering
    // does not depend on ephemeral modal/dialog state or fail due to missing Directionality/MediaQuery/Material
    final wrappedWidget = Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: Material(
          color: Colors.white,
          child: ReceiptImageWidget(
            transaction: transaction,
            businessInfo: businessInfo,
            config: config,
          ),
        ),
      ),
    );

    // 1. Capture widget as PNG bytes using captureFromLongWidget with unbounded height.
    // This completely eliminates RenderFlex overflow crashes on long receipts or on 360dp phone screens.
    final pngBytes = await _screenshotController.captureFromLongWidget(
      wrappedWidget,
      context: context,
      delay: const Duration(milliseconds: 60),
      pixelRatio: 2.0,
      constraints: const BoxConstraints(
        minWidth: 380,
        maxWidth: 400,
        maxHeight: double.infinity,
      ),
    );

    if (pngBytes.isEmpty) {
      throw Exception('Gagal membuat gambar struk: snapshot kosong.');
    }

    // 2. Decode PNG and re-encode to true JPG with high quality compression
    try {
      final decodedImage = img.decodeImage(pngBytes);
      if (decodedImage != null) {
        return Uint8List.fromList(img.encodeJpg(decodedImage, quality: 90));
      }
    } catch (e) {
      debugPrint('Warning: JPG re-encoding failed ($e), falling back to PNG bytes');
    }

    return pngBytes;
  }

  /// Generates a JPG receipt file in the temporary directory and returns the [File]
  static Future<File> generateReceiptJpgFile({
    required TransactionEntity transaction,
    BusinessInfo? businessInfo,
    ReceiptConfig? config,
    BuildContext? context,
  }) async {
    final jpgBytes = await generateReceiptJpgBytes(
      transaction: transaction,
      businessInfo: businessInfo,
      config: config,
      context: context,
    );

    final tempDir = await getTemporaryDirectory();
    final cleanCode = transaction.transactionCode.replaceAll(
      RegExp(r'[^\w\-]'),
      '_',
    );
    final file = File('${tempDir.path}/struk_$cleanCode.jpg');
    await file.writeAsBytes(jpgBytes, flush: true);

    if (!file.existsSync() || await file.length() == 0) {
      throw Exception('Gagal menyimpan file gambar struk ke memori sementara.');
    }

    return file;
  }
}
