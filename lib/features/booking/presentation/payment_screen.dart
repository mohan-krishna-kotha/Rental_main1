import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/models/order_models.dart';
import '../../../../core/models/product_model.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/items_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import 'mock_payment_gateway_dialog.dart'; // <-- Import the dialog

class PaymentScreen extends ConsumerStatefulWidget {
  final OrderModel order;
  final List<OrderItemModel> items;
  final ProductModel? sourceProduct; // For Seeding

  const PaymentScreen({
    super.key,
    required this.order,
    required this.items,
    this.sourceProduct,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _isProcessing = false;
  int _selectedMethod = 0;

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    // Simulate Network Delay
    await Future.delayed(const Duration(seconds: 2));

    try {
      final item = widget.items.first;
      final product = widget.sourceProduct;

      // 1. Seed the Product FIRST if it doesn't exist (Sample Item)
      if (product != null) {
        print('DEBUG: Seeding Product ID: ${product.id}');
        await ref.read(firestoreServiceProvider).seedProductIfNeeded(product);
      }

      // 2. Create comprehensive order with all subcollections
      print(
        'DEBUG: Creating comprehensive order for Order ID: ${widget.order.id}',
      );
      await ref
          .read(firestoreServiceProvider)
          .createCompleteOrder(
            order: widget.order,
            orderItems: widget.items,
            transactionData: {
              'transactionType': 'payment',
              'transactionStatus': 'success',
              'paymentMethod': _selectedMethod == 0
                  ? 'credit_card'
                  : _selectedMethod == 1
                  ? 'debit_card'
                  : 'upi',
              'amount': widget.order.totalAmount,
              'gatewayName': 'razorpay',
              'gatewayTransactionId':
                  'PAY_${DateTime.now().millisecondsSinceEpoch}',
            },
            rentalData: {
              'depositAmount': widget.order.depositAmount,
              'startDate': item.rentalStartDate,
              'endDate': item.rentalEndDate,
              'returnStatus': 'pending',
              'refundStatus': 'pending',
            },
          );
      print('DEBUG: Order creation SUCCESS!');

      // 3. Product Status Update skipped to avoid permission errors.
      // Availability is guaranteed by the 'bookings' subcollection created in createCompleteOrder.
      // Logic for updating 'status' to 'rented' should be handled by a backend trigger or
      // by the Owner/Admin accepting the request, if we move to that flow.
      print(
        'DEBUG: Sub-collection booking created, skipping direct product update.',
      );

      if (mounted) {
        // Navigate to Success
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const PaymentSuccessScreen()),
          (route) => route.isFirst,
        );
      }
    } catch (e, stack) {
      print('ERROR: Payment processing failed: $e');
      print(stack);

      String errorMessage = e.toString();

      // Attempt to unwrap "Dart exception thrown from converted Future"
      try {
        // Check if e has an 'error' property (BoxedError)
        final dynamic errorObj = e;
        // Using dynamic access to check for .error property which might exist on wrapped JS errors
        try {
          if (errorObj.error != null) {
            errorMessage = errorObj.error.toString();
          }
        } catch (_) {}
      } catch (_) {}

      if (errorMessage.contains(
        'Dart exception thrown from converted Future',
      )) {
        errorMessage = "Network or Database Error. Please try again.";
      } else if (e is FirebaseException && e.message != null) {
        errorMessage = e.message!;
      } else if (e.toString().contains('unavailable')) {
        errorMessage = 'Selected dates are unavailable.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// Opens the Razorpay-style payment dialog.
  /// Only calls [_processPayment] after the user successfully completes the gateway.
  void _showPaymentGateway(double amount) {
    // Map our method index to dialog's method index
    // 0: Credit/Debit Card -> 0 (Card)
    // 1: UPI               -> 1 (UPI)
    // 2: Netbanking        -> 3 (Netbanking)
    // 3: Wallets           -> 4 (wallet)
    // 4: Cash on Delivery  -> show a simple snackbar confirmation
    if (_selectedMethod == 4) {
      // Cash on Delivery: no gateway needed, directly process
      _processPayment();
      return;
    }

    final dialogMethodIndex = [0, 1, 3, 4, 0][_selectedMethod.clamp(0, 4)];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => MockPaymentGatewayDialog(
        amount: amount,
        paymentMethodIndex: dialogMethodIndex,
        onSuccess: () {
          // Called only after user enters details and confirms
          _processPayment();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Assuming single item for now as per UI design
    final firstItem = widget.items.first;
    final days = firstItem.rentalEndDate
        .difference(firstItem.rentalStartDate)
        .inDays;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Return to Home',
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: ref
            .read(firestoreServiceProvider)
            .getProductById(firstItem.productId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final product = snapshot.data;
          final itemTitle = product?.title ?? firstItem.productName;
          final pricePerDay = firstItem.unitPrice;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Consumer(
                    builder: (context, ref, _) {
                      final userModel = ref.watch(userModelProvider).value;
                      final hasReducedFees = userModel?.hasReducedFees ?? false;

                      final subtotal = (days > 0 ? days : 1) * pricePerDay;
                      final feeRate = hasReducedFees
                          ? 0.05
                          : 0.10; // 5% for Premium, 10% for Basic
                      final platformFee = subtotal * feeRate;

                      // Delivery Charge Logic (Standard: ₹50, Premium: Free)
                      final deliveryCharge = hasReducedFees ? 0.0 : 50.0;

                      // Recalculate total to display breakdown (stored totalAmount in order should match)
                      final calculatedTotal =
                          subtotal + platformFee + deliveryCharge;

                      return Column(
                        children: [
                          // Rental Cost
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Rental Cost',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                itemTitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                '₹${subtotal.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24, thickness: 1),

                          // Platform Fee
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Platform Fee',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (hasReducedFees)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.green),
                                      ),
                                      child: const Text(
                                        '50% OFF',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              Text(
                                '₹${platformFee.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: hasReducedFees
                                      ? Colors.green
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24, thickness: 1),

                          // Delivery Charges
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Delivery Charges',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (deliveryCharge == 0)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.green),
                                      ),
                                      child: const Text(
                                        'FREE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              Text(
                                '₹${deliveryCharge.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: deliveryCharge == 0
                                      ? Colors.green
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24, thickness: 1),

                          // Total
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Payable',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '₹${calculatedTotal.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Color(0xFF781C2E),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),

                const Text(
                  'Payment Method',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),

                _buildMethodTile(0, 'Credit / Debit Card', Icons.credit_card),
                _buildMethodTile(
                  1,
                  'UPI (Google Pay / PhonePe)',
                  Icons.qr_code_scanner,
                ),
                _buildMethodTile(2, 'Netbanking', Icons.account_balance),
                _buildMethodTile(3, 'Wallets', Icons.account_balance_wallet),
                _buildMethodTile(4, 'Cash on Delivery', Icons.money),

                const SizedBox(height: 48),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                    child: ElevatedButton(
                      onPressed: _isProcessing
                          ? null
                          : () {
                              // Calculate total to pass to dialog
                              final userModel = ref.read(userModelProvider).value;
                              final hasReducedFees = userModel?.hasReducedFees ?? false;
                              final days = widget.items.first.rentalEndDate
                                  .difference(widget.items.first.rentalStartDate)
                                  .inDays;
                              final subtotal = (days > 0 ? days : 1) * widget.items.first.unitPrice;
                              final feeRate = hasReducedFees ? 0.05 : 0.10;
                              final platformFee = subtotal * feeRate;
                              final deliveryCharge = hasReducedFees ? 0.0 : 50.0;
                              final total = subtotal + platformFee + deliveryCharge;
                              _showPaymentGateway(total);
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF781C2E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isProcessing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'PAY & BOOK NOW',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMethodTile(int index, String title, IconData icon) {
    final isSelected = _selectedMethod == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF781C2E) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF781C2E) : Colors.grey,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF781C2E)),
          ],
        ),
      ),
    );
  }
}

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 100,
            ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
            const SizedBox(height: 24),
            const Text(
              'Booking Confirmed!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your order has been placed successfully.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
