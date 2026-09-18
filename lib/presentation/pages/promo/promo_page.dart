import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Promo & Diskon',
          style: TextStyle(
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
      floatingActionButton: FloatingActionButton(
        elevation: 0,
        highlightElevation: 0,
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditPromoPage()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
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
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            );
          }

          if (state.promos.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: state.promos.length,
            itemBuilder: (context, index) {
              final promo = state.promos[index];
              return _buildPromoCard(promo, currencyFormatter);
            },
          );
        },
      ),
    );
  }

  Widget _buildPromoCard(PromoEntity promo, NumberFormat formatter) {
    final bool isExpired =
        promo.endDate != null && promo.endDate!.isBefore(DateTime.now());
    final bool isFuture =
        promo.startDate != null && promo.startDate!.isAfter(DateTime.now());

    String statusText = 'Aktif';
    Color statusBg = AppColors.primary;
    Color statusColor = AppColors.white;
    Color statusBorder = const Color(0xFFA7F3D0);

    if (!promo.isActive) {
      statusText = 'Nonaktif';
      statusBg = const Color(0xFFF1F5F9);
      statusColor = const Color(0xFF64748B);
      statusBorder = const Color(0xFFE2E8F0);
    } else if (isExpired) {
      statusText = 'Berakhir';
      statusBg = const Color(0xFFFEF2F2);
      statusColor = const Color(0xFFDC2626);
      statusBorder = const Color(0xFFFECACA);
    } else if (isFuture) {
      statusText = 'Akan Datang';
      statusBg = const Color(0xFFFFFBEB);
      statusColor = const Color(0xFFD97706);
      statusBorder = const Color(0xFFFDE68A);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddEditPromoPage(promo: promo)),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset("assets/icons/promoItem.svg", height: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          promo.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          promo.type == PromoType.percentage
                              ? 'Diskon ${promo.value.toStringAsFixed(0)}%'
                              : 'Potongan ${formatter.format(promo.value)}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusBorder),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF1F5F9),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    size: 14,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Min. Belanja: ${promo.minPurchase > 0 ? formatter.format(promo.minPurchase) : 'Tanpa Minimum'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Periode: ${_formatDateRange(promo)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateRange(PromoEntity promo) {
    try {
      final df = DateFormat('dd MMM yyyy', 'id_ID');
      if (promo.startDate != null && promo.endDate != null) {
        return '${df.format(promo.startDate!)} - ${df.format(promo.endDate!)}';
      } else if (promo.startDate != null) {
        return 'Mulai ${df.format(promo.startDate!)}';
      } else if (promo.endDate != null) {
        return 'Hingga ${df.format(promo.endDate!)}';
      }
    } catch (_) {
      final df = DateFormat('dd/MM/yyyy');
      if (promo.startDate != null && promo.endDate != null) {
        return '${df.format(promo.startDate!)} - ${df.format(promo.endDate!)}';
      } else if (promo.startDate != null) {
        return 'Mulai ${df.format(promo.startDate!)}';
      } else if (promo.endDate != null) {
        return 'Hingga ${df.format(promo.endDate!)}';
      }
    }
    return 'Berlaku Seterusnya';
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
                Icons.confirmation_number_outlined,
                size: 34,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada promo',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Buat kupon promo atau diskon menarik untuk meningkatkan penjualan',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
