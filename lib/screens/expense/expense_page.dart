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

  // ------------------------------------------------------------
  // Selected Dropdown & Date Values
  // ------------------------------------------------------------

  // Default expense category.
  String _selectedCategory = 'Other';

  // Default payment method.
  String _selectedPaymentMethod = 'Cash';

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

  // ------------------------------------------------------------
  // Dispose Controllers
  // ------------------------------------------------------------

  @override
  void dispose() {
    // Always dispose controllers when the page is removed.
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();

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
  // Save Expense
  // ------------------------------------------------------------

 /// Validates the form and saves the expense to SQLite.
Future<void> _saveExpense() async {
  // Stop if form validation fails.
  if (!_formKey.currentState!.validate()) {
    return;
  }

  // Convert the entered amount to a number.
  final amount = double.parse(
    _amountController.text.trim(),
  );

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
      const SnackBar(
        content: Text(
          'Expense saved successfully.',
        ),
      ),
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
  } catch (e) {
    // Make sure the page still exists before using context.
    if (!mounted) return;

    // Show database error.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Failed to save expense: $e',
        ),
      ),
    );
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

      appBar: AppBar(
        title: const Text('Expenses'),
      ),

      // ----------------------------------------------------------
      // Main Content
      // ----------------------------------------------------------

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 700,
            ),

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
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Record a business expense.',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
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
                      final amount = double.tryParse(
                        value?.trim() ?? '',
                      );

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
                      prefixIcon: Icon(
                        Icons.account_balance_wallet,
                      ),
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

                      label: const Text(
                        'Save Expense',
                      ),
                    ),
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