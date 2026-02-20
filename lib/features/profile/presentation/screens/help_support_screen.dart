import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/items_provider.dart';
import '../../../../core/providers/support_provider.dart';
import '../../../../core/models/support_faq_model.dart';
import '../../../../core/models/support_ticket_model.dart';

class HelpSupportScreen extends ConsumerStatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  ConsumerState<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends ConsumerState<HelpSupportScreen> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedCategory = 'general';
  String _selectedPriority = 'normal';
  bool _submitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final faqAsync = ref.watch(supportFaqsProvider);
    final ticketsAsync = ref.watch(userSupportTicketsProvider);
    final user = ref.watch(currentUserProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Help & Support'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'FAQs'),
              Tab(text: 'My Tickets'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFaqsTab(context, faqAsync),
            _buildTicketsTab(context, user, ticketsAsync),
          ],
        ),
        floatingActionButton: user == null
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _openTicketSheet(context),
                icon: const Icon(Icons.support_agent),
                label: const Text('New Ticket'),
              ),
      ),
    );
  }

  Widget _buildFaqsTab(
    BuildContext context,
    AsyncValue<List<SupportFaqModel>> faqAsync,
  ) {
    return faqAsync.when(
      data: (faqs) {
        final list = faqs.isNotEmpty ? faqs : _defaultFaqs;

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final faq = list[index];
            return _FaqTile(faq: faq).animate().fadeIn(delay: (50 * index).ms);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Unable to load FAQs: $err')),
    );
  }

  Widget _buildTicketsTab(
    BuildContext context,
    User? user,
    AsyncValue<List<SupportTicketModel>> ticketsAsync,
  ) {
    if (user == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48),
              const SizedBox(height: 16),
              Text(
                'Sign in to track your support tickets.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    return ticketsAsync.when(
      data: (tickets) {
        if (tickets.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.support, size: 48),
                const SizedBox(height: 12),
                const Text('No tickets yet. Need help? Tap "New Ticket".'),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: tickets.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final ticket = tickets[index];
            return _TicketCard(ticket: ticket).animate().fadeIn();
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Unable to load tickets: $err')),
    );
  }

  void _openTicketSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Support Ticket',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Subject is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _messageController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Describe the issue',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      (value == null || value.trim().length < 10)
                      ? 'Provide at least 10 characters'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'general',
                            child: Text('General'),
                          ),
                          DropdownMenuItem(
                            value: 'payments',
                            child: Text('Payments'),
                          ),
                          DropdownMenuItem(
                            value: 'rentals',
                            child: Text('Rentals & Orders'),
                          ),
                          DropdownMenuItem(
                            value: 'account',
                            child: Text('Account & KYC'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedCategory = value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedPriority,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'low', child: Text('Low')),
                          DropdownMenuItem(
                            value: 'normal',
                            child: Text('Normal'),
                          ),
                          DropdownMenuItem(value: 'high', child: Text('High')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedPriority = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submitting
                        ? null
                        : () => _submitTicket(context),
                    icon: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: Text(
                      _submitting ? 'Submitting...' : 'Submit Ticket',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitTicket(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await ref
          .read(firestoreServiceProvider)
          .createSupportTicket(
            subject: _subjectController.text.trim(),
            message: _messageController.text.trim(),
            category: _selectedCategory,
            priority: _selectedPriority,
          );
      if (mounted) {
        Navigator.of(context).pop();
        _subjectController.clear();
        _messageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Support ticket submitted.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit ticket: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.faq});

  final SupportFaqModel faq;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
      title: Text(faq.question, style: Theme.of(context).textTheme.titleMedium),
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            faq.answer,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});

  final SupportTicketModel ticket;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(ticket.status, context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ticket.subject,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(ticket.status.toUpperCase()),
                  backgroundColor: statusColor.withOpacity(0.1),
                  labelStyle: TextStyle(color: statusColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(ticket.message, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Category: ${ticket.category}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  _formatDate(ticket.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Color _statusColor(String status, BuildContext context) {
    switch (status) {
      case 'resolved':
        return Colors.green;
      case 'in_progress':
        return Colors.deepPurple;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

const List<SupportFaqModel> _defaultFaqs = [
  SupportFaqModel(
    id: 'local-1',
    question: 'How do I contact support?',
    answer:
        'Open the Help & Support screen, switch to "My Tickets", and tap "New Ticket" to send us a message. We will reply inside the app.',
    category: 'general',
    displayOrder: 0,
  ),
  SupportFaqModel(
    id: 'local-2',
    question: 'When will I get a response?',
    answer:
        'Most tickets receive a response within 24 hours. High priority issues are handled as quickly as possible.',
    category: 'general',
    displayOrder: 1,
  ),
];
