import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../data/dive_site_model.dart';
import '../data/dive_sites_api.dart';

class DiveSitesPage extends StatefulWidget { const DiveSitesPage({super.key}); @override State<DiveSitesPage> createState() => _DiveSitesPageState(); }
class _DiveSitesPageState extends State<DiveSitesPage> {
  final _api = DiveSitesApi(); List<DiveSiteModel> _sites = []; bool _loading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { try { final s = await _api.findAll(); if (mounted) setState(() { _sites=s; _loading=false; }); } catch (_) { if (mounted) setState(() => _loading=false); } }
  @override Widget build(BuildContext context) => SafeArea(child: RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 100), children: [const Text('Dive Sites', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: DiverrTheme.dark)), const SizedBox(height: 6), Text('Descubra pontos de mergulho cadastrados pela comunidade.', style: TextStyle(color: Colors.grey.shade600)), const SizedBox(height: 20), if (_loading) const Center(child: CircularProgressIndicator()) else if (_sites.isEmpty) _empty() else ..._sites.map(_card)])));
  Widget _card(DiveSiteModel s) => Card(margin: const EdgeInsets.only(bottom: 12), child: ListTile(contentPadding: const EdgeInsets.all(14), leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: DiverrTheme.ocean.withOpacity(.25), shape: BoxShape.circle), child: const Icon(Icons.location_on, color: DiverrTheme.primary)), title: Text(s.nome, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text([s.cidade, s.estado, s.pais].where((e) => e != null && e!.isNotEmpty).join(', ')), trailing: const Icon(Icons.chevron_right)));
  Widget _empty() => Card(child: Padding(padding: const EdgeInsets.all(28), child: Column(children: [Icon(Icons.explore_outlined, size: 48, color: Colors.grey.shade400), const SizedBox(height: 12), const Text('Nenhum Dive Site ainda', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)), const SizedBox(height: 6), Text('Os pontos criados pela comunidade aparecerão aqui.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600))])));
}
