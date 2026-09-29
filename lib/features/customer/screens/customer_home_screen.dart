import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/firestore_keys.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/demo_seeder.dart';
import '../../../core/widgets/book_category_chip.dart';
import '../../../core/widgets/book_section_header.dart';
import '../../../core/widgets/book_skeleton.dart';
import '../../../firebase/carto_maps_config.dart';
import '../../appointments/models/appointment_model.dart';
import '../../barber/data/barber_repository.dart';
import '../../barber/models/barber_model.dart';
import '../../barber/providers/barber_provider.dart';
import '../widgets/barber_card.dart';
import 'customer_my_bookings_screen.dart';

final _customerProfileProvider =
    StreamProvider.autoDispose<Map<String, dynamic>?>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection(FirestoreKeys.users)
      .doc(uid)
      .snapshots()
      .map((s) => s.data());
});

const _categories = [
  BookCategoryItem(id: 'haircut', label: 'Haircuts', icon: Icons.content_cut),
  BookCategoryItem(id: 'color', label: 'Coloring', icon: Icons.palette_outlined),
  BookCategoryItem(
    id: 'beard',
    label: 'Beard',
    icon: Icons.face_retouching_natural,
  ),
  BookCategoryItem(id: 'style', label: 'Styling', icon: Icons.brush_outlined),
];

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});
  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  bool _isLoading = true;
  LatLng _center = const LatLng(24.8607, 67.0011);
  List<BarberModel> _barbers = [];
  List<BarberModel> _allBarbers = [];
  String _searchQuery = '';
  bool _isSearching = false;
  String? _selectedCategory;
  String? _categoryEmptyHint;
  int _searchGen = 0;
  Timer? _debounce;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    if (mounted) setState(() => _isLoading = true);
    final repo = ref.read(barberRepositoryProvider);

    // Never block the UI on geo / heavy seed. Hard ceiling: 3s.
    try {
      await Future.any([
        _loadShopsFast(repo),
        Future<void>.delayed(const Duration(seconds: 3)),
      ]);
    } catch (_) {}

    // If still empty after the race, one last quick fetch.
    if (_allBarbers.isEmpty) {
      try {
        final list = await repo
            .listDiscoverableShops()
            .timeout(const Duration(seconds: 2));
        if (mounted) {
          final ranked = _rankForFeed(list);
          setState(() {
            _allBarbers = ranked;
            _barbers = _applyCategory(ranked, _selectedCategory);
          });
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isSearching = false;
      });
    }

    // Location + rich extras never gate the first paint.
    // ignore: unawaited_futures
    _refreshLocationInBackground();
    // ignore: unawaited_futures
    DemoSeeder.ensureDemoCatalog().catchError((_) {});
  }

  Future<void> _loadShopsFast(BarberRepository repo) async {
    try {
      await DemoSeeder.ensureDemoShopsFast().timeout(
        const Duration(seconds: 2),
        onTimeout: () {},
      );
    } catch (_) {}

    List<BarberModel> list = [];
    try {
      list = await repo.listDiscoverableShops().timeout(
        const Duration(seconds: 2),
      );
    } catch (_) {
      list = [];
    }

    final ranked = _rankForFeed(list);
    if (!mounted) return;
    setState(() {
      _allBarbers = ranked;
      _barbers = _applyCategory(ranked, _selectedCategory);
      _searchQuery = '';
      // Leave skeleton as soon as we have shops (don't wait for the 3s race).
      if (ranked.isNotEmpty) {
        _isLoading = false;
        _isSearching = false;
      }
    });
  }

  /// Catalog demo shops first; drop junk placeholders (Demo Shop / letter avatars).
  List<BarberModel> _rankForFeed(List<BarberModel> source) {
    final quality = source.where(_isFeedQuality).toList();
    quality.sort((a, b) {
      final aDemo = a.uid.startsWith('demo_shop_') ? 0 : 1;
      final bDemo = b.uid.startsWith('demo_shop_') ? 0 : 1;
      if (aDemo != bDemo) return aDemo.compareTo(bDemo);
      final aPro = a.isPro ? 0 : 1;
      final bPro = b.isPro ? 0 : 1;
      if (aPro != bPro) return aPro.compareTo(bPro);
      return b.rating.compareTo(a.rating);
    });
    return quality;
  }

  bool _isFeedQuality(BarberModel b) {
    if (b.uid.startsWith('demo_shop_')) return true;
    final name = b.shopName.trim().toLowerCase();
    if (name == 'demo shop' || name == 'test shop') return false;
    final photo = b.photoUrl.trim().toLowerCase();
    if (photo.isEmpty) return false;
    if (photo.contains('ui-avatars') ||
        photo.contains('dicebear') ||
        photo.contains('pravatar') ||
        photo.contains('robohash')) {
      return false;
    }
    // Prefer real http photos with some reviews/rating signal.
    if (!photo.startsWith('http')) return false;
    return true;
  }

  Future<void> _refreshLocationInBackground() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission().timeout(
          const Duration(seconds: 2),
          onTimeout: () => LocationPermission.denied,
        );
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 2),
      );
      if (!mounted) return;
      setState(() {
        _center = LatLng(pos.latitude, pos.longitude);
      });
    } catch (_) {}
  }

  List<BarberModel> _applyCategory(List<BarberModel> source, String? cat) {
    _categoryEmptyHint = null;
    if (cat == null) return List.of(source);
    final needle = switch (cat) {
      'haircut' => ['hair', 'cut', 'fade', 'combo', 'signature'],
      'color' => ['color', 'dye', 'highlight', 'tint'],
      'beard' => ['beard', 'shave', 'trim'],
      'style' => ['style', 'blow', 'finish', 'combo'],
      _ => <String>[],
    };
    final filtered = source.where((b) {
      return b.services.any((s) {
        final n = s.name.toLowerCase();
        return needle.any(n.contains);
      });
    }).toList();
    if (filtered.isEmpty) {
      _categoryEmptyHint = 'No exact matches — showing all shops';
      return List.of(source);
    }
    return filtered;
  }

  List<BarberModel> _localFilter(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return List.of(_allBarbers);
    return _allBarbers.where((b) {
      if (b.shopName.toLowerCase().contains(q)) return true;
      if (b.address.toLowerCase().contains(q)) return true;
      if (b.ownerName.toLowerCase().contains(q)) return true;
      return b.services.any((s) => s.name.toLowerCase().contains(q));
    }).toList();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 320),
      () => _performSearch(query),
    );
  }

  void _performSearch(String query) {
    if (!mounted) return;
    final gen = ++_searchGen;
    final q = query.trim();
    setState(() {
      _searchQuery = q;
      _isSearching = true;
    });

    // Local filter only — avoids Firestore prefix races / empty mid-string results.
    final list = _localFilter(q);
    if (!mounted || gen != _searchGen) return;
    setState(() {
      _barbers = _applyCategory(list, _selectedCategory);
      _isSearching = false;
    });
  }

  double _distanceKm(BarberModel b) {
    if (b.location.latitude.abs() < 0.01 && b.location.longitude.abs() < 0.01) {
      return 0;
    }
    return Geolocator.distanceBetween(
          _center.latitude,
          _center.longitude,
          b.location.latitude,
          b.location.longitude,
        ) /
        1000;
  }

  Future<void> _openMapSheet() async {
    final accent = Theme.of(context).colorScheme.primary;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.customerCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.sizeOf(ctx).height * 0.72,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.customerBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Text(
                      'Near you',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: _center,
                      initialZoom: 13,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: CartoMapTiles.urlTemplate(dark: true),
                        maxNativeZoom: 18,
                        userAgentPackageName: 'com.barberbook.app',
                      ),
                      MarkerLayer(
                        markers: _barbers
                            .where(
                              (b) =>
                                  b.location.latitude.abs() > 0.01 ||
                                  b.location.longitude.abs() > 0.01,
                            )
                            .map(
                              (b) => Marker(
                                point: LatLng(
                                  b.location.latitude,
                                  b.location.longitude,
                                ),
                                width: 44,
                                height: 44,
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    context.push('/customer/barber/${b.uid}');
                                  },
                                  child: Icon(
                                    Icons.location_on_rounded,
                                    color: accent,
                                    size: 40,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final user = FirebaseAuth.instance.currentUser;
    final profile = ref.watch(_customerProfileProvider).maybeWhen(
          data: (d) => d,
          orElse: () => null,
        );
    final firstName = ((profile?[FirestoreKeys.userName] as String?) ??
            user?.displayName ??
            'there')
        .split(' ')
        .first;
    final upcomingAsync = ref.watch(customerBookingsProvider);

    final allBookings = upcomingAsync.maybeWhen(
      data: (list) => list,
      orElse: () => <AppointmentModel>[],
    );
    final upcoming = allBookings
        .where(
          (a) =>
              a.slot.toDate().isAfter(DateTime.now()) &&
              a.status != FirestoreKeys.appointmentStatusCancelled,
        )
        .take(2)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: _isLoading
              ? _HomeSkeleton(key: const ValueKey('skeleton'))
              : RefreshIndicator(
                  key: const ValueKey('content'),
                  color: accent,
                  onRefresh: _initData,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.customerAccentSoft,
                                backgroundImage: user?.photoURL != null
                                    ? NetworkImage(user!.photoURL!)
                                    : null,
                                child: user?.photoURL == null
                                    ? Text(
                                        firstName.isNotEmpty
                                            ? firstName[0].toUpperCase()
                                            : 'J',
                                        style: TextStyle(
                                          color: accent,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hello, $firstName',
                                      style:
                                          theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 22,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Find your next great cut',
                                      style: TextStyle(
                                        color: AppColors.customerSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Map',
                                onPressed: _openMapSheet,
                                icon: Icon(
                                  Icons.map_outlined,
                                  color: accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.customerCard,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.r16),
                              border:
                                  Border.all(color: AppColors.customerBorder),
                            ),
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocus,
                              onChanged: _onSearchChanged,
                              textInputAction: TextInputAction.search,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                prefixIcon: _isSearching
                                    ? Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: accent,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.search_rounded,
                                        color: AppColors.customerSecondary,
                                      ),
                                hintText: 'Search shops, services…',
                                hintStyle: const TextStyle(
                                  color: AppColors.customerSecondary,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 14,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.clear_rounded,
                                          color: AppColors.customerSecondary,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          _performSearch('');
                                        },
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (upcoming.isNotEmpty) ...[
                        const SliverToBoxAdapter(child: SizedBox(height: 22)),
                        SliverToBoxAdapter(
                          child: BookSectionHeader(
                            title: 'Upcoming',
                            actionLabel: 'See all',
                            onAction: () => context.go('/customer/home?tab=1'),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 12)),
                        ...upcoming.map(
                          (a) => SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 0, 20, 10),
                              child: _UpcomingCard(
                                appointment: a,
                                accent: accent,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SliverToBoxAdapter(child: SizedBox(height: 22)),
                      const SliverToBoxAdapter(
                        child: BookSectionHeader(title: 'Categories'),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 12)),
                      SliverToBoxAdapter(
                        child: BookCategoryRow(
                          items: _categories,
                          selectedId: _selectedCategory,
                          onSelected: (id) {
                            setState(() {
                              _selectedCategory = id;
                              final base = _searchQuery.isEmpty
                                  ? _allBarbers
                                  : _localFilter(_searchQuery);
                              _barbers = _applyCategory(base, id);
                            });
                          },
                        ),
                      ),
                      if (_categoryEmptyHint != null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                            child: Text(
                              _categoryEmptyHint!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: accent,
                              ),
                            ),
                          ),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 20)),
                      SliverToBoxAdapter(
                        child: BookSectionHeader(
                          title: _searchQuery.isEmpty
                              ? 'Near you'
                              : 'Results',
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 12)),
                      if (_barbers.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              20,
                              12,
                              20,
                              BookScaffoldPadding.bottomNav,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: AppColors.customerCard,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.r20),
                                border: Border.all(
                                  color: AppColors.customerBorder,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.storefront_outlined,
                                    size: 40,
                                    color: accent,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No shops to show',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Pull to refresh or clear your search.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.customerSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            20,
                            0,
                            20,
                            BookScaffoldPadding.bottomNav,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final b = _barbers[index];
                                return TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: 1),
                                  duration: Duration(
                                    milliseconds: 220 + (index * 40).clamp(0, 200),
                                  ),
                                  curve: Curves.easeOut,
                                  builder: (context, value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: Transform.translate(
                                        offset: Offset(0, 12 * (1 - value)),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: BarberCard(
                                      barber: b,
                                      distanceKm: _distanceKm(b),
                                    ),
                                  ),
                                );
                              },
                              childCount: _barbers.length,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      children: const [
        Row(
          children: [
            BookSkeleton(
              width: 48,
              height: 48,
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BookSkeleton(width: 140, height: 20),
                  SizedBox(height: 8),
                  BookSkeleton(width: 180, height: 12),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 22),
        BookSkeleton(height: 52),
        SizedBox(height: 28),
        BookSkeleton(width: 100, height: 18),
        SizedBox(height: 14),
        BookShopCardSkeleton(),
        SizedBox(height: 16),
        BookShopCardSkeleton(),
        SizedBox(height: 16),
        BookShopCardSkeleton(),
      ],
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({
    required this.appointment,
    required this.accent,
  });
  final AppointmentModel appointment;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.customerCard,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.customerBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.customerAccentSoft,
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
            child: Icon(
              Icons.event_available_rounded,
              color: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.service.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  DateFormat('EEE, MMM d · h:mm a')
                      .format(appointment.slot.toDate()),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.customerSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${appointment.service.price.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}
