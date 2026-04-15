// lib/widgets/customer_list.dart
import 'package:flutter/material.dart';
import 'package:vrs_erp/Masters/Customer/Customer.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/services/app_services.dart';


class CustomerList extends StatefulWidget {
  const CustomerList({Key? key}) : super(key: key);

  @override
  State<CustomerList> createState() => _CustomerListState();
}

class _CustomerListState extends State<CustomerList> {
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _filteredCustomers = [];
  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final customers = await ApiService.getCustomers();
      setState(() {
        _customers = customers;
        _filteredCustomers = customers;
      });
    } catch (e) {
      print('Error fetching customers: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching customers: $e'),
          backgroundColor: AppColors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _searchCustomers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = _customers;
      } else {
        _filteredCustomers = _customers.where((customer) {
          final customerName = customer['Led_Name']?.toString().toLowerCase() ?? '';
          final customerKey = customer['Led_Key']?.toString().toLowerCase() ?? '';
          return customerName.contains(query.toLowerCase()) ||
              customerKey.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _deleteCustomer(String ledKey, String customerName) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Customer'),
          content: Text('Are you sure you want to delete "$customerName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });
      try {
        await ApiService.deleteLedger(ledKey);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Customer "$customerName" deleted successfully'),
            backgroundColor: AppColors.accentColor,
          ),
        );
        await _fetchCustomers(); // Refresh the list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting customer: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openCustomerForm({String? editItemId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerForm(
          onSuccess: () {
            _fetchCustomers(); // Refresh list when customer is added/updated
          },
          onClose: () {
            Navigator.pop(context); // Close the form
          },
        ),
      ),
    );
  }

  void _editCustomer(String ledKey) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerForm(
          editItemId: ledKey,
          onSuccess: () {
            _fetchCustomers(); // Refresh list when customer is updated
          },
          onClose: () {
            Navigator.pop(context); // Close the form
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search by name or key...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      _searchController.clear();
                      _searchCustomers('');
                      setState(() {
                        _isSearching = false;
                      });
                    },
                  ),
                ),
                onChanged: _searchCustomers,
              )
            : const Text(
                'Customers',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              ),
            )
          : _filteredCustomers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 80,
                        color: AppColors.slate600.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isNotEmpty
                            ? 'No customers found'
                            : 'No customers added yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.slate600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_searchController.text.isNotEmpty)
                        ElevatedButton(
                          onPressed: () {
                            _searchController.clear();
                            _searchCustomers('');
                            setState(() {
                              _isSearching = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: AppColors.white,
                          ),
                          child: const Text('Clear Search'),
                        ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _filteredCustomers.length,
                  itemBuilder: (context, index) {
                    final customer = _filteredCustomers[index];
                    final ledKey = customer['Led_Key']?.toString() ?? '';
                    final customerName = customer['Led_Name']?.toString() ?? '';
                    
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryColor.withOpacity(0.2),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.person,
                              color: AppColors.primaryColor,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            customerName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Key: $ledKey',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.slate600,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  color: AppColors.primaryColor,
                                  size: 20,
                                ),
                                onPressed: () => _editCustomer(ledKey),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  color: AppColors.red,
                                  size: 20,
                                ),
                                onPressed: () => _deleteCustomer(ledKey, customerName),
                              ),
                            ],
                          ),
                          onTap: () => _editCustomer(ledKey),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCustomerForm,
        backgroundColor: AppColors.accentColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}