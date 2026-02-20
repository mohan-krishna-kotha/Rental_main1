import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/product_model.dart'; // Updated import
import '../../../../core/models/user_model.dart';
import '../../../../core/providers/items_provider.dart'; // Keeping provider import
import '../../../../core/providers/location_provider.dart';
import '../../../../core/providers/favorites_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/services/location_service.dart';
import '../../../booking/presentation/booking_screen.dart';
import '../../../add_listing/presentation/screens/add_listing_screen.dart';
import 'item_details_screen.dart';
import 'subscription_screen.dart';
import 'search_dashboard_screen.dart';
import '../../../chat/presentation/screens/chat_list_screen.dart';
import '../../../../core/providers/chat_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.8);
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String? _selectedCategory;

  static const List<CategoryPill> _categoryPills = [
    CategoryPill('Electronics', Icons.devices, [
      Color(0xFF8B2635),
      Color(0xFFB13843),
    ]),
    CategoryPill('Vehicles', Icons.directions_car, [
      Color(0xFF9E2F3C),
      Color(0xFFB75D69),
    ]),
    CategoryPill('Sports', Icons.sports_soccer, [
      Color(0xFF781C2E),
      Color(0xFF8B2635),
    ]),
    CategoryPill('Tools', Icons.handyman, [
      Color(0xFF9E2F3C),
      Color(0xFFB13843),
    ]),
    CategoryPill('Furniture', Icons.weekend, [
      Color(0xFF8B2635),
      Color(0xFFA64B5D),
    ]),
    CategoryPill('Clothing', Icons.checkroom, [
      Color(0xFFB13843),
      Color(0xFFCF6679),
    ]),
  ];

  String _getLocalizedCategoryName(String key, AppLocalizations l10n) {
    switch (key) {
      case 'Electronics':
        return l10n.electronics;
      case 'Vehicles':
        return l10n.vehicles;
      case 'Sports':
        return l10n.sports;
      case 'Tools':
        return l10n.tools;
      case 'Furniture':
        return l10n.furniture;
      case 'Clothing':
        return l10n.clothing;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final currentLocationAsync = ref.watch(currentLocationProvider);
    final nearbyProductsAsync = ref.watch(nearbyProductsProvider);
    final searchRadius = ref.watch(searchRadiusProvider);
    final userAsync = ref.watch(userModelProvider);
    final currentUser = userAsync.maybeWhen(
      data: (user) => user,
      orElse: () => null,
    );

    final currentPosition = currentLocationAsync.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );

    final greeting = userAsync.maybeWhen(
      data: (user) {
        if (user == null) return 'there';
        final name = user.displayName.trim();
        if (name.isEmpty) return 'there';
        return name.split(' ').first;
      },
      orElse: () => 'there',
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        color: colorScheme.primary,
        onRefresh: () async {
          ref.invalidate(nearbyProductsProvider);
          await ref.read(currentLocationProvider.notifier).refreshLocation();
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeroSection(
                context: context,
                greeting: greeting,
                currentLocation: currentLocationAsync,
                searchRadius: searchRadius,
                currentUser: currentUser,
                l10n: l10n,
              ),
            ),
            SliverToBoxAdapter(
              child: _buildLocationCallout(
                context,
                currentLocationAsync,
                searchRadius,
                l10n,
              ),
            ),
            SliverToBoxAdapter(child: _buildCategoriesSection(context, l10n)),
            SliverToBoxAdapter(
              child: _buildProductsSection(
                context,
                nearbyProductsAsync,
                currentPosition,
                l10n,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
      floatingActionButton: _buildPrimaryFab(context),
    );
  }

  Widget _buildHeroSection({
    required BuildContext context,
    required String greeting,
    required AsyncValue<dynamic> currentLocation,
    required double searchRadius,
    required UserModel? currentUser,
    required AppLocalizations l10n,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF781C2E), Color(0xFF8B2635), Color(0xFFB13843)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 12,
        20,
        28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.goodToSeeYou,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.heyGreeting(greeting),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildSubscriptionChip(context, currentUser, l10n),
              const SizedBox(width: 8),
              _buildChatBadge(context),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _showRadiusDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  const Icon(Icons.near_me, color: Colors.white70, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${searchRadius.toInt()} km ${l10n.searchRadius}', // Using searchRadius key if suitable or just 'km radius' logic
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const Spacer(),
                  const Icon(Icons.tune, color: Colors.white70, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          currentLocation.when(
            data: (position) {
              if (position != null) {
                return Text(
                  l10n.deliveringCurated,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                );
              }
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_off, color: Colors.white70),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.enableLocationUnlock,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await LocationService.requestLocationPermission();
                        await ref
                            .read(currentLocationProvider.notifier)
                            .refreshLocation();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: Text(l10n.enable),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: LinearProgressIndicator(color: Colors.white),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchDashboardScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAD9D5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.search,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.searchPlaceholder,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF8E8A86),
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_outward, color: Color(0xFF8E8A86)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionChip(BuildContext context, UserModel? currentUser, AppLocalizations l10n) {
    final tier = currentUser?.subscriptionTier ?? 'basic';
    final isPremium = tier != 'basic';
    final tierVisual = _resolveTier(tier);
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
        );
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Colors.white.withOpacity(0.12),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPremium ? tierVisual.icon : Icons.workspace_premium,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              isPremium ? tierVisual.label : l10n.goPremium,
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCallout(
    BuildContext context,
    AsyncValue<dynamic> currentLocation,
    double searchRadius,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: currentLocation.when(
        data: (position) {
          if (position == null) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_disabled,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.locationOffMessage,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return Text(
            l10n.curatedInventoryMessage(searchRadius.toInt()),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: LinearProgressIndicator(),
        ),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildCategoriesSection(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.exploreCategories,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              if (_selectedCategory != null)
                TextButton(
                  onPressed: () {
                    setState(() => _selectedCategory = null);
                  },
                  child: Text(l10n.clear),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final pill = _categoryPills[index];
                final isSelected = _selectedCategory == pill.name;
                final localizedName = _getLocalizedCategoryName(pill.name, l10n);
                return _buildCategoryChip(pill, isSelected, localizedName, l10n);
              },
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemCount: _categoryPills.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(CategoryPill pill, bool isSelected, String localizedName, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = isSelected ? null : pill.name;
        });
        if (!isSelected) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.filteringInventory(localizedName))),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: isSelected
              ? LinearGradient(
                  colors: pill.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0x1A781C2E),
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: pill.gradient.last.withOpacity(0.25),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              pill.icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF7A736E),
            ),
            const SizedBox(width: 8),
            Text(
              localizedName,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF463F3A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSection(
    BuildContext context,
    AsyncValue<List<ProductModel>> productsAsync,
    Position? currentPosition,
    AppLocalizations l10n,
  ) {
    return productsAsync.when(
      data: (products) {
        final currentUser = ref.watch(currentUserProvider);

        final filtered = products.where((item) {
          if (!item.isActive) return false;
          if (currentUser != null && item.ownerId == currentUser.uid) {
            return false;
          }
          return _selectedCategory == null ||
              item.categoryName == _selectedCategory;
        }).toList();

        if (filtered.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: _buildEmptyState(context), // Assuming _buildEmptyState exists (might need updating too if it has hardcoded strings)
          );
        }

        final featured = filtered.take(5).toList();
        final recommended = filtered.skip(5).toList();

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(
                context,
                title: l10n.trendingNearby,
                action: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchDashboardScreen(),
                      ),
                    );
                  },
                  child: Text(l10n.seeAll),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 360,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: featured.length,
                  padEnds: false,
                  itemBuilder: (context, index) {
                    final item = featured[index];
                    final distance = currentPosition != null
                        ? LocationService.formatDistance(
                            item.location.distanceFrom(
                              currentPosition.latitude,
                              currentPosition.longitude,
                            ),
                          )
                        : null;
                    return _buildFeaturedCard(context, item, index, distance, l10n); // Pass l10n
                  },
                ),
              ),
              if (recommended.isNotEmpty) ...[
                const SizedBox(height: 24),
                _sectionHeader(context, title: l10n.recommendedForYou),
                const SizedBox(height: 12),
                ...recommended.map((item) {
                  final distance = currentPosition != null
                      ? LocationService.formatDistance(
                          item.location.distanceFrom(
                            currentPosition.latitude,
                            currentPosition.longitude,
                          ),
                        )
                      : null;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildRecommendationTile(context, item, distance, l10n), // Pass l10n if needed, assumes it might use pricePerDay
                  );
                }),
              ],
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: _buildErrorState(err, context),
      ),
    );
  }

  Widget _buildFeaturedCard(
    BuildContext context,
    ProductModel item,
    int index,
    String? distanceLabel,
    AppLocalizations l10n,
  ) {
    final accent = _getCategoryColor(item.categoryName);
    final heroImage = item.images.isNotEmpty ? item.images.first : null;

    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        final difference = (_currentPage - index).abs();
        final scale = 1 - (difference * 0.06).clamp(0.0, 0.12);
        return Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetailsScreen(item: item),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.15),
                blurRadius: 24,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                child: heroImage != null
                    ? Image.network(
                        heroImage,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: 180,
                        width: double.infinity,
                        color: accent.withOpacity(0.1),
                        child: Icon(
                          _getCategoryIcon(item.categoryName),
                          size: 48,
                          color: accent,
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _getLocalizedCategoryName(item.categoryName, l10n), // Use localized name
                            style: TextStyle(color: accent, fontSize: 12),
                          ),
                        ),
                        const Spacer(),
                        if (distanceLabel != null)
                          Row(
                            children: [
                              const Icon(
                                Icons.place,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                distanceLabel,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF2B1B1F),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          l10n.pricePerDay(item.rentalPricePerDay.toStringAsFixed(0)),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const Spacer(),
                        _buildFavoriteButton(context, item),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationTile(
    BuildContext context,
    ProductModel item,
    String? distanceLabel,
    AppLocalizations l10n,
  ) {
    final accent = _getCategoryColor(item.categoryName);
    final thumbnail = item.images.isNotEmpty ? item.images.first : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x14781C2E)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: thumbnail != null
                ? Image.network(
                    thumbnail,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 70,
                    height: 70,
                    color: accent.withOpacity(0.1),
                    child: Icon(
                      _getCategoryIcon(item.categoryName),
                      color: accent,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF2B1B1F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.pricePerDay(item.rentalPricePerDay.toStringAsFixed(0)),
                  style: TextStyle(color: accent, fontWeight: FontWeight.bold),
                ),
                if (distanceLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    distanceLabel,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildFavoriteButton(context, item, compact: true),
              const SizedBox(height: 12),
              SizedBox(
                height: 36,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingScreen(item: item),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(88, 36),
                  ),
                  child: Text(l10n.book),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(
    BuildContext context, {
    required String title,
    Widget? action,
  }) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const Spacer(),
        if (action != null) action,
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Icon(Icons.hourglass_empty, size: 48, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Text(l10n.noItemsFound, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          l10n.increaseRadiusHint,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorState(Object err, BuildContext context) { // Taking context to get l10n
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
        const SizedBox(height: 12),
        Text(l10n.errorLoadingInventory(err.toString())),
      ],
    );
  }

  Widget _buildFavoriteButton(
    BuildContext context,
    ProductModel item, {
    bool compact = false,
  }) {
    final favorites = ref.watch(userFavoritesProvider).value ?? [];
    final isFavorite = favorites.contains(item.id);
    final currentUser = ref.watch(currentUserProvider);
    final l10n = AppLocalizations.of(context)!;

    return InkWell(
      onTap: () async {
        if (currentUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.signInToManageFavorites)),
          );
          return;
        }
        await ref
            .read(firestoreServiceProvider)
            .toggleFavorite(currentUser.uid, item.id);
      },
      customBorder: const CircleBorder(),
      child: Container(
        padding: EdgeInsets.all(compact ? 6 : 10),
        decoration: BoxDecoration(
          color: isFavorite
              ? Colors.red.withOpacity(0.15)
              : Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? Colors.red : Colors.grey.shade600,
          size: compact ? 18 : 20,
        ),
      ),
    );
  }

  Widget _buildPrimaryFab(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FloatingActionButton.extended(
      heroTag: 'home-list-fab',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddListingScreen()),
        );
      },
      icon: const Icon(Icons.add),
      label: Text(l10n.listItem),
    );
  }

  Widget _buildChatBadge(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chatsAsync = ref.watch(userChatsProvider);
    final currentUser = FirebaseAuth.instance.currentUser;

    final unreadCount = chatsAsync.maybeWhen(
      data: (chats) {
        if (currentUser == null) return 0;
        return chats.fold<int>(0, (count, chat) {
          if (currentUser.uid == chat.ownerId) {
            return count + chat.ownerUnreadCount;
          }
          if (currentUser.uid == chat.renterId) {
            return count + chat.renterUnreadCount;
          }
          return count;
        });
      },
      orElse: () => 0,
    );

    return Badge(
      label: Text(
        '$unreadCount',
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
      isLabelVisible: unreadCount > 0,
      backgroundColor: Colors.red,
      child: IconButton(
        icon: const Icon(Icons.message_outlined, color: Colors.white),
        tooltip: l10n.messages,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatListScreen()),
          );
        },
      ),
    );
  }

  void _showRadiusDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentRadius = ref.read(searchRadiusProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.searchRadius),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.current(currentRadius.toInt())),
            Slider(
              value: currentRadius,
              min: 1,
              max: 50,
              divisions: 49,
              label: '${currentRadius.toInt()} km',
              onChanged: (value) {
                ref.read(searchRadiusProvider.notifier).setRadius(value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.done),
          ),
        ],
      ),
    );
  }

  _TierVisual _resolveTier(String tier) {
    switch (tier) {
      case 'renter_plus':
        return const _TierVisual(
          label: 'Renter+',
          icon: Icons.shopping_bag,
          color: Color(0xFF145DA0),
          description: 'Priority bookings & concierge support.',
        );
      case 'lender_pro':
        return const _TierVisual(
          label: 'Lender Pro',
          icon: Icons.storefront,
          color: Color(0xFF6A1B9A),
          description: 'Boosted visibility for every listing.',
        );
      case 'pro_max':
        return const _TierVisual(
          label: 'Pro Max',
          icon: Icons.workspace_premium,
          color: Color(0xFFD4AF37),
          description: 'All-access with smart insights.',
        );
      default:
        return const _TierVisual(
          label: 'Premium',
          icon: Icons.verified,
          color: Color(0xFF781C2E),
          description: 'Enjoy the premium toolkit.',
        );
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'electronics':
        return const Color(0xFF8B2635);
      case 'vehicles':
        return const Color(0xFFB13843);
      case 'sports':
        return const Color(0xFF9E2F3C);
      case 'tools':
        return const Color(0xFF781C2E);
      case 'furniture':
        return const Color(0xFFB75D69);
      case 'clothing':
        return const Color(0xFFA64B5D);
      default:
        return const Color(0xFF8B2635);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'electronics':
        return Icons.devices;
      case 'vehicles':
        return Icons.directions_car;
      case 'sports':
        return Icons.sports_basketball;
      case 'tools':
        return Icons.construction;
      case 'furniture':
        return Icons.chair_alt;
      case 'clothing':
        return Icons.checkroom;
      default:
        return Icons.inventory;
    }
  }
}

class CategoryPill {
  final String name;
  final IconData icon;
  final List<Color> gradient;

  const CategoryPill(this.name, this.icon, this.gradient);
}

class _TierVisual {
  final String label;
  final IconData icon;
  final Color color;
  final String description;

  const _TierVisual({
    required this.label,
    required this.icon,
    required this.color,
    required this.description,
  });
}
