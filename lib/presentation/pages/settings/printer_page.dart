import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../../../core/services/printer_service.dart';
import '../../../core/style/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import 'receipt_settings_page.dart';

class PrinterPage extends StatefulWidget {
  const PrinterPage({super.key});

  @override
  State<PrinterPage> createState() => _PrinterPageState();
}

class _PrinterPageState extends State<PrinterPage> {
  final PrinterService _printerService = PrinterService();
  List<BluetoothInfo> _devices = [];
  bool _isScanning = false;
  String? _connectingAddress;

  bool _isTestingPrint = false;
  bool _isTestingDrawer = false;

  @override
  void initState() {
    super.initState();
    _initPrinter();
  }

  Future<void> _initPrinter() async {
    await _printerService.init();
    if (mounted) setState(() {});
    _getPairedDevices();
  }

  Future<void> _getPairedDevices() async {
    setState(() => _isScanning = true);
    try {
      final devices = await _printerService.getBluetoothDevices();
      if (mounted) {
        setState(() {
          _devices = devices;
          _isScanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        AppToast.showError(context, 'Gagal memindai perangkat: $e');
      }
    }
  }

  Future<void> _connect(BluetoothInfo device) async {
    setState(() => _connectingAddress = device.macAdress);
    try {
      if (!mounted) return;
      final success = await _printerService.connect(
        device.macAdress,
        device.name,
      );
      if (!mounted) return;
      if (success) {
        AppToast.showSuccess(context, 'Berhasil terhubung ke ${device.name}');
      } else {
        AppToast.showError(context, 'Gagal terhubung ke ${device.name}');
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _connectingAddress = null);
    }
  }

  Future<void> _disconnect() async {
    await _printerService.disconnect();
    if (!mounted) return;
    setState(() {});
    AppToast.showSuccess(context, 'Printer terputus');
  }

  Future<void> _testPrint() async {
    if (!_printerService.isConnected) {
      AppToast.showWarning(context, 'Printer belum terhubung');
      return;
    }
    setState(() => _isTestingPrint = true);
    try {
      final success = await _printerService.printTestReceipt();
      if (!mounted) return;
      if (success) {
        AppToast.showSuccess(context, 'Perintah cetak uji coba terkirim');
      } else {
        AppToast.showError(context, 'Gagal mencetak struk uji coba');
      }
    } catch (e) {
      if (mounted) AppToast.showError(context, 'Gagal tes cetak: $e');
    } finally {
      if (mounted) setState(() => _isTestingPrint = false);
    }
  }

  Future<void> _testDrawer() async {
    if (!_printerService.isConnected) {
      AppToast.showWarning(context, 'Printer belum terhubung');
      return;
    }
    setState(() => _isTestingDrawer = true);
    try {
      final success = await _printerService.openCashDrawer();
      if (!mounted) return;
      if (success) {
        AppToast.showSuccess(context, 'Sinyal buka laci kas (RJ-11) terkirim');
      } else {
        AppToast.showError(context, 'Gagal mengirim sinyal buka laci kas');
      }
    } catch (e) {
      if (mounted) AppToast.showError(context, 'Gagal buka laci kas: $e');
    } finally {
      if (mounted) setState(() => _isTestingDrawer = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pengaturan Printer',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            icon: _isScanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                : Icon(
                    Icons.refresh,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
            tooltip: 'Pindai Ulang',
            onPressed: _isScanning ? null : _getPairedDevices,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatusHeader(),
          const SizedBox(height: 16),
          _buildHardwareConfigCard(isDark),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'DAFTAR PRINTER BLUETOOTH',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          if (_devices.isEmpty)
            _buildEmptyState()
          else
            ..._devices.map((device) => _buildDeviceCard(device)),
        ],
      ),
    );
  }

  Widget _buildHardwareConfigCard(bool isDark) {
    final paperSizeStr = _printerService.paperSizeString;
    final isConnected = _printerService.isConnected;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'KONFIGURASI STRUK & LACI KAS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),

          // Pilihan Ukuran Kertas
          Text(
            'Ukuran Kertas Thermal',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildPaperSizeOption(
                  size: '58',
                  title: '58 mm',
                  subtitle: 'Mini / Portabel',
                  isSelected: paperSizeStr == '58',
                  isDark: isDark,
                  onTap: () async {
                    await _printerService.setPaperSize('58');
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildPaperSizeOption(
                  size: '80',
                  title: '80 mm',
                  subtitle: 'Desktop / Standar',
                  isSelected: paperSizeStr == '80',
                  isDark: isDark,
                  onTap: () async {
                    await _printerService.setPaperSize('80');
                    setState(() {});
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          const SizedBox(height: 14),

          // Switch Buka Laci Kas
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buka Laci Kas Otomatis (Drawer Kick)',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kirim sinyal RJ-11 untuk membuka laci kas saat transaksi tunai',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _printerService.autoDrawerKick,
                activeThumbColor: AppColors.primary,
                onChanged: (v) async {
                  await _printerService.setAutoDrawerKick(v);
                  setState(() {});
                },
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          const SizedBox(height: 14),

          // Switch Auto-Reconnect
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sambungkan Otomatis (Auto-Reconnect)',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sambungkan ulang printer otomatis saat aplikasi kasir dibuka',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _printerService.autoReconnect,
                activeThumbColor: AppColors.primary,
                onChanged: (v) async {
                  await _printerService.setAutoReconnect(v);
                  setState(() {});
                },
              ),
            ],
          ),

          const SizedBox(height: 16),
          // Action Buttons: Tes Cetak & Uji Buka Laci
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (!isConnected || _isTestingPrint)
                      ? null
                      : _testPrint,
                  icon: _isTestingPrint
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.print_outlined, size: 16),
                  label: const Text('Tes Cetak Struk'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFCBD5E1),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (!isConnected || _isTestingDrawer)
                      ? null
                      : _testDrawer,
                  icon: _isTestingDrawer
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.point_of_sale_outlined, size: 16),
                  label: const Text('Uji Buka Laci'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFCBD5E1),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ReceiptSettingsPage(),
              ),
            ),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    size: 18,
                    color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Kustomisasi Tampilan Struk & Logo',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaperSizeOption({
    required String size,
    required String title,
    required String subtitle,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10.5,
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    final isConnected = _printerService.isConnected;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isConnected ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isConnected ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isConnected
                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                    : const Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isConnected ? Icons.print_outlined : Icons.print_disabled_outlined,
                color: isConnected ? const Color(0xFF059669) : const Color(0xFF64748B),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isConnected ? 'Printer Terhubung' : 'Belum Terhubung',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isConnected ? const Color(0xFF065F46) : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isConnected ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isConnected
                        ? 'Aktif: ${_printerService.connectedDeviceName ?? '-'}'
                        : 'Pilih printer thermal Bluetooth yang sudah di-pairing',
                    style: TextStyle(
                      color: isConnected ? const Color(0xFF047857) : const Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCard(BluetoothInfo device) {
    final isConnecting = _connectingAddress == device.macAdress;
    final isConnected = _printerService.isConnected &&
        _printerService.connectedDeviceName == device.name;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isConnected ? AppColors.primary : const Color(0xFFE2E8F0),
          width: isConnected ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isConnected ? const Color(0xFFE6F4F2) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.bluetooth,
                color: isConnected ? AppColors.primary : const Color(0xFF64748B),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name.isNotEmpty ? device.name : 'Unknown Device',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    device.macAdress,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            if (isConnecting)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            else if (isConnected)
              OutlinedButton(
                onPressed: _disconnect,
                style: OutlinedButton.styleFrom(
                  elevation: 0,
                  visualDensity: VisualDensity.compact,
                  side: const BorderSide(color: Color(0xFFDC2626)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Putuskan',
                  style: TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              )
            else
              ElevatedButton(
                onPressed: () => _connect(device),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  visualDensity: VisualDensity.compact,
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Hubungkan',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
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
                Icons.bluetooth_searching,
                size: 34,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tidak ada printer Bluetooth terdeteksi',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pastikan printer thermal aktif dan sudah dipasangkan (paired) lewat menu Pengaturan Bluetooth HP Anda',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _getPairedDevices,
              icon: const Icon(Icons.refresh, size: 16, color: AppColors.primary),
              label: const Text(
                'Pindai Ulang',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
