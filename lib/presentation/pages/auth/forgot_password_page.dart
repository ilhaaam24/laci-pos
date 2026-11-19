import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/di/injection.dart';
import '../../../core/style/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../domain/repositories/auth_repository.dart';

class ForgotPasswordPage extends StatefulWidget {
  final String? initialEmail;
  final AuthRepository? authRepository;

  const ForgotPasswordPage({super.key, this.initialEmail, this.authRepository});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;

  bool _isLoading = false;
  bool _emailSent = false;
  String _sentEmailAddress = '';

  int _cooldown = 60;
  Timer? _cooldownTimer;
  bool _isResending = false;

  late final AuthRepository _authRepository;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    _authRepository = widget.authRepository ?? getIt<AuthRepository>();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    setState(() => _cooldown = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldown > 0) {
        setState(() => _cooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email wajib diisi';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Format email tidak valid';
    }
    return null;
  }

  Future<void> _handleSendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    setState(() => _isLoading = true);

    final result = await _authRepository.sendPasswordResetEmail(email: email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (errorMessage) {
        AppToast.showError(context, errorMessage);
      },
      (_) {
        setState(() {
          _emailSent = true;
          _sentEmailAddress = email;
        });
        _startCooldownTimer();
        AppToast.showSuccess(
          context,
          'Tautan reset password berhasil dikirim ke email!',
        );
      },
    );
  }

  Future<void> _handleResend() async {
    if (_cooldown > 0 || _isResending) return;

    setState(() => _isResending = true);
    final result = await _authRepository.sendPasswordResetEmail(
      email: _sentEmailAddress,
    );

    if (!mounted) return;
    setState(() => _isResending = false);

    result.fold(
      (errorMessage) {
        AppToast.showError(context, errorMessage);
      },
      (_) {
        _startCooldownTimer();
        AppToast.showSuccess(
          context,
          'Tautan reset baru telah dikirimkan ke email!',
        );
      },
    );
  }

  Future<void> _handleOpenEmailApp() async {
    final Uri emailLaunchUri = Uri(scheme: 'mailto');
    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        if (mounted) {
          AppToast.showInfo(
            context,
            'Silakan buka aplikasi email di perangkat Anda.',
          );
        }
      }
    } catch (_) {
      if (mounted) {
        AppToast.showInfo(
          context,
          'Silakan buka aplikasi email di perangkat Anda.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final textSecondaryColor = isDark
        ? const Color(0xFF94A3B8)
        : AppColors.textSecondary;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final inputFillColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final inputPrefixIconColor = isDark
        ? AppColors.primaryLight
        : AppColors.primary;
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final backButtonColor = isDark ? Colors.white : AppColors.textPrimary;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: backButtonColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _emailSent
                    ? _buildSuccessView(
                        context,
                        isDark,
                        textColor,
                        textSecondaryColor,
                        surfaceColor,
                        borderColor,
                      )
                    : _buildRequestView(
                        context,
                        isDark,
                        textColor,
                        textSecondaryColor,
                        surfaceColor,
                        inputFillColor,
                        inputPrefixIconColor,
                        borderColor,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestView(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color textSecondaryColor,
    Color surfaceColor,
    Color inputFillColor,
    Color inputPrefixIconColor,
    Color borderColor,
  ) {
    return Column(
      key: const ValueKey('request_view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : AppColors.primaryLight,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor),
            ),
            child: const Center(
              child: Icon(
                Icons.lock_reset_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
        ),
        const SizedBox(height: 24),
        Text(
          'Lupa Kata Sandi?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ).animate().fadeIn(delay: 150.ms),
        const SizedBox(height: 10),
        Text(
          'Masukkan email yang terdaftar di akun Anda. Kami akan mengirimkan tautan untuk mengatur ulang kata sandi.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: textSecondaryColor,
          ),
        ).animate().fadeIn(delay: 250.ms),
        const SizedBox(height: 36),

        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alamat Email',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const ValueKey('forgot_password_email_field'),
                controller: _emailController,
                style: TextStyle(color: textColor),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
                decoration: InputDecoration(
                  hintText: 'nama@email.com',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                  ),
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: inputPrefixIconColor,
                  ),
                  filled: true,
                  fillColor: inputFillColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.8,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.error,
                      width: 1.2,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.error,
                      width: 1.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 350.ms),

        const SizedBox(height: 28),

        SizedBox(
          height: 50,
          child: ElevatedButton(
            key: const ValueKey('send_reset_button'),
            onPressed: _isLoading ? null : _handleSendResetEmail,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'KIRIM TAUTAN RESET',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
          ),
        ).animate().fadeIn(delay: 450.ms),

        const SizedBox(height: 28),

        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Ingat kata sandi Anda? ',
              style: TextStyle(fontSize: 14, color: textSecondaryColor),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Text(
                'Masuk',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 550.ms),
      ],
    );
  }

  Widget _buildSuccessView(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color textSecondaryColor,
    Color surfaceColor,
    Color borderColor,
  ) {
    return Column(
      key: const ValueKey('success_view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SvgPicture.asset(
            "assets/icons/email.svg",
            width: 84,
            height: 84,
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
        ),
        const SizedBox(height: 24),
        Text(
          'Periksa Email Anda',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ).animate().fadeIn(delay: 150.ms),
        const SizedBox(height: 10),
        Text(
          'Kami telah mengirimkan tautan untuk mengatur ulang kata sandi ke:',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: textSecondaryColor),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 14),

        // Email address pill
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.mail_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _sentEmailAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 250.ms),

        const SizedBox(height: 24),

        // Info box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF475569),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Klik tautan di email untuk mereset kata sandi. Jika tidak menemukannya di kotak masuk, silakan periksa folder Spam atau Promosi.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 300.ms),

        const SizedBox(height: 32),

        // Open Email App Button
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            key: const ValueKey('open_email_app_button'),
            onPressed: _handleOpenEmailApp,
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: const Text(
              'Buka Aplikasi Email',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ).animate().fadeIn(delay: 350.ms),

        const SizedBox(height: 12),

        // Resend email button with countdown
        SizedBox(
          height: 48,
          child: OutlinedButton(
            key: const ValueKey('resend_reset_button'),
            onPressed: (_cooldown > 0 || _isResending) ? null : _handleResend,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: borderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              backgroundColor: surfaceColor,
            ),
            child: _isResending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : Text(
                    _cooldown > 0
                        ? 'Kirim Ulang (${_cooldown}s)'
                        : 'Kirim Ulang Email',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _cooldown > 0
                          ? textSecondaryColor
                          : (isDark ? Colors.white : AppColors.textPrimary),
                    ),
                  ),
          ),
        ).animate().fadeIn(delay: 400.ms),

        const SizedBox(height: 20),

        Center(
          child: TextButton(
            key: const ValueKey('back_to_login_button'),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Kembali ke Halaman Masuk',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
            ),
          ),
        ).animate().fadeIn(delay: 450.ms),
      ],
    );
  }
}
