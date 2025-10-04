// lib/services/pdf_service.dart
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:hotel_order_taking_app/Model/order.dart';

class PdfService {
  Future<File> generateOrderPdf(Order order) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Restaurant Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'RESTAURANT NAME',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Address Line 1, City, State',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.Text(
                      'Phone: +91-XXXXXXXXXX',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),

              // Order Details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Order Date:'),
                      pw.Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(order.time),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Table No:'),
                      pw.Text(
                        '${order.tableNo} (${order.tableType})',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Phone:'),
                      pw.Text(
                        order.phoneNo,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),

              // Items Table Header
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                color: PdfColors.grey300,
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        'Item',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        'Qty',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        'Price',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        'Total',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),

              // Items List
              ...order.items.map((item) {
                return pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey400),
                    ),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 3,
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(item.name),
                                if (item.notes.isNotEmpty)
                                  pw.Text(
                                    'Note: ${item.notes}',
                                    style: const pw.TextStyle(
                                      fontSize: 10,
                                      color: PdfColors.grey700,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Text(
                              '${item.quantity}',
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Text(
                              '₹${item.price.toStringAsFixed(2)}',
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Text(
                              '₹${item.totalPrice.toStringAsFixed(2)}',
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),

              pw.SizedBox(height: 20),

              // Total Section
              pw.Divider(thickness: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'TOTAL: ',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '₹${order.totalPrice.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.Divider(thickness: 2),

              pw.Spacer(),

              // Footer
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Thank you for dining with us!',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Visit us again',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // Save PDF to device
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/order_${order.tableNo}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());

    return file;
  }
}
