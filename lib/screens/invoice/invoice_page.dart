import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../db/database_helper.dart';
import '../../service/invoice_pdf_service.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  // ============================================================
  // INVOICE LIST DATA
  // ============================================================

  List<Map<String, dynamic>> invoices = [];
  List<Map<String, dynamic>> filteredInvoices = [];

  bool isLoadingInvoices = true;

  String invoiceSearchQuery = '';
  String selectedStatus = 'All';

  // ============================================================
  // CREATE INVOICE
  // ============================================================

  Future<void> _showCreateInvoiceDialog() async {
    final invoiceNumberController = TextEditingController(
      text: 'INV-${DateTime.now().millisecondsSinceEpoch}',
    );

    String? selectedCustomer;
    int? selectedCustomerId;

    DateTime selectedDate = DateTime.now();
    DateTime selectedDueDate = DateTime.now().add(const Duration(days: 30));

    final itemDescriptionController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final unitPriceController = TextEditingController(text: '0');

    double itemTotal = 0;
    List<Map<String, dynamic>> invoiceItems = [];

    double subtotal = 0;
    double discount = 0;
    double taxPercent = 0;
    double taxAmount = 0;
    double grandTotal = 0;

    final customers = await DatabaseHelper.getCustomers();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  _buildDialogIcon(Icons.receipt_long_outlined),
                  const SizedBox(width: 10),
                  const Text('Create Invoice'),
                ],
              ),
              content: SizedBox(
                width: 550,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(
                        'Invoice Details',
                        Icons.description_outlined,
                      ),

                      const SizedBox(height: 18),

                      DropdownButtonFormField<String>(
                        initialValue: selectedCustomer,
                        decoration: _inputDecoration(
                          'Customer',
                          Icons.person_outline,
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

                      const SizedBox(height: 16),

                      TextField(
                        controller: invoiceNumberController,
                        decoration: _inputDecoration(
                          'Invoice Number',
                          Icons.numbers,
                        ),
                      ),

                      const SizedBox(height: 16),

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

                              if (selectedDueDate.isBefore(selectedDate)) {
                                selectedDueDate = selectedDate.add(
                                  const Duration(days: 30),
                                );
                              }
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: _inputDecoration(
                            'Invoice Date',
                            Icons.calendar_today_outlined,
                          ),
                          child: Text(_formatDate(selectedDate)),
                        ),
                      ),

                      const SizedBox(height: 16),

                      InkWell(
                        onTap: () async {
                          final pickedDueDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDueDate,
                            firstDate: selectedDate,
                            lastDate: DateTime(2100),
                          );

                          if (pickedDueDate != null) {
                            setDialogState(() {
                              selectedDueDate = pickedDueDate;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: _inputDecoration(
                            'Due Date',
                            Icons.event_available_outlined,
                          ),
                          child: Text(_formatDate(selectedDueDate)),
                        ),
                      ),

                      const SizedBox(height: 28),

                      _buildSectionTitle(
                        'Invoice Item',
                        Icons.inventory_2_outlined,
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: itemDescriptionController,
                        decoration: _inputDecoration(
                          'Description',
                          Icons.inventory_2_outlined,
                          hint: 'Enter product or service',
                        ),
                      ),

                      const SizedBox(height: 16),

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
                              decoration: _inputDecoration(
                                'Quantity',
                                Icons.numbers,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
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
                              decoration: _inputDecoration(
                                'Unit Price',
                                Icons.attach_money,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      _buildAmountBox(
                        'Item Total',
                        itemTotal,
                        icon: Icons.calculate_outlined,
                      ),

                      const SizedBox(height: 14),

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

                      if (invoiceItems.isNotEmpty) ...[
                        const SizedBox(height: 24),

                        _buildSectionTitle(
                          'Added Items',
                          Icons.list_alt_outlined,
                        ),

                        const SizedBox(height: 10),

                        ...invoiceItems.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                item['description'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
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
                                    'Rs. '
                                    '${item['total'].toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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

                        const SizedBox(height: 12),

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
                          decoration: _inputDecoration(
                            'Tax',
                            Icons.percent,
                            hint: 'Enter tax percentage',
                          ).copyWith(suffixText: '%'),
                        ),

                        const SizedBox(height: 14),

                        _buildCalculationRow('Tax Amount', taxAmount),

                        const SizedBox(height: 8),

                        const Divider(),

                        const SizedBox(height: 8),

                        _buildCalculationRow('Subtotal', subtotal, bold: true),

                        const SizedBox(height: 14),

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
                          decoration: _inputDecoration(
                            'Discount',
                            Icons.discount_outlined,
                            hint: 'Enter discount amount',
                          ).copyWith(prefixText: 'Rs. '),
                        ),

                        const SizedBox(height: 18),

                        _buildGrandTotalBox(grandTotal),
                      ],
                    ],
                  ),
                ),
              ),
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

                    final now = DateTime.now().toIso8601String();

                    final invoice = {
                      'invoice_number': invoiceNumberController.text.trim(),
                      'customer_id': selectedCustomerId!,
                      'invoice_date': selectedDate.toIso8601String(),
                      'due_date': selectedDueDate.toIso8601String(),
                      'subtotal': subtotal,
                      'discount': discount,
                      'tax_percent': taxPercent,
                      'tax_amount': taxAmount,
                      'grand_total': grandTotal,
                      'status': 'Draft',
                      'created_at': now,
                      'updated_at': now,
                    };

                    final items = invoiceItems.map((item) {
                      return {
                        'description': item['description'],
                        'quantity': item['quantity'],
                        'unit_price': item['unitPrice'],
                        'total': item['total'],
                      };
                    }).toList();

                    try {
                      await DatabaseHelper.saveInvoiceWithItems(
                        invoice: invoice,
                        items: items,
                      );

                      if (!mounted) return;

                      await _loadInvoices();

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

    for (final invoice in data) {
      final dueDateString = invoice['due_date']?.toString();

      if (dueDateString == null || dueDateString.isEmpty) {
        continue;
      }

      final dueDate = DateTime.tryParse(dueDateString);

      if (dueDate == null) {
        continue;
      }

      final grandTotal = (invoice['grand_total'] as num?)?.toDouble() ?? 0;

      final paidAmount = await DatabaseHelper.getInvoicePaidAmount(
        invoice['id'] as int,
      );

      final currentStatus = invoice['status']?.toString() ?? 'Draft';

      final today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );

      final invoiceDueDate = DateTime(dueDate.year, dueDate.month, dueDate.day);

      if (invoiceDueDate.isBefore(today) &&
          paidAmount < grandTotal &&
          currentStatus != 'Cancelled' &&
          currentStatus != 'Paid') {
        await DatabaseHelper.updateInvoiceStatus(
          invoice['id'] as int,
          'Overdue',
        );

        invoice['status'] = 'Overdue';
      }
    }

    if (!mounted) return;

    setState(() {
      invoices = data;

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
  // SEARCH + FILTER
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

        final matchesSearch =
            searchQuery.isEmpty ||
            invoiceNumber.contains(searchQuery) ||
            customerName.contains(searchQuery) ||
            customerPhone.contains(searchQuery);

        final matchesStatus =
            selectedStatus == 'All' || status == selectedStatus;

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  // ============================================================
  // EDIT INVOICE
  // ============================================================

  Future<void> _showEditInvoiceDialog(Map<String, dynamic> invoice) async {
    final customers = await DatabaseHelper.getCustomers();

    final invoiceId = invoice['id'] as int;

    final existingItems = await DatabaseHelper.getInvoiceItems(invoiceId);

    final invoiceNumberController = TextEditingController(
      text: invoice['invoice_number'].toString(),
    );

    String? selectedCustomer = invoice['customer_id'].toString();

    int? selectedCustomerId = invoice['customer_id'] as int?;

    DateTime selectedDate =
        DateTime.tryParse(invoice['invoice_date'].toString()) ?? DateTime.now();

    DateTime selectedDueDate =
        DateTime.tryParse(invoice['due_date']?.toString() ?? '') ??
        DateTime.now().add(const Duration(days: 30));

    final itemDescriptionController = TextEditingController();

    final quantityController = TextEditingController(text: '1');

    final unitPriceController = TextEditingController(text: '0');

    double itemTotal = 0;

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

    double subtotal = invoiceItems.fold(
      0,
      (sum, item) => sum + (item['total'] as double),
    );

    double discount = double.tryParse(invoice['discount'].toString()) ?? 0;

    double taxPercent = double.tryParse(invoice['tax_percent'].toString()) ?? 0;

    double taxAmount = (subtotal - discount) * taxPercent / 100;

    double grandTotal = subtotal - discount + taxAmount;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  _buildDialogIcon(Icons.edit_outlined),
                  const SizedBox(width: 10),
                  const Text('Edit Invoice'),
                ],
              ),
              content: SizedBox(
                width: 550,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(
                        'Invoice Details',
                        Icons.description_outlined,
                      ),

                      const SizedBox(height: 18),

                      DropdownButtonFormField<String>(
                        initialValue: selectedCustomer,
                        decoration: _inputDecoration(
                          'Customer',
                          Icons.person_outline,
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

                      const SizedBox(height: 16),

                      TextField(
                        controller: invoiceNumberController,
                        decoration: _inputDecoration(
                          'Invoice Number',
                          Icons.numbers,
                        ),
                      ),

                      const SizedBox(height: 16),

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

                              if (selectedDueDate.isBefore(selectedDate)) {
                                selectedDueDate = selectedDate.add(
                                  const Duration(days: 30),
                                );
                              }
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: _inputDecoration(
                            'Invoice Date',
                            Icons.calendar_today_outlined,
                          ),
                          child: Text(_formatDate(selectedDate)),
                        ),
                      ),

                      const SizedBox(height: 16),

                      InkWell(
                        onTap: () async {
                          final pickedDueDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDueDate,
                            firstDate: selectedDate,
                            lastDate: DateTime(2100),
                          );

                          if (pickedDueDate != null) {
                            setDialogState(() {
                              selectedDueDate = pickedDueDate;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: _inputDecoration(
                            'Due Date',
                            Icons.event_available_outlined,
                          ),
                          child: Text(_formatDate(selectedDueDate)),
                        ),
                      ),

                      const SizedBox(height: 26),

                      _buildSectionTitle(
                        'Invoice Items',
                        Icons.list_alt_outlined,
                      ),

                      const SizedBox(height: 10),

                      ...invoiceItems.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;

                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              item['description'].toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
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

                      const SizedBox(height: 12),

                      TextField(
                        controller: itemDescriptionController,
                        decoration: _inputDecoration(
                          'Description',
                          Icons.inventory_2_outlined,
                          hint: 'Enter product or service',
                        ),
                      ),

                      const SizedBox(height: 14),

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
                              decoration: _inputDecoration(
                                'Quantity',
                                Icons.numbers,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
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
                              decoration: _inputDecoration(
                                'Unit Price',
                                Icons.attach_money,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      _buildAmountBox(
                        'Item Total',
                        itemTotal,
                        icon: Icons.calculate_outlined,
                      ),

                      const SizedBox(height: 14),

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
                        decoration: _inputDecoration(
                          'Tax',
                          Icons.percent,
                        ).copyWith(suffixText: '%'),
                      ),

                      const SizedBox(height: 14),

                      _buildCalculationRow('Tax Amount', taxAmount),

                      const SizedBox(height: 8),

                      _buildCalculationRow('Subtotal', subtotal, bold: true),

                      const SizedBox(height: 14),

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
                        decoration: _inputDecoration(
                          'Discount',
                          Icons.discount_outlined,
                        ).copyWith(prefixText: 'Rs. '),
                      ),

                      const SizedBox(height: 18),

                      _buildGrandTotalBox(grandTotal),
                    ],
                  ),
                ),
              ),
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

                    final updatedInvoice = {
                      'invoice_number': invoiceNumberController.text.trim(),
                      'customer_id': selectedCustomerId!,
                      'invoice_date': selectedDate.toIso8601String(),
                      'due_date': selectedDueDate.toIso8601String(),
                      'subtotal': subtotal,
                      'discount': discount,
                      'tax_percent': taxPercent,
                      'tax_amount': taxAmount,
                      'grand_total': grandTotal,
                      'status': invoice['status'],
                      'updated_at': DateTime.now().toIso8601String(),
                    };

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

                      Navigator.pop(context);

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
  // PDF GENERATOR
  // ============================================================

  Future<void> _generateInvoicePdf(Map<String, dynamic> invoice) async {
    try {
      final items = await DatabaseHelper.getInvoiceItems(invoice['id'] as int);

      final paidAmount = await DatabaseHelper.getInvoicePaidAmount(
        invoice['id'] as int,
      );

      final pdfBytes = await InvoicePdfService.generateInvoicePdf(
        invoice: invoice,
        items: items,
        paidAmount: paidAmount,
      );

      final directory = await getApplicationDocumentsDirectory();

      final invoiceNumber = invoice['invoice_number']?.toString() ?? 'invoice';

      final file = File('${directory.path}\\$invoiceNumber.pdf');

      await file.writeAsBytes(pdfBytes);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invoice PDF saved successfully:\n${file.path}'),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to generate PDF: $e')));
    }
  }

  // ============================================================
  // INVOICE DETAILS
  // ============================================================

  Future<void> _showInvoiceDetails(Map<String, dynamic> invoice) async {
    final invoiceId = invoice['id'] as int;

    final items = await DatabaseHelper.getInvoiceItems(invoiceId);

    final paidAmount = await DatabaseHelper.getInvoicePaidAmount(invoiceId);

    final payments = await DatabaseHelper.getInvoicePayments(invoiceId);

    final grandTotal = (invoice['grand_total'] as num).toDouble();

    final remainingAmount = grandTotal - paidAmount;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              _buildDialogIcon(Icons.receipt_long_outlined),
              const SizedBox(width: 10),
              Expanded(child: Text(invoice['invoice_number'].toString())),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showAddPaymentDialog(invoice);
                },
                icon: const Icon(Icons.payment_outlined, size: 18),
                label: const Text('Payment'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  _generateInvoicePdf(invoice);
                },
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: const Text('PDF'),
              ),
            ],
          ),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailsCustomerCard(invoice),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    initialValue: invoice['status'] ?? 'Draft',
                    decoration: _inputDecoration(
                      'Invoice Status',
                      Icons.info_outline,
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

                  _buildSectionTitle('Items', Icons.list_alt_outlined),

                  const SizedBox(height: 10),

                  ...items.map((item) {
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: _buildSmallIcon(Icons.inventory_2_outlined),
                        title: Text(item['description'].toString()),
                        subtitle: Text(
                          '${item['quantity']} × Rs. '
                          '${double.parse(item['unit_price'].toString()).toStringAsFixed(2)}',
                        ),
                        trailing: Text(
                          'Rs. '
                          '${double.parse(item['total'].toString()).toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 10),

                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          _invoiceSummaryRow('Subtotal', invoice['subtotal']),
                          _invoiceSummaryRow('Discount', invoice['discount']),
                          _invoiceSummaryRow('Tax', invoice['tax_amount']),
                          const Divider(),
                          _invoiceSummaryRow(
                            'Grand Total',
                            invoice['grand_total'],
                            isGrandTotal: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  _buildSectionTitle(
                    'Payment History',
                    Icons.payments_outlined,
                  ),

                  const SizedBox(height: 10),

                  if (payments.isEmpty)
                    Card(
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            _buildSmallIcon(Icons.payment_outlined),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text('No payments recorded yet.'),
                            ),
                          ],
                        ),
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
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: _buildSmallIcon(Icons.payment_outlined),
                          title: Text(
                            'Rs. '
                            '${amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '$paymentDate • $method'
                            '${note.isNotEmpty ? '\nNote: $note' : ''}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Edit Payment',
                                onPressed: () {
                                  Navigator.pop(context);

                                  _showEditPaymentDialog(invoice, payment);
                                },
                              ),
                              IconButton(
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
                                            icon: const Icon(
                                              Icons.delete_outline,
                                            ),
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
                                        (invoice['grand_total'] as num)
                                            .toDouble();

                                    String newStatus;

                                    if (updatedPaidAmount <= 0) {
                                      newStatus = 'Draft';
                                    } else if (updatedPaidAmount >=
                                        invoiceTotal) {
                                      newStatus = 'Paid';
                                    } else {
                                      newStatus = 'Partially Paid';
                                    }

                                    await DatabaseHelper.updateInvoiceStatus(
                                      invoice['id'] as int,
                                      newStatus,
                                    );

                                    if (!mounted) {
                                      return;
                                    }

                                    Navigator.pop(context);

                                    await _loadInvoices();

                                    if (!mounted) {
                                      return;
                                    }

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Payment deleted successfully.',
                                        ),
                                      ),
                                    );

                                    _showInvoiceDetails(invoice);
                                  } catch (e) {
                                    if (!mounted) {
                                      return;
                                    }

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
                            ],
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 8),

                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
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
                ],
              ),
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);

                _showEditInvoiceDialog(invoice);
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Invoice'),
            ),

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
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context, false);
                          },
                          icon: const Icon(Icons.close),
                          label: const Text('Cancel'),
                        ),
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
  // ADD PAYMENT
  // ============================================================

  Future<void> _showAddPaymentDialog(Map<String, dynamic> invoice) async {
    final amountController = TextEditingController();

    final noteController = TextEditingController();

    DateTime selectedPaymentDate = DateTime.now();

    String selectedPaymentMethod = 'Cash';

    final invoiceTotal =
        double.tryParse(invoice['grand_total'].toString()) ?? 0;

    final paidAmount = await DatabaseHelper.getInvoicePaidAmount(
      invoice['id'] as int,
    );

    final remainingAmount = invoiceTotal - paidAmount;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  _buildDialogIcon(Icons.payment_outlined),
                  const SizedBox(width: 10),
                  const Text('Add Payment'),
                ],
              ),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _invoiceSummaryRow('Invoice Total', invoiceTotal),
                      _invoiceSummaryRow('Already Paid', paidAmount),
                      _invoiceSummaryRow(
                        'Remaining',
                        remainingAmount,
                        isGrandTotal: true,
                      ),

                      const SizedBox(height: 18),

                      const Divider(),

                      const SizedBox(height: 14),

                      TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _inputDecoration(
                          'Payment Amount',
                          Icons.attach_money,
                          hint: 'Enter amount paid',
                        ).copyWith(prefixText: 'Rs. '),
                      ),

                      const SizedBox(height: 16),

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
                          decoration: _inputDecoration(
                            'Payment Date',
                            Icons.calendar_today_outlined,
                          ),
                          child: Text(_formatDate(selectedPaymentDate)),
                        ),
                      ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        initialValue: selectedPaymentMethod,
                        decoration: _inputDecoration(
                          'Payment Method',
                          Icons.account_balance_wallet_outlined,
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

                      const SizedBox(height: 16),

                      TextField(
                        controller: noteController,
                        maxLines: 3,
                        decoration: _inputDecoration(
                          'Note (Optional)',
                          Icons.note_outlined,
                          hint: 'Add a payment note',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    final amount =
                        double.tryParse(amountController.text.trim()) ?? 0;

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
                      await DatabaseHelper.insertPayment(payment);

                      final updatedPaidAmount =
                          await DatabaseHelper.getInvoicePaidAmount(
                            invoice['id'] as int,
                          );

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
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Payment'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // EDIT PAYMENT
  // ============================================================

  Future<void> _showEditPaymentDialog(
    Map<String, dynamic> invoice,
    Map<String, dynamic> payment,
  ) async {
    final amountController = TextEditingController(
      text: (payment['amount'] as num).toString(),
    );

    final noteController = TextEditingController(
      text: payment['note']?.toString() ?? '',
    );

    DateTime selectedPaymentDate =
        DateTime.tryParse(payment['payment_date']?.toString() ?? '') ??
        DateTime.now();

    String selectedPaymentMethod =
        payment['payment_method']?.toString() ?? 'Cash';

    final invoiceTotal = (invoice['grand_total'] as num).toDouble();

    final paidAmount = await DatabaseHelper.getInvoicePaidAmount(
      invoice['id'] as int,
    );

    final currentPaymentAmount = (payment['amount'] as num).toDouble();

    final paidWithoutCurrentPayment = paidAmount - currentPaymentAmount;

    final maximumPaymentAmount = invoiceTotal - paidWithoutCurrentPayment;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  _buildDialogIcon(Icons.edit_outlined),
                  const SizedBox(width: 10),
                  const Text('Edit Payment'),
                ],
              ),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _invoiceSummaryRow('Invoice Total', invoiceTotal),
                      _invoiceSummaryRow(
                        'Paid Before This Payment',
                        paidWithoutCurrentPayment,
                      ),
                      _invoiceSummaryRow(
                        'Maximum Payment',
                        maximumPaymentAmount,
                        isGrandTotal: true,
                      ),

                      const SizedBox(height: 18),

                      const Divider(),

                      const SizedBox(height: 14),

                      TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _inputDecoration(
                          'Payment Amount',
                          Icons.attach_money,
                          hint: 'Enter payment amount',
                        ).copyWith(prefixText: 'Rs. '),
                      ),

                      const SizedBox(height: 16),

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
                          decoration: _inputDecoration(
                            'Payment Date',
                            Icons.calendar_today_outlined,
                          ),
                          child: Text(_formatDate(selectedPaymentDate)),
                        ),
                      ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        initialValue: selectedPaymentMethod,
                        decoration: _inputDecoration(
                          'Payment Method',
                          Icons.account_balance_wallet_outlined,
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

                      const SizedBox(height: 16),

                      TextField(
                        controller: noteController,
                        maxLines: 3,
                        decoration: _inputDecoration(
                          'Note (Optional)',
                          Icons.note_outlined,
                          hint: 'Add a payment note',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    final amount =
                        double.tryParse(amountController.text.trim()) ?? 0;

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

                    if (amount > maximumPaymentAmount) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Payment cannot exceed '
                            'Rs. ${maximumPaymentAmount.toStringAsFixed(2)}.',
                          ),
                        ),
                      );
                      return;
                    }

                    final updatedPayment = {
                      'amount': amount,
                      'payment_date': selectedPaymentDate.toIso8601String(),
                      'payment_method': selectedPaymentMethod,
                      'note': noteController.text.trim().isEmpty
                          ? null
                          : noteController.text.trim(),
                    };

                    try {
                      await DatabaseHelper.updatePayment(
                        payment['id'] as int,
                        updatedPayment,
                      );

                      final updatedPaidAmount =
                          await DatabaseHelper.getInvoicePaidAmount(
                            invoice['id'] as int,
                          );

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
                          content: Text('Payment updated successfully.'),
                        ),
                      );

                      _showInvoiceDetails(invoice);
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update payment: $e')),
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
  // UI HELPERS
  // ============================================================

  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
    );
  }

  Widget _buildDialogIcon(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 23),
    );
  }

  Widget _buildSmallIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 21),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        _buildSmallIcon(icon),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildAmountBox(
    String label,
    double amount, {
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            'Rs. ${amount.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildGrandTotalBox(double amount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer
            .withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Grand Total',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            'Rs. ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationRow(
    String label,
    double amount, {
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          'Rs. ${amount.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDetailsCustomerCard(Map<String, dynamic> invoice) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                _buildSmallIcon(Icons.person_outline),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice['customer_name']?.toString() ??
                            'Unknown Customer',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        invoice['customer_phone']?.toString() ?? '-',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            const Divider(),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _buildDateInfo(
                    'Invoice Date',
                    invoice['invoice_date']?.toString().split('T').first ?? '-',
                    Icons.calendar_today_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDateInfo(
                    'Due Date',
                    invoice['due_date'] != null
                        ? invoice['due_date'].toString().split('T').first
                        : '-',
                    Icons.event_available_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateInfo(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceStatusBadge(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case 'Paid':
        color = Colors.green;
        icon = Icons.check_circle_outline;
        break;

      case 'Partially Paid':
        color = Colors.orange;
        icon = Icons.timelapse;
        break;

      case 'Overdue':
        color = Colors.red;
        icon = Icons.warning_amber_rounded;
        break;

      case 'Cancelled':
        color = Colors.grey;
        icon = Icons.cancel_outlined;
        break;

      case 'Draft':
      default:
        color = Colors.blue;
        icon = Icons.edit_note;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceIcon({bool overdue = false}) {
    final color = overdue ? Colors.red : Theme.of(context).colorScheme.primary;

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.receipt_long_outlined, color: color, size: 24),
    );
  }

  Widget _buildInvoiceInfo(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard({
    required Map<String, dynamic> invoice,
    required String invoiceNumber,
    required String customerName,
    required String customerPhone,
    required String invoiceDate,
    required String status,
    required double total,
    required bool isOverdue,
    required bool isSmallWidth,
  }) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          _showInvoiceDetails(invoice);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: isSmallWidth
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInvoiceIcon(overdue: isOverdue),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                invoiceNumber,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                customerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 12,
                                ),
                              ),
                              if (customerPhone.isNotEmpty)
                                Text(
                                  customerPhone,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          onSelected: (value) {
                            if (value == 'view') {
                              _showInvoiceDetails(invoice);
                            } else if (value == 'edit') {
                              _showEditInvoiceDialog(invoice);
                            } else if (value == 'pdf') {
                              _generateInvoicePdf(invoice);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'view',
                              child: Text('View Details'),
                            ),
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit Invoice'),
                            ),
                            PopupMenuItem(
                              value: 'pdf',
                              child: Text('Export PDF'),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    const Divider(height: 1),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildInvoiceInfo(
                            'Date',
                            invoiceDate,
                            Icons.calendar_today_outlined,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildInvoiceInfo(
                            'Status',
                            status,
                            Icons.info_outline,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Rs. '
                          '${total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isOverdue ? Colors.red : null,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        _buildInvoiceStatusBadge(
                          isOverdue ? 'Overdue' : status,
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            _showInvoiceDetails(invoice);
                          },
                          icon: const Icon(Icons.visibility_outlined, size: 17),
                          label: const Text('View'),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    _buildInvoiceIcon(overdue: isOverdue),

                    const SizedBox(width: 12),

                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoiceNumber,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            customerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                          if (customerPhone.isNotEmpty)
                            Text(
                              customerPhone,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: _buildInvoiceInfo(
                        'Date',
                        invoiceDate,
                        Icons.calendar_today_outlined,
                      ),
                    ),

                    const SizedBox(width: 12),

                    _buildInvoiceStatusBadge(isOverdue ? 'Overdue' : status),

                    const SizedBox(width: 18),

                    Text(
                      'Rs. '
                      '${total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isOverdue ? Colors.red : null,
                      ),
                    ),

                    const SizedBox(width: 8),

                    PopupMenuButton<String>(
                      tooltip: 'Invoice Actions',
                      onSelected: (value) {
                        if (value == 'view') {
                          _showInvoiceDetails(invoice);
                        } else if (value == 'edit') {
                          _showEditInvoiceDialog(invoice);
                        } else if (value == 'pdf') {
                          _generateInvoicePdf(invoice);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'view',
                          child: Text('View Details'),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit Invoice'),
                        ),
                        PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY ROW
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
              fontSize: isGrandTotal ? 17 : 14,
              fontWeight: isGrandTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            'Rs. ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isGrandTotal ? 17 : 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ============================================================
  // INITIAL LOAD
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadInvoices();
  }

  // ============================================================
  // MAIN UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.receipt_long_outlined,
                                color: Theme.of(context).colorScheme.primary,
                                size: 25,
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Invoices',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Create and manage your business invoices',
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
                            onPressed: _showCreateInvoiceDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Create Invoice'),
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
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.receipt_long_outlined,
                            color: Theme.of(context).colorScheme.primary,
                            size: 28,
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Invoice Management',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Create and manage your business invoices',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),

                        FilledButton.icon(
                          onPressed: _showCreateInvoiceDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Create Invoice'),
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),

                  // ========================================================
                  // SEARCH + FILTER
                  // ========================================================
                  if (isSmallWidth)
                    Column(
                      children: [
                        TextField(
                          onChanged: _searchInvoices,
                          decoration: InputDecoration(
                            hintText: 'Search invoices...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.35),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        DropdownButtonFormField<String>(
                          initialValue: selectedStatus,
                          decoration: InputDecoration(
                            labelText: 'Status',
                            prefixIcon: const Icon(Icons.filter_list),
                            filled: true,
                            fillColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.35),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: _statusItems(),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }

                            setState(() {
                              selectedStatus = value;
                            });

                            _searchInvoices(invoiceSearchQuery);
                          },
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            onChanged: _searchInvoices,
                            decoration: InputDecoration(
                              hintText:
                                  'Search invoices, customers or phone...',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.35),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedStatus,
                            decoration: InputDecoration(
                              labelText: 'Status',
                              prefixIcon: const Icon(Icons.filter_list),
                              filled: true,
                              fillColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.35),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: _statusItems(),
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }

                              setState(() {
                                selectedStatus = value;
                              });

                              _searchInvoices(invoiceSearchQuery);
                            },
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 10),

                  // ========================================================
                  // RESULT COUNT
                  // ========================================================
                  Row(
                    children: [
                      Text(
                        '${filteredInvoices.length} invoice'
                        '${filteredInvoices.length == 1 ? '' : 's'}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),

                      const Spacer(),

                      if (invoiceSearchQuery.isNotEmpty ||
                          selectedStatus != 'All')
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              invoiceSearchQuery = '';
                              selectedStatus = 'All';
                              filteredInvoices = List.from(invoices);
                            });
                          },
                          icon: const Icon(Icons.clear, size: 18),
                          label: const Text('Clear Filters'),
                        ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // ========================================================
                  // INVOICE LIST
                  // ========================================================
                  Expanded(
                    child: isLoadingInvoices
                        ? const Center(child: CircularProgressIndicator())
                        : filteredInvoices.isEmpty
                        ? _buildEmptyState()
                        : Card(
                            elevation: 0,
                            clipBehavior: Clip.antiAlias,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: filteredInvoices.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final invoice = filteredInvoices[index];

                                final dueDateString = invoice['due_date']
                                    ?.toString();

                                final dueDate = dueDateString != null
                                    ? DateTime.tryParse(dueDateString)
                                    : null;

                                final today = DateTime(
                                  DateTime.now().year,
                                  DateTime.now().month,
                                  DateTime.now().day,
                                );

                                final isOverdue =
                                    dueDate != null &&
                                    DateTime(
                                      dueDate.year,
                                      dueDate.month,
                                      dueDate.day,
                                    ).isBefore(today) &&
                                    invoice['status'] != 'Paid' &&
                                    invoice['status'] != 'Cancelled';

                                final invoiceNumber =
                                    invoice['invoice_number']?.toString() ??
                                    '-';

                                final customerName =
                                    invoice['customer_name']?.toString() ??
                                    'Unknown Customer';

                                final customerPhone =
                                    invoice['customer_phone']?.toString() ?? '';

                                final invoiceDate =
                                    invoice['invoice_date']
                                        ?.toString()
                                        .split('T')
                                        .first ??
                                    '-';

                                final status =
                                    invoice['status']?.toString() ?? 'Draft';

                                final total =
                                    double.tryParse(
                                      invoice['grand_total'].toString(),
                                    ) ??
                                    0;

                                return _buildInvoiceCard(
                                  invoice: invoice,
                                  invoiceNumber: invoiceNumber,
                                  customerName: customerName,
                                  customerPhone: customerPhone,
                                  invoiceDate: invoiceDate,
                                  status: status,
                                  total: total,
                                  isOverdue: isOverdue,
                                  isSmallWidth: isSmallWidth,
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
  // ============================================================
  // STATUS ITEMS
  // ============================================================

  List<DropdownMenuItem<String>> _statusItems() {
    return const [
      DropdownMenuItem(value: 'All', child: Text('All Status')),
      DropdownMenuItem(value: 'Draft', child: Text('Draft')),
      DropdownMenuItem(value: 'Paid', child: Text('Paid')),
      DropdownMenuItem(value: 'Partially Paid', child: Text('Partially Paid')),
      DropdownMenuItem(value: 'Overdue', child: Text('Overdue')),
      DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
    ];
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    final hasFilters = invoiceSearchQuery.isNotEmpty || selectedStatus != 'All';

    return Card(
      elevation: 0,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  size: 37,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(height: 18),

              Text(
                hasFilters ? 'No matching invoices found' : 'No invoices yet',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                hasFilters
                    ? 'Try changing your search or status filter.'
                    : 'Create your first invoice to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),

              const SizedBox(height: 20),

              if (!hasFilters)
                FilledButton.icon(
                  onPressed: _showCreateInvoiceDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Invoice'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
