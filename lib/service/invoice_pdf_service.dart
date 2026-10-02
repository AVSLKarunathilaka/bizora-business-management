import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../db/database_helper.dart';

class InvoicePdfService {
  static Future<List<int>> generateInvoicePdf({
    required Map<String, dynamic> invoice,
    required List<Map<String, dynamic>> items,
    required double paidAmount,
  }) async {
    final pdf = pw.Document();

    final businessSettings = await DatabaseHelper.getBusinessSettings();

    final businessName =
        businessSettings?['business_name']?.toString() ?? 'Bizora';

    final businessPhone = businessSettings?['phone']?.toString() ?? '';

    final businessEmail = businessSettings?['email']?.toString() ?? '';

    final businessAddress = businessSettings?['address']?.toString() ?? '';

    final grandTotal = (invoice['grand_total'] as num?)?.toDouble() ?? 0;

    final remaining = grandTotal - paidAmount;

    final logoPath = businessSettings?['logo_path']?.toString();

    pw.MemoryImage? logoImage;

    if (logoPath != null &&
        logoPath.isNotEmpty &&
        File(logoPath).existsSync()) {
      logoImage = pw.MemoryImage(await File(logoPath).readAsBytes());
    }

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logoImage != null) ...[
                    pw.Container(
                      width: 70,
                      height: 70,
                      child: pw.Image(logoImage!, fit: pw.BoxFit.contain),
                    ),

                    pw.SizedBox(width: 15),
                  ],

                  pw.Expanded(
                    child: pw.Text(
                      businessName,
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 15),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Seller / Business',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      businessName,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),

                    if (businessPhone.isNotEmpty)
                      pw.Text('Phone: $businessPhone'),

                    if (businessEmail.isNotEmpty)
                      pw.Text('Email: $businessEmail'),
                    pw.Text(''),

                    if (businessAddress.isNotEmpty)
                      pw.Text('Address:$businessAddress'),
                  ],
                ),
              ),

              pw.SizedBox(height: 25),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'INVOICE',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),

                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Invoice No: ${invoice['invoice_number'] ?? '-'}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),

                      pw.SizedBox(height: 4),

                      pw.Text(
                        'Invoice Date: '
                        '${invoice['invoice_date']?.toString().split('T').first ?? '-'}',
                      ),

                      pw.Text(
                        'Due Date: '
                        '${invoice['due_date']?.toString().split('T').first ?? '-'}',
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Bill To',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),

                    pw.SizedBox(height: 5),

                    pw.Text(
                      invoice['customer_name'] ?? 'Unknown Customer',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),

                    if (invoice['customer_phone'] != null &&
                        invoice['customer_phone'].toString().isNotEmpty)
                      pw.Text('Phone: ${invoice['customer_phone']}'),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              pw.SizedBox(height: 25),

              pw.Table.fromTextArray(
                headers: const ['Description', 'Qty', 'Unit Price', 'Total'],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 7,
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                },
                data: items.map((item) {
                  final quantity = (item['quantity'] as num?)?.toDouble() ?? 0;

                  final unitPrice =
                      (item['unit_price'] as num?)?.toDouble() ?? 0;

                  final total = (item['total'] as num?)?.toDouble() ?? 0;

                  return [
                    item['description'] ?? '',
                    quantity.toStringAsFixed(2),
                    'Rs. ${unitPrice.toStringAsFixed(2)}',
                    'Rs. ${total.toStringAsFixed(2)}',
                  ];
                }).toList(),
              ),

              pw.SizedBox(height: 25),

              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  width: 260,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Text(
                        'Invoice Summary',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),

                      pw.SizedBox(height: 10),

                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Subtotal'),
                          pw.Text(
                            'Rs. '
                            '${((invoice['subtotal'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 5),

                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Discount'),
                          pw.Text(
                            'Rs. '
                            '${((invoice['discount'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 5),

                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Tax'),
                          pw.Text(
                            'Rs. '
                            '${((invoice['tax_amount'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                          ),
                        ],
                      ),

                      pw.Divider(),

                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Grand Total',
                            style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            'Rs. ${grandTotal.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 8),

                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Paid'),
                          pw.Text('Rs. ${paidAmount.toStringAsFixed(2)}'),
                        ],
                      ),

                      pw.SizedBox(height: 5),

                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Balance',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            'Rs. ${remaining.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              pw.Spacer(),

              pw.Divider(),

              pw.SizedBox(height: 8),

              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Thank you for your business!',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),

                    pw.SizedBox(height: 3),

                    pw.Text(
                      'Generated by Bizora Business Management System',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
