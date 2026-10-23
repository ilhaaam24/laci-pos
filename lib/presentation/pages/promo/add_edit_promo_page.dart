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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor),
        ),
        title: Text(
          'Hapus Promo?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus promo ini?',
          style: TextStyle(fontSize: 14, color: subtextColor),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: borderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Batal',
              style: TextStyle(color: subtextColor),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEdit ? 'Edit Promo' : 'Tambah Promo',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: borderColor),
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
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
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
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
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
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
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
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status Promo Aktif',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Dapat dipilih oleh kasir saat transaksi berlangsung',
                              style: TextStyle(
                                fontSize: 11,
                                color: subtextColor,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF172554) : const Color(0xFFE6F4F2))
              : unselectedBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : textColor,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppColors.primary : subtextColor,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pickerBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

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
          color: pickerBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: subtextColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value != null ? df.format(value) : label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: value != null
                      ? textColor
                      : subtextColor,
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
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: subtextColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildCardGroup({
    required String title,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillCol = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderCol = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textCol = isDark ? Colors.white : const Color(0xFF0F172A);
    final hintCol = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final iconCol = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: hintCol),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 20, color: iconCol)
          : null,
      prefixText: prefixText,
      prefixStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textCol,
      ),
      suffixText: suffixText,
      suffixStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textCol,
      ),
      filled: true,
      fillColor: fillCol,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderCol),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderCol),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: Color(0xFFDC2626)),
      ),
    );
  }
}
