import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/models/payment_method_model.dart';
import '../../../../core/providers/items_provider.dart';

// ─────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────
final paymentMethodsProvider =
    StreamProvider.autoDispose<List<PaymentMethodModel>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value([]);
  return ref.read(firestoreServiceProvider).streamPaymentMethods(uid);
});

// ─────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────
class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  static const _maroon = Color(0xFF781C2E);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methodsAsync = ref.watch(paymentMethodsProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
        actions: [
          TextButton.icon(
            onPressed: () => _showAddMethodSheet(context, ref, uid),
            icon: const Icon(Icons.add, color: _maroon),
            label: const Text('Add', style: TextStyle(color: _maroon)),
          ),
        ],
      ),
      body: methodsAsync.when(
        data: (methods) {
          if (methods.isEmpty) {
            return _buildEmptyState(context, ref, uid);
          }
          return _buildMethodList(context, ref, uid, methods);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  // ── Empty State ──────────────────────────────────────────────
  Widget _buildEmptyState(
      BuildContext context, WidgetRef ref, String uid) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.credit_card_off, size: 72, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No saved payment methods',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add a card, UPI, or bank account\nfor faster checkout.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showAddMethodSheet(context, ref, uid),
            icon: const Icon(Icons.add),
            label: const Text('Add Payment Method'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _maroon,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  // ── Method List ──────────────────────────────────────────────
  Widget _buildMethodList(BuildContext context, WidgetRef ref, String uid,
      List<PaymentMethodModel> methods) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Saved Methods
        const Text(
          'Saved Methods',
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        ...methods.asMap().entries.map((entry) {
          final method = entry.value;
          return _PaymentMethodTile(
            method: method,
            onSetDefault: () => ref
                .read(firestoreServiceProvider)
                .setDefaultPaymentMethod(uid, method.id),
            onDelete: () => _confirmDelete(context, ref, uid, method),
          )
              .animate(delay: Duration(milliseconds: entry.key * 60))
              .fadeIn()
              .slideX(begin: -0.05);
        }),

        const SizedBox(height: 32),

        // Add Another
        OutlinedButton.icon(
          onPressed: () => _showAddMethodSheet(context, ref, uid),
          icon: const Icon(Icons.add, color: _maroon),
          label:
              const Text('Add Another Method', style: TextStyle(color: _maroon)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: _maroon),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),

        const SizedBox(height: 24),

        // Supported UPI apps row
        const Text(
          'Supported UPI Apps',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _UpiAppPill('Google Pay', Colors.blue.shade700),
              _UpiAppPill('PhonePe', Colors.purple.shade700),
              _UpiAppPill('Paytm', Colors.blue.shade400),
              _UpiAppPill('BHIM', Colors.green.shade600),
              _UpiAppPill('Cred', Colors.black),
            ],
          ),
        ),
      ],
    );
  }

  // ── Dialogs ──────────────────────────────────────────────────
  void _showAddMethodSheet(
      BuildContext context, WidgetRef ref, String uid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddPaymentMethodSheet(userId: uid, ref: ref),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String uid,
      PaymentMethodModel method) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Method'),
        content: Text('Remove "${method.displayTitle}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(firestoreServiceProvider)
                  .deletePaymentMethod(uid, method.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment method removed')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Method Tile
// ─────────────────────────────────────────────────────────────
class _PaymentMethodTile extends StatelessWidget {
  final PaymentMethodModel method;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  const _PaymentMethodTile({
    required this.method,
    required this.onSetDefault,
    required this.onDelete,
  });

  static const _maroon = Color(0xFF781C2E);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: method.isDefault ? _maroon : Colors.grey.shade200,
          width: method.isDefault ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _iconColor(method.type).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_iconData(method.type),
                  color: _iconColor(method.type), size: 22),
            ),
            const SizedBox(width: 14),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        method.displayTitle,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      if (method.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _maroon,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('DEFAULT',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    method.displaySubtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),

            // Actions menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onSelected: (val) {
                if (val == 'default') onSetDefault();
                if (val == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                if (!method.isDefault)
                  const PopupMenuItem(
                      value: 'default',
                      child: Row(children: [
                        Icon(Icons.star_outline, size: 18),
                        SizedBox(width: 8),
                        Text('Set as Default'),
                      ])),
                const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Remove', style: TextStyle(color: Colors.red)),
                    ])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconData(PaymentMethodType t) {
    switch (t) {
      case PaymentMethodType.card:
        return Icons.credit_card;
      case PaymentMethodType.upi:
        return Icons.qr_code_scanner;
      case PaymentMethodType.netbanking:
        return Icons.account_balance;
      case PaymentMethodType.wallet:
        return Icons.account_balance_wallet;
    }
  }

  Color _iconColor(PaymentMethodType t) {
    switch (t) {
      case PaymentMethodType.card:
        return Colors.blue;
      case PaymentMethodType.upi:
        return Colors.green;
      case PaymentMethodType.netbanking:
        return Colors.orange;
      case PaymentMethodType.wallet:
        return Colors.purple;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Add Method Bottom Sheet
// ─────────────────────────────────────────────────────────────
class _AddPaymentMethodSheet extends StatefulWidget {
  final String userId;
  final WidgetRef ref;

  const _AddPaymentMethodSheet({required this.userId, required this.ref});

  @override
  State<_AddPaymentMethodSheet> createState() => _AddPaymentMethodSheetState();
}

class _AddPaymentMethodSheetState extends State<_AddPaymentMethodSheet> {
  PaymentMethodType _selectedType = PaymentMethodType.card;
  bool _setAsDefault = false;
  bool _isSaving = false;

  static const _maroon = Color(0xFF781C2E);

  // Card fields
  final _cardNumberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  // UPI fields
  final _upiCtrl = TextEditingController();
  String _selectedUpiApp = 'Google Pay';
  final List<String> _upiApps = [
    'Google Pay', 'PhonePe', 'Paytm', 'BHIM', 'Cred', 'Other'
  ];

  // Netbanking fields
  String? _selectedBank;
  final List<String> _banks = [
    'SBI', 'HDFC Bank', 'ICICI Bank', 'Axis Bank',
    'Kotak Bank', 'PNB', 'Bank of Baroda', 'Canara Bank', 'Other'
  ];

  // Wallet fields
  String _selectedWallet = 'Paytm Wallet';
  final List<String> _wallets = [
    'Paytm Wallet', 'Amazon Pay', 'Ola Money', 'Mobikwik', 'Freecharge'
  ];

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _nameCtrl.dispose();
    _upiCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // Validation
    if (_selectedType == PaymentMethodType.card) {
      if (_cardNumberCtrl.text.replaceAll(' ', '').length < 16) {
        _snack('Enter a valid 16-digit card number');
        return;
      }
      if (_expiryCtrl.text.length < 5) {
        _snack('Enter valid expiry (MM/YY)');
        return;
      }
      if (_cvvCtrl.text.length < 3) {
        _snack('Enter valid CVV');
        return;
      }
      if (_nameCtrl.text.trim().isEmpty) {
        _snack('Enter card holder name');
        return;
      }
    } else if (_selectedType == PaymentMethodType.upi) {
      if (!_upiCtrl.text.contains('@')) {
        _snack('Enter a valid UPI ID (e.g. name@upi)');
        return;
      }
    } else if (_selectedType == PaymentMethodType.netbanking) {
      if (_selectedBank == null) {
        _snack('Please select a bank');
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      // For cards: we only store last4 + brand (never full number)
      String? last4;
      String? brand;
      if (_selectedType == PaymentMethodType.card) {
        final digits = _cardNumberCtrl.text.replaceAll(' ', '');
        last4 = digits.substring(digits.length - 4);
        // Simple brand detection
        if (digits.startsWith('4')) brand = 'Visa';
        else if (digits.startsWith('5')) brand = 'Mastercard';
        else if (digits.startsWith('6')) brand = 'Rupay';
        else brand = 'Card';
      }

      final method = PaymentMethodModel(
        userId: widget.userId,
        type: _selectedType,
        cardLast4: last4,
        cardBrand: brand,
        cardExpiry: _selectedType == PaymentMethodType.card
            ? _expiryCtrl.text
            : null,
        cardHolderName: _selectedType == PaymentMethodType.card
            ? _nameCtrl.text.trim()
            : null,
        upiId:
            _selectedType == PaymentMethodType.upi ? _upiCtrl.text.trim() : null,
        upiApp: _selectedType == PaymentMethodType.upi ? _selectedUpiApp : null,
        bankName: _selectedType == PaymentMethodType.netbanking
            ? _selectedBank
            : null,
        walletName: _selectedType == PaymentMethodType.wallet
            ? _selectedWallet
            : null,
        isDefault: _setAsDefault,
      );

      await widget.ref.read(firestoreServiceProvider).addPaymentMethod(method);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment method saved ✓'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _snack('Failed to save: $e');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const Text(
                'Add Payment Method',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Type selector tabs
              Row(
                children: PaymentMethodType.values.map((type) {
                  final isSelected = _selectedType == type;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _maroon.withOpacity(0.1)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? _maroon : Colors.transparent,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(_typeIcon(type),
                                color: isSelected ? _maroon : Colors.grey,
                                size: 20),
                            const SizedBox(height: 4),
                            Text(
                              _typeLabel(type),
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected ? _maroon : Colors.grey,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Dynamic Form
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _buildForm(),
              ),

              const SizedBox(height: 16),

              // Set as default toggle
              Row(
                children: [
                  Switch(
                    value: _setAsDefault,
                    onChanged: (v) => setState(() => _setAsDefault = v),
                    activeColor: _maroon,
                  ),
                  const SizedBox(width: 8),
                  const Text('Set as default payment method'),
                ],
              ),

              const SizedBox(height: 8),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _maroon,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Save Payment Method',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    switch (_selectedType) {
      case PaymentMethodType.card:
        return _CardForm(
          key: const ValueKey('card'),
          numberCtrl: _cardNumberCtrl,
          expiryCtrl: _expiryCtrl,
          cvvCtrl: _cvvCtrl,
          nameCtrl: _nameCtrl,
        );
      case PaymentMethodType.upi:
        return _UpiForm(
          key: const ValueKey('upi'),
          upiCtrl: _upiCtrl,
          selectedApp: _selectedUpiApp,
          apps: _upiApps,
          onAppChanged: (v) => setState(() => _selectedUpiApp = v!),
        );
      case PaymentMethodType.netbanking:
        return _NetbankingForm(
          key: const ValueKey('netbanking'),
          selectedBank: _selectedBank,
          banks: _banks,
          onBankChanged: (v) => setState(() => _selectedBank = v),
        );
      case PaymentMethodType.wallet:
        return _WalletForm(
          key: const ValueKey('wallet'),
          selectedWallet: _selectedWallet,
          wallets: _wallets,
          onWalletChanged: (v) => setState(() => _selectedWallet = v!),
        );
    }
  }

  IconData _typeIcon(PaymentMethodType t) {
    switch (t) {
      case PaymentMethodType.card:
        return Icons.credit_card;
      case PaymentMethodType.upi:
        return Icons.qr_code_scanner;
      case PaymentMethodType.netbanking:
        return Icons.account_balance;
      case PaymentMethodType.wallet:
        return Icons.account_balance_wallet;
    }
  }

  String _typeLabel(PaymentMethodType t) {
    switch (t) {
      case PaymentMethodType.card:
        return 'Card';
      case PaymentMethodType.upi:
        return 'UPI';
      case PaymentMethodType.netbanking:
        return 'Bank';
      case PaymentMethodType.wallet:
        return 'Wallet';
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Sub-forms
// ─────────────────────────────────────────────────────────────
class _CardForm extends StatelessWidget {
  final TextEditingController numberCtrl, expiryCtrl, cvvCtrl, nameCtrl;

  const _CardForm({
    super.key,
    required this.numberCtrl,
    required this.expiryCtrl,
    required this.cvvCtrl,
    required this.nameCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Card Number'),
        TextField(
          controller: numberCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [
            LengthLimitingTextInputFormatter(19),
            _CardNumberFormatter(),
          ],
          decoration: _deco('0000 0000 0000 0000', Icons.credit_card),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Expiry (MM/YY)'),
                  TextField(
                    controller: expiryCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(5),
                      _ExpiryFormatter(),
                    ],
                    decoration: _deco('MM/YY', null),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('CVV'),
                  TextField(
                    controller: cvvCtrl,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: _deco('•••', null).copyWith(counterText: ''),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _label('Card Holder Name'),
        TextField(
          controller: nameCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: _deco('Full name on card', Icons.person_outline),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.lock, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            const Text(
              'Your full card number is never stored.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }
}

class _UpiForm extends StatelessWidget {
  final TextEditingController upiCtrl;
  final String selectedApp;
  final List<String> apps;
  final ValueChanged<String?> onAppChanged;

  const _UpiForm({
    super.key,
    required this.upiCtrl,
    required this.selectedApp,
    required this.apps,
    required this.onAppChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('UPI App'),
        DropdownButtonFormField<String>(
          value: selectedApp,
          items: apps.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
          onChanged: onAppChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
        const SizedBox(height: 12),
        _label('UPI ID'),
        TextField(
          controller: upiCtrl,
          decoration: _deco('example@upi', Icons.alternate_email),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.blue),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'A collect request will be sent to your UPI app at time of payment.',
                  style: TextStyle(fontSize: 11, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NetbankingForm extends StatelessWidget {
  final String? selectedBank;
  final List<String> banks;
  final ValueChanged<String?> onBankChanged;

  const _NetbankingForm({
    super.key,
    required this.selectedBank,
    required this.banks,
    required this.onBankChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Select Your Bank'),
        DropdownButtonFormField<String>(
          value: selectedBank,
          hint: const Text('Choose a bank...'),
          items: banks.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
          onChanged: onBankChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'You will be redirected to your bank\'s portal at payment time.',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}

class _WalletForm extends StatelessWidget {
  final String selectedWallet;
  final List<String> wallets;
  final ValueChanged<String?> onWalletChanged;

  const _WalletForm({
    super.key,
    required this.selectedWallet,
    required this.wallets,
    required this.onWalletChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Select Wallet'),
        DropdownButtonFormField<String>(
          value: selectedWallet,
          items: wallets
              .map((w) => DropdownMenuItem(value: w, child: Text(w)))
              .toList(),
          onChanged: onWalletChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// UPI App pill (decorative)
// ─────────────────────────────────────────────────────────────
class _UpiAppPill extends StatelessWidget {
  final String name;
  final Color color;

  const _UpiAppPill(this.name, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(name,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────
Widget _label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
    );

InputDecoration _deco(String hint, IconData? icon) => InputDecoration(
      hintText: hint,
      prefixIcon:
          icon != null ? Icon(icon, size: 18, color: Colors.grey) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      isDense: true,
    );

// ─────────────────────────────────────────────────────────────
// Input Formatters
// ─────────────────────────────────────────────────────────────
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final s = buf.toString();
    return newValue.copyWith(
        text: s, selection: TextSelection.collapsed(offset: s.length));
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final buf = StringBuffer();
    for (int i = 0; i < digits.length && i < 4; i++) {
      if (i == 2) buf.write('/');
      buf.write(digits[i]);
    }
    final s = buf.toString();
    return newValue.copyWith(
        text: s, selection: TextSelection.collapsed(offset: s.length));
  }
}
