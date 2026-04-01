import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/items_provider.dart';
import 'subscription_payment_screen.dart';

const _maroon = Color(0xFF781C2E);

class PaymentVerificationScreen extends ConsumerStatefulWidget {
  final String tierId;
  final String tierName;
  final double amount;
  final String billingCycle;

  const PaymentVerificationScreen({
    super.key,
    required this.tierId,
    required this.tierName,
    required this.amount,
    required this.billingCycle,
  });

  @override
  ConsumerState<PaymentVerificationScreen> createState() =>
      _PaymentVerificationScreenState();
}

class _PaymentVerificationScreenState
    extends ConsumerState<PaymentVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _utrCtrl = TextEditingController();

  XFile? _screenshot;
  Uint8List? _screenshotBytes; // Add this to store bytes for preview
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _utrCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Lower quality for Base64 (to fit in 1MB limit)
      maxWidth: 512,   // Smaller size
      maxHeight: 512,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _screenshot = picked;
        _screenshotBytes = bytes;
      });
    }
  }

  Future<String?> _uploadScreenshot(String uid) async {
    if (_screenshot == null) return null;
    try {
      // 🟢 NO STORAGE NEEDED: Convert to Base64 string for Firestore
      final bytes = await _screenshot!.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      print('Conversion error: $e');
      return null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_screenshot == null) {
      _snack('Please attach your payment screenshot', Colors.orange);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw 'Not logged in';

      // 1. Create the document FIRST so it appears in Firestore immediately
      final docId = await ref.read(firestoreServiceProvider).submitSubscriptionVerification(
            userId: user.uid,
            userEmail: user.email ?? '',
            name: _nameCtrl.text.trim(),
            utrId: _utrCtrl.text.trim(),
            amount: widget.amount,
            tierId: widget.tierId,
            tierName: widget.tierName,
            billingCycle: widget.billingCycle,
            screenshotUrl: null, // Initial write with no URL
          );

      // 2. Now upload the screenshot
      final screenshotUrl = await _uploadScreenshot(user.uid);

      // 3. Update the document with the URL link
      if (screenshotUrl != null) {
        await ref.read(firestoreServiceProvider).updateSubscriptionVerificationUrl(
              docId: docId,
              screenshotUrl: screenshotUrl,
            );
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (_) => const VerificationSubmittedScreen()),
        );
      }
    } catch (e) {
      _snack('Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6EE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _maroon),
        title: const Text(
          'Payment Verification',
          style: TextStyle(color: _maroon, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header info ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _maroon.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _maroon.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: _maroon, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Please fill in the details below after completing your UPI payment of ₹${widget.amount.toStringAsFixed(0)}. '
                        'Your plan will be activated after admin verification.',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(),

              const SizedBox(height: 24),

              // ── Plan Badge ──────────────────────────────────────────────
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: _maroon,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    '${widget.tierName} · ₹${widget.amount.toStringAsFixed(0)} · ${widget.billingCycle}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 28),

              // ── Form Fields ─────────────────────────────────────────────
              _label('Full Name *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(color: Colors.black87),
                decoration: _deco(
                    'Enter your full name', Icons.person_outline),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 18),

              _label('UTR / Transaction ID *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _utrCtrl,
                style: const TextStyle(color: Colors.black87),
                decoration: _deco(
                    'e.g. 123456789012 (12-digit UTR)', Icons.receipt_long),
                keyboardType: TextInputType.text,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'UTR ID is required';
                  if (v.trim().length < 6) return 'Enter a valid UTR / Transaction ID';
                  return null;
                },
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 24),

              // ── Screenshot Upload ───────────────────────────────────────
              _label('Payment Screenshot *'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _isSubmitting ? null : _pickScreenshot,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  height: _screenshot == null ? 140 : 240,
                  decoration: BoxDecoration(
                    color: _screenshot == null
                        ? Colors.grey.shade50
                        : Colors.black,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _screenshot == null
                          ? Colors.grey.shade300
                          : _maroon,
                      width: _screenshot == null ? 1.5 : 2,
                      style: _screenshot == null
                          ? BorderStyle.solid
                          : BorderStyle.solid,
                    ),
                  ),
                  child: _screenshot == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 42,
                                color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            const Text(
                              'Tap to upload payment screenshot',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'JPG, PNG supported',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 11),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _screenshotBytes!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 240,
                          ),
                        ),
                ),
              ).animate().fadeIn(delay: 250.ms),

              if (_screenshot != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 16),
                    const SizedBox(width: 6),
                    const Text(
                      'Screenshot attached',
                      style:
                          TextStyle(color: Colors.green, fontSize: 12),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _pickScreenshot,
                      child: const Text('Change',
                          style: TextStyle(color: _maroon, fontSize: 12)),
                    )
                  ],
                ),
              ],

              const SizedBox(height: 32),

              // ── Submit Button ───────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _maroon,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Submitting verification…',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_outlined, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Submit for Verification',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Admin will verify and activate your plan within 24 hours.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black87),
      );

  InputDecoration _deco(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(icon, size: 20, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _maroon, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
}

// ─── Verification Submitted Success Screen ────────────────────────────────────
class VerificationSubmittedScreen extends StatelessWidget {
  const VerificationSubmittedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_top_rounded,
                    color: Colors.orange, size: 72),
              )
                  .animate()
                  .scale(curve: Curves.elasticOut, duration: 700.ms)
                  .then()
                  .shimmer(duration: 1200.ms),

              const SizedBox(height: 28),

              const Text(
                'Verification Submitted!',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ).animate().fadeIn().moveY(begin: 12, end: 0),

              const SizedBox(height: 12),

              Text(
                'Our admin will review your payment details and activate your subscription within 24 hours.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 40),

              // Status card
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 380),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  children: [
                    _statusRow(
                        Icons.check_circle, Colors.green, 'Payment details submitted'),
                    const SizedBox(height: 12),
                    _statusRow(
                        Icons.hourglass_empty, Colors.orange, 'Admin review pending'),
                    const SizedBox(height: 12),
                    _statusRow(
                        Icons.lock_clock, Colors.grey, 'Subscription activation'),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.15, end: 0),

              const SizedBox(height: 48),

              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // Pop back to profile / home
                    Navigator.of(context)
                        .popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF781C2E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Back to Home',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ).animate().fadeIn(delay: 400.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusRow(IconData icon, Color color, String label) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
      ],
    );
  }
}
