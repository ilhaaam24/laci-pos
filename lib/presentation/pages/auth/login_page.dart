import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../../core/style/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : AppColors.background;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : AppColors.surface;
    final borderColor = isDark ? const Color(0xFF334155) : AppColors.border;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final subtextColor =
        isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            AppToast.showError(context, state.message);
          }
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand & Header
                    Center(
                      child: SvgPicture.asset(
                        'assets/icons/logo.svg',
                        height: 64,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Masuk ke Laci POS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Kelola kasir, stok, dan laporan toko Anda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: subtextColor,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 1-Tap Google Sign-In
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isLoading = state is AuthLoading;
                        return SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: isLoading ? null : _handleGoogleLogin,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: surfaceColor,
                              foregroundColor: textColor,
                              side: BorderSide(color: borderColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/google.png',
                                  height: 20,
                                  width: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Lanjutkan dengan Google',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 22),

                    // Subtle Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: borderColor, height: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'atau',
                            style: TextStyle(
                              color: subtextColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: borderColor, height: 1)),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // Email & Password Form
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            style: TextStyle(fontSize: 14, color: textColor),
                            decoration: InputDecoration(
                              hintText: 'Email',
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                size: 20,
                                color: subtextColor,
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
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (v) => v == null || !v.contains('@')
                                ? 'Email tidak valid'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(fontSize: 14, color: textColor),
                            decoration: InputDecoration(
                              hintText: 'Password',
                              prefixIcon: Icon(
                                Icons.lock_outline_rounded,
                                size: 20,
                                color: subtextColor,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: subtextColor,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
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
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleEmailLogin(),
                            validator: (v) => v == null || v.length < 6
                                ? 'Password minimal 6 karakter'
                                : null,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ForgotPasswordPage(
                                initialEmail: _emailController.text.trim(),
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          child: Text(
                            'Lupa password?',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? const Color(0xFF34D399)
                                  : AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Primary Submit Button
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isLoading = state is AuthLoading;
                        return SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _handleEmailLogin,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Masuk',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Secondary actions: Register + Quiet Demo escape hatch
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Belum punya akun? ',
                          style: TextStyle(fontSize: 13.5, color: subtextColor),
                        ),
                        InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterPage(),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 2,
                            ),
                            child: Text(
                              'Daftar',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? const Color(0xFF34D399)
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isLoading = state is AuthLoading;
                        return Center(
                          child: InkWell(
                            onTap: isLoading ? null : _handleDemoMode,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.play_arrow_rounded,
                                    size: 17,
                                    color: subtextColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Coba Mode Demo tanpa akun',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: subtextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleEmailLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        SignInRequested(
          email: _emailController.text.trim().toLowerCase(),
          password: _passwordController.text,
        ),
      );
    }
  }

  void _handleGoogleLogin() {
    context.read<AuthBloc>().add(GoogleSignInRequested());
  }

  void _handleDemoMode() {
    context.read<AuthBloc>().add(EnterDemoModeRequested());
  }
}
