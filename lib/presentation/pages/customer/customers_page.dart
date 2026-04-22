import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/customer/customer_bloc.dart';
import '../../../domain/entities/customer_entity.dart';
import '../../../core/style/app_colors.dart';
import 'add_edit_customer_page.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<CustomerBloc>().add(LoadCustomers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Kelola Pelanggan')),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: BlocBuilder<CustomerBloc, CustomerState>(
              builder: (context, state) {
                if (state.isLoading && state.customers.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredCustomers = state.customers.where((customer) {
                  return customer.name.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      (customer.phone?.contains(_searchQuery) ?? false);
                }).toList();

                if (filteredCustomers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Belum ada pelanggan'
                              : 'Pelanggan tidak ditemukan',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredCustomers.length,
                  itemBuilder: (context, index) {
                    final customer = filteredCustomers[index];
                    return _buildCustomerCard(customer);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditCustomerPage()),
        ),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.person_add_alt_1_outlined, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Cari nama atau nomor telepon...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          fillColor: AppColors.background,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddEditCustomerPage(customer: customer),
          ),
        ),
        leading: CircleAvatar(
          backgroundColor: Colors.teal.shade50,
          child: Text(
            customer.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: Colors.teal,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (customer.phone != null && customer.phone!.isNotEmpty)
              Row(
                children: [
                  const Icon(
                    Icons.phone_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(customer.phone!, style: const TextStyle(fontSize: 12)),
                ],
              ),
          ],
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textDisabled,
        ),
      ),
    );
  }
}
