import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:projeto/src/orders/order.dart';

class InvoiceService {
  static Future<void> generateInvoicePdf(
    BuildContext context,
    Order order,
  ) async {
    final pdf = pw.Document();
    final ByteData logoData = await rootBundle.load('assets/images/logo.jpeg');
    final Uint8List logoBytes = logoData.buffer.asUint8List();
    final image = pw.MemoryImage(logoBytes);

    final date = order.createdAt.toLocal();
    final formattedDate =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(32),
        build:
            (pw.Context context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Image(image, height: 60),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'FATURA',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text('Fatura #: ${order.id}'),
                        pw.Text('Data: $formattedDate'),
                      ],
                    ),
                  ],
                ),
                pw.Divider(height: 32),
                pw.Text(
                  'De:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text('HelloFarmer'),
                pw.Text('Rua Principal 123, Lisboa'),
                pw.Text('NIF: 123456789'),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Para:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text('Cliente: ${order.clientId}'),
                pw.Text('Endereço: ${order.address}'),
                pw.SizedBox(height: 24),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Descrição',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Qtd',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Preço',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(order.advertisementName),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('1'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '${order.price?.toStringAsFixed(2) ?? 'N/A'} EUR',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Total: ${order.price?.toStringAsFixed(2) ?? 'N/A'} EUR',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 24),
                pw.Center(
                  child: pw.Text(
                    'Obrigado pela sua preferência!',
                    style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
                  ),
                ),
              ],
            ),
      ),
    );

    final bytes = await pdf.save();
    final dir = await getExternalStorageDirectory();
    if (dir == null) {
      throw Exception('Não foi possível encontrar o diretório seguro.');
    }
    final filePath = '${dir.path}/fatura_${order.id}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fatura guardada em: $filePath')));
    }

    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }
}
