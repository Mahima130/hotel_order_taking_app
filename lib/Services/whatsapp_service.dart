// lib/services/whatsapp_service.dart
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class WhatsAppService {
  // Send PDF via WhatsApp
  Future<bool> sendPdfToWhatsApp(String phoneNo, File pdfFile) async {
    try {
      // Share the PDF file
      // The user can then choose WhatsApp from the share menu
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: 'Your order bill from Restaurant Name',
      );
      return true;
    } catch (e) {
      print('Error sharing PDF: $e');
      return false;
    }
  }

  // Alternative: Open WhatsApp with phone number (text only)
  Future<bool> openWhatsAppChat(String phoneNo, String message) async {
    // Format phone number (remove +, spaces, etc.)
    final formattedPhone = phoneNo.replaceAll(RegExp(r'[^\d]'), '');

    // WhatsApp URL scheme
    final whatsappUrl =
        'https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}';

    try {
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        print('Could not launch WhatsApp');
        return false;
      }
    } catch (e) {
      print('Error opening WhatsApp: $e');
      return false;
    }
  }
}
