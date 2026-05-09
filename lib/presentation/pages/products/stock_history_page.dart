import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/di/injection.dart';
import '../../../core/services/stock_service.dart';
import '../../../core/style/app_colors.dart';
import '../../../domain/entities/stock_log_entity.dart';
import '../../../domain/entities/product_entity.dart';

class StockHistoryPage extends StatelessWidget {
  final Product? product; // Optional: filter by product

  const StockHistoryPage({super.key, this.product});

  @override
  Widget build(BuildContext context) {
    final stockService = getIt<StockService>();
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          product == null ? 'Riwayat Stok' : 'Riwayat: ${product!.name}',
        ),
      ),
      body: StreamBuilder<List<StockLog>>(
        stream: product != null
            ? stockService.getStockLogs(product!.id)
            : stockService.getAllStockLogs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final logs = snapshot.data ?? [];

          if (logs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return _buildLogCard(log, dateFormat, index);
            },
          );
        },
      ),
    );
  }

  Widget _buildLogCard(StockLog log, DateFormat dateFormat, int index) {
    Color typeColor;
    IconData icon;
    String typeLabel;

    switch (log.type) {
      case StockLogType.stockIn:
        typeColor = AppColors.success;
        icon = Icons.add_circle_outline;
        typeLabel = 'Stok Masuk';
        break;
      case StockLogType.stockOut:
        typeColor = AppColors.error;
        icon = Icons.remove_circle_outline;
        typeLabel = 'Stok Keluar';
        break;
      case StockLogType.sale:
        typeColor = Colors.blue;
        icon = Icons.shopping_cart_outlined;
        typeLabel = 'Penjualan';
        break;
      case StockLogType.adjustment:
        typeColor = Colors.orange;
        icon = Icons.settings_backup_restore;
        typeLabel = 'Penyesuaian';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
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
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
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
                    Text(
                      'Stok: ${log.newStock}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (log.reason != null && log.reason!.isNotEmpty) ...[
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 14,
                    color: AppColors.textDisabled,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      log.reason!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                dateFormat.format(log.createdAt),
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textDisabled,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 30).ms).slideX(begin: 0.1);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.history,
            size: 80,
            color: AppColors.textDisabled,
          ).animate().scale(duration: 500.ms, curve: Curves.bounceIn),
          const SizedBox(height: 16),
          const Text(
            'Belum ada riwayat stok',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
