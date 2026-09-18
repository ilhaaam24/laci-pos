import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/entities/promo_entity.dart';
import '../../blocs/business/business_bloc.dart';
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

  bool get _isEdit => widget.promo != null;

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
      final businessId = widget.promo?.businessId ??
          context.read<BusinessBloc>().state.businessInfo?.id;

      final promo = PromoEntity(
        id: widget.promo?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        type: _selectedType,
        value: double.parse(_valueController.text),
        minPurchase: double.parse(_minPurchaseController.text),
        isActive: _isActive,
        startDate: _startDate,
        endDate: _endDate != null
            ? DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59)
            : null,
        businessId: businessId,
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        title: const Text(
          'Hapus Promo?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        content: const Text(
          'Apakah Anda yakin ingin menghapus promo ini?',
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Batal',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<PromoBloc>().add(DeletePromo(widget.promo!.id));
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Hapus',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          _isEdit ? 'Edit Promo' : 'Tambah Promo',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
              tooltip: 'Hapus Promo',
              onPressed: _showDeleteDialog,
            ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCardGroup(
              title: 'INFORMASI PROMO',
              children: [
                _buildLabel('Nama Promo'),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: _buildInputDecoration(
                    hint: 'Contoh: Diskon Kemerdekaan, Promo Weekend',
                    prefixIcon: Icons.local_offer_outlined,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Nama promo tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildLabel('Tipe Potongan'),
                Row(
                  children: [
                    Expanded(
                      child: _buildTypeCard(
                        title: 'Nominal Tetap',
                        subtitle: 'Potongan Rp',
                        isSelected: _selectedType == PromoType.fixed,
                        onTap: () =>
                            setState(() => _selectedType = PromoType.fixed),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTypeCard(
                        title: 'Persentase',
                        subtitle: 'Diskon %',
                        isSelected: _selectedType == PromoType.percentage,
                        onTap: () => setState(
                          () => _selectedType = PromoType.percentage,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildLabel(
                  _selectedType == PromoType.fixed
                      ? 'Nilai Potongan (Rp)'
                      : 'Besaran Persentase (%)',
                ),
                TextFormField(
                  controller: _valueController,
                  keyboardType: TextInputType.number,

                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: _buildInputDecoration(
                    hint: _selectedType == PromoType.fixed ? '0' : '10',
                    prefixText: _selectedType == PromoType.fixed ? 'Rp ' : null,
                    suffixText: _selectedType == PromoType.percentage
                        ? '%'
                        : null,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Wajib diisi';
                    final parsed = int.tryParse(v);
                    if (parsed == null || parsed <= 0) {
                      return 'Nilai harus lebih dari 0';
                    }
                    if (_selectedType == PromoType.percentage && parsed > 100) {
                      return 'Maksimal 100%';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCardGroup(
              title: 'KETENTUAN & PERIODE',
              children: [
                _buildLabel('Minimal Belanja (Rp)'),
                TextFormField(
                  controller: _minPurchaseController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: _buildInputDecoration(
                    hint: '0',
                    prefixText: 'Rp ',
                  ),
                ),
                const SizedBox(height: 16),
                _buildLabel('Masa Berlaku Promo (Opsional)'),
                Row(
                  children: [
                    Expanded(
                      child: _buildDatePicker(
                        label: 'Tanggal Mulai',
                        value: _startDate,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (date != null) {
                            setState(() => _startDate = DateTime(date.year, date.month, date.day, 0, 0, 0));
                          }
                        },
                        onClear: () => setState(() => _startDate = null),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDatePicker(
                        label: 'Tanggal Selesai',
                        value: _endDate,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate:
                                _endDate ?? (_startDate ?? DateTime.now()),
                            firstDate: _startDate ?? DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (date != null) {
                            setState(() => _endDate = DateTime(date.year, date.month, date.day, 23, 59, 59));
                          }
                        },
                        onClear: () => setState(() => _endDate = null),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Status Promo Aktif',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Dapat dipilih oleh kasir saat transaksi berlangsung',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isActive,
                        activeThumbColor: AppColors.primary,
                        onChanged: (v) => setState(() => _isActive = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _savePromo,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        _isEdit ? 'Simpan Perubahan' : 'Simpan Promo',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE6F4F2) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : const Color(0xFF0F172A),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppColors.primary : const Color(0xFF64748B),
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
    DateFormat df;
    try {
      df = DateFormat('dd MMM yyyy', 'id_ID');
    } catch (_) {
      df = DateFormat('dd/MM/yyyy');
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value != null ? df.format(value) : label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: value != null
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF94A3B8),
                  fontSize: 12.5,
                  fontWeight: value != null
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
            if (value != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildCardGroup({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    IconData? prefixIcon,
    String? prefixText,
    String? suffixText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 20, color: const Color(0xFF64748B))
          : null,
      prefixText: prefixText,
      prefixStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF0F172A),
      ),
      suffixText: suffixText,
      suffixStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF0F172A),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
    );
  }
}
