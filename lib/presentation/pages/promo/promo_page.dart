import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../blocs/promo/promo_bloc.dart';
import '../../../domain/entities/promo_entity.dart';
import '../../../core/style/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import 'add_edit_promo_page.dart';

class PromoPage extends StatefulWidget {
  const PromoPage({super.key});

  @override
  State<PromoPage> createState() => _PromoPageState();
}

class _PromoPageState extends State<PromoPage> {
  @override
  void initState() {
    super.initState();
    context.read<PromoBloc>().add(LoadPromos());
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Manajemen Promo')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditPromoPage()),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Promo'),
      ),
      body: BlocConsumer<PromoBloc, PromoState>(
        listener: (context, state) {
          if (state.isSuccess && state.message != null) {
            AppToast.showSuccess(context, state.message!);
          }
          if (state.error != null) {
            AppToast.showError(context, state.error!);
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.promos.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.promos.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.promos.length,
            itemBuilder: (context, index) {
              final promo = state.promos[index];
              return _buildPromoCard(promo, currencyFormatter, index);
            },
          );
        },
      ),
    );
  }

  Widget _buildPromoCard(PromoEntity promo, NumberFormat formatter, int index) {
    final bool isExpired = promo.endDate != null && promo.endDate!.isBefore(DateTime.now());
    final bool isFuture = promo.startDate != null && promo.startDate!.isAfter(DateTime.now());
    
    String statusText = 'Aktif';
    Color statusColor = AppColors.success;
    
    if (!promo.isActive) {
      statusText = 'Nonaktif';
      statusColor = AppColors.textDisabled;
    } else if (isExpired) {
      statusText = 'Berakhir';
      statusColor = AppColors.error;
    } else if (isFuture) {
      statusText = 'Akan Datang';
      statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddEditPromoPage(promo: promo)),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          promo.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          promo.type == PromoType.percentage
                              ? 'Diskon ${promo.value.toStringAsFixed(0)}%'
                              : 'Potongan ${formatter.format(promo.value)}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    'Min. Belanja: ${formatter.format(promo.minPurchase)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              if (promo.startDate != null || promo.endDate != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'Periode: ${_formatDateRange(promo)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1);
  }

  String _formatDateRange(PromoEntity promo) {
    final df = DateFormat('dd MMM yyyy');
    if (promo.startDate != null && promo.endDate != null) {
      return '${df.format(promo.startDate!)} - ${df.format(promo.endDate!)}';
    } else if (promo.startDate != null) {
      return 'Mulai ${df.format(promo.startDate!)}';
    } else if (promo.endDate != null) {
      return 'Sampai ${df.format(promo.endDate!)}';
    }
    return 'Selamanya';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.confirmation_number_outlined,
            size: 80,
            color: AppColors.textDisabled,
          ).animate().scale(duration: 500.ms, curve: Curves.bounceIn),
          const SizedBox(height: 16),
          const Text(
            'Belum ada promo aktif',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditPromoPage()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Tambah Promo Sekarang'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
