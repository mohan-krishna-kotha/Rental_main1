import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/product_model.dart';
import '../../../booking/presentation/booking_screen.dart';
import '../../../booking/presentation/buy_checkout_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/models/review_model.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/providers/items_provider.dart'; // Correct import for firestoreServiceProvider
import '../../../../core/providers/favorites_provider.dart';

class ItemDetailsScreen extends ConsumerWidget {
  final ProductModel item;

  const ItemDetailsScreen({super.key, required this.item});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text(
          'Are you sure you want to delete this item? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        final firestoreService = ref.read(firestoreServiceProvider);
        await firestoreService.deleteProduct(item.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item deleted successfully')),
          );
          Navigator.of(context).pop(); // Go back to Home
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete item: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _handleAction(
    BuildContext context,
    WidgetRef ref,
    ProductModel item,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login to continue')));
      return;
    }

    // Always Rent Flow
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BookingScreen(item: item)),
    );
  }

  void _handleBuyAction(BuildContext context, ProductModel item) {
    final salePrice = item.transactionMode == 'sell' ? item.salePrice : null;
    if (salePrice == null || salePrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This item is not available for sale')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login to continue')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BuyCheckoutScreen(item: item)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestoreService = ref.watch(firestoreServiceProvider);

    return StreamBuilder<ProductModel?>(
      stream: firestoreService.getProductStream(item.id),
      initialData: item,
      builder: (context, snapshot) {
        // Use stream data or fallback to initial item (optimistic)
        final item = snapshot.data ?? this.item;

        if (snapshot.hasData && snapshot.data == null) {
          return const Scaffold(
            body: Center(child: Text("Item no longer exists")),
          );
        }

        final currency = '₹';
        final hasRentOffer = item.rentalPricePerDay > 0;
        final saleOfferPrice = item.transactionMode == 'sell'
            ? item.salePrice
            : null;
        final hasSaleOffer = saleOfferPrice != null && saleOfferPrice > 0;
        final rentPriceText =
            '$currency${item.rentalPricePerDay.toStringAsFixed(0)} / day';
        final salePriceText = hasSaleOffer
            ? '$currency${saleOfferPrice.toStringAsFixed(0)}'
            : 'Not available for sale';

        final currentUser = FirebaseAuth.instance.currentUser;
        final isOwner = currentUser?.uid == item.ownerId;
        final favorites = ref.watch(userFavoritesProvider).value ?? [];
        final isFavorite = favorites.contains(item.id);
        const headerColor = Colors.white;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar.large(
                expandedHeight: 300,
                pinned: true,
                foregroundColor: headerColor,
                iconTheme: IconThemeData(color: headerColor),
                actionsIconTheme: IconThemeData(color: headerColor),
                actions: [
                  if (!isOwner)
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : headerColor,
                      ),
                      tooltip: isFavorite
                          ? 'Remove from favorites'
                          : 'Add to favorites',
                      onPressed: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please login to manage favorites'),
                            ),
                          );
                          return;
                        }

                        await ref
                            .read(firestoreServiceProvider)
                            .toggleFavorite(user.uid, item.id);
                      },
                    ),
                  if (isOwner)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(context, ref),
                      tooltip: 'Delete Item',
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black87,
                          blurRadius: 6,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  background: Container(
                    color: Colors.transparent,
                    child: item.images.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FullScreenImageViewer(
                                    imageUrl: item.images.first,
                                    tag: 'item_image_${item.id}',
                                  ),
                                ),
                              );
                            },
                            child: Hero(
                              tag: 'item_image_${item.id}',
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    item.images.first,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(
                                        Icons.image,
                                        size: 100,
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ),
                                  const DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.center,
                                        colors: [
                                          Color(0xAA000000),
                                          Color(0x00000000),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.image,
                              size: 100,
                              color: Colors.white54,
                            ),
                          ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ARCHIVED BADGE
                      if (!item.isActive)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.archive, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'ARCHIVED - Private',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Mode Badge removed as per user request (UI Cleanup)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item.categoryName,
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (hasRentOffer)
                                Text(
                                  rentPriceText,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                ),
                              if (hasSaleOffer)
                                Text(
                                  'Buy $salePriceText',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.orange.shade700,
                                      ),
                                ),
                            ],
                          ),
                        ],
                      ).animate().fadeIn().slideX(),
                      const SizedBox(height: 24),
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),

                      if (hasRentOffer) ...[
                        _buildDetailRow(
                          context,
                          'Security Deposit',
                          '$currency${item.securityDeposit ?? 0}',
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          context,
                          'Weekly Rate',
                          item.rentalPricePerWeek != null
                              ? '$currency${item.rentalPricePerWeek}'
                              : '-',
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          context,
                          'Monthly Rate',
                          item.rentalPricePerMonth != null
                              ? '$currency${item.rentalPricePerMonth}'
                              : '-',
                        ),
                      ],

                      if (hasSaleOffer) ...[
                        const SizedBox(height: 12),
                        _buildDetailRow(context, 'Sale Price', salePriceText),
                        const SizedBox(height: 12),
                        _buildDetailRow(context, 'Condition', 'Used'),
                      ],

                      const SizedBox(height: 12),
                      if (item.originalPrice != null) ...[
                        _buildDetailRow(
                          context,
                          'Original Price (MRP)',
                          '$currency${item.originalPrice}',
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (item.dimensions != null) ...[
                        _buildDetailRow(
                          context,
                          'Dimensions / Specs',
                          item.dimensions!,
                        ),
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 24),

                      const SizedBox(height: 24),

                      const Divider(),
                      const SizedBox(height: 16),

                      // Owner Profile
                      Row(
                        children: [
                          const CircleAvatar(child: Icon(Icons.store)),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Listed by ${item.ownerName}',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Row(
                                children: [
                                  Text(
                                    'Verified Seller',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.grey),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.star,
                                    size: 14,
                                    color: Colors.amber,
                                  ),
                                  Text(
                                    ' ${item.averageRating > 0 ? item.averageRating.toStringAsFixed(1) : "New"} (${item.reviewCount})',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Reviews Section
                      _buildReviewsList(context),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FirebaseAuth.instance.currentUser != null && !isOwner
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasRentOffer)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () =>
                                  _handleAction(context, ref, item),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                backgroundColor: const Color(0xFF781C2E),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'RENT NOW',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        if (hasRentOffer && hasSaleOffer)
                          const SizedBox(height: 12),
                        if (hasSaleOffer)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _handleBuyAction(context, item),
                              icon: const Icon(Icons.shopping_bag_outlined),
                              label: Text('BUY NOW • $salePriceText'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                backgroundColor: Colors.orange.shade50,
                                foregroundColor: Colors.orange.shade800,
                                side: BorderSide(color: Colors.orange.shade700),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        if (!hasSaleOffer)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.block_outlined,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Not available for sale',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'This item can only be rented right now.',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    )
                  : ElevatedButton(
                      onPressed: () {
                        if (isOwner) {
                          _showOwnerManageDialog(context, item);
                        } else {
                          // Fallback (e.g. not logged in)
                          _handleAction(context, ref, item);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: isOwner
                            ? Colors.blueGrey.shade800
                            : const Color(0xFF781C2E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isOwner ? 'MANAGE ITEM' : 'RENT NOW',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  void _showOwnerManageDialog(BuildContext context, ProductModel initialItem) {
    final parentContext = context;

    showModalBottomSheet(
      context: parentContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        // Use StreamBuilder to get real-time updates inside the bottom sheet
        final firestoreService = FirestoreService(
          FirebaseFirestore.instance,
          FirebaseAuth.instance,
        );

        return StreamBuilder<ProductModel?>(
          stream: firestoreService.getProductStream(initialItem.id),
          initialData: initialItem,
          builder: (_, snapshot) {
            final item = snapshot.data ?? initialItem;

            bool isSellMode = item.transactionMode == 'sell';

            return StatefulBuilder(
              builder: (_, setState) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Manage Item Transaction Mode',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Switch between Renting and Selling. Changing this will instantly update the item availability for all users.',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),

                        SwitchListTile(
                          title: Text(
                            isSellMode ? 'Selling Mode' : 'Renting Mode',
                          ),
                          subtitle: Text(
                            isSellMode
                                ? 'Item is available for purchase only.'
                                : 'Item is available for rental booking.',
                          ),
                          value: isSellMode,
                          activeThumbColor: Colors.orange,
                          secondary: Icon(
                            isSellMode ? Icons.sell : Icons.timer,
                          ),
                          onChanged: (value) async {
                            // Case 1: Switching to SALE
                            if (value) {
                              // Check if sale price exists
                              if (item.salePrice != null &&
                                  item.salePrice! > 0) {
                                // Fast switch
                                await _updateItemMode(
                                  parentContext,
                                  item.id,
                                  'sell',
                                  isSale: true,
                                );
                                return;
                              }

                              // No sale price, ask for it
                              Navigator.pop(sheetContext);

                              if (parentContext.mounted) {
                                _showSetPriceDialog(
                                  parentContext,
                                  'Sale Price',
                                  (price) async {
                                    await _updateItemMode(
                                      parentContext,
                                      item.id,
                                      'sell',
                                      price: price,
                                      isSale: true,
                                    );
                                  },
                                );
                              }
                              return;
                            }

                            // Case 2: Switching to RENT
                            if (!value) {
                              // Check if rental price exists
                              if (item.rentalPricePerDay > 0) {
                                // Fast switch
                                await _updateItemMode(
                                  parentContext,
                                  item.id,
                                  'rent',
                                  isSale: false,
                                );
                                return;
                              }

                              // No rental price, ask for it
                              Navigator.pop(sheetContext);
                              if (parentContext.mounted) {
                                _showSetRentalDetailsDialog(parentContext, (
                                  price,
                                  deposit,
                                ) async {
                                  await _updateItemMode(
                                    parentContext,
                                    item.id,
                                    'rent',
                                    price: price,
                                    securityDeposit: deposit,
                                    isSale: false,
                                  );
                                });
                              }
                              return;
                            }
                          },
                        ),
                        const Divider(height: 32),

                        // ARCHIVE TOGGLE
                        SwitchListTile(
                          title: const Text('Archived (Hidden)'),
                          subtitle: const Text(
                            'Hide this item from search results and feeds.',
                          ),
                          value: !(item.isActive),
                          activeThumbColor: Colors.grey,
                          secondary: const Icon(Icons.archive),
                          onChanged: (isArchived) async {
                            try {
                              if (isArchived) {
                                await firestoreService.archiveProduct(item.id);
                                if (parentContext.mounted) {
                                  ScaffoldMessenger.of(
                                    parentContext,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text('Item archived'),
                                    ),
                                  );
                                }
                              } else {
                                await firestoreService.unarchiveProduct(
                                  item.id,
                                );
                                if (parentContext.mounted) {
                                  ScaffoldMessenger.of(
                                    parentContext,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text('Item unarchived'),
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              if (parentContext.mounted) {
                                ScaffoldMessenger.of(
                                  parentContext,
                                ).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                        ),

                        const SizedBox(height: 12),

                        // DELETE BUTTON
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () {
                              // Confirm Delete
                              showDialog(
                                context: parentContext,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Item?'),
                                  content: const Text(
                                    'This action cannot be undone. Any active bookings will remain in history, but the item will be permanently removed.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('CANCEL'),
                                    ),
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      onPressed: () async {
                                        Navigator.pop(ctx); // Close alert
                                        Navigator.pop(
                                          sheetContext,
                                        ); // Close sheet
                                        try {
                                          await firestoreService.deleteProduct(
                                            item.id,
                                          );
                                          if (parentContext.mounted) {
                                            Navigator.pop(
                                              parentContext,
                                            ); // Go back to Home
                                            ScaffoldMessenger.of(
                                              parentContext,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Item deleted successfully',
                                                ),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (parentContext.mounted) {
                                            ScaffoldMessenger.of(
                                              parentContext,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Delete failed: $e',
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      child: const Text('DELETE PERMANENTLY'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.delete_forever,
                              color: Colors.red,
                            ),
                            label: const Text(
                              'Delete Item',
                              style: TextStyle(color: Colors.red),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              backgroundColor: Colors.red.withOpacity(0.1),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildReviewsList(BuildContext context) {
    return StreamBuilder<List<ReviewModel>>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .doc(item.id)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snap) =>
                snap.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList(),
          ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error loading reviews: ${snapshot.error}');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final reviews = snapshot.data ?? [];
        if (reviews.isEmpty) {
          return const Text(
            'No reviews yet. Be the first to rent and review!',
            style: TextStyle(color: Colors.grey),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length > 3 ? 3 : reviews.length, // Show max 3
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final review = reviews[index];
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: review.reviewerImage != null
                      ? NetworkImage(review.reviewerImage!)
                      : null,
                  child: review.reviewerImage == null
                      ? Text(review.reviewerName[0].toUpperCase())
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            review.reviewerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            DateFormat.yMMMd().format(review.createdAt),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: List.generate(5, (starIndex) {
                          return Icon(
                            starIndex < review.rating
                                ? Icons.star
                                : Icons.star_border,
                            size: 12,
                            color: Colors.amber,
                          );
                        }),
                      ),
                      const SizedBox(height: 4),
                      if (review.comment.isNotEmpty)
                        Text(
                          review.comment,
                          style: const TextStyle(fontSize: 13),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateItemMode(
    BuildContext context,
    String itemId,
    String mode, {
    double? price,
    double? securityDeposit,
    required bool isSale,
  }) async {
    final updates = <String, dynamic>{'transactionMode': mode};

    if (price != null) {
      if (isSale) {
        updates['salePrice'] = price;
      } else {
        updates['rentalPricePerDay'] = price;
        updates['price'] = price; // Sync legacy price field
        // Optionally auto-calculate weekly/monthly
        updates['rentalPricePerWeek'] = price * 6;
        updates['rentalPricePerMonth'] = price * 25;
        if (securityDeposit != null) {
          updates['securityDeposit'] = securityDeposit;
        }
      }
    }

    try {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Updating item...')));
      }

      await FirestoreService(
        FirebaseFirestore.instance,
        FirebaseAuth.instance,
      ).updateProduct(itemId, updates);

      if (context.mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  void _showSetPriceDialog(
    BuildContext context,
    String label,
    Function(double) onConfirm,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Set $label'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: label,
            prefixText: '₹ ',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                Navigator.pop(ctx);
                onConfirm(val);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSetRentalDetailsDialog(
    BuildContext context,
    Function(double price, double deposit) onConfirm,
  ) {
    final priceController = TextEditingController();
    final depositController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Rental Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Daily Rental Price',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: depositController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Security Deposit',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(priceController.text);
              final deposit = double.tryParse(depositController.text);

              if (price != null && price > 0) {
                Navigator.pop(ctx);
                onConfirm(price, deposit ?? 0);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid price')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String tag;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.1,
              maxScale: 5.0,
              child: Hero(
                tag: tag,
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: CircleAvatar(
              backgroundColor: Colors.black45,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
