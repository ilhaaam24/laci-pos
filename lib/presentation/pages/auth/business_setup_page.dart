import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import '../../blocs/business/business_bloc.dart';
import '../../blocs/category/category_bloc.dart';
import '../../blocs/product/product_bloc.dart';
import '../../../domain/entities/business_entity.dart';
import '../../../domain/repositories/business_repository.dart';
import '../../../core/di/injection.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/product_template_service.dart';
import '../../../core/style/app_colors.dart';
import '../../../core/utils/app_toast.dart';

class BusinessSetupPage extends StatefulWidget {
  const BusinessSetupPage({super.key});

  @override
  State<BusinessSetupPage> createState() => _BusinessSetupPageState();
}

class _BusinessSetupPageState extends State<BusinessSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  BusinessTemplateType _selectedTemplate = BusinessTemplateType.coffeeShop;
  bool _seedSampleProducts = true;
  bool _isSubmitting = false;
  int _seededProductCount = 0;

  @override
  void initState() {
    super.initState();
    context.read<BusinessBloc>().add(LoadBusinessInfo());
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : AppColors.background;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : AppColors.surface;
    final borderColor = isDark ? const Color(0xFF334155) : AppColors.border;
    final textPrimary = isDark ? Colors.white : AppColors.textPrimary;
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;
    final activeTemplate = ProductTemplateService.getTemplate(_selectedTemplate);

    return Scaffold(
      backgroundColor: bgColor,
      body: BlocConsumer<BusinessBloc, BusinessState>(
        listener: (context, state) {
          if (state.isSuccess && state.message != null) {
            final msg = _seededProductCount > 0
                ? 'Bisnis siap dengan $_seededProductCount produk contoh!'
                : 'Selamat! Bisnis Anda telah siap.';
            AppToast.showSuccess(context, msg);
          }
          if (state.message != null && !state.isSuccess) {
            if (_isSubmitting) {
              setState(() => _isSubmitting = false);
            }
            AppToast.showError(context, state.message!);
          }
        },
        builder: (context, state) {
          final isBusy = state.isLoading || _isSubmitting;

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: SvgPicture.asset(
                          'assets/icons/logo.svg',
                          height: 60,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Siapkan Toko Anda',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Isi nama bisnis dan pilih jenis usaha agar kasir langsung siap digunakan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.45,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Nama Bisnis',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nameController,
                              enabled: !isBusy,
                              style: TextStyle(
                                fontSize: 14,
                                color: textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: activeTemplate.businessNameHint,
                                prefixIcon: Icon(
                                  Icons.storefront_outlined,
                                  size: 20,
                                  color: textSecondary,
                                ),
                                filled: true,
                                fillColor: surfaceColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Nama bisnis tidak boleh kosong'
                                  : null,
                            ),
                            const SizedBox(height: 22),

                            Text(
                              'Jenis Usaha',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: ProductTemplateService.templates.map((
                                template,
                              ) {
                                final isSelected =
                                    template.type == _selectedTemplate;
                                return InkWell(
                                  onTap: isBusy
                                      ? null
                                      : () => setState(
                                          () => _selectedTemplate =
                                              template.type,
                                        ),
                                  borderRadius: BorderRadius.circular(12),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 13,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? (isDark
                                              ? Colors.white
                                              : AppColors.darkCharcoal)
                                          : surfaceColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? (isDark
                                                ? Colors.white
                                                : AppColors.darkCharcoal)
                                            : borderColor,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          template.icon,
                                          size: 16,
                                          color: isSelected
                                              ? (isDark
                                                  ? AppColors.textPrimary
                                                  : Colors.white)
                                              : textSecondary,
                                        ),
                                        const SizedBox(width: 7),
                                        Text(
                                          template.label,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? (isDark
                                                    ? AppColors.textPrimary
                                                    : Colors.white)
                                                : textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),

                            Divider(color: borderColor, height: 1),
                            const SizedBox(height: 14),

                            InkWell(
                              onTap: isBusy
                                  ? null
                                  : () => setState(
                                      () => _seedSampleProducts =
                                          !_seedSampleProducts,
                                    ),
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Isi ${activeTemplate.products.length} produk contoh',
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w600,
                                              color: textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Langsung bisa coba kasir & struk. Bisa dihapus kapan saja.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Switch.adaptive(
                                      value: _seedSampleProducts,
                                      activeTrackColor: AppColors.primary,
                                      onChanged: isBusy
                                          ? null
                                          : (val) => setState(
                                              () => _seedSampleProducts = val,
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: isBusy
                                    ? null
                                    : () => _onSave(state.businessInfo),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: isBusy
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            _seedSampleProducts
                                                ? 'Menyiapkan produk contoh...'
                                                : 'Menyimpan...',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Text(
                                        'Mulai Sekarang',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _onSave(BusinessInfo? currentInfo) async {
    if (currentInfo == null) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _seededProductCount = 0;
    });

    final updatedInfo = currentInfo.copyWith(
      businessName: _nameController.text.trim(),
      updatedAt: DateTime.now(),
    );

    // Save business name first (marks pendingUpload + queues sync) BEFORE
    // seeding sample products so concurrent syncs never overwrite it back to 'Toko Saya'.
    await getIt<BusinessRepository>().updateBusinessInfo(updatedInfo);

    if (_seedSampleProducts) {
      try {
        final count = await getIt<ProductTemplateService>().seedTemplate(
          _selectedTemplate,
        );
        _seededProductCount = count;
        if (mounted) {
          context.read<CategoryBloc>().add(LoadCategories());
          context.read<ProductBloc>().add(LoadProducts());
        }
      } catch (_) {
        // Do not block business setup if sample seeding fails
      }
    }

    if (!mounted) return;

    AnalyticsService.logBusinessSetupCompleted(
      templateType: _selectedTemplate.name,
      seededSamples: _seedSampleProducts,
      sampleCount: _seededProductCount,
    );

    context.read<BusinessBloc>().add(UpdateBusinessInfo(updatedInfo));
  }
}
