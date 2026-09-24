import 'package:flutter/material.dart';
import '../../../core/networking/api_client.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key, required this.api});
  final ApiClient api;
  @override State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String,dynamic>? _data; String? _error;
  @override void initState(){ super.initState(); _load(); }
  Future<void> _load() async { try { final d=await widget.api.getMyAnalytics(); if(mounted)setState(()=>_data=d); } catch(e){ if(mounted)setState(()=>_error=e.toString()); } }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar: AppBar(title: const Text('NOVA İstatistiklerim', style: TextStyle(fontWeight: FontWeight.w900))),
    body: _data==null ? Center(child:_error==null?const CircularProgressIndicator():Text(_error!)) : ListView(padding: const EdgeInsets.all(16), children:[
      _Metric('Paylaşım', _data!['posts_created'] ?? 0, Icons.edit_note_rounded),
      _Metric('Alınan reaksiyon', _data!['reactions_received'] ?? 0, Icons.favorite_outline_rounded),
      _Metric('Kim söyledi? açılması', _data!['reveals_received'] ?? 0, Icons.visibility_outlined),
      _Metric('Kaydedilme', _data!['saves_received'] ?? 0, Icons.bookmark_border_rounded),
      _Metric('Profil ziyareti', _data!['profile_visits'] ?? 0, Icons.person_search_rounded),
      const SizedBox(height:16),
      Text('Bu ekran takipçi sayısını değil, içeriklerinin yarattığı gerçek etkileşimi gösterir.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height:1.4)),
    ]),
  );
}
class _Metric extends StatelessWidget { const _Metric(this.label,this.value,this.icon); final String label; final dynamic value; final IconData icon; @override Widget build(BuildContext context)=>Card(child:ListTile(leading:CircleAvatar(child:Icon(icon)),title:Text(label),trailing:Text('$value',style:const TextStyle(fontSize:22,fontWeight:FontWeight.w900)))); }
