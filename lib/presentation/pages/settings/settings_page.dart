import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:laci/domain/entities/user_entity.dart';
import '../products/products_page.dart';
import '../categories/categories_page.dart';
import '../customer/customers_page.dart';
import 'business_info_page.dart';
import 'printer_page.dart';
import 'users_management_page.dart';
import '../../blocs/auth/auth_bloc.dart';
import 'package:laci/core/style/app_colors.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final role = (state is Authenticated)
            ? state.user.role
            : UserRole.kasir;

        return Scaffold(
          appBar: AppBar(title: const Text('Pengaturan')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (role.canManageInventory || role.isAdmin) ...[
                _buildSectionHeader('Manajemen Data'),
                _buildSettingTile(
                  context,
                  title: 'Kelola Produk',
                  subtitle: 'Tambah, edit, atau hapus produk',
                  icon: Icons.inventory_2_outlined,
                  color: Colors.blue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProductsPage()),
                  ),
                ),
                _buildSettingTile(
                  context,
                  title: 'Kelola Kategori',
                  subtitle: 'Atur kategori produk Anda',
                  icon: Icons.category_outlined,
                  color: Colors.orange,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CategoriesPage()),
                  ),
                ),
                _buildSettingTile(
                  context,
                  title: 'Kelola Pelanggan',
                  subtitle: 'Daftar pelanggan dan loyalitas',
                  icon: Icons.people_outline,
                  color: Colors.teal,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CustomersPage()),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              _buildSectionHeader('Konfigurasi Aplikasi'),
              if (role.isAdmin || role.isOwner)
                _buildSettingTile(
                  context,
                  title: 'Info Bisnis',
                  subtitle: 'Nama toko, alamat, dan kontak',
                  icon: Icons.storefront_outlined,
                  color: Colors.indigo,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BusinessInfoPage()),
                  ),
                ),
              _buildSettingTile(
                context,
                title: 'Pengaturan Printer',
                subtitle: 'Sambungkan printer thermal Bluetooth/USB',
                icon: Icons.print_outlined,
                color: Colors.blueGrey,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrinterPage()),
                ),
              ),
              if (role.canManageUsers)
                _buildSettingTile(
                  context,
                  title: 'User & Keamanan',
                  subtitle: 'Atur akses staf dan password',
                  icon: Icons.lock_outline,
                  color: Colors.redAccent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UsersManagementPage(),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              _buildSectionHeader('Lainnya'),
              _buildSettingTile(
                context,
                title: 'Kebijakan Privasi',
                subtitle: 'Syarat & Ketentuan Penggunaan',
                icon: Icons.privacy_tip_outlined,
                color: AppColors.textSecondary,
                onTap: () async {
                  final url = Uri.parse(
                    'https://sites.google.com/view/lacipos-privacypolicy',
                  );
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildLogoutTile(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogoutTile(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => _showLogoutDialog(context),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.logout, color: AppColors.error),
        ),
        title: const Text(
          'Keluar',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
        ),
        subtitle: const Text(
          'Keluar dari akun Anda',
          style: TextStyle(fontSize: 12),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textDisabled,
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AuthBloc>().add(SignOutRequested());
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textDisabled,
        ),
      ),
    );
  }
}
