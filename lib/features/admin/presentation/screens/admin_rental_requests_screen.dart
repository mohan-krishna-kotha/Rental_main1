import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/booking_request_model.dart';
import '../../../../core/providers/items_provider.dart';
import '../../../../core/providers/auth_provider.dart';

class AdminRentalRequestsScreen extends ConsumerStatefulWidget {
  const AdminRentalRequestsScreen({super.key});

  @override
  ConsumerState<AdminRentalRequestsScreen> createState() =>
      _AdminRentalRequestsScreenState();
}

class _AdminRentalRequestsScreenState
    extends ConsumerState<AdminRentalRequestsScreen> {
  bool _markedSeen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _markSeenOnce();
  }

  Future<void> _markSeenOnce() async {
    if (_markedSeen) return;
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;
    _markedSeen = true;
    final fs = ref.read(firestoreServiceProvider);
    await fs.updateOwnerLastSeenBookingRequests(currentUser.uid);
    await fs.markNotificationsSeenForOwner(currentUser.uid);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view rental requests')),
      );
    }

    final pendingRequestsStream = ref
        .watch(firestoreServiceProvider)
        .getOwnerBookingRequests(currentUser.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rental Requests'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<BookingRequestModel>>(
        stream: pendingRequestsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading rental requests: ${snapshot.error}'),
            );
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return const Center(
              child: Text('No pending rental requests for your listings.'),
            );
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return _RentalRequestCard(request: request);
            },
          );
        },
      ),
    );
  }
}

class _RentalRequestCard extends ConsumerWidget {
  final BookingRequestModel request;
  const _RentalRequestCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateRange =
        '${request.startDate.day.toString().padLeft(2, '0')} ${_monthName(request.startDate.month)} - ${request.endDate.day.toString().padLeft(2, '0')} ${_monthName(request.endDate.month)}';

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              request.productName,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text('Renter: ${request.renterName}'),
            Text('Dates: $dateRange'),
            Text('Amount: Rs ${request.totalPrice.toStringAsFixed(0)}'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectRequest(context, ref),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approveRequest(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveRequest(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.approveBookingRequest(request);

      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Rental request approved.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      final errorText = e.toString();
      final message = _friendlyApprovalError(errorText);
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _rejectRequest(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(firestoreServiceProvider).rejectBookingRequest(request.id);
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Rental request rejected.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Rejection failed: $e')));
    }
  }

  String _monthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[month - 1];
  }

  String _friendlyApprovalError(String errorText) {
    final lower = errorText.toLowerCase();
    if (lower.contains('dates no longer available') ||
        lower.contains('overlap') ||
        lower.contains('already booked')) {
      return 'Approval failed: those dates are already booked for this item.';
    }
    return 'Approval failed: $errorText';
  }
}
