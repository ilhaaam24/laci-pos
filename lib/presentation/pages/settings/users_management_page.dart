import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/user_entity.dart';
import '../../blocs/users/users_bloc.dart';
import '../../../core/style/app_colors.dart';

class UsersManagementPage extends StatelessWidget {
  const UsersManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manajemen User'),
        actions: [
          IconButton(
            onPressed: () => context.read<UsersBloc>().add(LoadUsers()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocConsumer<UsersBloc, UsersState>(
        listener: (context, state) {
          if (state.message != null && !state.isLoading) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message!)));
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.users.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.users.isEmpty) {
            return const Center(child: Text('Tidak ada user ditemukan'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.users.length,
            itemBuilder: (context, index) {
              final user = state.users[index];
              return _buildUserCard(context, user);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUserDialog(context),
        label: const Text('Tambah Staff'),
        icon: const Icon(Icons.person_add_outlined),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    UserRole selectedRole = UserRole.kasir;
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tambah Staff Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Staff',
                    hintText: 'contoh: staff@gmail.com',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password Staff',
                    hintText: 'Minimal 6 karakter',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setDialogState(
                          () => obscurePassword = !obscurePassword,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Pilih Role:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ...UserRole.values
                    .where((r) => r != UserRole.admin && r != UserRole.owner)
                    .map(
                      (role) => RadioListTile<UserRole>(
                        title: Text(role.name.toUpperCase()),
                        value: role,
                        groupValue: selectedRole,
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => selectedRole = value);
                          }
                        },
                      ),
                    ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
              ),
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final email = emailController.text.trim();
                final password = passwordController.text;
                if (email.isNotEmpty &&
                    email.contains('@') &&
                    password.length >= 6) {
                  context.read<UsersBloc>().add(
                    InviteUser(email, password, selectedRole),
                  );
                  Navigator.pop(dialogContext);
                } else if (password.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password minimal 6 karakter'),
                    ),
                  );
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, UserEntity user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          backgroundImage: user.photoUrl != null
              ? NetworkImage(user.photoUrl!)
              : null,
          child: user.photoUrl == null
              ? Text(
                  (user.name ?? user.email).substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          user.name ?? 'Tanpa Nama',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getRoleColor(user.role).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                user.role.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _getRoleColor(user.role),
                ),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
          onPressed: () => _showRoleDialog(context, user),
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.manager:
        return Colors.blue;
      case UserRole.owner:
        return Colors.purple;
      case UserRole.kasir:
        return Colors.green;
    }
  }

  void _showRoleDialog(BuildContext context, UserEntity user) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ubah Role User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: UserRole.values.map((role) {
            return RadioListTile<UserRole>(
              title: Text(role.name.toUpperCase()),
              value: role,
              groupValue: user.role,
              onChanged: (value) {
                if (value != null) {
                  context.read<UsersBloc>().add(UpdateUserRole(user.id, value));
                  Navigator.pop(dialogContext);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
