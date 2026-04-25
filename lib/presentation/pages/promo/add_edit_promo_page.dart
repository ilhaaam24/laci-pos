import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/entities/promo_entity.dart';
import '../../blocs/promo/promo_bloc.dart';
import '../../../core/style/app_colors.dart';
import '../../../core/utils/app_toast.dart';

class AddEditPromoPage extends StatefulWidget {
  final PromoEntity? promo;
  const AddEditPromoPage({super.key, this.promo});

  @override
  State<AddEditPromoPage> createState() => _AddEditPromoPageState();
}

class _AddEditPromoPageState extends State<AddEditPromoPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _valueController;
  late TextEditingController _minPurchaseController;

  PromoType _selectedType = PromoType.fixed;
  bool _isActive = true;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.promo?.name ?? '');
    _valueController = TextEditingController(
      text: widget.promo?.value.toStringAsFixed(0) ?? '',
    );
    _minPurchaseController = TextEditingController(
      text: widget.promo?.minPurchase.toStringAsFixed(0) ?? '0',
    );
    _selectedType = widget.promo?.type ?? PromoType.fixed;
    _isActive = widget.promo?.isActive ?? true;
    _startDate = widget.promo?.startDate;
    _endDate = widget.promo?.endDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    _minPurchaseController.dispose();
    super.dispose();
  }

  Future<void> _savePromo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final promo = PromoEntity(
        id: widget.promo?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        type: _selectedType,
        value: double.parse(_valueController.text),
        minPurchase: double.parse(_minPurchaseController.text),
        isActive: _isActive,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (widget.promo == null) {
        context.read<PromoBloc>().add(CreatePromo(promo));
      } else {
        context.read<PromoBloc>().add(UpdatePromo(promo));
      }

      Navigator.pop(context);
    } catch (e) {
      AppToast.showError(context, 'Gagal menyimpan promo: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.promo == null ? 'Tambah Promo' : 'Edit Promo'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            IconButton(icon: const Icon(Icons.check), onPressed: _savePromo),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Promo (Contoh: Diskon Lebaran)',
                prefixIcon: Icon(Icons.confirmation_number_outlined),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Nama tidak boleh kosong' : null,
            ),
            const SizedBox(height: 20),

            const Text(
              'Tipe Promo',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTypeCard(
                    title: 'Potongan Tetap',
                    subtitle: 'Contoh: Rp 5.000',
                    type: PromoType.fixed,
                    isSelected: _selectedType == PromoType.fixed,
                    onTap: () =>
                        setState(() => _selectedType = PromoType.fixed),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeCard(
                    title: 'Persentase',
                    subtitle: 'Contoh: 10%',
                    type: PromoType.percentage,
                    isSelected: _selectedType == PromoType.percentage,
                    onTap: () =>
                        setState(() => _selectedType = PromoType.percentage),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _valueController,
              decoration: InputDecoration(
                labelText: _selectedType == PromoType.fixed
                    ? 'Nilai Potongan (Rp)'
                    : 'Nilai Persentase (%)',
                prefixText: _selectedType == PromoType.fixed ? 'Rp ' : null,
                suffixText: _selectedType == PromoType.percentage ? '%' : null,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Wajib diisi';
                if (_selectedType == PromoType.percentage && int.parse(v) > 100)
                  return 'Maksimal 100%';
                return null;
              },
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _minPurchaseController,
              decoration: const InputDecoration(
                labelText: 'Minimal Belanja (Opsional)',
                prefixText: 'Rp ',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 20),

            const Text(
              'Periode Promo (Opsional)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDatePicker(
                    label: 'Mulai',
                    value: _startDate,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) setState(() => _startDate = date);
                    },
                    onClear: () => setState(() => _startDate = null),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDatePicker(
                    label: 'Berakhir',
                    value: _endDate,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) setState(() => _endDate = date);
                    },
                    onClear: () => setState(() => _endDate = null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            SwitchListTile(
              title: const Text('Aktifkan Promo'),
              subtitle: const Text(
                'Promo tidak akan muncul saat checkout jika dinonaktifkan',
              ),
              value: _isActive,
              activeThumbColor: AppColors.primary,
              onChanged: (v) => setState(() => _isActive = v),
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 40),

            if (widget.promo != null)
              OutlinedButton.icon(
                onPressed: () => _showDeleteDialog(),
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                label: const Text(
                  'HAPUS PROMO',
                  style: TextStyle(color: AppColors.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard({
    required String title,
    required String subtitle,
    required PromoType type,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    final df = DateFormat('dd/MM/yyyy');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value != null ? df.format(value) : label,
                style: TextStyle(
                  color: value != null
                      ? AppColors.textPrimary
                      : AppColors.textDisabled,
                  fontSize: 13,
                ),
              ),
            ),
            if (value != null)
              GestureDetector(
                onTap: () {
                  onClear();
                },
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.error,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Promo'),
        content: const Text('Apakah Anda yakin ingin menghapus promo ini?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<PromoBloc>().add(DeletePromo(widget.promo!.id));
              Navigator.pop(dialogContext); // Close dialog
              Navigator.pop(context); // Back to list
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
