import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/providers/items_provider.dart';

const _maroon = Color(0xFF781C2E);

// ─── Provider ────────────────────────────────────────────────────────────────
final subscriptionVerificationsProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
      return ref
          .read(firestoreServiceProvider)
          .streamSubscriptionVerifications();
    });

class AdminSubscriptionVerificationsScreen extends ConsumerWidget {
  const AdminSubscriptionVerificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verificationsAsync = ref.watch(subscriptionVerificationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        foregroundColor: Colors.white,
        title: const Text(
          'Subscription Verifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: verificationsAsync.when(
        data: (verifications) {
          if (verifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_outlined,
                    size: 72,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pending verifications',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          // Sort: pending first
          final sorted = [...verifications]
            ..sort((a, b) {
              final statusA = a['status'] ?? 'pending';
              final statusB = b['status'] ?? 'pending';
              if (statusA == 'pending' && statusB != 'pending') return -1;
              if (statusA != 'pending' && statusB == 'pending') return 1;
              return 0;
            });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final v = sorted[index];
              return _VerificationCard(data: v, ref: ref)
                  .animate(delay: Duration(milliseconds: index * 60))
                  .fadeIn()
                  .slideX(begin: 0.05);
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _maroon)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final WidgetRef ref;

  const _VerificationCard({required this.data, required this.ref});

  String get _status => data['status'] ?? 'pending';
  bool get _isPending => _status == 'pending';

  Color get _statusColor {
    switch (_status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData get _statusIcon {
    switch (_status) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.hourglass_empty;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _isPending ? Colors.orange.shade200 : Colors.grey.shade200,
          width: _isPending ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _isPending ? Colors.orange.shade50 : Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _maroon.withValues(alpha: 0.12),
                  child: const Icon(Icons.person, color: _maroon, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? '—',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        data['userEmail'] ?? '—',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon, size: 13, color: _statusColor),
                      const SizedBox(width: 4),
                      Text(
                        _status.toUpperCase(),
                        style: TextStyle(
                          color: _statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Body ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plan & Amount
                Row(
                  children: [
                    _chip(
                      Icons.workspace_premium,
                      '${data['tierName'] ?? '—'} · ${data['billingCycle'] ?? ''}',
                      _maroon,
                    ),
                    const SizedBox(width: 8),
                    _chip(
                      Icons.currency_rupee,
                      '${data['amount'] ?? '—'}',
                      Colors.green.shade700,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // UTR ID
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.receipt_long,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'UTR / Transaction ID: ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          data['utrId'] ?? '—',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(text: data['utrId'] ?? ''),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('UTR copied!'),
                              backgroundColor: Colors.blue,
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: const Icon(
                          Icons.copy,
                          size: 14,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Screenshot
                if (data['screenshotUrl'] != null) ...[
                  const Text(
                    'Payment Screenshot:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () =>
                        _showFullScreenshot(context, data['screenshotUrl']),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _buildImage(data['screenshotUrl']),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Tap image to view full screen',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ] else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'No screenshot uploaded',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Submitted time
                if (data['submittedAt'] != null)
                  Text(
                    'Submitted: ${_formatDate(data['submittedAt'])}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),

                // ── Action Buttons (pending only) ──────────────
                if (_isPending) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _reject(
                            context,
                            data['id'] ?? '',
                            data['userId'] ?? '',
                          ),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 18,
                          ),
                          label: const Text(
                            'Reject',
                            style: TextStyle(color: Colors.red),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _approve(context, data),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text(
                            'Approve',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenshot(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: InteractiveViewer(
                  child: _buildImage(url, fullHeight: true),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String url, {bool fullHeight = false}) {
    // Check if URL is base64 string
    final isBase64 = !url.startsWith('http');

    if (isBase64) {
      try {
        return Image.memory(
          base64Decode(url),
          height: fullHeight ? null : 180,
          width: double.infinity,
          fit: fullHeight ? BoxFit.contain : BoxFit.cover,
          errorBuilder: (_, __, ___) => _errorIcon(),
        );
      } catch (e) {
        return _errorIcon();
      }
    } else {
      return Image.network(
        url,
        height: fullHeight ? null : 180,
        width: double.infinity,
        fit: fullHeight ? BoxFit.contain : BoxFit.cover,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Container(
                height: 180,
                color: Colors.grey.shade100,
                child: const Center(child: CircularProgressIndicator()),
              ),
        errorBuilder: (_, __, ___) => _errorIcon(),
      );
    }
  }

  Widget _errorIcon() {
    return Container(
      height: 120,
      color: Colors.grey.shade100,
      child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
    );
  }

  Future<void> _approve(BuildContext context, Map<String, dynamic> data) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Approve Subscription'),
        content: Text(
          'Approve ${data['name']}\'s ${data['tierName']} plan for ₹${data['amount']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final duration = (data['billingCycle'] ?? 'monthly') == 'yearly'
          ? const Duration(days: 365)
          : const Duration(days: 30);
      final expiryDate = DateTime.now().add(duration);

      await ref
          .read(firestoreServiceProvider)
          .approveSubscriptionVerification(
            docId: data['id'],
            userId: data['userId'],
            tierId: data['tierId'],
            amount: (data['amount'] as num).toDouble(),
            expiry: expiryDate,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Subscription approved & activated!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _reject(
    BuildContext context,
    String docId,
    String userId,
  ) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. Invalid UTR, blurry screenshot...',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref
          .read(firestoreServiceProvider)
          .rejectSubscriptionVerification(
            docId: docId,
            userId: userId,
            reason: reasonCtrl.text.trim(),
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification rejected'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatDate(dynamic ts) {
    try {
      if (ts == null) return '—';
      DateTime dt;
      if (ts is DateTime) {
        dt = ts;
      } else {
        dt = ts.toDate();
      }
      return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '—';
    }
  }
}
