import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/di/injection.dart';
import '../../../core/services/stock_service.dart';
import '../../../core/style/app_colors.dart';
import '../../../domain/entities/stock_log_entity.dart';
import '../../../domain/entities/product_entity.dart';

class StockHistoryPage extends StatelessWidget {
  final Product? product;

  const StockHistoryPage({super.key, this.product});

  @override
  Widget build(BuildContext context) {
    final stockService = getIt<StockService>();
    DateFormat dateFormat;
    try {
      dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
    } catch (_) {
      dateFormat = DateFormat('dd/MM/yyyy, HH:mm');
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          product == null ? 'Riwayat Stok' : 'Stok: ${product!.name}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: StreamBuilder<List<StockLog>>(
        stream: product != null
            ? stockService.getStockLogs(product!.id)
            : stockService.getAllStockLogs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Terjadi kesalahan: ${snapshot.error}',
                style: const TextStyle(color: Color(0xFFDC2626)),
              ),
            );
          }

          final logs = snapshot.data ?? [];

          if (logs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return _buildLogCard(log, dateFormat);
            },
          );
        },
      ),
    );
  }

  Widget _buildLogCard(StockLog log, DateFormat dateFormat) {
    Color typeColor;
    Color typeBg;
    IconData icon;
    String typeLabel;

    switch (log.type) {
      case StockLogType.stockIn:
        typeColor = const Color(0xFF059669);
        typeBg = const Color(0xFFECFDF5);
        icon = Icons.add_circle_outline;
        typeLabel = 'Stok Masuk';
        break;
      case StockLogType.stockOut:
        typeColor = const Color(0xFFDC2626);
        typeBg = const Color(0xFFFEF2F2);
        icon = Icons.remove_circle_outline;
        typeLabel = 'Stok Keluar';
        break;
      case StockLogType.sale:
        typeColor = const Color(0xFF2563EB);
        typeBg = const Color(0xFFEFF6FF);
        icon = Icons.shopping_cart_outlined;
        typeLabel = 'Penjualan';
        break;
      case StockLogType.adjustment:
        typeColor = const Color(0xFFD97706);
        typeBg = const Color(0xFFFFFBEB);
        icon = Icons.settings_backup_restore;
        typeLabel = 'Penyesuaian';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: typeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: typeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      typeLabel,
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${log.quantity > 0 ? '+' : ''}${log.quantity}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: typeColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sisa: ${log.newStock}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (log.reason != null && log.reason!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      log.reason!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(
                Icons.access_time,
                size: 12,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(width: 4),
              Text(
                dateFormat.format(log.createdAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.history_toggle_off_rounded,
                size: 34,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada riwayat stok',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Perubahan stok dari penjualan atau penyesuaian akan muncul di sini',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
