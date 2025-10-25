import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class InvoiceService {
  Future<void> generateInvoice(Map<String, dynamic> orderData) async {
    try {
      print('Starting invoice generation...');
      
      // Create PDF document
      final pdf = pw.Document();

      // Extract order data with null safety
      final customerInfo = orderData['customerInfo'] as Map<String, dynamic>? ?? {};
      final deliveryAddress = orderData['deliveryAddress'] as Map<String, dynamic>? ?? {};
      final addressData = (deliveryAddress['address'] as Map<String, dynamic>?) ?? {};
      final items = (orderData['items'] as List<dynamic>?) ?? [];
      final pricing = orderData['pricing'] as Map<String, dynamic>? ?? {};
      final payment = orderData['payment'] as Map<String, dynamic>? ?? {};
      final orderDate = orderData['orderDate'] as DateTime? ?? DateTime.now();
      final orderNumber = orderData['orderNumber']?.toString() ?? 'N/A';

      print('Order data extracted successfully');

      // Format address safely
      final fullAddress = _buildAddress(addressData);

      // Add page to PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header with Company Logo and Info
              _buildHeader(),
              pw.SizedBox(height: 30),

              // Invoice Title and Order Info
              _buildInvoiceTitle(orderNumber, orderDate),
              pw.SizedBox(height: 30),

              // Customer and Shipping Info
              _buildCustomerInfo(customerInfo, deliveryAddress, fullAddress),
              pw.SizedBox(height: 30),

              // Items Table
              _buildItemsTable(items.cast<Map<String, dynamic>>()),
              pw.SizedBox(height: 30),

              // Price Summary
              _buildPriceSummary(pricing),
              pw.SizedBox(height: 30),

              // Payment Info
              _buildPaymentInfo(payment),
              pw.SizedBox(height: 30),

              // Footer
              _buildFooter(),
            ];
          },
        ),
      );

      print('PDF created successfully');

      // Save PDF to device
      await _savePdfToDevice(pdf, orderNumber);
      print('Invoice generation completed successfully');
      
    } catch (e) {
      print('Error in generateInvoice: $e');
      throw Exception('Failed to generate invoice: $e');
    }
  }

  String _buildAddress(Map<String, dynamic> addressData) {
    final parts = <String>[];
    
    if (addressData['building']?.toString().isNotEmpty == true) {
      parts.add(addressData['building'].toString());
    }
    if (addressData['area']?.toString().isNotEmpty == true) {
      parts.add(addressData['area'].toString());
    }
    if (addressData['landmark']?.toString().isNotEmpty == true) {
      parts.add(addressData['landmark'].toString());
    }
    if (addressData['city']?.toString().isNotEmpty == true) {
      parts.add(addressData['city'].toString());
    }
    if (addressData['state']?.toString().isNotEmpty == true) {
      parts.add(addressData['state'].toString());
    }
    if (addressData['pincode']?.toString().isNotEmpty == true) {
      parts.add(addressData['pincode'].toString());
    }
    
    return parts.join(', ');
  }

  pw.Widget _buildHeader() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'BEINN',
              style: pw.TextStyle(
                fontSize: 32,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#D2691E'),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Premium Fashion & Lifestyle',
              style: pw.TextStyle(
                fontSize: 14,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Email: beinnlifestyle@gmail.com',
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
            ),
            pw.Text(
              'Phone: +91 9876543210',
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
            ),
          ],
        ),
        pw.Container(
          width: 80,
          height: 80,
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#D2691E'),
            borderRadius: pw.BorderRadius.circular(40),
          ),
          child: pw.Center(
            child: pw.Text(
              'B',
              style: pw.TextStyle(
                fontSize: 36,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildInvoiceTitle(String orderNumber, DateTime orderDate) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Order #$orderNumber',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#D2691E'),
              ),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Date: ${DateFormat('MMM dd, yyyy').format(orderDate)}',
              style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
            ),
            pw.Text(
              'Time: ${DateFormat('hh:mm a').format(orderDate)}',
              style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildCustomerInfo(Map<String, dynamic> customerInfo, Map<String, dynamic> deliveryAddress, String fullAddress) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'BILL TO:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                deliveryAddress['fullName']?.toString() ?? 'N/A',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                customerInfo['email']?.toString() ?? 'N/A',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
              ),
              pw.Text(
                customerInfo['mobile']?.toString() ?? 'N/A',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 40),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'SHIP TO:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                deliveryAddress['fullName']?.toString() ?? 'N/A',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                fullAddress.isNotEmpty ? fullAddress : 'Address not available',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                maxLines: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildItemsTable(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return pw.Text('No items found');
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'ORDER DETAILS',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
          columnWidths: {
            0: pw.FlexColumnWidth(3),
            1: pw.FlexColumnWidth(1),
            2: pw.FlexColumnWidth(1),
            3: pw.FlexColumnWidth(1),
            4: pw.FlexColumnWidth(1.5),
            5: pw.FlexColumnWidth(1.5),
          },
          children: [
            // Header row
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#D2691E'),
              ),
              children: [
                _buildTableCell('Product Name', isHeader: true),
                _buildTableCell('Size', isHeader: true),
                _buildTableCell('Color', isHeader: true),
                _buildTableCell('Qty', isHeader: true),
                _buildTableCell('Price', isHeader: true),
                _buildTableCell('Total', isHeader: true),
              ],
            ),
            // Data rows
            ...items.map((item) {
              final priceStr = item['price']?.toString() ?? '0';
              final cleanPrice = priceStr.replaceAll('₹', '').replaceAll(',', '');
              double itemPrice = double.tryParse(cleanPrice) ?? 0.0;
              int quantity = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
              double totalItemPrice = itemPrice * quantity;
              
              return pw.TableRow(
                children: [
                  _buildTableCell(item['name']?.toString() ?? 'N/A'),
                  _buildTableCell(item['selectedSize']?.toString() ?? 'N/A'),
                  _buildTableCell(item['selectedColor']?.toString() ?? 'N/A'),
                  _buildTableCell(quantity.toString()),
                  _buildTableCell('Rs. ${itemPrice.toStringAsFixed(0)}'),
                  _buildTableCell('Rs. ${totalItemPrice.toStringAsFixed(0)}'),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 11,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : PdfColors.black,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  pw.Widget _buildPriceSummary(Map<String, dynamic> pricing) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 250,
          child: pw.Column(
            children: [
              _buildPriceRow('Subtotal (${pricing['totalItems'] ?? 0} items)', 'Rs. ${(pricing['subtotal'] ?? 0).toStringAsFixed(0)}'),
              _buildPriceRow('Tax (GST 18%)', 'Rs. ${(pricing['tax'] ?? 0).toStringAsFixed(0)}'),
              _buildPriceRow('Shipping', (pricing['shipping'] ?? 0) == 0 ? 'FREE' : 'Rs. ${(pricing['shipping'] ?? 0).toStringAsFixed(0)}'),
              pw.Divider(color: PdfColors.grey400, thickness: 1),
              _buildPriceRow('TOTAL AMOUNT', 'Rs. ${(pricing['grandTotal'] ?? 0).toStringAsFixed(0)}', isTotal: true),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isTotal ? 14 : 12,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isTotal ? PdfColors.black : PdfColors.grey700,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: isTotal ? 14 : 12,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isTotal ? PdfColor.fromHex('#D2691E') : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPaymentInfo(Map<String, dynamic> payment) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'PAYMENT INFORMATION',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Text('Payment Method: ', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
                  pw.Text('Razorpay', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                children: [
                  pw.Text('Payment ID: ', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
                  pw.Text(payment['paymentId']?.toString() ?? 'N/A', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                children: [
                  pw.Text('Status: ', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
                  pw.Container(
                    padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.green100,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'COMPLETED',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey400, thickness: 1),
        pw.SizedBox(height: 16),
        pw.Text(
          'Thank you for choosing BEINN!',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#D2691E'),
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'We appreciate your business and hope you love your new items.',
          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 16),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              'For support, contact us at beinnlifestyle@gmail.com or +91 9876543210',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'This is a computer-generated invoice and does not require a signature.',
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey400),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _savePdfToDevice(pw.Document pdf, String orderNumber) async {
    try {
      print('Starting PDF save process...');
      final Uint8List bytes = await pdf.save();
      print('PDF bytes generated: ${bytes.length}');
      
      Directory? directory;
      
      if (Platform.isAndroid) {
        // Try to get external storage directory
        directory = await getExternalStorageDirectory();
        print('External storage directory: ${directory?.path}');
        
        // Try to use Downloads folder
        if (directory != null) {
          final downloadsPath = '/storage/emulated/0/Download';
          final downloadsDir = Directory(downloadsPath);
          if (await downloadsDir.exists()) {
            directory = downloadsDir;
            print('Using Downloads directory: ${directory.path}');
          }
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
        print('iOS documents directory: ${directory.path}');
      }

      if (directory != null) {
        final String fileName = 'BEINN_Invoice_$orderNumber.pdf';
        final File file = File('${directory.path}/$fileName');
        await file.writeAsBytes(bytes);
        print('Invoice saved successfully to: ${file.path}');
        
        // Verify file was created
        if (await file.exists()) {
          print('File verification successful. Size: ${await file.length()} bytes');
        } else {
          throw Exception('File was not created successfully');
        }
      } else {
        throw Exception('Could not access storage directory');
      }
    } catch (e) {
      print('Error in _savePdfToDevice: $e');
      throw Exception('Failed to save PDF: $e');
    }
  }
}
