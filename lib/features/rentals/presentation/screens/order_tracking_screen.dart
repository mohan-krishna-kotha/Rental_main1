import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/providers/items_provider.dart';
import '../../../../core/models/order_models.dart';

class OrderTrackingScreen extends ConsumerWidget {
  final OrderModel order;
  const OrderTrackingScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Order #${order.orderNumber.isNotEmpty ? order.orderNumber : order.id.substring(0, 8)}',
        ),
      ),
      body: FutureBuilder(
        // Fetch items, rental info, and delivery info in parallel
        future: Future.wait([
          ref.read(firestoreServiceProvider).getOrderItems(order.id),
          // Fetch rental info: orders/{orderId}/rentals/details
          FirebaseFirestore.instance
              .collection('orders')
              .doc(order.id)
              .collection('rentals')
              .doc('details')
              .get(),
          // Fetch delivery info: delivery/{orderId} (ROOT)
          FirebaseFirestore.instance.collection('delivery').doc(order.id).get(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading order details: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Order details not found.'));
          }

          final results = snapshot.data as List<dynamic>;
          // Safety check for list length
          if (results.isEmpty)
            return const Center(child: Text('No order data.'));

          // Safely cast items, defaulting to empty list if null/wrong type
          final items = (results[0] is List)
              ? (results[0] as List).cast<OrderItemModel>()
              : <OrderItemModel>[];

          final deliveryDoc = results[2] as DocumentSnapshot;

          final firstItem = items.isNotEmpty ? items.first : null;
          final title = firstItem?.productName ?? 'Order Items';
          final totalAmount = order.totalAmount;

          final deliveryStatus =
              (deliveryDoc.exists && deliveryDoc.data() != null)
              ? (deliveryDoc.data()
                        as Map<String, dynamic>)['deliveryStatus'] ??
                    'pending'
              : 'pending';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        image:
                            firstItem != null && firstItem.productId.isNotEmpty
                            ? null // TODO: Fetch product image properly if needed here, but for now icon is safe fallback
                            : null,
                      ),
                      child: const Icon(
                        Icons.shopping_bag,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total: ₹${totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${items.length} Items',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                const Text(
                  'Order Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                _buildTimeline(
                  order,
                  deliveryStatus,
                ), // Pass entire order object
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeline(OrderModel order, String deliveryStatus) {
    // Mapping complex architecture statuses to UI
    // Order: pending -> confirmed -> active -> completed
    // Delivery: assigned -> picked -> delivered
    final orderStatus = order.orderStatus.toLowerCase();

    // Determine current step index
    int currentStep = 0;
    if (orderStatus == 'confirmed') {
      currentStep = 1;
    } else if (deliveryStatus == 'picked' ||
        deliveryStatus == 'out_for_delivery')
      currentStep = 2;
    else if (['active', 'delivered', 'in use'].contains(orderStatus))
      currentStep = 3;
    else if (['completed', 'returned'].contains(orderStatus))
      currentStep = 4;

    // Timeline Steps
    final steps = [
      {'title': 'Order Placed', 'date': order.createdAt},
      {'title': 'Confirmed', 'date': null}, // TODO: capture confirmedAt
      {'title': 'Out for Delivery / Pickup', 'date': null},
      {'title': 'In Use / Delivered', 'date': null},
      {
        'title': 'Returned & Completed',
        'date': null,
      }, // TODO: capture returnedAt
    ];

    if (orderStatus == 'cancelled') {
      return Center(
        child: Column(
          children: [
            const Icon(Icons.cancel, color: Colors.red, size: 50),
            const SizedBox(height: 10),
            Text(
              'Order Cancelled',
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'This order has been cancelled and is no longer active.',
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        final step = steps[index];
        final isCompleted = index <= currentStep;
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? Colors.green : Colors.grey[300],
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      if (isCompleted)
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 50,
                    color: index < currentStep
                        ? Colors.green
                        : Colors.grey[300],
                  ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step['title'] as String,
                    style: TextStyle(
                      fontWeight: isCompleted
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 16,
                      color: isCompleted ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  if (step['date'] != null && index == 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(step['date'] as DateTime),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
