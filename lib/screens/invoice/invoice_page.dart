import 'package:flutter/material.dart';

import '../../db/database_helper.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  List<Map<String, dynamic>> invoices = [];
  bool isLoadingInvoices = true;

  Future<void> _showCreateInvoiceDialog() async {
    final invoiceNumberController = TextEditingController(
      text: 'INV-${DateTime.now().millisecondsSinceEpoch}',
    );

    String? selectedCustomer;
    int? selectedCustomerId;

    DateTime selectedDate = DateTime.now();

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

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.receipt_long),
                  SizedBox(width: 10),
                  Text('Create Invoice'),
                ],
              ),

              content: SizedBox(
                width: 550,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // =========================
                      // INVOICE DETAILS
                      // =========================

                      const Text(
                        'Invoice Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

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

                      TextField(
                        controller: invoiceNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Invoice Number',
                          prefixIcon: Icon(Icons.numbers),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 18),

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

                      // =========================
                      // INVOICE ITEM
                      // =========================
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
                      const SizedBox(height: 20),

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

              // =========================
              // ACTION BUTTONS
              // =========================
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

  Future<void> _loadInvoices() async {
    final data = await DatabaseHelper.getInvoices();

    if (!mounted) return;

    setState(() {
      invoices = data;
      isLoadingInvoices = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invoices')),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search Invoices...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 15),

                FilledButton.icon(
                  onPressed: _showCreateInvoiceDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Invoice'),
                ),
              ],
            ),

            const SizedBox(height: 25),

            Expanded(
              child: isLoadingInvoices
                  ? const Center(child: CircularProgressIndicator())
                  : invoices.isEmpty
                  ? Card(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.receipt_long, size: 70),

                            const SizedBox(height: 15),

                            const Text(
                              'No invoices yet',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            const Text(
                              'Create your first invoice to get started.',
                            ),

                            const SizedBox(height: 20),

                            FilledButton.icon(
                              onPressed: _showCreateInvoiceDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('Create Invoice'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Card(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: invoices.length,
                        separatorBuilder: (context, index) {
                          return const Divider();
                        },
                        itemBuilder: (context, index) {
                          final invoice = invoices[index];

                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.receipt_long),
                            ),

                            title: Text(
                              invoice['invoice_number'].toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            subtitle: Text(
                              '${invoice['customer_name'] ?? 'Unknown Customer'}\n'
                              '${invoice['customer_phone'] ?? ''}\n'
                              'Date: ${invoice['invoice_date'].toString().split('T').first}\n'
                              'Status: ${invoice['status']}',
                            ),

                            isThreeLine: true,

                            trailing: Text(
                              'Rs. ${double.parse(invoice['grand_total'].toString()).toStringAsFixed(2)}',
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
}
