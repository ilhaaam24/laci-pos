import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/injection.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/style/app_colors.dart';
import '../../../domain/entities/user_entity.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/product/product_bloc.dart';
import '../../blocs/category/category_bloc.dart';
import '../../blocs/customer/customer_bloc.dart';
import '../../blocs/transaction/transaction_bloc.dart';
import '../../blocs/business/business_bloc.dart';
import '../../blocs/promo/promo_bloc.dart';
import '../../widgets/sync_status_indicator.dart';
import '../products/products_page.dart';
import '../categories/categories_page.dart';
import '../customer/customers_page.dart';
import '../promo/promo_page.dart';
import 'business_info_page.dart';
import 'printer_page.dart';
import 'users_management_page.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const SettingsPage({super.key, this.onOpenDrawer});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    context.read<BusinessBloc>().add(LoadBusinessInfo());
    context.read<ProductBloc>().add(LoadProducts());
    context.read<CategoryBloc>().add(LoadCategories());
    context.read<CustomerBloc>().add(LoadCustomers());
    context.read<PromoBloc>().add(LoadPromos());
  }

  String _getInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'LP';
    final parts = clean.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return clean.substring(0, clean.length >= 2 ? 2 : 1).toUpperCase();
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final role = (authState is Authenticated)
            ? authState.user.role
            : UserRole.kasir;

        final canManageData =
            role.canManageInventory || role.isAdmin || role.isOwner;
        final canManageStore = role.isAdmin || role.isOwner;
        final canManageUsers = role.canManageUsers || role.isOwner;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            leading: MediaQuery.of(context).size.width >= 720
                ? IconButton(
                    icon: const Icon(
                      Icons.menu_rounded,
                      color: Color(0xFF0F172A),
                    ),
                    tooltip: 'Menu Navigasi',
                    onPressed: () {
                      if (widget.onOpenDrawer != null) {
                        widget.onOpenDrawer!();
                      } else {
                        context
                            .findRootAncestorStateOfType<ScaffoldState>()
                            ?.openDrawer();
                      }
                    },
                  )
                : null,
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: const Text(
              'Pengaturan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // 1. Business & User Profile Card
              _buildProfileCard(authState),
              const SizedBox(height: 20),

              // 2. Section: Manajemen Toko (Only if authorized)
              if (canManageData) ...[
                _buildSectionHeader('MANAJEMEN TOKO'),
                _buildCardGroup([
                  BlocBuilder<ProductBloc, ProductState>(
                    builder: (context, pState) {
                      return _buildTile(
                        icon: "assets/icons/product.svg",
                        title: 'Kelola Produk',
                        subtitle: 'Daftar produk, harga, dan stok',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProductsPage(),
                          ),
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                  BlocBuilder<CategoryBloc, CategoryState>(
                    builder: (context, cState) {
                      return _buildTile(
                        icon: "assets/icons/category.svg",
                        title: 'Kelola Kategori',
                        subtitle: 'Pengelompokan menu & barang',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CategoriesPage(),
                          ),
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                  BlocBuilder<CustomerBloc, CustomerState>(
                    builder: (context, custState) {
                      return _buildTile(
                        icon: "assets/icons/customer.svg",
                        title: 'Kelola Pelanggan',
                        subtitle: 'Data pelanggan dan loyalitas',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CustomersPage(),
                          ),
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                  BlocBuilder<PromoBloc, PromoState>(
                    builder: (context, promoState) {
                      return _buildTile(
                        icon: "assets/icons/discount.svg",
                        title: 'Promo & Diskon',
                        subtitle: 'Voucher dan kupon potongan harga',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PromoPage()),
                        ),
                      );
                    },
                  ),
                ]),
                const SizedBox(height: 20),
              ],

              // 3. Section: Perangkat & Konfigurasi
              _buildSectionHeader('PERANGKAT & KONFIGURASI'),
              _buildCardGroup([
                _buildTile(
                  icon: "assets/icons/printer.svg",
                  title: 'Pengaturan Printer',
                  subtitle: 'Koneksi printer thermal Bluetooth (58mm/80mm)',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PrinterPage()),
                  ),
                ),
                if (canManageStore) ...[
                  _buildDivider(),
                  _buildTile(
                    icon: "assets/icons/busines.svg",
                    title: 'Profil Bisnis & QRIS',
                    subtitle: 'Nama toko, alamat, logo, dan barcode QRIS',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BusinessInfoPage(),
                      ),
                    ),
                  ),
                ],
                if (canManageUsers) ...[
                  _buildDivider(),
                  _buildTile(
                    icon: "assets/icons/staff.svg",
                    title: 'Manajemen Staf & User',
                    subtitle: 'Kelola akun kasir dan hak akses staf',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UsersManagementPage(),
                      ),
                    ),
                  ),
                ],
              ]),
              const SizedBox(height: 20),

              // 4. Section: Sistem & Informasi
              _buildSectionHeader('SISTEM & INFORMASI'),
              _buildCardGroup([
                _buildTile(
                  icon: "assets/icons/sync.svg",
                  title: 'Sinkronisasi Data',
                  subtitle: 'Sinkronkan database lokal dengan cloud',
                  customTrailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SyncStatusIndicator(),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: () {
                          getIt<SyncService>().fullSync();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Memulai sinkronisasi data...'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text(
                          'Sinkronkan',
                          style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    getIt<SyncService>().fullSync();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Memulai sinkronisasi data...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildTile(
                  icon: "assets/icons/policy.svg",
                  title: 'Kebijakan Privasi',
                  subtitle: 'Syarat & ketentuan penggunaan Laci POS',
                  onTap: () async {
                    final url = Uri.parse(
                      'https://sites.google.com/view/lacipos-privacypolicy',
                    );
                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),
              ]),
              const SizedBox(height: 16),

              // 5. Logout Button (Clean, flat, zero shadow)
              _buildLogoutButton(),
              const SizedBox(height: 16),

              // Version Info
              const Center(
                child: Text(
                  'Laci POS v2.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Profile Card: Real Store & User Info (Clean flat card, no shadow)
  Widget _buildProfileCard(AuthState authState) {
    return BlocBuilder<BusinessBloc, BusinessState>(
      builder: (context, bState) {
        final businessInfo = bState.businessInfo;
        final businessName =
            businessInfo?.businessName.isNotEmpty == true &&
                businessInfo?.businessName != 'Toko Saya'
            ? businessInfo!.businessName
            : 'Toko Saya';
        final initials = _getInitials(businessName);

        String userName = 'Kasir';
        String roleName = 'Kasir';
        String userEmail = '-';

        if (authState is Authenticated) {
          final user = authState.user;
          userName = user.name?.isNotEmpty == true
              ? user.name!
              : user.email.split('@').first;
          userEmail = user.email;
          roleName = _capitalize(user.role.name);
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              // Store Logo or Initials Box
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child:
                      (businessInfo?.logoUrl != null &&
                          businessInfo!.logoUrl!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: businessInfo.logoUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      : SvgPicture.asset(
                          "assets/icons/logo.svg",
                          height: 30,
                          width: 30,
                        ),
                ),
              ),
              const SizedBox(width: 14),
              // Store Name & User Role
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      businessName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '$userName ($userEmail)',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Role Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  roleName,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF64748B),
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 54,
      color: Color(0xFFF1F5F9),
    );
  }

  Widget _buildTile({
    required String icon,
    required String title,
    required String subtitle,
    String? trailingText,
    Widget? customTrailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            SvgPicture.asset(icon, width: 34, height: 34),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (customTrailing != null)
              customTrailing
            else ...[
              if (trailingText != null) ...[
                Text(
                  trailingText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFCBD5E1),
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Logout Button (Flat clean red card, no shadow)
  Widget _buildLogoutButton() {
    return InkWell(
      onTap: () => _showLogoutDialog(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          // color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(14),
          // border: Border.all(color: const Color(0xFFFEE2E2)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 20),
            SizedBox(width: 8),
            Text(
              'Keluar dari Akun',
              style: TextStyle(
                color: Color(0xFFDC2626),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Keluar dari Akun',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: Colors.black87,
          ),
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun ini? Semua perubahan offline telah diamankan.',
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
              context.read<CartBloc>().add(ClearCart());
              context.read<ProductBloc>().add(ResetProducts());
              context.read<CategoryBloc>().add(ResetCategories());
              context.read<CustomerBloc>().add(ResetCustomers());
              context.read<TransactionBloc>().add(ResetTransactions());
              context.read<BusinessBloc>().add(ResetBusinessInfo());
              context.read<AuthBloc>().add(SignOutRequested());
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Keluar',
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
}
