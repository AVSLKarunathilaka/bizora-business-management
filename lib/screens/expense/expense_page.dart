import 'package:flutter/material.dart';

import '../../db/database_helper.dart';

/// Expense management page.
///
/// This page currently provides the expense entry form.
/// Database saving will be connected separately.
class ExpensePage extends StatefulWidget {
  const ExpensePage({super.key});

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  // ------------------------------------------------------------
  // Form & Text Controllers
  // ------------------------------------------------------------

  // Used to validate the entire expense form.
  final _formKey = GlobalKey<FormState>();

  // Controllers for user-entered values.
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _searchController = TextEditingController();

  // ------------------------------------------------------------
  // Selected Dropdown & Date Values
  // ------------------------------------------------------------

  // Default expense category.
  String _selectedCategory = 'Other';

  // Default payment method.
  String _selectedPaymentMethod = 'Cash';

  // ------------------------------------------------------------
  // Expense List State
  // ------------------------------------------------------------

  List<Map<String, dynamic>> _expenses = [];

  bool _isLoadingExpenses = true;
  String _searchQuery = '';
  String _selectedFilterCategory = 'All';
  String _selectedFilterPaymentMethod = 'All';

  // Default expense date is today's date.
  DateTime _selectedDate = DateTime.now();

  // ------------------------------------------------------------
  // Expense Categories
  // ------------------------------------------------------------

  // Available expense categories.
  final List<String> _categories = [
    'Rent',
    'Utilities',
    'Transport',
    'Salaries',
    'Supplies',
    'Marketing',
    'Maintenance',
    'Other',
  ];

  // ------------------------------------------------------------
  // Payment Methods
  // ------------------------------------------------------------

  // Available payment methods.
  final List<String> _paymentMethods = [
    'Cash',
    'Bank Transfer',
    'Card',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    _loadExpenses();
  }

  // ------------------------------------------------------------
  // Dispose Controllers
  // ------------------------------------------------------------

  @override
  void dispose() {
    // Always dispose controllers when the page is removed.
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _searchController.dispose();

    super.dispose();
  }

  // ------------------------------------------------------------
  // Date Picker
  // ------------------------------------------------------------

  /// Opens the date picker and allows the user to select
  /// the date of the expense.
  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,

      // Currently selected date.
      initialDate: _selectedDate,

      // Allow expenses from the year 2000 onwards.
      firstDate: DateTime(2000),

      // Allow dates up to the year 2100.
      lastDate: DateTime(2100),
    );

    // Update the selected date if the user selected one.
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  // ------------------------------------------------------------
  // Load Expenses
  // ------------------------------------------------------------

  /// Loads all saved expenses from SQLite.
  Future<void> _loadExpenses() async {
    try {
      final expenses = await DatabaseHelper.getExpenses();

      if (!mounted) return;

      setState(() {
        _expenses = expenses;
        _isLoadingExpenses = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingExpenses = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load expenses: $e')));
    }
  }

  // ------------------------------------------------------------
  // Filter Expenses
  // ------------------------------------------------------------

  List<Map<String, dynamic>> get _filteredExpenses {
    final query = _searchQuery.trim().toLowerCase();

    return _expenses.where((expense) {
      final title = expense['title']?.toString().toLowerCase() ?? '';
      final category = expense['category']?.toString().toLowerCase() ?? '';
      final paymentMethod =
          expense['payment_method']?.toString().toLowerCase() ?? '';

      // Search filter
      final matchesSearch =
          query.isEmpty ||
          title.contains(query) ||
          category.contains(query) ||
          paymentMethod.contains(query);

      // Category filter
      final matchesCategory =
          _selectedFilterCategory == 'All' ||
          expense['category']?.toString() == _selectedFilterCategory;

      // Payment method filter
      final matchesPaymentMethod =
          _selectedFilterPaymentMethod == 'All' ||
          expense['payment_method']?.toString() == _selectedFilterPaymentMethod;

      return matchesSearch && matchesCategory && matchesPaymentMethod;
    }).toList();
  }

  // ------------------------------------------------------------
  // Expense Category Icon
  // ------------------------------------------------------------

  IconData _getExpenseIcon(String category) {
    switch (category) {
      case 'Rent':
        return Icons.home_work_outlined;

      case 'Utilities':
        return Icons.electrical_services;

      case 'Transport':
        return Icons.directions_car_outlined;

      case 'Salaries':
        return Icons.people_outline;

      case 'Supplies':
        return Icons.inventory_2_outlined;

      case 'Marketing':
        return Icons.campaign_outlined;

      case 'Maintenance':
        return Icons.build_outlined;

      default:
        return Icons.receipt_long_outlined;
    }
  }

  // ------------------------------------------------------------
  // Delete Expense
  // ------------------------------------------------------------

  Future<void> _deleteExpense(Map<String, dynamic> expense) async {
    final expenseId = expense['id'] as int;
    final expenseTitle = expense['title']?.toString() ?? 'this expense';

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Expense?'),
          content: Text('Are you sure you want to delete "$expenseTitle"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await DatabaseHelper.deleteExpense(expenseId);

      if (!mounted) return;

      await _loadExpenses();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense deleted successfully.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete expense: $e')));
    }
  }

  // ------------------------------------------------------------
  // Save Expense
  // ------------------------------------------------------------

  /// Validates the form and saves the expense to SQLite.
  Future<void> _saveExpense() async {
    // Stop if form validation fails.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Convert the entered amount to a number.
    final amount = double.parse(_amountController.text.trim());

    try {
      // Save the expense to the database.
      await DatabaseHelper.insertExpense({
        'title': _titleController.text.trim(),
        'category': _selectedCategory,
        'amount': amount,
        'expense_date': _selectedDate.toIso8601String(),
        'payment_method': _selectedPaymentMethod,
        'note': _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });

      // Make sure the page still exists before using context.
      if (!mounted) return;

      // Show successful save message.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense saved successfully.')),
      );

      // Clear the form after successful save.
      _titleController.clear();
      _amountController.clear();
      _noteController.clear();

      setState(() {
        _selectedCategory = 'Other';
        _selectedPaymentMethod = 'Cash';
        _selectedDate = DateTime.now();
      });
      await _loadExpenses();
    } catch (e) {
      // Make sure the page still exists before using context.
      if (!mounted) return;

      // Show database error.
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to save expense: $e')));
    }
  }

  // ------------------------------------------------------------
  // Build UI
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ----------------------------------------------------------
      // App Bar
      // ----------------------------------------------------------

      appBar: AppBar(title: const Text('Expenses')),

      // ----------------------------------------------------------
      // Main Content
      // ----------------------------------------------------------
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),

            // Expense form.
            child: Form(
              key: _formKey,

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ------------------------------------------------
                  // Page Heading
                  // ------------------------------------------------

                  const Text(
                    'Add Expense',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Record a business expense.',
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 30),

                  // ------------------------------------------------
                  // Expense Title
                  // ------------------------------------------------
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Expense Title',
                      hintText: 'e.g. Electricity Bill',
                      prefixIcon: Icon(Icons.receipt_long),
                      border: OutlineInputBorder(),
                    ),

                    // Title is required.
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Expense title is required.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  // ------------------------------------------------
                  // Expense Category
                  // ------------------------------------------------
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,

                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                    ),

                    // Create dropdown items from the category list.
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),

                    // Update selected category.
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 18),

                  // ------------------------------------------------
                  // Expense Amount
                  // ------------------------------------------------
                  TextFormField(
                    controller: _amountController,

                    // Show numeric keyboard.
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),

                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      hintText: '0.00',
                      prefixText: 'Rs. ',
                      prefixIcon: Icon(Icons.payments),
                      border: OutlineInputBorder(),
                    ),

                    // Validate expense amount.
                    validator: (value) {
                      final amount = double.tryParse(value?.trim() ?? '');

                      if (amount == null || amount <= 0) {
                        return 'Enter a valid amount.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  // ------------------------------------------------
                  // Expense Date
                  // ------------------------------------------------
                  InkWell(
                    onTap: _selectDate,

                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Expense Date',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),

                      // Display selected date.
                      child: Text(
                        '${_selectedDate.day.toString().padLeft(2, '0')}/'
                        '${_selectedDate.month.toString().padLeft(2, '0')}/'
                        '${_selectedDate.year}',
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ------------------------------------------------
                  // Payment Method
                  // ------------------------------------------------
                  DropdownButtonFormField<String>(
                    initialValue: _selectedPaymentMethod,

                    decoration: const InputDecoration(
                      labelText: 'Payment Method',
                      prefixIcon: Icon(Icons.account_balance_wallet),
                      border: OutlineInputBorder(),
                    ),

                    // Create dropdown items from payment methods.
                    items: _paymentMethods.map((method) {
                      return DropdownMenuItem(
                        value: method,
                        child: Text(method),
                      );
                    }).toList(),

                    // Update selected payment method.
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedPaymentMethod = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 18),

                  // ------------------------------------------------
                  // Optional Note
                  // ------------------------------------------------
                  TextFormField(
                    controller: _noteController,
                    maxLines: 3,

                    decoration: const InputDecoration(
                      labelText: 'Note',
                      hintText: 'Optional note',
                      prefixIcon: Icon(Icons.notes),
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ------------------------------------------------
                  // Save Button
                  // ------------------------------------------------
                  SizedBox(
                    width: double.infinity,

                    child: FilledButton.icon(
                      onPressed: _saveExpense,

                      icon: const Icon(Icons.save),

                      label: const Text('Save Expense'),
                    ),
                  ),

                  const SizedBox(height: 50),

                  // ------------------------------------------------
                  // Expense List
                  // ------------------------------------------------
                  const Text(
                    'Expense History',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'View your recorded business expenses.',
                    style: TextStyle(color: Colors.grey),
                  ),

                  // ------------------------------------------------
                  // Search Expenses
                  // ------------------------------------------------
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Search Expenses',
                      hintText: 'Search by title, category or payment method',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();

                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ------------------------------------------------
                  // Expense Filters
                  // ------------------------------------------------
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedFilterCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            prefixIcon: Icon(Icons.category_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: 'All',
                              child: Text('All Categories'),
                            ),
                            ..._categories.map(
                              (category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;

                            setState(() {
                              _selectedFilterCategory = value;
                            });
                          },
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedFilterPaymentMethod,
                          decoration: const InputDecoration(
                            labelText: 'Payment',
                            prefixIcon: Icon(
                              Icons.account_balance_wallet_outlined,
                            ),
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: 'All',
                              child: Text('All Methods'),
                            ),
                            ..._paymentMethods.map(
                              (method) => DropdownMenuItem(
                                value: method,
                                child: Text(method),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;

                            setState(() {
                              _selectedFilterPaymentMethod = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const SizedBox(height: 20),

                  // Loading state
                  if (_isLoadingExpenses)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(30),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  // Empty state
                  else if (_expenses.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 50,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No expenses yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Saved expenses will appear here.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  // Expense list
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredExpenses.length,
                      separatorBuilder: (context, index) {
                        return const SizedBox(height: 12);
                      },
                      itemBuilder: (context, index) {
                        final expense = _filteredExpenses[index];

                        final title = expense['title']?.toString() ?? '-';

                        final category = expense['category']?.toString() ?? '-';

                        final paymentMethod =
                            expense['payment_method']?.toString() ?? '-';

                        final amount =
                            (expense['amount'] as num?)?.toDouble() ?? 0;

                        final expenseDate = expense['expense_date']?.toString();

                        String formattedDate = '-';

                        if (expenseDate != null) {
                          final parsedDate = DateTime.tryParse(expenseDate);

                          if (parsedDate != null) {
                            formattedDate =
                                '${parsedDate.day.toString().padLeft(2, '0')}/'
                                '${parsedDate.month.toString().padLeft(2, '0')}/'
                                '${parsedDate.year}';
                          }
                        }

                        return Card(
                          elevation: 1,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            leading: CircleAvatar(
                              child: Icon(_getExpenseIcon(category)),
                            ),
                            title: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '$category • $paymentMethod\n'
                                '$formattedDate',
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Rs. ${amount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: 'Delete Expense',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () {
                                    _deleteExpense(expense);
                                  },
                                ),
                              ],
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
    );
  }
}
