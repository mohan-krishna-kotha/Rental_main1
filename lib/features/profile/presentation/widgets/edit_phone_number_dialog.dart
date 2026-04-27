import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/items_provider.dart';

class EditPhoneNumberDialog extends ConsumerStatefulWidget {
  const EditPhoneNumberDialog({super.key, this.currentPhoneNumber});

  final String? currentPhoneNumber;

  @override
  ConsumerState<EditPhoneNumberDialog> createState() =>
      _EditPhoneNumberDialogState();
}

class _EditPhoneNumberDialogState extends ConsumerState<EditPhoneNumberDialog> {
  late TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentPhoneNumber ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _normalizeToTenDigits(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('91')) {
      return digits.substring(2);
    }
    return digits;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final tenDigits = _normalizeToTenDigits(_controller.text);
    setState(() => _isSaving = true);

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) throw 'No user logged in';

      await ref
          .read(firestoreServiceProvider)
          .updatePhoneNumber(currentUser.uid, tenDigits);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number saved successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save phone number: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Phone Number'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _controller,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter 10-digit number',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final v = _normalizeToTenDigits(value ?? '');
                if (v.isEmpty) return 'Phone number cannot be empty';
                if (!RegExp(r'^\d{10}$').hasMatch(v)) {
                  return 'Phone number must be exactly 10 digits';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
