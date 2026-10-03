import 'package:flutter/material.dart';

import 'package:small_business_invoice/screens/customer/customer_page.dart';
import 'package:small_business_invoice/screens/expense/expense_page.dart';
import 'package:small_business_invoice/screens/settings/business_settings_page.dart';
import 'package:small_business_invoice/screens/product/product_page.dart';

import '../db/database_helper.dart';
import '../screens/invoice/invoice_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ============================================================
  // RECENT DATA
  // ============================================================

  List<Map<String, dynamic>> recentInvoices = [];
  List<Map<String, dynamic>> recentExpenses = [];

  bool isLoadingRecentData = true;

  // ============================================================
  // LOAD RECENT DATA
  // ============================================================

  Future<void> _loadRecentData() async {
    try {
      final invoices = await DatabaseHelper.getRecentInvoices(limit: 5);

      final expenses = await DatabaseHelper.getRecentExpenses(limit: 5);

      if (!mounted) return;

      setState(() {
        recentInvoices = invoices;
        recentExpenses = expenses;
        isLoadingRecentData = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingRecentData = false;
      });
    }
  }

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadRecentData();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ==========================================================
      // APP BAR
      // ==========================================================

      appBar: AppBar(title: const Text('Small Business Management')),

      // ==========================================================
      // SIDE NAVIGATION DRAWER
      // ==========================================================
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ----------------------------------------------------
            // Drawer Header
            // ----------------------------------------------------

            const DrawerHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.business, size: 45),

                  SizedBox(height: 10),

                  Text(
                    'Small Business',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  Text('Invoice & Expense Management'),
                ],
              ),
            ),

            // ----------------------------------------------------
            // Dashboard
            // ----------------------------------------------------
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            // ----------------------------------------------------
            // Customers
            // ----------------------------------------------------
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Customers'),
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CustomerPage()),
                );
              },
            ),

            // ----------------------------------------------------
            // Invoices
            // ----------------------------------------------------
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Invoices'),
              onTap: () async {
                Navigator.pop(context);

                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InvoicePage()),
                );

                // Refresh recent invoices when returning
                _loadRecentData();
              },
            ),

            // ----------------------------------------------------
            // Products
            // ----------------------------------------------------
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text('Products'),
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProductPage()),
                );
              },
            ),

            // ----------------------------------------------------
            // Expenses
            // ----------------------------------------------------
            ListTile(
              leading: const Icon(Icons.money_off),
              title: const Text('Expenses'),
              onTap: () async {
                Navigator.pop(context);

                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ExpensePage()),
                );

                // Refresh recent expenses when returning
                _loadRecentData();
              },
            ),

            // ----------------------------------------------------
            // Financial Summary
            // ----------------------------------------------------
            ListTile(
              leading: const Icon(Icons.account_balance),
              title: const Text('Financial Summary'),
              onTap: () {
                // Financial Summary page will be connected later.
                Navigator.pop(context);
              },
            ),

            const Divider(),

            // ----------------------------------------------------
            // Settings
            // ----------------------------------------------------
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BusinessSettingsPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),

      // ==========================================================
      // DASHBOARD CONTENT
      // ==========================================================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ======================================================
            // DASHBOARD HEADING
            // ======================================================

            const Text(
              'Financial Dashboard',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              'Overview of your business finances',
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 25),

            // ======================================================
            // FINANCIAL SUMMARY CARDS
            // ======================================================
            Wrap(
              spacing: 15,
              runSpacing: 15,
              children: [
                _summaryCard('Total Income', 'Rs. 0.00', Icons.trending_up),

                _summaryCard('Total Expenses', 'Rs. 0.00', Icons.money_off),

                _summaryCard(
                  'Net Profit',
                  'Rs. 0.00',
                  Icons.account_balance_wallet,
                ),

                _summaryCard('Outstanding', 'Rs. 0.00', Icons.pending_actions),
              ],
            ),

            const SizedBox(height: 35),

            // ======================================================
            // QUICK ACTIONS
            // ======================================================
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                // --------------------------------------------------
                // Create Invoice
                // --------------------------------------------------

                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InvoicePage(),
                        ),
                      ).then((_) {
                        _loadRecentData();
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Invoice'),
                  ),
                ),

                const SizedBox(width: 12),

                // --------------------------------------------------
                // Add Expense
                // --------------------------------------------------
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ExpensePage(),
                        ),
                      ).then((_) {
                        _loadRecentData();
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Expense'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 35),

            // ======================================================
            // RECENT INVOICES
            // ======================================================
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Invoices',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Loading
                    if (isLoadingRecentData)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    // No invoices
                    else if (recentInvoices.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'No invoices yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    // Invoice list
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recentInvoices.length,
                        separatorBuilder: (context, index) {
                          return const Divider();
                        },
                        itemBuilder: (context, index) {
                          final invoice = recentInvoices[index];

                          final invoiceNumber =
                              invoice['invoice_number']?.toString() ?? '-';

                          final customerName =
                              invoice['customer_name']?.toString() ??
                              'Walk-in Customer';

                          final total =
                              (invoice['grand_total'] as num?)?.toDouble() ??
                              0.0;

                          final status =
                              invoice['status']?.toString() ?? 'Draft';

                          return ListTile(
                            contentPadding: EdgeInsets.zero,

                            leading: const CircleAvatar(
                              child: Icon(Icons.receipt_long),
                            ),

                            title: Text(
                              invoiceNumber,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            subtitle: Text(customerName),

                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Rs. ${total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 3),

                                Text(
                                  status,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ======================================================
            // RECENT EXPENSES
            // ======================================================
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Expenses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Loading
                    if (isLoadingRecentData)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    // No expenses
                    else if (recentExpenses.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'No expenses yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    // Expense list
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recentExpenses.length,
                        separatorBuilder: (context, index) {
                          return const Divider();
                        },
                        itemBuilder: (context, index) {
                          final expense = recentExpenses[index];

                          final title = expense['title']?.toString() ?? '-';

                          final category =
                              expense['category']?.toString() ?? 'Other';

                          final amount =
                              (expense['amount'] as num?)?.toDouble() ?? 0.0;

                          final paymentMethod =
                              expense['payment_method']?.toString() ?? 'Cash';

                          return ListTile(
                            contentPadding: EdgeInsets.zero,

                            leading: const CircleAvatar(
                              child: Icon(Icons.money_off),
                            ),

                            title: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            subtitle: Text('$category • $paymentMethod'),

                            trailing: Text(
                              'Rs. ${amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // REUSABLE FINANCIAL SUMMARY CARD
  // ============================================================

  /// Creates a reusable financial summary card.
  ///
  /// These values are currently placeholders.
  /// They will later be connected to real database calculations.
  static Widget _summaryCard(String title, String value, IconData icon) {
    return SizedBox(
      width: 220,

      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card icon
              Icon(icon, size: 32),

              const SizedBox(height: 15),

              // Card title
              Text(title, style: const TextStyle(fontSize: 16)),

              const SizedBox(height: 5),

              // Card value
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
