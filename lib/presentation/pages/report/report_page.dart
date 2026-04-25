import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/style/app_colors.dart';
import '../../blocs/report/report_bloc.dart';
import '../../blocs/transaction/transaction_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import '../../../core/services/export_service.dart';
import '../../blocs/business/business_bloc.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String _selectedPeriod =
      'Bulanan'; // Changed default to Bulanan to see more data
  DateTime _selectedDate = DateTime.now();
  DateTime? _endDate;

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
      if (_endDate != null) {
        context.read<ReportBloc>().add(
          LoadCustomRangeReport(_selectedDate, _endDate!),
        );
      } else {
        final start = _selectedDate.subtract(
          Duration(days: _selectedDate.weekday - 1),
        );
        final end = start.add(const Duration(days: 6));
        context.read<ReportBloc>().add(LoadCustomRangeReport(start, end));
      }
    } else if (_selectedPeriod == 'Bulanan') {
      context.read<ReportBloc>().add(LoadMonthlyReport(_selectedDate));
    } else if (_selectedPeriod == 'Kustom' && _endDate != null) {
      context.read<ReportBloc>().add(
        LoadCustomRangeReport(_selectedDate, _endDate!),
      );
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
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16),
        title: const Text('Laporan Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _selectDate(context),
          ),
          const SizedBox(width: 8),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _exportReport,
            child: Row(
              children: [
                const Icon(
                  Icons.download_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 4),
                const Text(
                  'Export PDF',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
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
              _buildTopSellingSection(),
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

  void _exportReport() {
    final reportState = context.read<ReportBloc>().state;
    if (reportState is ReportLoaded) {
      final businessState = context.read<BusinessBloc>().state;
      final businessInfo = businessState.businessInfo;

      ExportService.exportReportToPdf(
        reportData: reportState.reportData,
        period: _selectedPeriod == 'Kustom'
            ? '${DateFormat('dd MMM').format(_selectedDate)} - ${DateFormat('dd MMM').format(_endDate ?? _selectedDate)}'
            : _selectedPeriod,
        businessInfo: businessInfo,
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Laporan belum dimuat')));
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    if (_selectedPeriod == 'Bulanan') {
      final picked = await showMonthPicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      );
      if (picked != null) {
        setState(() {
          _selectedDate = picked;
          _endDate = null;
        });
        _loadReport();
      }
    } else if (_selectedPeriod == 'Kustom' || _selectedPeriod == 'Mingguan') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: SizedBox(
            height: 350,
            width: 300,
            child: SfDateRangePicker(
              onSelectionChanged: (args) {
                if (args.value is PickerDateRange) {
                  if (args.value.startDate != null &&
                      args.value.endDate != null) {
                    Navigator.pop(context, args.value);
                  }
                }
              },
              selectionMode: DateRangePickerSelectionMode.range,
              initialSelectedRange: PickerDateRange(_selectedDate, _endDate),
              maxDate: DateTime.now(),
            ),
          ),
        ),
      ).then((value) {
        if (value is PickerDateRange) {
          setState(() {
            _selectedDate = value.startDate!;
            _endDate = value.endDate;
          });
          _loadReport();
        }
      });
    } else {
      final picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      );
      if (picked != null) {
        setState(() {
          _selectedDate = picked;
          _endDate = null;
        });
        _loadReport();
      }
    }
  }

  Widget _buildSelectedDateInfo() {
    String dateText = '';
    if (_selectedPeriod == 'Harian') {
      dateText = DateFormat('dd MMMM yyyy').format(_selectedDate);
    } else if (_selectedPeriod == 'Mingguan' || _selectedPeriod == 'Kustom') {
      if (_endDate != null) {
        dateText =
            '${DateFormat('dd MMM').format(_selectedDate)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}';
      } else {
        final start = _selectedDate.subtract(
          Duration(days: _selectedDate.weekday - 1),
        );
        final end = start.add(const Duration(days: 6));
        dateText =
            '${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}';
      }
    } else {
      dateText = DateFormat('MMMM yyyy').format(_selectedDate);
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
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
          _buildPeriodButton('Kustom'),
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
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Gagal memuat laporan',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadReport,
                    child: const Text('Coba Lagi'),
                  ),
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

  Widget _buildTopSellingSection() {
    return BlocBuilder<ReportBloc, ReportState>(
      builder: (context, state) {
        if (state is ReportLoaded) {
          final bestSellers =
              state.reportData['bestSellingProducts'] as List<dynamic>? ?? [];

          if (bestSellers.isEmpty) return const SizedBox();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Top 5 Produk Terlaris',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 250,
                padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.divider),
                ),
                child: BarChart(
                  BarChartData(
                    backgroundColor: Colors.white,
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _getMaxQuantity(bestSellers).toDouble() + 1,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: AppColors.primary,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${bestSellers[groupIndex]['productName']}\n',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text: '${rod.toY.toInt()} terjual',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < bestSellers.length) {
                              final name =
                                  bestSellers[index]['productName'] as String;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  name.length > 8
                                      ? '${name.substring(0, 6)}..'
                                      : name,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                          reservedSize: 30,
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: bestSellers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: (data['totalQuantity'] as int).toDouble(),
                            color: AppColors.primary,
                            width: 25,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: _getMaxQuantity(bestSellers).toDouble() + 1,
                              color: AppColors.divider.withOpacity(0.5),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          );
        }
        return const SizedBox();
      },
    );
  }

  int _getMaxQuantity(List<dynamic> data) {
    if (data.isEmpty) return 0;
    return data
        .map((e) => e['totalQuantity'] as int)
        .reduce((a, b) => a > b ? a : b);
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
            color: Colors.black.withOpacity(0.05),
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
              color: color.withOpacity(0.1),
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
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: Colors.grey[300],
                    ),
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
                    child: const Icon(
                      Icons.receipt_outlined,
                      color: Colors.purple,
                    ),
                  ),
                  title: Text(
                    transaction.transactionCode,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    DateFormat(
                      'dd MMM yyyy, HH:mm',
                    ).format(transaction.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
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
