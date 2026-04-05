import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/firestore_keys.dart';
import '../models/service_model.dart';
import '../providers/barber_provider.dart';

class _StepMeta {
  const _StepMeta({required this.icon, required this.title, required this.subtitle});
  final IconData icon; final String title, subtitle;
}

class BarberOnboardingScreen extends ConsumerStatefulWidget {
  const BarberOnboardingScreen({super.key});
  @override
  ConsumerState<BarberOnboardingScreen> createState() => _BarberOnboardingScreenState();
}

class _BarberOnboardingScreenState extends ConsumerState<BarberOnboardingScreen> {
  int _stepIndex = 0;
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  static const List<String> _days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
  final Map<String, bool> _enabledDays = {'mon': true, 'tue': true, 'wed': true, 'thu': true, 'fri': true, 'sat': false, 'sun': false};
  final Map<String, TimeOfDay> _openTimes = Map.fromIterable(_days, value: (_) => const TimeOfDay(hour: 9, minute: 0));
  final Map<String, TimeOfDay> _closeTimes = Map.fromIterable(_days, value: (_) => const TimeOfDay(hour: 17, minute: 0));
  final TextEditingController _serviceNameController = TextEditingController();
  final TextEditingController _servicePriceController = TextEditingController();
  final TextEditingController _serviceDurationController = TextEditingController(text: '30');
  bool _isSaving = false;

  static final List<_StepMeta> _steps = [
    const _StepMeta(icon: Icons.storefront_rounded, title: 'Barbershop', subtitle: 'Identify your workspace.'),
    const _StepMeta(icon: Icons.schedule_rounded, title: 'Availability', subtitle: 'Define your weekly schedule.'),
    const _StepMeta(icon: Icons.content_cut_rounded, title: 'Offerings', subtitle: 'Add your primary service.'),
  ];

  Future<void> _onNext() async {
    if (_stepIndex < 2) { setState(() => _stepIndex += 1); return; }
    final user = FirebaseAuth.instance.currentUser; if (user == null) return;
    final repo = ref.read(barberRepositoryProvider);
    final workingHours = <String, Map<String, String>>{};
    for (final d in _days) { if (_enabledDays[d] == true) workingHours[d] = {FirestoreKeys.workingHoursOpen: '${_openTimes[d]!.hour}:${_openTimes[d]!.minute.toString().padLeft(2, '0')}', FirestoreKeys.workingHoursClose: '${_closeTimes[d]!.hour}:${_closeTimes[d]!.minute.toString().padLeft(2, '0')}'}; }
    setState(() => _isSaving = true);
    try {
      await repo.updateBarberProfile(user.uid, {FirestoreKeys.barberShopName: _shopNameController.text, FirestoreKeys.barberOwnerName: _ownerNameController.text, FirestoreKeys.barberAddress: _addressController.text, FirestoreKeys.barberIsActive: true});
      await repo.setWorkingHours(user.uid, workingHours);
      await repo.addService(user.uid, ServiceModel(name: _serviceNameController.text, price: double.parse(_servicePriceController.text), durationMinutes: int.parse(_serviceDurationController.text)));
      if (mounted) context.go('/barber/home');
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e'))); }
    finally { if (mounted) setState(() => _isSaving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = _steps[_stepIndex];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => _stepIndex > 0 ? setState(() => _stepIndex -= 1) : context.go('/splash'))),
      body: SafeArea(
        child: Column(children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 40), child: _MinimalProgress(current: _stepIndex, total: 3)),
          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(32), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(meta.title.toUpperCase(), style: theme.textTheme.displayMedium),
            const SizedBox(height: 12),
            Text(meta.subtitle, style: const TextStyle(color: Colors.white24, fontWeight: FontWeight.w400)),
            const SizedBox(height: 64),
            AnimatedSwitcher(duration: const Duration(milliseconds: 400), child: KeyedSubtree(key: ValueKey(_stepIndex), child: _stepIndex == 0 ? _Step1(shop: _shopNameController, owner: _ownerNameController, address: _addressController) : _stepIndex == 1 ? _Step2(days: _days, enabled: _enabledDays, onToggle: (d, v) => setState(() => _enabledDays[d] = v)) : _Step3(name: _serviceNameController, price: _servicePriceController, mins: _serviceDurationController))),
          ]))),
          Padding(padding: const EdgeInsets.all(32), child: SizedBox(width: double.infinity, height: 64, child: FilledButton(onPressed: _isSaving ? null : _onNext, child: _isSaving ? const CircularProgressIndicator() : Text(_stepIndex < 2 ? 'CONTINUE' : 'FINISH SETUP'))))
        ]),
      ),
    );
  }
}

class _MinimalProgress extends StatelessWidget {
  const _MinimalProgress({required this.current, required this.total});
  final int current, total;
  @override
  Widget build(BuildContext context) => Row(children: List.generate(total, (i) => Expanded(child: Container(height: 2, margin: const EdgeInsets.only(right: 8), color: i <= current ? Colors.white : Colors.white10))));
}

class _Step1 extends StatelessWidget {
  const _Step1({required this.shop, required this.owner, required this.address});
  final TextEditingController shop, owner, address;
  @override
  Widget build(BuildContext context) => Column(children: [
    TextField(controller: shop, decoration: const InputDecoration(labelText: 'SHOP NAME')),
    const SizedBox(height: 24),
    TextField(controller: owner, decoration: const InputDecoration(labelText: 'OWNER NAME')),
    const SizedBox(height: 24),
    TextField(controller: address, decoration: const InputDecoration(labelText: 'LOCATION')),
  ]);
}

class _Step2 extends StatelessWidget {
  const _Step2({required this.days, required this.enabled, required this.onToggle});
  final List<String> days; final Map<String, bool> enabled; final void Function(String, bool) onToggle;
  @override
  Widget build(BuildContext context) => Column(children: days.map((d) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    decoration: BoxDecoration(color: const Color(0xFF0A0A0A), borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      Text(d.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.5, fontSize: 13)),
      const Spacer(),
      Switch(value: enabled[d] == true, onChanged: (v) => onToggle(d, v), activeColor: Colors.white),
    ]),
  )).toList());
}

class _Step3 extends StatelessWidget {
  const _Step3({required this.name, required this.price, required this.mins});
  final TextEditingController name, price, mins;
  @override
  Widget build(BuildContext context) => Column(children: [
    TextField(controller: name, decoration: const InputDecoration(labelText: 'SERVICE NAME')),
    const SizedBox(height: 24),
    Row(children: [
      Expanded(child: TextField(controller: price, decoration: const InputDecoration(labelText: 'PRICE'))),
      const SizedBox(width: 24),
      Expanded(child: TextField(controller: mins, decoration: const InputDecoration(labelText: 'MINUTES'))),
    ]),
  ]);
}
