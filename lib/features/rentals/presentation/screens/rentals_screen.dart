import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/items_provider.dart'; // For firestoreServiceProvider
import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/booking_policy.dart';
import '../providers/order_provider.dart';
import '../../../../core/models/booking_request_model.dart';
import '../../../../core/models/order_models.dart'; // Use new comprehensive order models
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/models/review_model.dart';
import '../../../reviews/presentation/widgets/review_dialog.dart';
import 'order_tracking_screen.dart';

class RentalsScreen extends ConsumerStatefulWidget {
  const RentalsScreen({super.key});

  @override
  ConsumerState<RentalsScreen> createState() => _RentalsScreenState();
}

class _RentalsScreenState extends ConsumerState<RentalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processRentalStatusTransitions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(userOrdersProvider);
    final bookingRequestsAsync = ref.watch(userBookingRequestsProvider);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar.large(
              floating: true,
              pinned: true,
              title: const Text('My Rentals'),
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Active'),
                  Tab(text: 'Pending'),
                  Tab(text: 'Completed'),
                ],
              ),
            ),
          ];
        },
        body: ordersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (orders) {
            return bookingRequestsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (requests) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRentalsList(orders, 'Active'),
                    _buildPendingCombinedList(orders, requests),
                    _buildRentalsList(orders, 'Completed'),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPendingCombinedList(
    List<OrderModel> allOrders,
    List<BookingRequestModel> allRequests,
  ) {
    final pendingOrders = allOrders
        .where((o) => o.orderStatus.toLowerCase() == 'pending')
        .toList();
    final pendingRequests = allRequests
        .where((r) => r.status.toLowerCase() == 'pending')
        .toList();

    if (pendingOrders.isEmpty && pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No Pending rentals',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey),
            ),
          ],
        ).animate().fadeIn().scale(),
      );
    }

    final widgets = <Widget>[];

    for (var i = 0; i < pendingOrders.length; i++) {
      widgets.add(_buildRentalCard(pendingOrders[i], i));
    }

    for (var i = 0; i < pendingRequests.length; i++) {
      widgets.add(
        _buildPendingRequestCard(pendingRequests[i], pendingOrders.length + i),
      );
    }

    return ListView(padding: const EdgeInsets.all(16), children: widgets);
  }

  Widget _buildRentalsList(List<OrderModel> allOrders, String tabCategory) {
    // Filter logic
    final rentals = allOrders.where((order) {
      final s = order.orderStatus.toLowerCase(); // Updated to use orderStatus

      // Map tabs to statuses
      if (tabCategory == 'Pending') return s == 'pending';
      if (tabCategory == 'Active') {
        return ['confirmed', 'active', 'picked up', 'in use'].contains(s);
      }
      if (tabCategory == 'Completed') {
        return ['completed', 'returned', 'cancelled'].contains(s);
      }
      return false;
    }).toList();

    if (rentals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No $tabCategory rentals',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey),
            ),
          ],
        ).animate().fadeIn().scale(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rentals.length,
      itemBuilder: (context, index) {
        final rental = rentals[index];
        return _buildRentalCard(rental, index);
      },
    );
  }

  Widget _buildRentalCard(OrderModel order, int index) {
    // Helper to get color
    Color color;
    IconData icon;
    final status = order.orderStatus.toLowerCase();

    switch (status) {
      case 'pending':
        color = Colors.orange;
        icon = Icons.pending;
        break;
      case 'confirmed':
        color = Colors.blue;
        icon = Icons.check_circle;
        break;
      case 'active':
      case 'picked up':
      case 'in use':
        color = Colors.green;
        icon = Icons.play_circle;
        break;
      case 'completed':
      case 'returned':
        color = Colors.grey;
        icon = Icons.task_alt;
        break;
      case 'cancelled':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.info;
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchOrderProductDetails(order.id),
      builder: (context, snapshot) {
        String title =
            'Order ${order.orderNumber.isNotEmpty ? order.orderNumber : order.id.substring(0, 4)}';
        String? imageUrl;
        DateTime? rentalStart;
        DateTime? rentalEnd;

        if (snapshot.hasData && snapshot.data != null) {
          final data = snapshot.data!;
          if (data['name'] != null) title = data['name'];
          if (data['image'] != null) imageUrl = data['image'];
          rentalStart = data['rentalStart'] as DateTime?;
          rentalEnd = data['rentalEnd'] as DateTime?;
        }

        return _buildCardUI(
          context,
          order,
          title,
          imageUrl,
          rentalStart,
          rentalEnd,
          color,
          icon,
          index,
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchOrderProductDetails(String orderId) async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final items = await firestoreService.getOrderItems(orderId);
      if (items.isEmpty) return {};

      final firstItem = items.first;
      String? imageUrl;

      // Try to get product image
      try {
        final product = await firestoreService.getProductById(
          firstItem.productId,
        );
        if (product != null && product.images.isNotEmpty) {
          imageUrl = product.images.first;
        }
      } catch (e) {
        // Ignore product fetch error, just use item name
      }

      return {
        'name': firstItem.productName,
        'image': imageUrl,
        'rentalStart': firstItem.rentalStartDate,
        'rentalEnd': firstItem.rentalEndDate,
      };
    } catch (e) {
      return {};
    }
  }

  Widget _buildCardUI(
    BuildContext context,
    OrderModel order,
    String itemTitle,
    String? itemImage,
    DateTime? rentalStart,
    DateTime? rentalEnd,
    Color color,
    IconData icon,
    int index,
  ) {
    final start = rentalStart ?? order.createdAt;
    final end = rentalEnd ?? order.createdAt.add(const Duration(days: 7));
    final dateStr =
        '${DateFormat("dd MMM").format(start)} - ${DateFormat("dd MMM").format(end)}';
    final canCancelPending = BookingPolicy.canCancelPendingRental(
      orderStatus: order.orderStatus,
      rentalStart: start,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderTrackingScreen(order: order),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Item Image or Category Icon
                  if (itemImage != null && itemImage.isNotEmpty)
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(itemImage),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 30),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemTitle,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            // color: Colors.white, // Removed white color to be visible on light card
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildStatusChip(order.orderStatus, color),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              // Allow reviews for completed or returned orders
              if ([
                'completed',
                'returned',
              ].contains(order.orderStatus.toLowerCase())) ...[
                const Divider(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showReviewDialog(context, order, itemTitle),
                    icon: const Icon(Icons.rate_review_outlined),
                    label: const Text('Write a Review'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber[800],
                      side: BorderSide(color: Colors.amber.shade800),
                    ),
                  ),
                ),
              ],

              // Cancel Action
              if (order.orderStatus.toLowerCase() == 'pending') ...[
                const Divider(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: canCancelPending
                        ? () => _confirmCancel(context, order)
                        : null,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel Order'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                if (!canCancelPending)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Rental already started. Cancellation is no longer available.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: -0.2);
  }

  Future<void> _confirmCancel(BuildContext context, OrderModel order) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text(
          'Are you sure you want to cancel this booking request? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) throw 'Please sign in again';

        await ref
            .read(firestoreServiceProvider)
            .cancelPendingRentalIfNotStarted(
              orderId: order.id,
              userId: currentUser.uid,
            );

        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Order cancelled successfully.')),
        );
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(SnackBar(content: Text('Failed to cancel: $e')));
      }
    }
  }

  Widget _buildPendingRequestCard(BookingRequestModel request, int index) {
    final start = request.startDate;
    final end = request.endDate;
    final now = DateTime.now();
    final isStartReached = !start.isAfter(now);
    final canCancel = BookingPolicy.canCancelPendingRequest(
      requestStart: start,
    );
    final dateStr =
        '${DateFormat("dd MMM").format(start)} - ${DateFormat("dd MMM").format(end)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.pending,
                    color: Colors.orange,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.productName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Pending request (waiting for owner/admin approval)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Rs ${request.totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFF781C2E),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: canCancel
                    ? () => _confirmCancelRequest(context, request)
                    : null,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel Request'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
            if (!canCancel)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  isStartReached
                      ? 'Start date has reached. This request still needs approval before it can become active.'
                      : 'This request is still waiting for approval before it can become active.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: -0.2);
  }

  Future<void> _confirmCancelRequest(
    BuildContext context,
    BookingRequestModel request,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Request?'),
        content: const Text(
          'Are you sure you want to cancel this rental request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(firestoreServiceProvider)
          .cancelBookingRequestByUser(request.id);

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Request cancelled successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to cancel request: $e')),
      );
    }
  }

  Future<void> _processRentalStatusTransitions() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final startedOrders = await ref
          .read(firestoreServiceProvider)
          .activateStartedPendingRentals(currentUser.uid);

      final completedOrders = await ref
          .read(firestoreServiceProvider)
          .completeEndedActiveRentals(currentUser.uid);

      if (!mounted || (startedOrders.isEmpty && completedOrders.isEmpty))
        return;

      final messages = <String>[];

      if (startedOrders.isNotEmpty) {
        messages.add(
          startedOrders.length == 1
              ? 'Rental ${startedOrders.first} has started.'
              : '${startedOrders.length} rentals have started.',
        );
      }

      if (completedOrders.isNotEmpty) {
        messages.add(
          completedOrders.length == 1
              ? 'Rental ${completedOrders.first} has been completed.'
              : '${completedOrders.length} rentals have been completed.',
        );
      }

      NotificationService().showInAppNotification(
        'Rental Updates',
        messages.join(' '),
      );
    } catch (e) {
      debugPrint('Failed to process rental status transitions: $e');
    }
  }

  void _showReviewDialog(
    BuildContext context,
    OrderModel order,
    String itemName,
  ) {
    showDialog(
      context: context,
      builder: (context) => ReviewDialog(
        targetName: itemName,
        onSubmit: (rating, comment) async {
          final messenger = ScaffoldMessenger.of(context);
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return;

          try {
            // 1. Get Order Items to find Product ID
            final orderItems = await ref
                .read(firestoreServiceProvider)
                .getOrderItems(order.id);
            if (orderItems.isEmpty) {
              throw 'Order items not found';
            }
            final productId = orderItems
                .first
                .productId; // Assuming single product per rental for now

            // 2. Create Review Model
            final review = ReviewModel(
              id: Uuid().v4(), // Generate new ID
              reviewerId: user.uid,
              reviewerName: user.displayName ?? 'Renter',
              reviewerImage: user.photoURL,
              rating: rating,
              comment: comment,
              orderId: order.id,
              orderType: 'rental',
              reviewType: 'product',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

            // 3. Submit Review via Service
            await ref
                .read(firestoreServiceProvider)
                .addProductReview(productId, review);

            if (!mounted) return;
            messenger.showSnackBar(
              const SnackBar(content: Text('Review submitted successfully!')),
            );
          } catch (e) {
            if (!mounted) return;
            messenger.showSnackBar(
              SnackBar(content: Text('Failed to submit review: $e')),
            );
          }
        },
      ),
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
