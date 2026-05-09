import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../blocs/business/business_bloc.dart';
import '../../../domain/entities/business_entity.dart';
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<BusinessBloc, BusinessState>(
        listener: (context, state) {
          if (state.isSuccess && state.message != null) {
            AppToast.showSuccess(context, 'Selamat! Bisnis Anda telah siap.');
            // Navigator is handled by AuthWrapper or we can pop here if needed
          }
          if (state.message != null && !state.isSuccess) {
            AppToast.showError(context, state.message!);
          }
        },
        builder: (context, state) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ).animate().scale(duration: 600.ms, curve: Curves.bounceIn),
                  const SizedBox(height: 32),
                  const Text(
                    'Satu Langkah Lagi!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 12),
                  const Text(
                    'Beri nama bisnis Anda untuk memulai pengelolaan kasir yang lebih profesional.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 48),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Nama Bisnis',
                            hintText: 'Contoh: Kedai Kopi Maju',
                            prefixIcon: const Icon(Icons.edit_note_rounded),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Nama bisnis tidak boleh kosong'
                              : null,
                        ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.1),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: state.isLoading
                              ? null
                              : () => _onSave(state.businessInfo),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryDark,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          child: state.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'MULAI SEKARANG',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                        ).animate().fadeIn(delay: 800.ms).scaleY(begin: 0.8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _onSave(BusinessInfo? currentInfo) {
    if (currentInfo == null) return;

    if (_formKey.currentState!.validate()) {
      final updatedInfo = BusinessInfo(
        id: currentInfo.id,
        businessName: _nameController.text.trim(),
        address: currentInfo.address,
        phone: currentInfo.phone,
        email: currentInfo.email,
        logoUrl: currentInfo.logoUrl,
        qrisUrl: currentInfo.qrisUrl,
        createdAt: currentInfo.createdAt,
        updatedAt: DateTime.now(),
      );

      context.read<BusinessBloc>().add(UpdateBusinessInfo(updatedInfo));
    }
  }
}
