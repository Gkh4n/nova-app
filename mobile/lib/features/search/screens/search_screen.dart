import 'package:flutter/material.dart';

import '../../../core/networking/api_client.dart';
import '../../profile/screens/profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.api});
  final ApiClient api;
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  Map<String,dynamic>? _result;
  String? _error;

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _search() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      final data = await widget.api.search(q);
      if (mounted) setState(() => _result = data);
    } catch (e) { if (mounted) setState(() => _error = e.toString()); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final users = (_result?['users'] as List<dynamic>?) ?? const [];
    final posts = (_result?['posts'] as List<dynamic>?) ?? const [];
    final topics = (_result?['topics'] as List<dynamic>?) ?? const [];
    return Scaffold(
      appBar: AppBar(title: const Text('Ara', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              hintText: 'İnsan, düşünce veya #konu ara',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(onPressed: _search, icon: const Icon(Icons.arrow_forward_rounded)),
            ),
          ),
          if (_loading) const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator())),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 16), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
          if (!_loading && _result != null) ...[
            const SizedBox(height: 24),
            if (users.isNotEmpty) ...[
              const Text('İnsanlar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              ...users.map((raw) {
                final u = raw as Map<String,dynamic>;
                return Card(child: ListTile(
                  leading: CircleAvatar(child: Text(((u['display_name'] as String?)?.isNotEmpty ?? false) ? (u['display_name'] as String)[0].toUpperCase() : '?')),
                  title: Text(u['display_name'] as String? ?? ''),
                  subtitle: Text('@${u['username']}'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push<void>(context, MaterialPageRoute(builder: (_) => ProfileScreen(api: widget.api, username: u['username'] as String))),
                ));
              }),
            ],
            if (topics.isNotEmpty) ...[
              const SizedBox(height: 22),
              const Text('Konular', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: topics.map((raw) {
                final t = raw as Map<String,dynamic>;
                return Chip(label: Text('#${t['name']} · ${t['post_count']}'));
              }).toList()),
            ],
            if (posts.isNotEmpty) ...[
              const SizedBox(height: 22),
              const Text('Düşünceler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              ...posts.map((raw) {
                final p = raw as Map<String,dynamic>;
                return Card(child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p['content'] as String? ?? '', maxLines: 4, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, height: 1.4)),
                    const SizedBox(height: 10),
                    Text('${p['comment_count'] ?? 0} yorum · ${p['reveal_count'] ?? 0} merak', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                  ]),
                ));
              }),
            ],
            if (users.isEmpty && posts.isEmpty && topics.isEmpty)
              const Padding(padding: EdgeInsets.only(top: 70), child: Center(child: Text('Sonuç bulunamadı.'))),
          ],
        ],
      ),
    );
  }
}
