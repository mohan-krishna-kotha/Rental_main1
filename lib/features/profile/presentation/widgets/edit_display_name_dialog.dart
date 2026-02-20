import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/items_provider.dart';

class EditDisplayNameDialog extends ConsumerStatefulWidget {
  const EditDisplayNameDialog({super.key, required this.currentName});

  final String currentName;

  @override
  ConsumerState<EditDisplayNameDialog> createState() => _EditDisplayNameDialogState();
}

class _EditDisplayNameDialogState extends ConsumerState<EditDisplayNameDialog> {
  late TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final newName = _controller.text.trim();
    if (newName == widget.currentName) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) throw 'No user logged in';

      await ref.read(authServiceProvider).updateDisplayName(newName);
      await ref.read(firestoreServiceProvider).updateDisplayName(currentUser.uid, newName);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Display name updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update name: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Display Name'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            hintText: 'Enter your name',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Name cannot be empty';
            }
            if (value.trim().length < 2) {
              return 'Name is too short';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
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
