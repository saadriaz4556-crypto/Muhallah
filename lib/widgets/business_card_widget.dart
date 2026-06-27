import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:muhallah/models/business_model.dart';

const Color deepNavy = Color(0xFF252A34);
const Color sectionBg = Color(0xFF2A303C);
const Color teal = Color(0xFF08D9D6);
const Color coral = Color(0xFFFF2E63);
const Color whiteish = Color(0xFFEAEAEA);
const Color successGreen = Color(0xFF10B981);

class BusinessCardWidget extends StatelessWidget {
  final BusinessModel business;
  final VoidCallback? onEdit;

  const BusinessCardWidget({
    super.key,
    required this.business,
    this.onEdit,
  });

  Future<void> _makeCall(BuildContext context) async {
    final phone = business.phone;
    if (phone.isEmpty) return;
    
    // Remove formatting characters like '-' for the tel URI
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final Uri phoneUri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _showError(context, 'Could not launch dialer for $phone');
      }
    } catch (e) {
      _showError(context, 'Error placing call: $e');
    }
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final whatsapp = business.whatsapp;
    if (whatsapp.isEmpty) return;

    String cleanWhatsApp = whatsapp.replaceAll(RegExp(r'\D'), '');
    if (cleanWhatsApp.startsWith('0')) {
      cleanWhatsApp = '92${cleanWhatsApp.substring(1)}';
    } else if (!cleanWhatsApp.startsWith('92') && cleanWhatsApp.length == 10) {
      cleanWhatsApp = '92$cleanWhatsApp';
    }

    final Uri whatsappAppUri = Uri.parse("whatsapp://send?phone=$cleanWhatsApp");
    final Uri whatsappWebUri = Uri.parse("https://wa.me/$cleanWhatsApp");

    try {
      if (await canLaunchUrl(whatsappAppUri)) {
        await launchUrl(whatsappAppUri);
      } else if (await canLaunchUrl(whatsappWebUri)) {
        await launchUrl(whatsappWebUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: try launching the web URL directly since canLaunchUrl can fail due to package visibility
        final launched = await launchUrl(whatsappWebUri, mode: LaunchMode.externalApplication);
        if (!launched) {
          _showError(context, 'Could not open WhatsApp for $whatsapp');
        }
      }
    } catch (e) {
      // Fallback: try launching the web URL directly in case of error
      try {
        final launched = await launchUrl(whatsappWebUri, mode: LaunchMode.externalApplication);
        if (!launched) {
          _showError(context, 'Could not open WhatsApp for $whatsapp');
        }
      } catch (e2) {
        _showError(context, 'Error launching WhatsApp: $e2');
      }
    }
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: coral,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bool hasImage = business.imageUrl.isNotEmpty;
    final bool hasWhatsApp = business.whatsapp.isNotEmpty;

    return Card(
      color: sectionBg,
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shop Image / Icon
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: hasImage
                      ? Image.network(
                          business.imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 80,
                              height: 80,
                              color: Colors.white.withValues(alpha: 0.05),
                              child: const Icon(Icons.storefront, color: Colors.white24, size: 36),
                            );
                          },
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          color: Colors.white.withValues(alpha: 0.05),
                          child: const Icon(Icons.storefront, color: Colors.white24, size: 36),
                        ),
                ),
                const SizedBox(width: 14),
                // Business Info Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              business.businessName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (onEdit != null)
                            IconButton(
                              icon: const Icon(Icons.edit, color: teal, size: 20),
                              onPressed: onEdit,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Category badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: teal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: teal.withValues(alpha: 0.3), width: 1),
                        ),
                        child: Text(
                          business.category,
                          style: const TextStyle(
                            color: teal,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Sub-category
                      Text(
                        business.subCategory,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 10),
            // Hours & Address
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.white30, size: 14),
                const SizedBox(width: 6),
                Text(
                  '${business.openTime} - ${business.closeTime}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const Spacer(),
                if (business.homeDelivery)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: successGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.delivery_dining, color: successGreen, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Delivery Available',
                          style: TextStyle(color: successGreen, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2.0),
                  child: Icon(Icons.location_on, color: Colors.white30, size: 14),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    business.address,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _makeCall(context),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Call Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: teal,
                      foregroundColor: deepNavy,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                if (hasWhatsApp) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openWhatsApp(context),
                      icon: const Icon(Icons.chat, size: 16),
                      label: const Text('WhatsApp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: successGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
