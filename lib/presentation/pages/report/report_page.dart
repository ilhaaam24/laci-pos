import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/style/app_colors.dart';
import '../../blocs/report/report_bloc.dart';
import '../../blocs/transaction/transaction_bloc.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String _selectedPeriod = 'Bulanan'; // Changed default to Bulanan to see more data
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadReport();
    context.read<TransactionBloc>().add(LoadTransactions());
  }

  void _loadReport() {
    if (_selectedPeriod == 'Harian') {
      context.read<ReportBloc>().add(LoadDailyReport(_selectedDate));
    } else if (_selectedPeriod == 'Mingguan') {
      context.read<ReportBloc>().add(LoadWeeklyReport(_selectedDate));
    } else if (_selectedPeriod == 'Bulanan') {
      context.read<ReportBloc>().add(LoadMonthlyReport(_selectedDate));
    }
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
      appBar: AppBar(
        title: const Text('Laporan Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadReport();
          context.read<TransactionBloc>().add(LoadTransactions());
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPeriodSelector(),
              const SizedBox(height: 16),
              _buildSelectedDateInfo(),
              const SizedBox(height: 24),
              _buildReportContent(currencyFormatter),
              const SizedBox(height: 32),
              _buildLastTransactionsHeader(),
              const SizedBox(height: 12),
              _buildTransactionList(currencyFormatter),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadReport();
    }
  }

  Widget _buildSelectedDateInfo() {
    String dateText = '';
    if (_selectedPeriod == 'Harian') {
      dateText = DateFormat('dd MMMM yyyy').format(_selectedDate);
    } else if (_selectedPeriod == 'Mingguan') {
      final start = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
      final end = start.add(const Duration(days: 6));
      dateText = '${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}';
    } else {
      dateText = DateFormat('MMMM yyyy').format(_selectedDate);
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          dateText,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          _buildPeriodButton('Harian'),
          _buildPeriodButton('Mingguan'),
          _buildPeriodButton('Bulanan'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String title) {
    final isSelected = _selectedPeriod == title;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _selectedPeriod = title);
          _loadReport();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.purple.shade700 : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportContent(NumberFormat formatter) {
    return BlocBuilder<ReportBloc, ReportState>(
      builder: (context, state) {
        if (state is ReportLoading || state is ReportInitial) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is ReportError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Gagal memuat laporan',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(state.message, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _loadReport, child: const Text('Coba Lagi')),
                ],
              ),
            ),
          );
        }

        if (state is ReportLoaded) {
          final data = state.reportData;
          return Column(
            children: [
              _buildMainSummaryCard(
                'Total Penjualan',
                formatter.format(data['totalRevenue'] ?? 0),
                Icons.payments_outlined,
                Colors.green,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSmallSummaryCard(
                      'Profit',
                      formatter.format(data['totalProfit'] ?? 0),
                      Icons.trending_up_outlined,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSmallSummaryCard(
                      'Transaksi',
                      '${data['totalTransactions'] ?? 0}',
                      Icons.receipt_long_outlined,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildMainSummaryCard(
                'Produk Terjual',
                '${data['totalItems'] ?? 0}',
                Icons.inventory_2_outlined,
                Colors.purple,
              ),
            ],
          );
        }

        return const Center(child: Text('Tidak ada status report'));
      },
    );
  }

  Widget _buildMainSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastTransactionsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Transaksi Terakhir',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        TextButton(onPressed: () {}, child: const Text('Lihat Semua')),
      ],
    );
  }

  Widget _buildTransactionList(NumberFormat formatter) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        if (state is TransactionLoading || state is TransactionInitial) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is TransactionError) {
          return Center(child: Text('Error transaksi: ${state.message}'));
        }

        if (state is TransactionLoaded) {
          final transactions = state.transactions;
          if (transactions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum ada transaksi sama sekali',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length > 10 ? 10 : transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple.shade50,
                    child: const Icon(Icons.receipt_outlined, color: Colors.purple),
                  ),
                  title: Text(
                    transaction.transactionCode,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(transaction.createdAt),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  trailing: Text(
                    formatter.format(transaction.totalAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              );
            },
          );
        }

        return const SizedBox();
      },
    );
  }
}
