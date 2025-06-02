import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../generated/l10n.dart';

class CommunicationService {
  static Future<void> makePhoneCall(BuildContext context, String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      _showErrorSnackbar(context, AppLocalizations.of(context).phoneNotAvailable);
      return;
    }

    // Clean phone number (remove spaces, dashes, etc.)
    final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri(scheme: 'tel', path: cleanedNumber);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showErrorSnackbar(context, AppLocalizations.of(context).cannotOpenDialer);
      }
    } catch (e) {
      _showErrorSnackbar(context, AppLocalizations.of(context).cannotOpenDialer);
    }
  }

  static Future<void> openWhatsAppChat(
    BuildContext context,
    String? phoneNumber,
    String itemName,
    String brand,
    String type,
    String color,
    String size,
  ) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      _showErrorSnackbar(context, AppLocalizations.of(context).phoneNotAvailable);
      return;
    }

    // Clean phone number and ensure it starts with country code
    String cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // If number doesn't start with +, assume it's Israeli number and add +972
    if (!cleanedNumber.startsWith('+')) {
      if (cleanedNumber.startsWith('0')) {
        cleanedNumber = '+972${cleanedNumber.substring(1)}';
      } else {
        cleanedNumber = '+972$cleanedNumber';
      }
    }

    // Create message template with item details
    final message = AppLocalizations.of(context).whatsappMessageTemplate(
      brand,
      color,
      itemName,
      size,
      type,
    );

    // Encode message for URL
    final encodedMessage = Uri.encodeComponent(message);
    
    // Try WhatsApp API first
    final whatsappUri = Uri.parse('https://wa.me/$cleanedNumber?text=$encodedMessage');
    
    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackbar(context, AppLocalizations.of(context).whatsappNotInstalled);
      }
    } catch (e) {
      _showErrorSnackbar(context, AppLocalizations.of(context).whatsappNotInstalled);
    }
  }

  static void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }
} 