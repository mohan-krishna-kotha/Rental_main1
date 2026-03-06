import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/providers/items_provider.dart';
import '../../../../core/providers/location_provider.dart';
import '../../../../core/services/location_service.dart';
import 'item_details_screen.dart';

class SearchDashboardScreen extends ConsumerStatefulWidget {
  const SearchDashboardScreen({super.key});

  @override
  ConsumerState<SearchDashboardScreen> createState() =>
      _SearchDashboardScreenState();
}

class _SearchDashboardScreenState extends ConsumerState<SearchDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'Default';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF781C2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 48,
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? theme.cardColor : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: const Color(0xFF781C2E).withOpacity(isDark ? 0.3 : 0.1),
              width: 1,
            ),
          ),
          child: Center(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
              cursorColor: const Color(0xFF781C2E),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Search items...',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
        actions: [
          // Sort Menu that appears right at the icon
          PopupMenuButton<String>(
            icon: const Icon(Icons.tune, color: Color(0xFF781C2E), size: 22),
            tooltip: 'Sort Options',
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (String value) {
              setState(() => _sortBy = value);
            },
            itemBuilder: (BuildContext context) {
              final options = ['Default', 'Price: Low to High', 'Price: High to Low', 'Newest'];
              return options.map((String opt) {
                final isSelected = _sortBy == opt;
                return PopupMenuItem<String>(
                  value: opt,
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                        size: 18,
                        color: isSelected ? const Color(0xFF781C2E) : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        opt,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? const Color(0xFF781C2E) : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();
            },
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF781C2E)),
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        const SizedBox(height: 16),
        // Active sort indicator (subtle)
        if (_sortBy != 'Default')
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 16),
            child: Row(
              children: [
                const Icon(Icons.sort, size: 14, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Sorted by: $_sortBy',
                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _sortBy = 'Default'),
                  child: const Text(
                    'Clear',
                    style: TextStyle(fontSize: 12, color: Color(0xFF781C2E), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: _searchQuery.isEmpty ? _buildTrendingSection() : _buildSearchResults(),
        ),
      ],
    );
  }

  Widget _buildTrendingSection() {
    final allProductsAsync = ref.watch(allProductsProvider);
    return allProductsAsync.when(
      data: (products) {
        final active = products.where((p) => p.isActive).toList();
        final sorted = _getSortedList(active).take(10).toList();

        if (sorted.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search, size: 80, color: Colors.grey.withOpacity(0.3)),
                const SizedBox(height: 16),
                const Text('Type to search items', style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.trending_up, color: Color(0xFF781C2E), size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Trending Items',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF781C2E), fontSize: 16),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: sorted.length,
                itemBuilder: (context, index) => _buildCompactCard(sorted[index], index),
              ),
            ),
          ],
        ).animate().fadeIn();
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildSearchResults() {
    final searchAsync = ref.watch(searchProductsProvider(_searchQuery));
    return searchAsync.when(
      data: (products) {
        final filtered = products.where((p) => p.isActive).toList();
        final sorted = _getSortedList(filtered);

        if (sorted.isEmpty) {
          return Center(child: Text('No items found for "$_searchQuery"', style: const TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: sorted.length,
          itemBuilder: (context, index) => _buildCompactCard(sorted[index], index),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  /// Sorting logic helper
  List<ProductModel> _getSortedList(List<ProductModel> products) {
    final list = List<ProductModel>.from(products);
    if (_sortBy == 'Price: Low to High') {
      list.sort((a, b) => a.rentalPricePerDay.compareTo(b.rentalPricePerDay));
    } else if (_sortBy == 'Price: High to Low') {
      list.sort((a, b) => b.rentalPricePerDay.compareTo(a.rentalPricePerDay));
    } else if (_sortBy == 'Newest') {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return list;
  }

  Widget _buildCompactCard(ProductModel product, int index) {
    final currentLocationAsync = ref.watch(currentLocationProvider);
    String? distanceText;
    currentLocationAsync.whenData((position) {
      if (position != null) {
        final dist = product.location.distanceFrom(position.latitude, position.longitude);
        distanceText = LocationService.formatDistance(dist);
      }
    });

    final accent = _getCategoryColor(product.categoryName);
    final postedDate = DateFormat('dd MMM yyyy').format(product.createdAt);
    final city = product.location.city ?? 'Nearby';

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDetailsScreen(item: product)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x14781C2E)),
          boxShadow: [
            BoxShadow(color: const Color(0x0A781C2E).withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: product.images.isNotEmpty
                  ? Image.network(product.images.first, width: 72, height: 72, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _iconBox(accent, product.categoryName))
                  : _iconBox(accent, product.categoryName),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF2B1B1F), fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 10, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('Posted $postedDate', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text('₹${product.rentalPricePerDay.toInt()}/day', style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 11, color: Colors.grey),
                      const SizedBox(width: 3),
                      Flexible(child: Text(distanceText != null ? '$city • $distanceText' : city, style: const TextStyle(fontSize: 10, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 40).ms).slideX(begin: 0.05);
  }

  Widget _iconBox(Color color, String category) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
      child: Icon(_getCategoryIcon(category), color: color, size: 30),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'electronics': return const Color(0xFF8B2635);
      case 'vehicles': return const Color(0xFFB13843);
      case 'sports': return const Color(0xFF9E2F3C);
      case 'tools': return const Color(0xFF781C2E);
      case 'furniture': return const Color(0xFFB75D69);
      case 'clothing': return const Color(0xFFA64B5D);
      default: return const Color(0xFF8B2635);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'electronics': return Icons.devices;
      case 'vehicles': return Icons.directions_car;
      case 'sports': return Icons.sports_basketball;
      case 'tools': return Icons.construction;
      case 'furniture': return Icons.chair_alt;
      case 'clothing': return Icons.checkroom;
      default: return Icons.inventory;
    }
  }
}
