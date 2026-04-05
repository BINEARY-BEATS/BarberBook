import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/widgets/book_empty_state.dart';
import '../../barber/models/barber_model.dart';
import '../../barber/providers/barber_provider.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});
  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  bool _isLoading = true;
  String? _errorText;
  LatLng? _currentLatLng;
  List<BarberModel> _barbers = [];
  String _searchQuery = '';
  bool _isSearching = false;
  Timer? _debounce; // To prevent terminal noise and firestore spam

  static const String _darkMapStyle = '''
[
  { "elementType": "geometry", "stylers": [{ "color": "#212121" }] },
  { "elementType": "labels.icon", "stylers": [{ "visibility": "off" }] },
  { "elementType": "labels.text.fill", "stylers": [{ "color": "#757575" }] },
  { "elementType": "labels.text.stroke", "stylers": [{ "color": "#212121" }] },
  { "featureType": "administrative", "elementType": "geometry", "stylers": [{ "color": "#757575" }] },
  { "featureType": "poi", "elementType": "geometry", "stylers": [{ "color": "#181818" }] },
  { "featureType": "road", "elementType": "geometry.fill", "stylers": [{ "color": "#2c2c2c" }] },
  { "featureType": "water", "elementType": "geometry", "stylers": [{ "color": "#000000" }] }
]
''';

  @override
  void initState() { super.initState(); _initData(); }
  @override
  void dispose() { _debounce?.cancel(); super.dispose(); }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final current = LatLng(pos.latitude, pos.longitude);
      final repo = ref.read(barberRepositoryProvider);
      final list = await repo.getNearbyBarbers(GeoPoint(pos.latitude, pos.longitude), 50.0);
      if (mounted) setState(() { _currentLatLng = current; _barbers = list; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _errorText = 'Location required for grooming discovery.'; _isLoading = false; });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => _performSearch(query));
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;
    setState(() { _searchQuery = query; _isSearching = true; });
    if (query.isEmpty) { await _initData(); return; }
    try {
      final repo = ref.read(barberRepositoryProvider);
      final results = await repo.searchBarbers(query);
      if (mounted) setState(() { _barbers = results; _isSearching = false; });
    } catch (_) { if (mounted) setState(() => _isSearching = false); }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Colors.white10)));
    if (_errorText != null) return Scaffold(backgroundColor: Colors.black, body: BookEmptyState(icon: Icons.location_off_rounded, title: 'ACCESS DENIED', subtitle: _errorText, action: FilledButton(onPressed: _initData, child: const Text('RETRY'))));

    final markers = _barbers.map((b) => Marker(
      markerId: MarkerId(b.uid),
      position: LatLng(b.location.latitude, b.location.longitude),
      onTap: () => context.push('/customer/barber/${b.uid}'),
    )).toSet();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: _currentLatLng!, zoom: 12),
              markers: markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              onMapCreated: (c) => c.setMapStyle(_darkMapStyle),
            ),
          ),
          
          Positioned(
            top: 60, left: 24, right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.05))),
              child: TextField(
                onChanged: _onSearchChanged,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  icon: _isSearching ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24)) : const Icon(Icons.search, color: Colors.white24, size: 20),
                  hintText: 'SEARCH MASTERS',
                  hintStyle: GoogleFonts.lexend(color: Colors.white12, fontSize: 13, letterSpacing: 1),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          DraggableScrollableSheet(
            initialChildSize: 0.3, minChildSize: 0.15, maxChildSize: 0.8,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(color: Color(0xFF0A0A0A), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  itemCount: _barbers.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) return Padding(padding: const EdgeInsets.only(bottom: 24), child: Text(_searchQuery.isEmpty ? 'NEARBY MASTERS' : 'MATCHING BARBERS', style: theme.textTheme.labelLarge));
                    final b = _barbers[index - 1];
                    return _BarberLuxuryTile(barber: b);
                  },
                ),
              );
            },
          ),

          Positioned(
            bottom: 40, left: 24, right: 24,
            child: SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: () => context.push('/customer/my-bookings'),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF111111), foregroundColor: Colors.white, side: BorderSide(color: Colors.white.withOpacity(0.05))),
                child: const Text('VIEW MY BOOKINGS'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarberLuxuryTile extends StatelessWidget {
  const _BarberLuxuryTile({required this.barber});
  final BarberModel barber;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.push('/customer/barber/${barber.uid}'),
    child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.04))),
      child: Row(children: [
        CircleAvatar(backgroundColor: Colors.white10, radius: 24, child: Text(barber.shopName[0].toUpperCase(), style: const TextStyle(color: Colors.white))),
        const SizedBox(width: 20),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(barber.shopName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 1)),
          Text(barber.ownerName, style: const TextStyle(color: Colors.white24, fontSize: 11)),
        ])),
        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white10, size: 14),
      ]),
    ),
  );
}
