import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/book_empty_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../../barber/models/barber_model.dart';
import '../../barber/providers/barber_provider.dart';
import '../widgets/barber_card.dart';

/// Customer home screen:
/// - Shows the user's current location on a Google Map.
/// - Fetches nearby barbers using a bounding-box + distance filter.
/// - Displays markers and a searchable list of barbers.
class CustomerHomeScreen extends ConsumerStatefulWidget {
  /// Creates the customer home screen.
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() =>
      _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  bool _isLoading = true;
  String? _errorText;
  bool _suggestOpenSettings = false;

  LatLng? _currentLatLng;
  List<BarberModel> _nearbyBarbers = const <BarberModel>[];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadNearbyBarbers();
  }

  /// Loads user location and fetches nearby barbers.
  Future<void> _loadNearbyBarbers() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
      _suggestOpenSettings = false;
    });

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _errorText =
                'Location is off for BarberBook. Allow access when asked, or enable it in Settings.';
            _suggestOpenSettings = true;
          });
          return;
        }
        if (requested == LocationPermission.deniedForever) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _errorText =
                'Location is blocked for this app. Turn it on in system Settings → Apps → BarberBook → Permissions.';
            _suggestOpenSettings = true;
          });
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final current = LatLng(position.latitude, position.longitude);
      final center = GeoPoint(position.latitude, position.longitude);

      final repo = ref.read(barberRepositoryProvider);
      final barbers = await repo.getNearbyBarbers(center, 5.0);

      if (!mounted) return;
      setState(() {
        _currentLatLng = current;
        _nearbyBarbers = barbers;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString();
      final userMessage = raw.contains('manifest') &&
              raw.contains('ACCESS_') &&
              raw.contains('LOCATION')
          ? 'This build was missing location permissions. They are now included — fully stop the app and open it again (or run a fresh install).'
          : 'Something went wrong while loading nearby barbers.';
      setState(() {
        _isLoading = false;
        _errorText = userMessage;
        _suggestOpenSettings = raw.toLowerCase().contains('permission');
      });
    }
  }

  /// Haversine distance in kilometers.
  double _distanceKm(LatLng a, LatLng b) {
    const earthRadiusKm = 6371.0;

    final dLat = (b.latitude - a.latitude) * pi / 180;
    final dLng = (b.longitude - a.longitude) * pi / 180;

    final lat1 = a.latitude * pi / 180;
    final lat2 = b.latitude * pi / 180;

    final sinDLat = sin(dLat / 2);
    final sinDLng = sin(dLng / 2);

    final h = sinDLat * sinDLat + sinDLng * sinDLng * cos(lat1) * cos(lat2);
    final c = 2 * atan2(sqrt(h), sqrt(1 - h));

    return earthRadiusKm * c;
  }

  AppBar _customerAppBar() {
    return AppBar(
      title: const Text('Nearby barbers'),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _isLoading ? null : () => _loadNearbyBarbers(),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (value) async {
            if (value == 'bookings') {
              if (!mounted) return;
              context.push('/customer/my-bookings');
            }
            if (value == 'signout') {
              await ref.read(authRepositoryProvider).signOut();
              if (!mounted) return;
              context.go('/splash');
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'bookings',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.bookmark_outline_rounded),
                title: Text('My bookings'),
              ),
            ),
            PopupMenuItem(
              value: 'signout',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.logout_rounded),
                title: Text('Sign out'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Please sign in.')));
    }

    if (_isLoading) {
      return Scaffold(
        appBar: _customerAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorText != null) {
      return Scaffold(
        appBar: _customerAppBar(),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: BookEmptyState(
              icon: Icons.location_searching_rounded,
              title: 'Can’t show nearby barbers',
              subtitle: _errorText,
              action: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.icon(
                    onPressed: () => _loadNearbyBarbers(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                  ),
                  if (_suggestOpenSettings) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () async {
                        await Geolocator.openAppSettings();
                      },
                      icon: const Icon(Icons.settings_rounded),
                      label: const Text('Open app settings'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    final current = _currentLatLng!;
    final filteredBarbers = _nearbyBarbers.where((b) {
      final q = _searchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      return b.shopName.toLowerCase().contains(q) ||
          b.ownerName.toLowerCase().contains(q);
    }).toList();

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('me'),
        position: current,
      ),
      ...filteredBarbers.map(
        (b) {
          final pos = LatLng(b.location.latitude, b.location.longitude);
          return Marker(
            markerId: MarkerId(b.uid),
            position: pos,
            onTap: () {
              context.push('/customer/barber/${b.uid}');
            },
          );
        },
      ),
    };

    return Scaffold(
      appBar: _customerAppBar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search barbers',
                hintText: 'Shop name or owner',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Flexible(
            flex: 1,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: current,
                zoom: 14,
              ),
              myLocationEnabled: false,
              markers: markers,
              onMapCreated: (_) {},
            ),
          ),
          Flexible(
            flex: 1,
            child: ListView.builder(
              itemCount: filteredBarbers.length,
              itemBuilder: (context, index) {
                final barber = filteredBarbers[index];
                final dist = _distanceKm(
                  current,
                  LatLng(barber.location.latitude, barber.location.longitude),
                );
                return BarberCard(
                  barber: barber,
                  distanceKm: dist,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

