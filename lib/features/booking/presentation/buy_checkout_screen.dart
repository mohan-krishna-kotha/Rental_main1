import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/product_model.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/items_provider.dart';
import '../../../../core/utils/booking_policy.dart';
import '../../kyc/helpers/kyc_enforcement.dart';
import '../../profile/presentation/screens/kyc_screen.dart';
import '../../profile/presentation/screens/settings_screen.dart';
import '../../home/presentation/screens/subscription_screen.dart';

class BuyCheckoutScreen extends ConsumerStatefulWidget {
  final ProductModel item;

  const BuyCheckoutScreen({super.key, required this.item});

  @override
  ConsumerState<BuyCheckoutScreen> createState() => _BuyCheckoutScreenState();
}

class _BuyCheckoutScreenState extends ConsumerState<BuyCheckoutScreen> {
  bool _isUnlocking = false;
  bool _isContactUnlocked = false;

  int? _usedThisMonth;
  int? _limitThisMonth;

  String? _ownerEmail;
  String? _ownerPhone;

  double get _salePrice => widget.item.salePrice ?? 0.0;

  Future<void> _unlockOwnerDetails() async {
    if (_isUnlocking || _isContactUnlocked) return;
    setState(() => _isUnlocking = true);

    try {
      final salePrice = _salePrice;
      if (salePrice <= 0) {
        throw Exception('This item is not available for sale');
      }

      final currentUser = ref.read(currentUserProvider);
      final userModel = ref.read(userModelProvider).value;

      if (currentUser == null || userModel == null) {
        throw Exception('Please sign in and wait for profile to load.');
      }

      final hasPhone = await KycEnforcement.ensurePhoneNumber(
        context: context,
        user: userModel,
        actionDescription: 'buy items',
        onAddPhone: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        },
      );
      if (!hasPhone) return;

      if (!userModel.canBookItems) {
        if (!mounted) return;
        final canBuy = await KycEnforcement.canUserBookItems(
          context: context,
          user: userModel,
          onStartKyc: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const KycScreen()),
            );
          },
        );
        if (!canBuy) return;
      }

      final firestoreService = ref.read(firestoreServiceProvider);
      int usedThisMonth;
      try {
        usedThisMonth = await firestoreService
            .getCurrentMonthContactUnlockCount(currentUser.uid);
      } catch (e) {
        debugPrint('Contact unlock usage read failed, using fallback: $e');
        usedThisMonth = await firestoreService.getCurrentMonthRentalCount(
          currentUser.uid,
        );
      }
      final limitThisMonth = userModel.monthlyRentLimit;

      if (!mounted) return;
      setState(() {
        _usedThisMonth = usedThisMonth;
        _limitThisMonth = limitThisMonth;
      });

      if (!BookingPolicy.canUnlockContact(
        usedThisMonth: usedThisMonth,
        monthlyLimit: limitThisMonth,
      )) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Monthly Limit Reached'),
            content: Text(
              'You have used $usedThisMonth of $limitThisMonth monthly actions. Upgrade your plan to view owner contact details.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Not now'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionScreen(),
                    ),
                  );
                },
                child: const Text('Upgrade Plan'),
              ),
            ],
          ),
        );
        return;
      }

      final ownerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.item.ownerId)
          .get();
      final ownerData = ownerDoc.data() ?? <String, dynamic>{};

      final ownerEmail = (ownerData['email'] ?? '').toString().trim();
      final ownerPhone = (ownerData['phoneNumber'] ?? ownerData['phone'] ?? '')
          .toString()
          .trim();

      var updatedUsed = usedThisMonth;
      try {
        await firestoreService.recordContactUnlock(
          userId: currentUser.uid,
          productId: widget.item.id,
          unlockType: 'buy',
        );
        updatedUsed = usedThisMonth + 1;
      } catch (e) {
        debugPrint('Contact unlock tracking write failed (non-blocking): $e');
      }

      if (!mounted) return;
      setState(() {
        _isContactUnlocked = true;
        _usedThisMonth = updatedUsed;
        _ownerEmail = ownerEmail.isNotEmpty
            ? ownerEmail
            : '${widget.item.ownerId}@rental.app';
        _ownerPhone = ownerPhone.isNotEmpty ? ownerPhone : null;
      });
    } catch (e, stack) {
      debugPrint('ERROR: Buy checkout contact unlock failed: $e');
      debugPrint(stack.toString());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUnlocking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final salePrice = item.salePrice ?? 0.0;

    if (salePrice <= 0 || item.transactionMode != 'sell') {
      return Scaffold(
        appBar: AppBar(title: const Text('Buy Checkout')),
        body: const Center(child: Text('This item is not available for sale.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy Checkout'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Return to Home',
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.ownerName,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const Divider(height: 24, thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sale Price',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Rs ${salePrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  if (item.originalPrice != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Original Price (MRP)',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Rs ${item.originalPrice!.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Divider(height: 24, thickness: 1),
                  const Text(
                    'Escrow and in-app payment are currently disabled. Discuss pricing and delivery directly with the owner.',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_usedThisMonth != null && _limitThisMonth != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'This month usage: $_usedThisMonth/$_limitThisMonth',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.contact_phone_outlined, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Owner Contact Details',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isContactUnlocked) ...[
                    _ContactRow(label: 'Name', value: item.ownerName),
                    const SizedBox(height: 8),
                    _ContactRow(
                      label: 'Email',
                      value: _ownerEmail ?? 'Not available',
                    ),
                    const SizedBox(height: 8),
                    _ContactRow(
                      label: 'Phone',
                      value: _ownerPhone ?? 'Not available',
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'You can now contact the owner and complete this purchase directly.',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else
                    Text(
                      'Contact details are hidden until plan eligibility is confirmed.',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: (_isUnlocking || _isContactUnlocked)
                    ? null
                    : _unlockOwnerDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF781C2E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isUnlocking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.4,
                        ),
                      )
                    : Text(
                        _isContactUnlocked
                            ? 'OWNER DETAILS UNLOCKED'
                            : 'GET OWNER DETAILS',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Text(': '),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
