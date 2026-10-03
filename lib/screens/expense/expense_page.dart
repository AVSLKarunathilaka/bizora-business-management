import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load expenses: $e')));
    }
  }

  // =========================
  // FILTERS
  // =========================

  void _applyFilters() {
    final query = expenseSearchQuery.toLowerCase().trim();

    setState(() {
      filteredExpenses = expenses.where((expense) {
        final expenseId = expense['expense_id']?.toString().toLowerCase() ?? '';

        final title = expense['title']?.toString().toLowerCase() ?? '';

        final category = expense['category']?.toString() ?? '';

        final paymentMethod = expense['payment_method']?.toString() ?? '';

        final note = expense['note']?.toString().toLowerCase() ?? '';

        final matchesSearch =
            query.isEmpty ||
            expenseId.contains(query) ||
            title.contains(query) ||
            category.toLowerCase().contains(query) ||
            paymentMethod.toLowerCase().contains(query) ||
            note.contains(query);

        final matchesCategory =
            selectedCategory == 'All' || category == selectedCategory;

        final matchesPaymentMethod =
            selectedPaymentMethod == 'All' ||
            paymentMethod == selectedPaymentMethod;

        return matchesSearch && matchesCategory && matchesPaymentMethod;
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
      (sum, expense) => sum + ((expense['amount'] as num?)?.toDouble() ?? 0),
    );
  }

  double get _todayExpenses {
    final now = DateTime.now();

    return expenses.fold<double>(0, (sum, expense) {
      final dateString = expense['expense_date']?.toString();

      if (dateString == null) {
        return sum;
      }

      try {
        final date = DateTime.parse(dateString);

        if (date.year == now.year &&
            date.month == now.month &&
            date.day == now.day) {
          return sum + ((expense['amount'] as num?)?.toDouble() ?? 0);
        }
      } catch (_) {}

      return sum;
    });
  }

  double get _thisMonthExpenses {
    final now = DateTime.now();

    return expenses.fold<double>(0, (sum, expense) {
      final dateString = expense['expense_date']?.toString();

      if (dateString == null) {
        return sum;
      }

      try {
        final date = DateTime.parse(dateString);

        if (date.year == now.year && date.month == now.month) {
          return sum + ((expense['amount'] as num?)?.toDouble() ?? 0);
        }
      } catch (_) {}

      return sum;
    });
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
                          prefixIcon: const Icon(Icons.title),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      DropdownButtonFormField<String>(
                        value: selectedCategoryValue,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          prefixIcon: const Icon(Icons.category_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: categories
                            .where((category) => category != 'All')
                            .map(
                              (category) => DropdownMenuItem<String>(
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
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          hintText: '0.00',
                          prefixIcon: const Icon(Icons.payments_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      DropdownButtonFormField<String>(
                        value: selectedPaymentMethodValue,
                        decoration: InputDecoration(
                          labelText: 'Payment Method',
                          prefixIcon: const Icon(
                            Icons.account_balance_wallet_outlined,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: paymentMethods
                            .where((method) => method != 'All')
                            .map(
                              (method) => DropdownMenuItem<String>(
                                value: method,
                                child: Text(method),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          setDialogState(() {
                            selectedPaymentMethodValue = value;
                          });
                        },
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        'Expense Date',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),

                      const SizedBox(height: 8),

                      InkWell(
                        onTap: () async {
                          final pickedDate = await showDatePicker(
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
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            _formatDate(selectedDate.toIso8601String()),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      TextField(
                        controller: noteController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Note',
                          hintText: 'Optional additional information',
                          prefixIcon: const Icon(Icons.notes_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
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
                    final title = titleController.text.trim();

                    final amountText = amountController.text.trim();

                    final note = noteController.text.trim();

                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter an expense title'),
                        ),
                      );
                      return;
                    }

                    final amount = double.tryParse(amountText);

                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid amount'),
                        ),
                      );
                      return;
                    }

                    try {
                      await DatabaseHelper.insertExpense({
                        'title': title,
                        'category': selectedCategoryValue,
                        'amount': amount,
                        'expense_date': selectedDate.toIso8601String(),
                        'payment_method': selectedPaymentMethodValue,
                        'note': note.isEmpty ? null : note,
                        'created_at': DateTime.now().toIso8601String(),
                      });

                      if (!mounted) return;

                      Navigator.pop(dialogContext);

                      await _loadExpenses();

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Expense created successfully'),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to create expense: $e')),
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

  Future<void> _showEditExpenseDialog(Map<String, dynamic> expense) async {
    final titleController = TextEditingController(
      text: expense['title']?.toString() ?? '',
    );

    final amountController = TextEditingController(
      text: ((expense['amount'] as num?)?.toDouble() ?? 0).toStringAsFixed(2),
    );

    final noteController = TextEditingController(
      text: expense['note']?.toString() ?? '',
    );

    String selectedCategoryValue = expense['category']?.toString() ?? 'Other';

    String selectedPaymentMethodValue =
        expense['payment_method']?.toString() ?? 'Cash';

    DateTime selectedDate =
        DateTime.tryParse(expense['expense_date']?.toString() ?? '') ??
        DateTime.now();

    if (!categories.contains(selectedCategoryValue) ||
        selectedCategoryValue == 'All') {
      selectedCategoryValue = 'Other';
    }

    if (!paymentMethods.contains(selectedPaymentMethodValue) ||
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
                          prefixIcon: const Icon(Icons.title),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      DropdownButtonFormField<String>(
                        value: selectedCategoryValue,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          prefixIcon: const Icon(Icons.category_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: categories
                            .where((category) => category != 'All')
                            .map(
                              (category) => DropdownMenuItem<String>(
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
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          prefixIcon: const Icon(Icons.payments_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      DropdownButtonFormField<String>(
                        value: selectedPaymentMethodValue,
                        decoration: InputDecoration(
                          labelText: 'Payment Method',
                          prefixIcon: const Icon(
                            Icons.account_balance_wallet_outlined,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: paymentMethods
                            .where((method) => method != 'All')
                            .map(
                              (method) => DropdownMenuItem<String>(
                                value: method,
                                child: Text(method),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          setDialogState(() {
                            selectedPaymentMethodValue = value;
                          });
                        },
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        'Expense Date',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),

                      const SizedBox(height: 8),

                      InkWell(
                        onTap: () async {
                          final pickedDate = await showDatePicker(
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
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            _formatDate(selectedDate.toIso8601String()),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      TextField(
                        controller: noteController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Note',
                          prefixIcon: const Icon(Icons.notes_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
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
                    final title = titleController.text.trim();

                    final amountText = amountController.text.trim();

                    final note = noteController.text.trim();

                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter an expense title'),
                        ),
                      );
                      return;
                    }

                    final amount = double.tryParse(amountText);

                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid amount'),
                        ),
                      );
                      return;
                    }

                    try {
                      await DatabaseHelper.updateExpense(expense['id'] as int, {
                        'title': title,
                        'category': selectedCategoryValue,
                        'amount': amount,
                        'expense_date': selectedDate.toIso8601String(),
                        'payment_method': selectedPaymentMethodValue,
                        'note': note.isEmpty ? null : note,
                      });

                      if (!mounted) return;

                      Navigator.pop(dialogContext);

                      await _loadExpenses();

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Expense updated successfully'),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update expense: $e')),
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

  Future<void> _deleteExpense(Map<String, dynamic> expense) async {
    final title = expense['title']?.toString() ?? 'this expense';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Expense'),
          content: Text('Are you sure you want to delete "$title"?'),
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
      await DatabaseHelper.deleteExpense(expense['id'] as int);

      await _loadExpenses();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete expense: $e')));
    }
  }

  // =========================
  // EXPENSE DETAILS
  // =========================

  Future<void> _showExpenseDetails(Map<String, dynamic> expense) async {
    final amount = ((expense['amount'] as num?)?.toDouble() ?? 0);

    final title = expense['title']?.toString() ?? '-';

    final expenseId = expense['expense_id']?.toString() ?? '-';

    final category = expense['category']?.toString() ?? '-';

    final paymentMethod = expense['payment_method']?.toString() ?? '-';

    final expenseDate = expense['expense_date']?.toString();

    final note = expense['note']?.toString() ?? '';

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(_getExpenseIcon(category)),
              const SizedBox(width: 10),
              Expanded(child: Text(title, overflow: TextOverflow.ellipsis)),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _expenseDetailRow('Expense ID', expenseId, Icons.tag),

                const Divider(),
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
                  _expenseDetailRow('Note', note, Icons.notes_outlined),
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

  Widget _expenseDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22),

          const SizedBox(width: 12),

          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // =========================
  // SUMMARY CARD
  // =========================

  Widget _summaryCard(String title, double amount, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 25),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Rs. ${amount.toStringAsFixed(2)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
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

  //--------------------------------------------------------------------
  //helper1
  //--------------------------------------------------------------------

  Widget _buildResponsiveSummaryCard(
    String title,
    double amount,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: colorScheme.primary),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    'Rs. ${amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  //----------------------------------------------------------------------
  //helper2
  //----------------------------------------------------------------------

  Widget _buildExpenseCard({
    required Map<String, dynamic> expense,
    required String title,
    required String category,
    required String paymentMethod,
    required String date,
    required double amount,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          _showExpenseDetails(expense);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // ============================================================
              // ICON
              // ============================================================

              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _getExpenseIcon(category),
                  color: colorScheme.primary,
                  size: 26,
                ),
              ),

              const SizedBox(width: 14),

              // ============================================================
              // EXPENSE INFORMATION
              // ============================================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense['expense_id']?.toString() ?? 'EXP-????',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Wrap(
                      spacing: 8,
                      runSpacing: 5,
                      children: [
                        _expenseInfoChip(Icons.category_outlined, category),

                        _expenseInfoChip(
                          Icons.account_balance_wallet_outlined,
                          paymentMethod,
                        ),

                        _expenseInfoChip(
                          Icons.calendar_today_outlined,
                          _formatDate(date),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // ============================================================
              // AMOUNT + ACTIONS
              // ============================================================
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rs. ${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Edit Expense',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () {
                          _showEditExpenseDialog(expense);
                        },
                      ),

                      IconButton(
                        tooltip: 'Delete Expense',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () {
                          _deleteExpense(expense);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  //============================================

  //expenseInfoChip
  //================================================

  Widget _expenseInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  // =========================
  // BUILD
  // =========================

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallWidth = constraints.maxWidth < 1000;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ========================================================
                  // HEADER
                  // ========================================================

                  if (isSmallWidth)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // BACK BUTTON
                            IconButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.arrow_back),
                              tooltip: 'Back',
                            ),

                            const SizedBox(width: 4),

                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.account_balance_wallet_outlined,
                                color: colorScheme.primary,
                                size: 25,
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Expenses',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),

                                  const SizedBox(height: 3),

                                  Text(
                                    'Track and manage your business expenses',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _showCreateExpenseDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Create Expense'),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        // BACK BUTTON
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.arrow_back),
                          tooltip: 'Back',
                        ),

                        const SizedBox(width: 4),

                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_outlined,
                            color: colorScheme.primary,
                            size: 28,
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Expense Management',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                'Track and manage your business expenses',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),

                        FilledButton.icon(
                          onPressed: _showCreateExpenseDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Create Expense'),
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),

                  // ========================================================
                  // SUMMARY CARDS
                  // ========================================================
                  if (isSmallWidth)
                    Column(
                      children: [
                        _buildResponsiveSummaryCard(
                          'Total Expenses',
                          _totalExpenses,
                          Icons.account_balance_wallet_outlined,
                        ),

                        const SizedBox(height: 10),

                        _buildResponsiveSummaryCard(
                          'This Month',
                          _thisMonthExpenses,
                          Icons.calendar_month_outlined,
                        ),

                        const SizedBox(height: 10),

                        _buildResponsiveSummaryCard(
                          'Today',
                          _todayExpenses,
                          Icons.today_outlined,
                        ),
                      ],
                    )
                  else
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

                  const SizedBox(height: 16),

                  // ========================================================
                  // SEARCH + FILTERS
                  // ========================================================
                  if (isSmallWidth)
                    Column(
                      children: [
                        TextField(
                          onChanged: _searchExpenses,
                          decoration: InputDecoration(
                            hintText: 'Search expenses...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.35),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: selectedCategory,
                                decoration: InputDecoration(
                                  labelText: 'Category',
                                  prefixIcon: const Icon(
                                    Icons.category_outlined,
                                  ),
                                  filled: true,
                                  fillColor: colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.35),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                items: categories
                                    .map(
                                      (category) => DropdownMenuItem<String>(
                                        value: category,
                                        child: Text(category),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value == null) {
                                    return;
                                  }

                                  setState(() {
                                    selectedCategory = value;
                                  });

                                  _applyFilters();
                                },
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: selectedPaymentMethod,
                                decoration: InputDecoration(
                                  labelText: 'Payment',
                                  prefixIcon: const Icon(
                                    Icons.account_balance_wallet_outlined,
                                  ),
                                  filled: true,
                                  fillColor: colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.35),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                items: paymentMethods
                                    .map(
                                      (method) => DropdownMenuItem<String>(
                                        value: method,
                                        child: Text(method),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value == null) {
                                    return;
                                  }

                                  setState(() {
                                    selectedPaymentMethod = value;
                                  });

                                  _applyFilters();
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            onChanged: _searchExpenses,
                            decoration: InputDecoration(
                              hintText: 'Search expenses, categories or payment methods...',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.35),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedCategory,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              prefixIcon: const Icon(Icons.category_outlined),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.35),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: categories
                                .map(
                                  (category) => DropdownMenuItem<String>(
                                    value: category,
                                    child: Text(category),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }

                              setState(() {
                                selectedCategory = value;
                              });

                              _applyFilters();
                            },
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedPaymentMethod,
                            decoration: InputDecoration(
                              labelText: 'Payment',
                              prefixIcon: const Icon(
                                Icons.account_balance_wallet_outlined,
                              ),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.35),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: paymentMethods
                                .map(
                                  (method) => DropdownMenuItem<String>(
                                    value: method,
                                    child: Text(method),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }

                              setState(() {
                                selectedPaymentMethod = value;
                              });

                              _applyFilters();
                            },
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 10),

                  // ========================================================
                  // RESULT COUNT + CLEAR
                  // ========================================================
                  Row(
                    children: [
                      Text(
                        '${filteredExpenses.length} expense'
                        '${filteredExpenses.length == 1 ? '' : 's'}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),

                      const Spacer(),

                      if (expenseSearchQuery.isNotEmpty ||
                          selectedCategory != 'All' ||
                          selectedPaymentMethod != 'All')
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              expenseSearchQuery = '';
                              selectedCategory = 'All';
                              selectedPaymentMethod = 'All';
                              filteredExpenses = List.from(expenses);
                            });
                          },
                          icon: const Icon(Icons.clear, size: 18),
                          label: const Text('Clear Filters'),
                        ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // ========================================================
                  // EXPENSE LIST
                  // ========================================================
                  Expanded(
                    child: isLoadingExpenses
                        ? const Center(child: CircularProgressIndicator())
                        : filteredExpenses.isEmpty
                        ? Card(
                            elevation: 0,
                            clipBehavior: Clip.antiAlias,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    child: Icon(
                                      Icons.receipt_long_outlined,
                                      size: 42,
                                      color: colorScheme.primary,
                                    ),
                                  ),

                                  const SizedBox(height: 18),

                                  Text(
                                    expenseSearchQuery.isNotEmpty ||
                                            selectedCategory != 'All' ||
                                            selectedPaymentMethod != 'All'
                                        ? 'No matching expenses found'
                                        : 'No expenses yet',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),

                                  const SizedBox(height: 8),

                                  if (expenseSearchQuery.isEmpty &&
                                      selectedCategory == 'All' &&
                                      selectedPaymentMethod == 'All')
                                    FilledButton.icon(
                                      onPressed: _showCreateExpenseDialog,
                                      icon: const Icon(Icons.add),
                                      label: const Text('Create Expense'),
                                    ),
                                ],
                              ),
                            ),
                          )
                        : Card(
                            elevation: 0,
                            clipBehavior: Clip.antiAlias,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: filteredExpenses.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final expense = filteredExpenses[index];

                                final amount =
                                    ((expense['amount'] as num?)?.toDouble() ??
                                    0);

                                final title =
                                    expense['title']?.toString() ?? '-';

                                final category =
                                    expense['category']?.toString() ?? '-';

                                final paymentMethod =
                                    expense['payment_method']?.toString() ??
                                    '-';

                                final date =
                                    expense['expense_date']?.toString() ?? '';

                                return _buildExpenseCard(
                                  expense: expense,
                                  title: title,
                                  category: category,
                                  paymentMethod: paymentMethod,
                                  date: date,
                                  amount: amount,
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
