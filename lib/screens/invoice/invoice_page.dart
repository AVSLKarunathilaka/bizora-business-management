import 'package:flutter/material.dart';

import '../../db/database_helper.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  // ============================================================
  // INVOICE LIST DATA
  // ============================================================

  // All invoices loaded from the database.
  List<Map<String, dynamic>> invoices = [];

  // Invoices displayed after search + status filtering.
  List<Map<String, dynamic>> filteredInvoices = [];

  // Loading state for invoice list.
  bool isLoadingInvoices = true;

  // Current invoice search text.
  String invoiceSearchQuery = '';

  // Current selected invoice status filter.
  String selectedStatus = 'All';

  // ============================================================
  // CREATE INVOICE
  // ============================================================

  Future<void> _showCreateInvoiceDialog() async {
    // Automatically generate an invoice number.
    final invoiceNumberController = TextEditingController(
      text: 'INV-${DateTime.now().millisecondsSinceEpoch}',
    );

    // Selected customer information.
    String? selectedCustomer;
    int? selectedCustomerId;

    // Default invoice date.
    DateTime selectedDate = DateTime.now();

    // Invoice item controllers.
    final itemDescriptionController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final unitPriceController = TextEditingController(text: '0');

    // Invoice calculation values.
    double itemTotal = 0;
    List<Map<String, dynamic>> invoiceItems = [];
    double subtotal = 0;
    double discount = 0;
    double taxPercent = 0;
    double taxAmount = 0;
    double grandTotal = 0;

    // Load real customers from SQLite database.
    final customers = await DatabaseHelper.getCustomers();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              // ============================================================
              // CREATE INVOICE TITLE
              // ============================================================

              title: const Row(
                children: [
                  Icon(Icons.receipt_long),
                  SizedBox(width: 10),
                  Text('Create Invoice'),
                ],
              ),

              // ============================================================
              // CREATE INVOICE CONTENT
              // ============================================================
              content: SizedBox(
                width: 550,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ======================================================
                      // INVOICE DETAILS
                      // ======================================================

                      const Text(
                        'Invoice Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Customer dropdown.
                      DropdownButtonFormField<String>(
                        initialValue: selectedCustomer,
                        decoration: const InputDecoration(
                          labelText: 'Customer',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        hint: const Text('Select Customer'),
                        items: customers.map((customer) {
                          return DropdownMenuItem<String>(
                            value: customer['id'].toString(),
                            child: Text(
                              '${customer['name']} - ${customer['phone']}',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedCustomer = value;
                              selectedCustomerId = int.tryParse(value);
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 18),

                      // Invoice number.
                      TextField(
                        controller: invoiceNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Invoice Number',
                          prefixIcon: Icon(Icons.numbers),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Invoice date picker.
                      InkWell(
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );

                          if (pickedDate != null) {
                            setDialogState(() {
                              selectedDate = pickedDate;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Invoice Date',
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            '${selectedDate.day.toString().padLeft(2, '0')}/'
                            '${selectedDate.month.toString().padLeft(2, '0')}/'
                            '${selectedDate.year}',
                          ),
                        ),
                      ),

                      // ======================================================
                      // INVOICE ITEM
                      // ======================================================
                      const SizedBox(height: 30),
                      const Divider(),
                      const SizedBox(height: 15),

                      const Text(
                        'Invoice Item',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Item description.
                      TextField(
                        controller: itemDescriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Enter product or service',
                          prefixIcon: Icon(Icons.inventory_2_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Quantity + unit price.
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: quantityController,
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                setDialogState(() {
                                  final quantity = double.tryParse(value) ?? 0;

                                  final unitPrice =
                                      double.tryParse(
                                        unitPriceController.text,
                                      ) ??
                                      0;

                                  itemTotal = quantity * unitPrice;
                                });
                              },
                              decoration: const InputDecoration(
                                labelText: 'Quantity',
                                prefixIcon: Icon(Icons.numbers),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),

                          const SizedBox(width: 15),

                          Expanded(
                            child: TextField(
                              controller: unitPriceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (value) {
                                setDialogState(() {
                                  final quantity =
                                      double.tryParse(
                                        quantityController.text,
                                      ) ??
                                      0;

                                  final unitPrice = double.tryParse(value) ?? 0;

                                  itemTotal = quantity * unitPrice;
                                });
                              },
                              decoration: const InputDecoration(
                                labelText: 'Unit Price',
                                prefixIcon: Icon(Icons.attach_money),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Current item total.
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Item Total',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Rs. ${itemTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Add item button.
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final description = itemDescriptionController.text
                                .trim();

                            final quantity =
                                double.tryParse(quantityController.text) ?? 0;

                            final unitPrice =
                                double.tryParse(unitPriceController.text) ?? 0;

                            // Validate description.
                            if (description.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please enter an item description.',
                                  ),
                                ),
                              );
                              return;
                            }

                            // Validate quantity.
                            if (quantity <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Quantity must be greater than 0.',
                                  ),
                                ),
                              );
                              return;
                            }

                            // Validate price.
                            if (unitPrice <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Unit price must be greater than 0.',
                                  ),
                                ),
                              );
                              return;
                            }

                            setDialogState(() {
                              final total = quantity * unitPrice;

                              // Add item to temporary invoice item list.
                              invoiceItems.add({
                                'description': description,
                                'quantity': quantity,
                                'unitPrice': unitPrice,
                                'total': total,
                              });

                              // Update calculations.
                              subtotal += total;

                              taxAmount =
                                  (subtotal - discount) * taxPercent / 100;

                              grandTotal = subtotal - discount + taxAmount;

                              // Reset item inputs.
                              itemDescriptionController.clear();
                              quantityController.text = '1';
                              unitPriceController.text = '0';
                              itemTotal = 0;
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Item'),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ======================================================
                      // ADDED ITEMS
                      // ======================================================
                      if (invoiceItems.isNotEmpty) ...[
                        const Divider(),
                        const SizedBox(height: 15),

                        const Text(
                          'Added Items',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        ...invoiceItems.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text('${index + 1}'),
                              ),
                              title: Text(
                                item['description'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${item['quantity']} × Rs. '
                                '${item['unitPrice'].toStringAsFixed(2)}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Rs. ${item['total'].toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  // Delete item.
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () {
                                      setDialogState(() {
                                        subtotal -= item['total'];

                                        taxAmount =
                                            (subtotal - discount) *
                                            taxPercent /
                                            100;

                                        grandTotal =
                                            subtotal - discount + taxAmount;

                                        invoiceItems.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),

                        const SizedBox(height: 15),

                        // ====================================================
                        // TAX
                        // ====================================================
                        TextField(
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (value) {
                            setDialogState(() {
                              taxPercent = double.tryParse(value) ?? 0;

                              if (taxPercent < 0) {
                                taxPercent = 0;
                              }

                              if (taxPercent > 100) {
                                taxPercent = 100;
                              }

                              taxAmount =
                                  (subtotal - discount) * taxPercent / 100;

                              grandTotal = subtotal - discount + taxAmount;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Tax',
                            hintText: 'Enter tax percentage',
                            prefixIcon: Icon(Icons.percent),
                            suffixText: '%',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 15),

                        // Tax amount.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tax Amount',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Rs. ${taxAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),
                        const Divider(),
                        const SizedBox(height: 10),

                        // Subtotal.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Subtotal',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Rs. ${subtotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        // Discount.
                        TextField(
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (value) {
                            setDialogState(() {
                              discount = double.tryParse(value) ?? 0;

                              if (discount < 0) {
                                discount = 0;
                              }

                              if (discount > subtotal) {
                                discount = subtotal;
                              }

                              taxAmount =
                                  (subtotal - discount) * taxPercent / 100;

                              grandTotal = subtotal - discount + taxAmount;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Discount',
                            hintText: 'Enter discount amount',
                            prefixIcon: Icon(Icons.discount_outlined),
                            prefixText: 'Rs. ',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Grand total.
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Grand Total',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Rs. ${grandTotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ============================================================
              // CREATE INVOICE ACTION BUTTONS
              // ============================================================
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),

                FilledButton.icon(
                  onPressed: () async {
                    // Customer validation.
                    if (selectedCustomerId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a customer.'),
                        ),
                      );
                      return;
                    }

                    // Item validation.
                    if (invoiceItems.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please add at least one item.'),
                        ),
                      );
                      return;
                    }

                    final now = DateTime.now().toIso8601String();

                    // Invoice database record.
                    final invoice = {
                      'invoice_number': invoiceNumberController.text.trim(),
                      'customer_id': selectedCustomerId!,
                      'invoice_date': selectedDate.toIso8601String(),
                      'subtotal': subtotal,
                      'discount': discount,
                      'tax_percent': taxPercent,
                      'tax_amount': taxAmount,
                      'grand_total': grandTotal,

                      // New invoices start as Draft.
                      'status': 'Draft',

                      'created_at': now,
                      'updated_at': now,
                    };

                    // Convert UI items into database items.
                    final items = invoiceItems.map((item) {
                      return {
                        'description': item['description'],
                        'quantity': item['quantity'],
                        'unit_price': item['unitPrice'],
                        'total': item['total'],
                      };
                    }).toList();

                    try {
                      // Save invoice + items in one database transaction.
                      await DatabaseHelper.saveInvoiceWithItems(
                        invoice: invoice,
                        items: items,
                      );

                      if (!mounted) return;

                      // Refresh invoice list immediately.
                      await _loadInvoices();

                      // Close create dialog.
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invoice saved successfully.'),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to save invoice: $e')),
                      );
                    }
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // LOAD INVOICES
  // ============================================================

  Future<void> _loadInvoices() async {
    final data = await DatabaseHelper.getInvoices();

    if (!mounted) return;

    setState(() {
      invoices = data;

      // Apply current search + status filter after refreshing.
      filteredInvoices = invoices.where((invoice) {
        final invoiceNumber =
            invoice['invoice_number']?.toString().toLowerCase() ?? '';

        final customerName =
            invoice['customer_name']?.toString().toLowerCase() ?? '';

        final customerPhone =
            invoice['customer_phone']?.toString().toLowerCase() ?? '';

        final status = invoice['status']?.toString() ?? 'Draft';

        final matchesSearch =
            invoiceSearchQuery.isEmpty ||
            invoiceNumber.contains(invoiceSearchQuery) ||
            customerName.contains(invoiceSearchQuery) ||
            customerPhone.contains(invoiceSearchQuery);

        final matchesStatus =
            selectedStatus == 'All' || status == selectedStatus;

        return matchesSearch && matchesStatus;
      }).toList();

      isLoadingInvoices = false;
    });
  }

  // ============================================================
  // SEARCH + STATUS FILTER
  // ============================================================

  void _searchInvoices(String query) {
    final searchQuery = query.trim().toLowerCase();

    setState(() {
      invoiceSearchQuery = searchQuery;

      filteredInvoices = invoices.where((invoice) {
        final invoiceNumber =
            invoice['invoice_number']?.toString().toLowerCase() ?? '';

        final customerName =
            invoice['customer_name']?.toString().toLowerCase() ?? '';

        final customerPhone =
            invoice['customer_phone']?.toString().toLowerCase() ?? '';

        final status = invoice['status']?.toString() ?? 'Draft';

        // Search matching.
        final matchesSearch =
            searchQuery.isEmpty ||
            invoiceNumber.contains(searchQuery) ||
            customerName.contains(searchQuery) ||
            customerPhone.contains(searchQuery);

        // Status matching.
        final matchesStatus =
            selectedStatus == 'All' || status == selectedStatus;

        // Invoice must match BOTH conditions.
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  // ============================================================
  // EDIT INVOICE
  // ============================================================

  Future<void> _showEditInvoiceDialog(Map<String, dynamic> invoice) async {
    // Load customers.
    final customers = await DatabaseHelper.getCustomers();

    final invoiceId = invoice['id'] as int;

    // Load existing invoice items.
    final existingItems = await DatabaseHelper.getInvoiceItems(invoiceId);

    // Invoice number controller.
    final invoiceNumberController = TextEditingController(
      text: invoice['invoice_number'].toString(),
    );

    // Existing customer.
    String? selectedCustomer = invoice['customer_id'].toString();

    int? selectedCustomerId = invoice['customer_id'] as int?;

    // Existing invoice date.
    DateTime selectedDate =
        DateTime.tryParse(invoice['invoice_date'].toString()) ?? DateTime.now();

    // New item controllers.
    final itemDescriptionController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final unitPriceController = TextEditingController(text: '0');

    double itemTotal = 0;

    // Convert database items into UI items.
    List<Map<String, dynamic>> invoiceItems = existingItems.map((item) {
      final quantity = double.tryParse(item['quantity'].toString()) ?? 0;

      final unitPrice = double.tryParse(item['unit_price'].toString()) ?? 0;

      final total = double.tryParse(item['total'].toString()) ?? 0;

      return {
        'description': item['description'].toString(),
        'quantity': quantity,
        'unitPrice': unitPrice,
        'total': total,
      };
    }).toList();

    // Calculate existing subtotal.
    double subtotal = invoiceItems.fold(
      0,
      (sum, item) => sum + (item['total'] as double),
    );

    // Existing discount.
    double discount = double.tryParse(invoice['discount'].toString()) ?? 0;

    // Existing tax percentage.
    double taxPercent = double.tryParse(invoice['tax_percent'].toString()) ?? 0;

    // Calculate tax and grand total.
    double taxAmount = (subtotal - discount) * taxPercent / 100;

    double grandTotal = subtotal - discount + taxAmount;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              // ============================================================
              // EDIT TITLE
              // ============================================================

              title: const Row(
                children: [
                  Icon(Icons.edit_outlined),
                  SizedBox(width: 10),
                  Text('Edit Invoice'),
                ],
              ),

              // ============================================================
              // EDIT CONTENT
              // ============================================================
              content: SizedBox(
                width: 550,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Invoice Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Customer dropdown.
                      DropdownButtonFormField<String>(
                        initialValue: selectedCustomer,
                        decoration: const InputDecoration(
                          labelText: 'Customer',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        items: customers.map((customer) {
                          return DropdownMenuItem<String>(
                            value: customer['id'].toString(),
                            child: Text(
                              '${customer['name']} - '
                              '${customer['phone']}',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedCustomer = value;
                              selectedCustomerId = int.tryParse(value);
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 18),

                      // Invoice number.
                      TextField(
                        controller: invoiceNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Invoice Number',
                          prefixIcon: Icon(Icons.numbers),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Invoice date.
                      InkWell(
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );

                          if (pickedDate != null) {
                            setDialogState(() {
                              selectedDate = pickedDate;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Invoice Date',
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            '${selectedDate.day.toString().padLeft(2, '0')}/'
                            '${selectedDate.month.toString().padLeft(2, '0')}/'
                            '${selectedDate.year}',
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                      const Divider(),
                      const SizedBox(height: 15),

                      // ======================================================
                      // EXISTING INVOICE ITEMS
                      // ======================================================
                      const Text(
                        'Invoice Items',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      ...invoiceItems.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(child: Text('${index + 1}')),
                            title: Text(
                              item['description'].toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${item['quantity']} × Rs. '
                              '${(item['unitPrice'] as double).toStringAsFixed(2)}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Rs. '
                                  '${(item['total'] as double).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                // Delete existing item.
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () {
                                    setDialogState(() {
                                      subtotal -= item['total'] as double;

                                      invoiceItems.removeAt(index);

                                      if (discount > subtotal) {
                                        discount = subtotal;
                                      }

                                      taxAmount =
                                          (subtotal - discount) *
                                          taxPercent /
                                          100;

                                      grandTotal =
                                          subtotal - discount + taxAmount;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 15),

                      // ======================================================
                      // ADD NEW ITEM
                      // ======================================================
                      TextField(
                        controller: itemDescriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Enter product or service',
                          prefixIcon: Icon(Icons.inventory_2_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 15),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: quantityController,
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                setDialogState(() {
                                  final quantity = double.tryParse(value) ?? 0;

                                  final unitPrice =
                                      double.tryParse(
                                        unitPriceController.text,
                                      ) ??
                                      0;

                                  itemTotal = quantity * unitPrice;
                                });
                              },
                              decoration: const InputDecoration(
                                labelText: 'Quantity',
                                prefixIcon: Icon(Icons.numbers),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),

                          const SizedBox(width: 15),

                          Expanded(
                            child: TextField(
                              controller: unitPriceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (value) {
                                setDialogState(() {
                                  final quantity =
                                      double.tryParse(
                                        quantityController.text,
                                      ) ??
                                      0;

                                  final unitPrice = double.tryParse(value) ?? 0;

                                  itemTotal = quantity * unitPrice;
                                });
                              },
                              decoration: const InputDecoration(
                                labelText: 'Unit Price',
                                prefixIcon: Icon(Icons.attach_money),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // New item total.
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Item Total',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Rs. '
                              '${itemTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Add new item.
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final description = itemDescriptionController.text
                                .trim();

                            final quantity =
                                double.tryParse(quantityController.text) ?? 0;

                            final unitPrice =
                                double.tryParse(unitPriceController.text) ?? 0;

                            if (description.isEmpty ||
                                quantity <= 0 ||
                                unitPrice <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please enter valid item details.',
                                  ),
                                ),
                              );
                              return;
                            }

                            setDialogState(() {
                              final total = quantity * unitPrice;

                              invoiceItems.add({
                                'description': description,
                                'quantity': quantity,
                                'unitPrice': unitPrice,
                                'total': total,
                              });

                              subtotal += total;

                              taxAmount =
                                  (subtotal - discount) * taxPercent / 100;

                              grandTotal = subtotal - discount + taxAmount;

                              // Reset item fields.
                              itemDescriptionController.clear();
                              quantityController.text = '1';
                              unitPriceController.text = '0';
                              itemTotal = 0;
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Item'),
                        ),
                      ),

                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 15),

                      // ======================================================
                      // TAX
                      // ======================================================
                      TextField(
                        controller: TextEditingController(
                          text: taxPercent.toString(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (value) {
                          setDialogState(() {
                            taxPercent = double.tryParse(value) ?? 0;

                            if (taxPercent < 0) {
                              taxPercent = 0;
                            }

                            if (taxPercent > 100) {
                              taxPercent = 100;
                            }

                            taxAmount =
                                (subtotal - discount) * taxPercent / 100;

                            grandTotal = subtotal - discount + taxAmount;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Tax',
                          suffixText: '%',
                          prefixIcon: Icon(Icons.percent),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 15),

                      Text(
                        'Tax Amount: Rs. '
                        '${taxAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),

                      const SizedBox(height: 15),

                      Text(
                        'Subtotal: Rs. '
                        '${subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 15),

                      // Discount.
                      TextField(
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (value) {
                          setDialogState(() {
                            discount = double.tryParse(value) ?? 0;

                            if (discount < 0) {
                              discount = 0;
                            }

                            if (discount > subtotal) {
                              discount = subtotal;
                            }

                            taxAmount =
                                (subtotal - discount) * taxPercent / 100;

                            grandTotal = subtotal - discount + taxAmount;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Discount',
                          prefixText: 'Rs. ',
                          prefixIcon: Icon(Icons.discount_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Grand total.
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Grand Total',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Rs. '
                              '${grandTotal.toStringAsFixed(2)}',
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

              // ============================================================
              // EDIT ACTION BUTTONS
              // ============================================================
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),

                FilledButton.icon(
                  onPressed: () async {
                    if (selectedCustomerId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a customer.'),
                        ),
                      );
                      return;
                    }

                    if (invoiceItems.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please add at least one item.'),
                        ),
                      );
                      return;
                    }

                    // Updated invoice data.
                    final updatedInvoice = {
                      'invoice_number': invoiceNumberController.text.trim(),
                      'customer_id': selectedCustomerId!,
                      'invoice_date': selectedDate.toIso8601String(),
                      'subtotal': subtotal,
                      'discount': discount,
                      'tax_percent': taxPercent,
                      'tax_amount': taxAmount,
                      'grand_total': grandTotal,

                      // Keep existing status.
                      'status': invoice['status'],

                      'updated_at': DateTime.now().toIso8601String(),
                    };

                    // Convert items to database format.
                    final updatedItems = invoiceItems.map((item) {
                      return {
                        'description': item['description'],
                        'quantity': item['quantity'],
                        'unit_price': item['unitPrice'],
                        'total': item['total'],
                      };
                    }).toList();

                    try {
                      await DatabaseHelper.updateInvoiceWithItems(
                        invoiceId: invoiceId,
                        invoice: updatedInvoice,
                        items: updatedItems,
                      );

                      if (!mounted) return;

                      // Close edit dialog.
                      Navigator.pop(context);

                      // Refresh invoice list.
                      await _loadInvoices();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invoice updated successfully.'),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update invoice: $e')),
                      );
                    }
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // INVOICE DETAILS
  // ============================================================

  Future<void> _showInvoiceDetails(Map<String, dynamic> invoice) async {
    final invoiceId = invoice['id'] as int;

    // Load invoice items.
    final items = await DatabaseHelper.getInvoiceItems(invoiceId);

    // Load payment summary.
    final paidAmount = await DatabaseHelper.getInvoicePaidAmount(invoiceId);
    // Load payment history.
    final payments = await DatabaseHelper.getInvoicePayments(invoiceId);

    final grandTotal = (invoice['grand_total'] as num).toDouble();

    final remainingAmount = grandTotal - paidAmount;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          // Invoice number title + Add Payment button.
          title: Row(
            children: [
              const Icon(Icons.receipt_long),

              const SizedBox(width: 10),

              Expanded(child: Text(invoice['invoice_number'].toString())),

              const SizedBox(width: 15),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);

                  _showAddPaymentDialog(invoice);
                },
                icon: const Icon(Icons.payment_outlined),
                label: const Text('Add Payment'),
              ),
            ],
          ),

          // ============================================================
          // DETAILS CONTENT
          // ============================================================
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer: '
                    '${invoice['customer_name'] ?? 'Unknown Customer'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    'Phone: '
                    '${invoice['customer_phone'] ?? '-'}',
                  ),

                  const SizedBox(height: 5),

                  Text(
                    'Date: '
                    '${invoice['invoice_date'].toString().split('T').first}',
                  ),

                  const SizedBox(height: 5),

                  // Current status.
                  // Current invoice status
                  DropdownButtonFormField<String>(
                    initialValue: invoice['status'] ?? 'Draft',
                    decoration: const InputDecoration(
                      labelText: 'Invoice Status',
                      prefixIcon: Icon(Icons.info_outline),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Draft', child: Text('Draft')),
                      DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                      DropdownMenuItem(
                        value: 'Partially Paid',
                        child: Text('Partially Paid'),
                      ),
                      DropdownMenuItem(
                        value: 'Overdue',
                        child: Text('Overdue'),
                      ),
                      DropdownMenuItem(
                        value: 'Cancelled',
                        child: Text('Cancelled'),
                      ),
                    ],
                    onChanged: (value) async {
                      if (value == null) return;

                      try {
                        await DatabaseHelper.updateInvoiceStatus(
                          invoice['id'] as int,
                          value,
                        );

                        if (!mounted) return;

                        await _loadInvoices();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Invoice status updated to $value.'),
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update status: $e'),
                          ),
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),

                  const Text(
                    'Items',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  // Invoice items.
                  ...items.map((item) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item['description'].toString()),
                      subtitle: Text(
                        '${item['quantity']} × '
                        'Rs. '
                        '${double.parse(item['unit_price'].toString()).toStringAsFixed(2)}',
                      ),
                      trailing: Text(
                        'Rs. '
                        '${double.parse(item['total'].toString()).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  }),

                  const Divider(),
                  const SizedBox(height: 10),

                  // Invoice summary.
                  _invoiceSummaryRow('Subtotal', invoice['subtotal']),

                  _invoiceSummaryRow('Discount', invoice['discount']),

                  _invoiceSummaryRow('Tax', invoice['tax_amount']),

                  const Divider(),

                  _invoiceSummaryRow(
                    'Grand Total',
                    invoice['grand_total'],
                    isGrandTotal: true,
                  ),

                  const SizedBox(height: 20),

                  const Divider(),

                  const SizedBox(height: 10),

                  const Text(
                    'Payment History',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  if (payments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'No payments recorded yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ...payments.map((payment) {
                      final amount = (payment['amount'] as num).toDouble();

                      final paymentDate = payment['payment_date']
                          .toString()
                          .split('T')
                          .first;

                      final method =
                          payment['payment_method']?.toString() ?? 'Unknown';

                      final note = payment['note']?.toString() ?? '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.payment),
                          ),

                          title: Text(
                            'Rs. ${amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),

                          subtitle: Text(
                            '$paymentDate • $method'
                            '${note.isNotEmpty ? '\nNote: $note' : ''}',
                          ),

                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Delete Payment',
                            onPressed: () async {
                              final shouldDelete = await showDialog<bool>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Delete Payment?'),
                                    content: const Text(
                                      'Are you sure you want to delete this payment?\n'
                                      'The invoice paid amount and status will be updated.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context, false);
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton.icon(
                                        onPressed: () {
                                          Navigator.pop(context, true);
                                        },
                                        icon: const Icon(Icons.delete_outline),
                                        label: const Text('Delete Payment'),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (shouldDelete != true) {
                                return;
                              }

                              try {
                                await DatabaseHelper.deletePayment(
                                  payment['id'] as int,
                                );

                                final updatedPaidAmount =
                                    await DatabaseHelper.getInvoicePaidAmount(
                                      invoice['id'] as int,
                                    );

                                final invoiceTotal =
                                    (invoice['grand_total'] as num).toDouble();

                                String newStatus;

                                if (updatedPaidAmount <= 0) {
                                  newStatus = 'Draft';
                                } else if (updatedPaidAmount >= invoiceTotal) {
                                  newStatus = 'Paid';
                                } else {
                                  newStatus = 'Partially Paid';
                                }

                                await DatabaseHelper.updateInvoiceStatus(
                                  invoice['id'] as int,
                                  newStatus,
                                );

                                if (!mounted) return;

                                Navigator.pop(context);

                                await _loadInvoices();

                                if (!mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Payment deleted successfully.',
                                    ),
                                  ),
                                );

                                // Re-open updated invoice details.
                                _showInvoiceDetails(invoice);
                              } catch (e) {
                                if (!mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to delete payment: $e',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 8),

                  _invoiceSummaryRow('Paid Amount', paidAmount),

                  _invoiceSummaryRow(
                    'Remaining',
                    remainingAmount,
                    isGrandTotal: true,
                  ),
                ],
              ),
            ),
          ),

          // ============================================================
          // DETAILS ACTIONS
          // ============================================================
          // ============================================================
          // DETAILS ACTIONS
          // ============================================================
          actions: [
            // Edit invoice.
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);

                _showEditInvoiceDialog(invoice);
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Invoice'),
            ),

            // Delete invoice.
            TextButton.icon(
              onPressed: () async {
                final shouldDelete = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Delete Invoice?'),
                      content: const Text(
                        'Are you sure you want to delete this invoice?\n'
                        'This action cannot be undone.',
                      ),
                      actions: [
                        // Cancel delete.
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context, false);
                          },
                          icon: const Icon(Icons.close),
                          label: const Text('Cancel'),
                        ),

                        // Confirm delete.
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(context, true);
                          },
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete Invoice'),
                        ),
                      ],
                    );
                  },
                );

                if (shouldDelete != true) {
                  return;
                }

                try {
                  await DatabaseHelper.deleteInvoice(invoice['id'] as int);

                  if (!mounted) return;

                  Navigator.pop(context);

                  // Refresh list after deletion.
                  await _loadInvoices();

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invoice deleted successfully.'),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete invoice: $e')),
                  );
                }
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete Invoice'),
            ),

            // Close details dialog.
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.close),
              label: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // INVOICE SUMMARY ROW
  // ============================================================

  Widget _invoiceSummaryRow(
    String label,
    dynamic value, {
    bool isGrandTotal = false,
  }) {
    final amount = double.tryParse(value.toString()) ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isGrandTotal ? 18 : 15,
              fontWeight: isGrandTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            'Rs. '
            '${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isGrandTotal ? 18 : 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INITIAL LOAD
  // ============================================================

  @override
  void initState() {
    super.initState();

    // Load invoices when the page opens.
    _loadInvoices();
  }

  // ============================================================
  // MAIN UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invoices')),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================================
            // PAGE HEADER
            // ==========================================================

            const Text(
              'Invoice Management',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              'Create and manage your business invoices',
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 25),

            // ==========================================================
            // SEARCH + STATUS FILTER + CREATE BUTTON
            // ==========================================================
            Row(
              children: [
                // Search field.
                Expanded(
                  child: TextField(
                    onChanged: _searchInvoices,
                    decoration: InputDecoration(
                      hintText: 'Search Invoices...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Status filter.
                DropdownButton<String>(
                  value: selectedStatus,
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Status')),
                    DropdownMenuItem(value: 'Draft', child: Text('Draft')),
                    DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                    DropdownMenuItem(
                      value: 'Partially Paid',
                      child: Text('Partially Paid'),
                    ),
                    DropdownMenuItem(value: 'Overdue', child: Text('Overdue')),
                    DropdownMenuItem(
                      value: 'Cancelled',
                      child: Text('Cancelled'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      selectedStatus = value;
                    });

                    // Reapply search with new status.
                    _searchInvoices(invoiceSearchQuery);
                  },
                ),

                const SizedBox(width: 15),

                // Create invoice button.
                FilledButton.icon(
                  onPressed: _showCreateInvoiceDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Invoice'),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // ==========================================================
            // INVOICE LIST
            // ==========================================================
            Expanded(
              child: isLoadingInvoices
                  ? const Center(child: CircularProgressIndicator())
                  // ======================================================
                  // EMPTY STATE
                  // ======================================================
                  : filteredInvoices.isEmpty
                  ? Card(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.receipt_long, size: 70),

                            const SizedBox(height: 15),

                            // Different message for
                            // search/filter empty state.
                            Text(
                              invoiceSearchQuery.isNotEmpty ||
                                      selectedStatus != 'All'
                                  ? 'No matching invoices found'
                                  : 'No invoices yet',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Different description for
                            // search/filter empty state.
                            Text(
                              invoiceSearchQuery.isNotEmpty ||
                                      selectedStatus != 'All'
                                  ? 'Try changing your search or status filter.'
                                  : 'Create your first invoice to get started.',
                            ),

                            const SizedBox(height: 20),

                            // Only show create button when
                            // there are no invoices at all.
                            if (invoiceSearchQuery.isEmpty &&
                                selectedStatus == 'All')
                              FilledButton.icon(
                                onPressed: _showCreateInvoiceDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Create Invoice'),
                              ),
                          ],
                        ),
                      ),
                    )
                  // ======================================================
                  // INVOICE LIST CARD
                  // ======================================================
                  : Card(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),

                        // Display filtered invoices.
                        itemCount: filteredInvoices.length,

                        separatorBuilder: (context, index) {
                          return const Divider();
                        },

                        itemBuilder: (context, index) {
                          final invoice = filteredInvoices[index];

                          return ListTile(
                            // Invoice icon.
                            leading: const CircleAvatar(
                              child: Icon(Icons.receipt_long),
                            ),

                            // Invoice number.
                            title: Text(
                              invoice['invoice_number'].toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            // Customer information.
                            subtitle: Text(
                              '${invoice['customer_name'] ?? 'Unknown Customer'}\n'
                              '${invoice['customer_phone'] ?? ''}\n'
                              'Date: ${invoice['invoice_date'].toString().split('T').first}\n'
                              'Status: ${invoice['status']}',
                            ),

                            isThreeLine: true,

                            // Open invoice details.
                            onTap: () {
                              _showInvoiceDetails(invoice);
                            },

                            // Grand total.
                            trailing: Text(
                              'Rs. '
                              '${double.parse(invoice['grand_total'].toString()).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
  // ============================================================
  // ADD PAYMENT
  // ============================================================

  Future<void> _showAddPaymentDialog(Map<String, dynamic> invoice) async {
    // Payment amount controller.
    final amountController = TextEditingController();

    // Optional payment note controller.
    final noteController = TextEditingController();

    // Default payment date.
    DateTime selectedPaymentDate = DateTime.now();

    // Default payment method.
    String selectedPaymentMethod = 'Cash';

    // Invoice total.
    final invoiceTotal =
        double.tryParse(invoice['grand_total'].toString()) ?? 0;

    // Get already paid amount.
    final paidAmount = await DatabaseHelper.getInvoicePaidAmount(
      invoice['id'] as int,
    );

    // Calculate remaining amount.
    final remainingAmount = invoiceTotal - paidAmount;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              // ==========================================================
              // TITLE
              // ==========================================================

              title: const Row(
                children: [
                  Icon(Icons.payment),
                  SizedBox(width: 10),
                  Text('Add Payment'),
                ],
              ),

              // ==========================================================
              // CONTENT
              // ==========================================================
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Invoice total.
                      _invoiceSummaryRow('Invoice Total', invoiceTotal),

                      // Already paid amount.
                      _invoiceSummaryRow('Already Paid', paidAmount),

                      // Remaining amount.
                      _invoiceSummaryRow(
                        'Remaining',
                        remainingAmount,
                        isGrandTotal: true,
                      ),

                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 15),

                      // ====================================================
                      // PAYMENT AMOUNT
                      // ====================================================
                      TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Payment Amount',
                          hintText: 'Enter amount paid',
                          prefixIcon: Icon(Icons.attach_money),
                          prefixText: 'Rs. ',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ====================================================
                      // PAYMENT DATE
                      // ====================================================
                      InkWell(
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedPaymentDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );

                          if (pickedDate != null) {
                            setDialogState(() {
                              selectedPaymentDate = pickedDate;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Payment Date',
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            '${selectedPaymentDate.day.toString().padLeft(2, '0')}/'
                            '${selectedPaymentDate.month.toString().padLeft(2, '0')}/'
                            '${selectedPaymentDate.year}',
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ====================================================
                      // PAYMENT METHOD
                      // ====================================================
                      DropdownButtonFormField<String>(
                        initialValue: selectedPaymentMethod,
                        decoration: const InputDecoration(
                          labelText: 'Payment Method',
                          prefixIcon: Icon(Icons.account_balance_wallet),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                          DropdownMenuItem(value: 'Card', child: Text('Card')),
                          DropdownMenuItem(
                            value: 'Bank Transfer',
                            child: Text('Bank Transfer'),
                          ),
                          DropdownMenuItem(
                            value: 'Other',
                            child: Text('Other'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setDialogState(() {
                            selectedPaymentMethod = value;
                          });
                        },
                      ),

                      const SizedBox(height: 18),

                      // ====================================================
                      // NOTE
                      // ====================================================
                      TextField(
                        controller: noteController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Note (Optional)',
                          hintText: 'Add a payment note',
                          prefixIcon: Icon(Icons.note_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ==========================================================
              // ACTION BUTTONS
              // ==========================================================
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),

                FilledButton.icon(
                  onPressed: () async {
                    // Convert entered amount to number.
                    final amount =
                        double.tryParse(amountController.text.trim()) ?? 0;

                    // Validate amount.
                    if (amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Payment amount must be greater than 0.',
                          ),
                        ),
                      );
                      return;
                    }

                    // Prevent overpayment.
                    if (amount > remainingAmount) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Payment cannot exceed remaining amount '
                            '(Rs. ${remainingAmount.toStringAsFixed(2)}).',
                          ),
                        ),
                      );
                      return;
                    }

                    // Payment database record.
                    final payment = {
                      'invoice_id': invoice['id'] as int,
                      'amount': amount,
                      'payment_date': selectedPaymentDate.toIso8601String(),
                      'payment_method': selectedPaymentMethod,
                      'note': noteController.text.trim().isEmpty
                          ? null
                          : noteController.text.trim(),
                      'created_at': DateTime.now().toIso8601String(),
                    };

                    try {
                      // Save payment to SQLite.
                      await DatabaseHelper.insertPayment(payment);

                      // Get the updated total paid amount.
                      final updatedPaidAmount =
                          await DatabaseHelper.getInvoicePaidAmount(
                            invoice['id'] as int,
                          );

                      // Determine the new invoice status.
                      String newStatus;

                      if (updatedPaidAmount <= 0) {
                        newStatus = 'Draft';
                      } else if (updatedPaidAmount >= invoiceTotal) {
                        newStatus = 'Paid';
                      } else {
                        newStatus = 'Partially Paid';
                      }

                      // Update invoice status automatically.
                      await DatabaseHelper.updateInvoiceStatus(
                        invoice['id'] as int,
                        newStatus,
                      );
                      if (!mounted) return;

                      // Close payment dialog.
                      Navigator.pop(context);

                      // Refresh invoice list so the new status appears immediately.
                      await _loadInvoices();

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Payment added successfully.'),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to add payment: $e')),
                      );
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save Payment'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
