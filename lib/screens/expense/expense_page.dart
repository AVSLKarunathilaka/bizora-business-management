import 'package:flutter/material.dart';
import '../../db/database_helper.dart';

class ExpensePage extends StatefulWidget {
  const ExpensePage({super.key});

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  List<Map<String, dynamic>> expenses = [];
  List<Map<String, dynamic>> filteredExpenses = [];

  bool isLoadingExpenses = true;

  String expenseSearchQuery = '';
  String selectedCategory = 'All';
  String selectedPaymentMethod = 'All';

  final List<String> categories = [
    'All',
    'Rent',
    'Utilities',
    'Transport',
    'Salaries',
    'Supplies',
    'Marketing',
    'Maintenance',
    'Other',
  ];

  final List<String> paymentMethods = [
    'All',
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

  // =========================
  // LOAD EXPENSES
  // =========================

  Future<void> _loadExpenses() async {
    try {
      final data = await DatabaseHelper.getExpenses();

      if (!mounted) return;

      setState(() {
        expenses = data;
        isLoadingExpenses = false;
      });

      _applyFilters();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingExpenses = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load expenses: $e'),
        ),
      );
    }
  }

  // =========================
  // FILTERS
  // =========================

  void _applyFilters() {
    final query = expenseSearchQuery.toLowerCase().trim();

    setState(() {
      filteredExpenses = expenses.where((expense) {
        final title =
            expense['title']?.toString().toLowerCase() ?? '';

        final category =
            expense['category']?.toString() ?? '';

        final paymentMethod =
            expense['payment_method']?.toString() ?? '';

        final note =
            expense['note']?.toString().toLowerCase() ?? '';

        final matchesSearch =
            query.isEmpty ||
            title.contains(query) ||
            category.toLowerCase().contains(query) ||
            paymentMethod.toLowerCase().contains(query) ||
            note.contains(query);

        final matchesCategory =
            selectedCategory == 'All' ||
            category == selectedCategory;

        final matchesPaymentMethod =
            selectedPaymentMethod == 'All' ||
            paymentMethod == selectedPaymentMethod;

        return matchesSearch &&
            matchesCategory &&
            matchesPaymentMethod;
      }).toList();
    });
  }

  void _searchExpenses(String value) {
    expenseSearchQuery = value;
    _applyFilters();
  }

  // =========================
  // ICON
  // =========================

  IconData _getExpenseIcon(String category) {
    switch (category) {
      case 'Rent':
        return Icons.home_work_outlined;

      case 'Utilities':
        return Icons.lightbulb_outline;

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

  // =========================
  // DATE FORMAT
  // =========================

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) {
      return '-';
    }

    try {
      final parsedDate = DateTime.parse(date);

      return '${parsedDate.day.toString().padLeft(2, '0')}/'
          '${parsedDate.month.toString().padLeft(2, '0')}/'
          '${parsedDate.year}';
    } catch (_) {
      return date;
    }
  }

  // =========================
  // SUMMARY
  // =========================

  double get _totalExpenses {
    return expenses.fold<double>(
      0,
      (sum, expense) =>
          sum + ((expense['amount'] as num?)?.toDouble() ?? 0),
    );
  }

  double get _todayExpenses {
    final now = DateTime.now();

    return expenses.fold<double>(
      0,
      (sum, expense) {
        final dateString = expense['expense_date']?.toString();

        if (dateString == null) {
          return sum;
        }

        try {
          final date = DateTime.parse(dateString);

          if (date.year == now.year &&
              date.month == now.month &&
              date.day == now.day) {
            return sum +
                ((expense['amount'] as num?)?.toDouble() ?? 0);
          }
        } catch (_) {}

        return sum;
      },
    );
  }

  double get _thisMonthExpenses {
    final now = DateTime.now();

    return expenses.fold<double>(
      0,
      (sum, expense) {
        final dateString = expense['expense_date']?.toString();

        if (dateString == null) {
          return sum;
        }

        try {
          final date = DateTime.parse(dateString);

          if (date.year == now.year &&
              date.month == now.month) {
            return sum +
                ((expense['amount'] as num?)?.toDouble() ?? 0);
          }
        } catch (_) {}

        return sum;
      },
    );
  }

  // =========================
  // CREATE EXPENSE
  // =========================

  Future<void> _showCreateExpenseDialog() async {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    String selectedCategoryValue = 'Rent';
    String selectedPaymentMethodValue = 'Cash';
    DateTime selectedDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.add_business_outlined),
                  SizedBox(width: 10),
                  Text('Create Expense'),
                ],
              ),
              content: SizedBox(
                width: 550,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Expense Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Expense Title',
                          hintText: 'Enter expense title',
                          prefixIcon:
                              const Icon(Icons.title),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      DropdownButtonFormField<String>(
                        value: selectedCategoryValue,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          prefixIcon:
                              const Icon(Icons.category_outlined),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                        ),
                        items: categories
                            .where((category) =>
                                category != 'All')
                            .map(
                              (category) =>
                                  DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          setDialogState(() {
                            selectedCategoryValue = value;
                          });
                        },
                      ),

                      const SizedBox(height: 15),

                      TextField(
                        controller: amountController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          hintText: '0.00',
                          prefixIcon:
                              const Icon(Icons.payments_outlined),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      DropdownButtonFormField<String>(
                        value: selectedPaymentMethodValue,
                        decoration: InputDecoration(
                          labelText: 'Payment Method',
                          prefixIcon:
                              const Icon(Icons.account_balance_wallet_outlined),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                        ),
                        items: paymentMethods
                            .where((method) =>
                                method != 'All')
                            .map(
                              (method) =>
                                  DropdownMenuItem<String>(
                                value: method,
                                child: Text(method),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          setDialogState(() {
                            selectedPaymentMethodValue =
                                value;
                          });
                        },
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        'Expense Date',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      InkWell(
                        onTap: () async {
                          final pickedDate =
                              await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );

                          if (pickedDate != null) {
                            setDialogState(() {
                              selectedDate = pickedDate;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.calendar_today_outlined,
                            ),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            _formatDate(
                              selectedDate
                                  .toIso8601String(),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      TextField(
                        controller: noteController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Note',
                          hintText:
                              'Optional additional information',
                          prefixIcon:
                              const Icon(Icons.notes_outlined),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),

                FilledButton.icon(
                  onPressed: () async {
                    final title =
                        titleController.text.trim();

                    final amountText =
                        amountController.text.trim();

                    final note =
                        noteController.text.trim();

                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter an expense title',
                          ),
                        ),
                      );
                      return;
                    }

                    final amount =
                        double.tryParse(amountText);

                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter a valid amount',
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      await DatabaseHelper.insertExpense({
                        'title': title,
                        'category':
                            selectedCategoryValue,
                        'amount': amount,
                        'expense_date':
                            selectedDate
                                .toIso8601String(),
                        'payment_method':
                            selectedPaymentMethodValue,
                        'note':
                            note.isEmpty ? null : note,
                        'created_at':
                            DateTime.now()
                                .toIso8601String(),
                      });

                      if (!mounted) return;

                      Navigator.pop(dialogContext);

                      await _loadExpenses();

                      if (!mounted) return;

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Expense created successfully',
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to create expense: $e',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Create Expense'),
                ),
              ],
            );
          },
        );
      },
    );

    // IMPORTANT:
    // Dispose only after the dialog is completely closed.
    titleController.dispose();
    amountController.dispose();
    noteController.dispose();
  }

  // =========================
  // EDIT EXPENSE
  // =========================

  Future<void> _showEditExpenseDialog(
    Map<String, dynamic> expense,
  ) async {
    final titleController = TextEditingController(
      text: expense['title']?.toString() ?? '',
    );

    final amountController = TextEditingController(
      text: ((expense['amount'] as num?)?.toDouble() ?? 0)
          .toStringAsFixed(2),
    );

    final noteController = TextEditingController(
      text: expense['note']?.toString() ?? '',
    );

    String selectedCategoryValue =
        expense['category']?.toString() ?? 'Other';

    String selectedPaymentMethodValue =
        expense['payment_method']?.toString() ?? 'Cash';

    DateTime selectedDate = DateTime.tryParse(
          expense['expense_date']?.toString() ?? '',
        ) ??
        DateTime.now();

    if (!categories.contains(selectedCategoryValue) ||
        selectedCategoryValue == 'All') {
      selectedCategoryValue = 'Other';
    }

    if (!paymentMethods.contains(
          selectedPaymentMethodValue,
        ) ||
        selectedPaymentMethodValue == 'All') {
      selectedPaymentMethodValue = 'Other';
    }

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.edit_outlined),
                  SizedBox(width: 10),
                  Text('Edit Expense'),
                ],
              ),
              content: SizedBox(
                width: 550,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Expense Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Expense Title',
                          prefixIcon:
                              const Icon(Icons.title),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      DropdownButtonFormField<String>(
                        value: selectedCategoryValue,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          prefixIcon:
                              const Icon(Icons.category_outlined),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                        ),
                        items: categories
                            .where((category) =>
                                category != 'All')
                            .map(
                              (category) =>
                                  DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          setDialogState(() {
                            selectedCategoryValue =
                                value;
                          });
                        },
                      ),

                      const SizedBox(height: 15),

                      TextField(
                        controller: amountController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          prefixIcon:
                              const Icon(Icons.payments_outlined),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      DropdownButtonFormField<String>(
                        value:
                            selectedPaymentMethodValue,
                        decoration: InputDecoration(
                          labelText: 'Payment Method',
                          prefixIcon:
                              const Icon(Icons.account_balance_wallet_outlined),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                        ),
                        items: paymentMethods
                            .where((method) =>
                                method != 'All')
                            .map(
                              (method) =>
                                  DropdownMenuItem<String>(
                                value: method,
                                child: Text(method),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          setDialogState(() {
                            selectedPaymentMethodValue =
                                value;
                          });
                        },
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        'Expense Date',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      InkWell(
                        onTap: () async {
                          final pickedDate =
                              await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );

                          if (pickedDate != null) {
                            setDialogState(() {
                              selectedDate =
                                  pickedDate;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.calendar_today_outlined,
                            ),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            _formatDate(
                              selectedDate
                                  .toIso8601String(),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      TextField(
                        controller: noteController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Note',
                          prefixIcon:
                              const Icon(Icons.notes_outlined),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),

                FilledButton.icon(
                  onPressed: () async {
                    final title =
                        titleController.text.trim();

                    final amountText =
                        amountController.text.trim();

                    final note =
                        noteController.text.trim();

                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter an expense title',
                          ),
                        ),
                      );
                      return;
                    }

                    final amount =
                        double.tryParse(amountText);

                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter a valid amount',
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      await DatabaseHelper.updateExpense(
                        expense['id'] as int,
                        {
                          'title': title,
                          'category':
                              selectedCategoryValue,
                          'amount': amount,
                          'expense_date':
                              selectedDate
                                  .toIso8601String(),
                          'payment_method':
                              selectedPaymentMethodValue,
                          'note':
                              note.isEmpty ? null : note,
                        },
                      );

                      if (!mounted) return;

                      Navigator.pop(dialogContext);

                      await _loadExpenses();

                      if (!mounted) return;

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Expense updated successfully',
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to update expense: $e',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );

    // IMPORTANT:
    // Dispose only after the dialog is completely closed.
    titleController.dispose();
    amountController.dispose();
    noteController.dispose();
  }

  // =========================
  // DELETE EXPENSE
  // =========================

  Future<void> _deleteExpense(
    Map<String, dynamic> expense,
  ) async {
    final title =
        expense['title']?.toString() ?? 'this expense';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Expense'),
          content: Text(
            'Are you sure you want to delete "$title"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await DatabaseHelper.deleteExpense(
        expense['id'] as int,
      );

      await _loadExpenses();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Expense deleted successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete expense: $e',
          ),
        ),
      );
    }
  }

  // =========================
  // EXPENSE DETAILS
  // =========================

  Future<void> _showExpenseDetails(
    Map<String, dynamic> expense,
  ) async {
    final amount =
        ((expense['amount'] as num?)?.toDouble() ?? 0);

    final title =
        expense['title']?.toString() ?? '-';

    final category =
        expense['category']?.toString() ?? '-';

    final paymentMethod =
        expense['payment_method']?.toString() ?? '-';

    final expenseDate =
        expense['expense_date']?.toString();

    final note =
        expense['note']?.toString() ?? '';

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                _getExpenseIcon(category),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _expenseDetailRow(
                  'Category',
                  category,
                  Icons.category_outlined,
                ),

                const Divider(),

                _expenseDetailRow(
                  'Amount',
                  'Rs. ${amount.toStringAsFixed(2)}',
                  Icons.payments_outlined,
                ),

                const Divider(),

                _expenseDetailRow(
                  'Payment Method',
                  paymentMethod,
                  Icons.account_balance_wallet_outlined,
                ),

                const Divider(),

                _expenseDetailRow(
                  'Date',
                  _formatDate(expenseDate),
                  Icons.calendar_today_outlined,
                ),

                if (note.isNotEmpty) ...[
                  const Divider(),
                  _expenseDetailRow(
                    'Note',
                    note,
                    Icons.notes_outlined,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Close'),
            ),

            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                _showEditExpenseDialog(expense);
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit'),
            ),

            FilledButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                _deleteExpense(expense);
              },
              icon: const Icon(Icons.delete),
              label: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // =========================
  // DETAIL ROW
  // =========================

  Widget _expenseDetailRow(
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 22,
          ),

          const SizedBox(width: 12),

          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  // =========================
  // SUMMARY CARD
  // =========================

  Widget _summaryCard(
    String title,
    double amount,
    IconData icon,
  ) {
    return Expanded(
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                child: Icon(icon),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Rs. ${amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // BUILD
  // =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Expense Management',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Create and manage your business expenses',
              style: TextStyle(
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 25),

            // =========================
            // SUMMARY CARDS
            // =========================

            Row(
              children: [
                _summaryCard(
                  'Total Expenses',
                  _totalExpenses,
                  Icons.account_balance_wallet_outlined,
                ),

                const SizedBox(width: 15),

                _summaryCard(
                  'This Month',
                  _thisMonthExpenses,
                  Icons.calendar_month_outlined,
                ),

                const SizedBox(width: 15),

                _summaryCard(
                  'Today',
                  _todayExpenses,
                  Icons.today_outlined,
                ),
              ],
            ),

            const SizedBox(height: 25),

            // =========================
            // SEARCH + FILTERS
            // =========================

            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: _searchExpenses,
                    decoration: InputDecoration(
                      hintText: 'Search Expenses...',
                      prefixIcon:
                          const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                DropdownButton<String>(
                  value: selectedCategory,
                  items: categories
                      .map(
                        (category) =>
                            DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      selectedCategory = value;
                    });

                    _applyFilters();
                  },
                ),

                const SizedBox(width: 15),

                DropdownButton<String>(
                  value: selectedPaymentMethod,
                  items: paymentMethods
                      .map(
                        (method) =>
                            DropdownMenuItem<String>(
                          value: method,
                          child: Text(method),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      selectedPaymentMethod = value;
                    });

                    _applyFilters();
                  },
                ),

                const SizedBox(width: 15),

                FilledButton.icon(
                  onPressed:
                      _showCreateExpenseDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Expense'),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // =========================
            // EXPENSE LIST
            // =========================

            Expanded(
              child: isLoadingExpenses
                  ? const Center(
                      child:
                          CircularProgressIndicator(),
                    )
                  : filteredExpenses.isEmpty
                      ? Card(
                          child: Center(
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.receipt_long,
                                  size: 70,
                                ),

                                const SizedBox(height: 15),

                                Text(
                                  expenseSearchQuery
                                              .isNotEmpty ||
                                          selectedCategory !=
                                              'All' ||
                                          selectedPaymentMethod !=
                                              'All'
                                      ? 'No matching expenses found'
                                      : 'No expenses yet',
                                  style:
                                      const TextStyle(
                                    fontSize: 20,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 10),

                                if (expenseSearchQuery
                                        .isEmpty &&
                                    selectedCategory ==
                                        'All' &&
                                    selectedPaymentMethod ==
                                        'All')
                                  FilledButton.icon(
                                    onPressed:
                                        _showCreateExpenseDialog,
                                    icon: const Icon(
                                      Icons.add,
                                    ),
                                    label: const Text(
                                      'Create Expense',
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        )
                      : Card(
                          child: ListView.separated(
                            padding:
                                const EdgeInsets.all(12),
                            itemCount:
                                filteredExpenses.length,
                            separatorBuilder:
                                (context, index) =>
                                    const Divider(),
                            itemBuilder:
                                (context, index) {
                              final expense =
                                  filteredExpenses[
                                      index];

                              final amount =
                                  ((expense['amount']
                                              as num?)
                                          ?.toDouble() ??
                                      0);

                              final title =
                                  expense['title']
                                          ?.toString() ??
                                      '-';

                              final category =
                                  expense['category']
                                          ?.toString() ??
                                      '-';

                              final paymentMethod =
                                  expense[
                                              'payment_method']
                                          ?.toString() ??
                                      '-';

                              final date =
                                  expense['expense_date']
                                          ?.toString();

                              return ListTile(
                                contentPadding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),

                                leading: CircleAvatar(
                                  child: Icon(
                                    _getExpenseIcon(
                                      category,
                                    ),
                                  ),
                                ),

                                title: Text(
                                  title,
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),

                                subtitle: Text(
                                  '$category • '
                                  '$paymentMethod • '
                                  '${_formatDate(date)}',
                                ),

                                trailing: Row(
                                  mainAxisSize:
                                      MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Rs. ${amount.toStringAsFixed(2)}',
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),

                                    const SizedBox(
                                      width: 15,
                                    ),

                                    IconButton(
                                      tooltip:
                                          'Edit Expense',
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                      ),
                                      onPressed: () {
                                        _showEditExpenseDialog(
                                          expense,
                                        );
                                      },
                                    ),

                                    IconButton(
                                      tooltip:
                                          'Delete Expense',
                                      icon: const Icon(
                                        Icons
                                            .delete_outline,
                                      ),
                                      onPressed: () {
                                        _deleteExpense(
                                          expense,
                                        );
                                      },
                                    ),
                                  ],
                                ),

                                onTap: () {
                                  _showExpenseDetails(
                                    expense,
                                  );
                                },
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}