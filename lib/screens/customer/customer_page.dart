import 'package:flutter/material.dart';

import '../../db/database_helper.dart';

class CustomerPage extends StatefulWidget {
  const CustomerPage({super.key});

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  final List<Map<String, String>> _customers = [];

  final _formkey = GlobalKey<FormState>();

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final customers = await DatabaseHelper.getCustomers();

    setState(() {
      _customers.clear();

      for (final customer in customers) {
        _customers.add({
          'id': customer['id'].toString(),
          'name': customer['name'].toString(),
          'email': customer['email'].toString(),
          'phone': customer['phone'].toString(),
          'address': customer['address'].toString(),
          'created_at': customer['created_at'].toString(),
        });
      }
    });
  }

  @override
  //controllers clean
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCustomers = _customers.where((customer) {
      final name = customer['name']?.toLowerCase() ?? '';
      final email = customer['email']?.toLowerCase() ?? '';
      final phone = customer['phone'] ?? '';
      final address = customer['address']?.toLowerCase() ?? '';

      return name.contains(_searchQuery.toLowerCase()) ||
          email.contains(_searchQuery.toLowerCase()) ||
          phone.contains(_searchQuery) ||
          address.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Management',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              'Manage your business customers',
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 25),

            //search+addbutton
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search Customers...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 15),

                FilledButton.icon(
                  onPressed: () {
                    _showAddCustomerDialog(context);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Customers'),
                ),
              ],
            ),

            const SizedBox(height: 25),

            //empty state
            Expanded(
              child: _customers.isEmpty
                  ? Card(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.people_outline, size: 70),

                            const SizedBox(height: 15),

                            const Text(
                              'No customers yet',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            const Text(
                              'Add your first customer to get started.',
                            ),

                            const SizedBox(height: 20),

                            FilledButton.icon(
                              onPressed: () {
                                _showAddCustomerDialog(context);
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Customer'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : filteredCustomers.isEmpty
                  ? const Card(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 60),

                            SizedBox(height: 15),

                            Text(
                              'No customers found',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: 8),

                            Text('Try a different search term.'),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = filteredCustomers[index];

                        return Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),

                            title: Text(customer['name'] ?? ''),

                            subtitle: Text(
                              '${customer['email'] ?? ''}\n'
                              '${customer['phone'] ?? ''}\n'
                              '${customer['address'] ?? ''}',
                            ),

                            isThreeLine: true,

                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    _showEditCustomerDialog(context, customer);
                                  },
                                ),

                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text('Delete Customer'),

                                          content: const Text(
                                            'Are you sure you want to delete this customer?',
                                          ),

                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: const Text('Cancel'),
                                            ),

                                            FilledButton(
                                              onPressed: () async {
                                                final id = int.parse(
                                                  customer['id']!,
                                                );

                                                await DatabaseHelper.deleteCustomer(
                                                  id,
                                                );

                                                await _loadCustomers();

                                                Navigator.pop(context);

                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Customer deleted successfully',
                                                        ),
                                                      ),
                                                    );
                                              },
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------method-------------------------------

  void _showAddCustomerDialog(BuildContext context) {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _addressController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Customer'),

          content: SizedBox(
            width: 450,
            child: Form(
              key: _formkey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Customer Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter customer name';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter Email';
                      }

                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Please enter a valid Email';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone),
                    ),

                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter phone number';
                      }

                      if (!RegExp(r'^07\d{8}$').hasMatch(value.trim())) {
                        return 'Enter a valid 10-digit phone number (Ex:07x xx xx xxx)';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      prefixIcon: Icon(Icons.home),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter address';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (_formkey.currentState!.validate()) {
                  final phone = _phoneController.text.trim();
                  final email = _emailController.text.trim();

                  // Check duplicate phone number
                  final phoneExists = await DatabaseHelper.customerPhoneExists(
                    phone,
                  );

                  if (phoneExists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Phone number already exists'),
                      ),
                    );
                    return;
                  }

                  // Check duplicate email
                  final emailExists = await DatabaseHelper.customerEmailExists(
                    email,
                  );

                  if (emailExists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Email already exists')),
                    );
                    return;
                  }

                  final customer = {
                    'name': _nameController.text.trim(),
                    'email': email,
                    'phone': phone,
                    'address': _addressController.text.trim(),
                    'created_at': DateTime.now().toIso8601String(),
                  };

                  await DatabaseHelper.insertCustomer(customer);

                  await _loadCustomers();

                  _nameController.clear();
                  _emailController.clear();
                  _phoneController.clear();
                  _addressController.clear();

                  Navigator.pop(context);
                }
              },
              child: const Text('Add Customer'),
            ),
          ],
        );
      },
    );
  }

  //------------------------------edit customer----------------------------------------

  void _showEditCustomerDialog(
    BuildContext context,
    Map<String, String> customer,
  ) {
    _nameController.text = customer['name'] ?? '';
    _emailController.text = customer['email'] ?? '';
    _phoneController.text = customer['phone'] ?? '';
    _addressController.text = customer['address'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Customer'),

          content: SizedBox(
            width: 450,
            child: Form(
              key: _formkey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Customer Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter customer name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),

                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter Email';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Please enter a valid Email';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter phone number';
                      }

                      if (!RegExp(r'^07\d{8}$').hasMatch(value.trim())) {
                        return 'Enter a valid 10-digit phone number';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  TextFormField(
                    controller: _addressController,
                    maxLength: 50,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      prefixIcon: Icon(Icons.home),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter address';
                      }

                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),

          actions: [
            FilledButton(
              onPressed: () async {
                if (!_formkey.currentState!.validate()) {
                  return;
                }

                final id = int.parse(customer['id']!);

                final phone = _phoneController.text.trim();
                final email = _emailController.text.trim();

                // Check duplicate phone number
                final phoneExists = await DatabaseHelper.customerPhoneExists(
                  phone,
                  excludeId: id,
                );

                if (phoneExists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Phone number already exists'),
                    ),
                  );
                  return;
                }

                // Check duplicate email
                final emailExists = await DatabaseHelper.customerEmailExists(
                  email,
                  excludeId: id,
                );

                if (emailExists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email already exists')),
                  );
                  return;
                }

                final updatedCustomer = {
                  'name': _nameController.text.trim(),
                  'email': email,
                  'phone': phone,
                  'address': _addressController.text.trim(),
                };

                await DatabaseHelper.updateCustomer(id, updatedCustomer);

                await _loadCustomers();

                _nameController.clear();
                _emailController.clear();
                _phoneController.clear();
                _addressController.clear();

                Navigator.pop(context);
              },
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }
}
