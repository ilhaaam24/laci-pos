import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../../../core/services/printer_service.dart';
import '../../../core/style/app_colors.dart';
import '../../../core/utils/app_toast.dart';

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

  @override
  void initState() {
    super.initState();
    _getPairedDevices();
  }

  Future<void> _getPairedDevices() async {
    setState(() => _isScanning = true);
    final devices = await _printerService.getBluetoothDevices();
    setState(() {
      _devices = devices;
      _isScanning = false;
    });
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
      setState(() => _connectingAddress = null);
    }
  }

  Future<void> _disconnect() async {
    await _printerService.disconnect();
    if (!mounted) return;
    setState(() {});
    AppToast.showSuccess(context, 'Printer terputus');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pengaturan Printer'),
        actions: [
          IconButton(
            icon: _isScanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isScanning ? null : _getPairedDevices,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusHeader(),
          Expanded(
            child: _devices.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      final isConnecting =
                          _connectingAddress == device.macAdress;
                      final isConnected =
                          _printerService.isConnected &&
                          _printerService.connectedDeviceName == device.name;

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(
                            Icons.print_outlined,
                            color: isConnected ? Colors.green : Colors.grey,
                          ),
                          title: Text(
                            device.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(device.macAdress),
                          trailing: isConnecting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : isConnected
                              ? ElevatedButton(
                                  onPressed: _disconnect,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.error,
                                  ),
                                  child: const Text(
                                    'PUTUSKAN',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: () => _connect(device),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                  ),
                                  child: const Text(
                                    'HUBUNGKAN',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (_printerService.isConnected ? Colors.green : Colors.grey)
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _printerService.isConnected
                  ? Icons.check_circle
                  : Icons.print_disabled,
              color: _printerService.isConnected ? Colors.green : Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _printerService.isConnected ? 'Terhubung' : 'Tidak Terhubung',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _printerService.isConnected
                      ? 'Printer: ${_printerService.connectedDeviceName}'
                      : 'Pilih printer dari daftar di bawah',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bluetooth_searching,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Tidak ada printer Bluetooth terdeteksi',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pastikan Bluetooth aktif dan printer sudah dipairing',
            style: TextStyle(fontSize: 12, color: AppColors.textDisabled),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _getPairedDevices,
            child: const Text('PINDAI ULANG'),
          ),
        ],
      ),
    );
  }
}
