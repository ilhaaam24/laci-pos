import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../../../core/style/app_colors.dart';
import '../../../core/services/export_service.dart';
import '../../blocs/report/report_bloc.dart';
import '../../blocs/business/business_bloc.dart';
import '../../blocs/transaction/transaction_bloc.dart';
import '../../../domain/entities/transaction_entity.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String _selectedPeriod = 'Bulanan';
  DateTime _selectedDate = DateTime.now();
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  void _loadReport() {
    if (_selectedPeriod == 'Harian') {
      context.read<ReportBloc>().add(LoadDailyReport(_selectedDate));
    } else if (_selectedPeriod == 'Mingguan') {
      context.read<ReportBloc>().add(LoadWeeklyReport(_selectedDate));
    } else if (_selectedPeriod == 'Bulanan') {
      context.read<ReportBloc>().add(LoadMonthlyReport(_selectedDate));
    } else if (_selectedPeriod == 'Kustom' && _endDate != null) {
      context.read<ReportBloc>().add(
        LoadCustomRangeReport(_selectedDate, _endDate!),
      );
    }
    // Also load recent transactions
    context.read<TransactionBloc>().add(LoadTransactions());
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
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Pilih Rentang Tanggal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
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
                  initialSelectedRange: PickerDateRange(
                    _selectedDate,
                    _endDate,
                  ),
                  maxDate: DateTime.now(),
                  headerStyle: const DateRangePickerHeaderStyle(
                    textStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  monthCellStyle: const DateRangePickerMonthCellStyle(
                    todayTextStyle: TextStyle(color: AppColors.primary),
                  ),
                  selectionColor: AppColors.primary,
                  startRangeSelectionColor: AppColors.primary,
                  endRangeSelectionColor: AppColors.primary,
                  rangeSelectionColor: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
            ],
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

  Future<void> _handleExport() async {
    final reportState = context.read<ReportBloc>().state;
    final businessState = context.read<BusinessBloc>().state;

    if (reportState is ReportLoaded) {
      try {
        await ExportService.exportReportToPdf(
          reportData: reportState.reportData,
          period: _selectedPeriod,
          businessInfo: businessState.businessInfo,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mengekspor laporan: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan belum dimuat atau sedang memproses data'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: "Rp",
      decimalDigits: 0,
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionTitle('Business Overview', 'Analytics'),
                    Row(
                      children: [
                        _buildDatePill(),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _handleExport,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: const Icon(
                              Icons.picture_as_pdf_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textDisabled,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    padding: const EdgeInsets.all(4),
                    tabs: const [
                      Tab(text: 'Transaksi'),
                      Tab(text: 'Laporan'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildTransactionTab(currencyFormatter),
                    _buildReportTab(currencyFormatter),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTab(NumberFormat currencyFormatter) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<TransactionBloc>().add(LoadTransactions());
      },
      child: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TransactionLoaded) {
            if (state.transactions.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                  const Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: AppColors.textDisabled,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Belum ada transaksi',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: state.transactions.length,
              itemBuilder: (context, index) {
                final txn = state.transactions[index];
                return _buildTransactionCard(
                  txn,
                  currencyFormatter,
                ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1);
              },
            );
          }

          if (state is TransactionError) {
            return Center(child: Text(state.message));
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildTransactionCard(
    TransactionEntity txn,
    NumberFormat currencyFormatter,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.receipt_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      txn.transactionCode,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm').format(txn.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormatter.format(txn.totalAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      txn.paymentStatus.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (txn.items.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: AppColors.divider),
            ),
            ...txn.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.productName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${item.quantity} x ${currencyFormatter.format(item.price)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildReportTab(NumberFormat currencyFormatter) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadReport();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodSelector(),
            const SizedBox(height: 24),
            _buildProfitCard(currencyFormatter),
            const SizedBox(height: 24),
            _buildWeeklySalesCard(),
            const SizedBox(height: 24),
            _buildStatsGrid(currencyFormatter),
            const SizedBox(height: 24),
            _buildTopSellingSection(currencyFormatter),
            const SizedBox(height: 100), // Bottom padding for navigation
          ],
        ),
      ),
    );
  }

  Widget _buildDatePill() {
    String dateText = '';
    if (_selectedPeriod == 'Harian') {
      dateText = DateFormat('dd MMM').format(_selectedDate);
    } else if (_selectedPeriod == 'Mingguan' || _selectedPeriod == 'Kustom') {
      if (_endDate != null) {
        dateText =
            '${DateFormat('dd MMM').format(_selectedDate)} - ${DateFormat('dd MMM').format(_endDate!)}';
      } else {
        final start = _selectedDate.subtract(
          Duration(days: _selectedDate.weekday - 1),
        );
        final end = start.add(const Duration(days: 6));
        dateText =
            '${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM').format(end)}';
      }
    } else {
      dateText = DateFormat('MMM yyyy').format(_selectedDate);
    }

    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, size: 12, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              dateText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
          setState(() {
            _selectedPeriod = title;
            _endDate = null;
          });
          _loadReport();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String subtitle, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textDisabled,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildProfitCard(NumberFormat formatter) {
    return BlocBuilder<ReportBloc, ReportState>(
      builder: (context, state) {
        if (state is ReportLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        double profit = 0;
        if (state is ReportLoaded) {
          profit = (state.reportData['totalProfit'] ?? 0).toDouble();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFFF59E0B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Insights',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.more_vert, color: Colors.white),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Total Profit',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatter.format(profit),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.query_stats, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Real-time data for your business',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack).fadeIn();
      },
    );
  }

  Widget _buildWeeklySalesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Sales',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Icon(
                Icons.analytics_outlined,
                color: AppColors.textDisabled,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 150,
            child: BlocBuilder<ReportBloc, ReportState>(
              builder: (context, state) {
                if (state is ReportLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is ReportError) {
                  return Center(
                    child: Text(
                      state.message,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.error,
                      ),
                    ),
                  );
                }

                Map<String, double> data = {
                  'Mon': 0,
                  'Tue': 0,
                  'Wed': 0,
                  'Thu': 0,
                  'Fri': 0,
                  'Sat': 0,
                  'Sun': 0,
                };

                if (state is ReportLoaded &&
                    state.reportData['dailySales'] != null) {
                  final rawData = state.reportData['dailySales'] as Map;
                  final days = [
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                    'Sun',
                  ];
                  for (var day in days) {
                    data[day] = (rawData[day] ?? 0).toDouble();
                  }
                }

                return BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const days = [
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                              'Sat',
                              'Sun',
                            ];
                            if (value.toInt() < days.length &&
                                value.toInt() >= 0) {
                              final day = days[value.toInt()];
                              final isToday =
                                  day ==
                                  DateFormat(
                                    'E',
                                    'en_US',
                                  ).format(DateTime.now());
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  day,
                                  style: TextStyle(
                                    color: isToday
                                        ? AppColors.primary
                                        : AppColors.textDisabled,
                                    fontSize: 10,
                                    fontWeight: isToday
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                          reservedSize: 22,
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
                    barGroups: [0, 1, 2, 3, 4, 5, 6].map((i) {
                      final day = [
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun',
                      ][i];
                      final isToday =
                          day ==
                          DateFormat('E', 'en_US').format(DateTime.now());
                      double val = (data[day]! / 1000).clamp(5, 100).toDouble();
                      if (data[day]! == 0) val = 5.0;

                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: val,
                            color: isToday
                                ? AppColors.primary
                                : AppColors.primary.withValues(alpha: 0.2),
                            width: 18,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(NumberFormat formatter) {
    return BlocBuilder<ReportBloc, ReportState>(
      builder: (context, state) {
        int newCustomers = 0;
        double avgOrderValue = 0;
        if (state is ReportLoaded) {
          newCustomers = state.reportData['newCustomers'] ?? 0;
          avgOrderValue = (state.reportData['averageTransaction'] ?? 0)
              .toDouble();
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildTargetCard()),
                const SizedBox(width: 20),
                Expanded(child: _buildNewCustomersCard(newCustomers)),
              ],
            ),
            const SizedBox(height: 20),
            _buildAvgOrderValueCard(formatter, avgOrderValue),
          ],
        );
      },
    );
  }

  Widget _buildTargetCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 80,
            width: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: 0.75,
                  strokeWidth: 8,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                  strokeCap: StrokeCap.round,
                ),
                const Text(
                  '75%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Target',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Text(
            'Monthly Goal',
            style: TextStyle(fontSize: 10, color: AppColors.textDisabled),
          ),
        ],
      ),
    );
  }

  Widget _buildNewCustomersCard(int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.secondaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people,
              color: AppColors.secondary,
              size: 18,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Text(
            'New Customers',
            style: TextStyle(fontSize: 12, color: AppColors.textDisabled),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.trending_up, color: AppColors.success, size: 14),
              SizedBox(width: 4),
              Text(
                '8%',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvgOrderValueCard(NumberFormat formatter, double value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.receipt_long, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Avg. Order Value',
                  style: TextStyle(fontSize: 12, color: AppColors.textDisabled),
                ),
                Text(
                  formatter.format(value),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.flash_on, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSellingSection(NumberFormat formatter) {
    return BlocBuilder<ReportBloc, ReportState>(
      builder: (context, state) {
        if (state is ReportLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ReportLoaded) {
          final bestSellers =
              state.reportData['bestSellingProducts'] as List<dynamic>? ?? [];
          if (bestSellers.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('Belum ada data penjualan'),
              ),
            );
          }

          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Top Selling',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: bestSellers.length,
                itemBuilder: (context, index) {
                  final item = bestSellers[index];
                  return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: 60,
                                height: 60,
                                color: AppColors.background,
                                child: item['imageUrl'] != null
                                    ? CachedNetworkImage(
                                        imageUrl: item['imageUrl'],
                                        fit: BoxFit.cover,
                                      )
                                    : const Icon(
                                        Icons.image,
                                        color: AppColors.textDisabled,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['productName'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${item['totalQuantity']} terjual',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textDisabled,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  formatter.format(item['totalRevenue']),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const Text(
                                  '+14%',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(delay: (index * 100).ms)
                      .slideX(begin: 0.1);
                },
              ),
            ],
          );
        }
        return const SizedBox();
      },
    );
  }
}
