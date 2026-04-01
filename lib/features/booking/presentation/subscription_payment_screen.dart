import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'payment_verification_screen.dart';

// ─── Constants ───────────────────────────────────────────────────────────────
const _maroon = Color(0xFF781C2E);
const _upiId = 'yourname@upi'; // 🔴 Replace with your actual UPI ID

class SubscriptionPaymentScreen extends ConsumerStatefulWidget {
  final String tierId;
  final String tierName;
  final double amount;
  final String billingCycle;

  const SubscriptionPaymentScreen({
    super.key,
    required this.tierId,
    required this.tierName,
    required this.amount,
    required this.billingCycle,
  });

  @override
  ConsumerState<SubscriptionPaymentScreen> createState() =>
      _SubscriptionPaymentScreenState();
}

class _SubscriptionPaymentScreenState
    extends ConsumerState<SubscriptionPaymentScreen> {
  // ── Navigate to verification form ────────────────────────────────────────
  void _confirmPayment() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentVerificationScreen(
          tierId: widget.tierId,
          tierName: widget.tierName,
          amount: widget.amount,
          billingCycle: widget.billingCycle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final amountText = '₹${widget.amount.toStringAsFixed(0)}';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6EE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _maroon),
        title: const Text(
          'Subscription Payment',
          style: TextStyle(color: _maroon, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Plan Summary Card ────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Plan',
                          style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600)),
                      Text(
                        '${widget.tierName} (${widget.billingCycle})',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Payable',
                          style: TextStyle(
                              color: Colors.black, fontWeight: FontWeight.bold)),
                      Text(
                        amountText,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: _maroon,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.1),

            const SizedBox(height: 28),

            // ── Instruction ──────────────────────────────────────────────────
            const Text(
              'Scan the QR code below to pay',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 6),
            Text(
              'Use any UPI app — Google Pay, PhonePe, Paytm, BHIM',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 24),

            // ── QR Code Box ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                      color: _maroon.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                children: [
                  // Supported Apps Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _upiChip('GPay', Colors.blue.shade700),
                      _upiChip('PhonePe', Colors.purple.shade700),
                      _upiChip('Paytm', Colors.blue.shade400),
                      _upiChip('BHIM', Colors.green.shade600),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // QR Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/upi_qr_code.png',
                      width: 230,
                      height: 230,
                      fit: BoxFit.cover,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Amount badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: _maroon,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      amountText,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // UPI ID Copy Row
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                          const ClipboardData(text: _upiId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('UPI ID copied!'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.account_balance_wallet_outlined,
                              size: 16, color: _maroon),
                          const SizedBox(width: 8),
                          Text(
                            _upiId,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontSize: 13),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.copy, size: 14, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1, 1)),

            const SizedBox(height: 24),

            // ── Steps ─────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('How to pay:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 10),
                  _step('1', 'Open your UPI app (GPay, PhonePe, etc.)'),
                  _step('2', 'Scan the QR code or enter UPI ID manually'),
                  _step('3', 'Enter amount: $amountText and complete payment'),
                  _step('4', 'Tap "I Have Paid" below to fill verification form'),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 28),

            // ── "I Have Paid" Button ───────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _confirmPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _maroon,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_outlined, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'I Have Paid — Fill Verification Form',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 350.ms),

            const SizedBox(height: 14),
            Text(
              'Your plan will be activated after admin confirms your payment.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _upiChip(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _step(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(right: 10, top: 1),
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(num,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: Text(text,
                style:
                    const TextStyle(fontSize: 13, color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}
