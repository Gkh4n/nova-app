import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/networking/api_client.dart';
import '../../comments/screens/comments_screen.dart';
import '../../home/models/post_model.dart';
import '../../home/widgets/post_card.dart';
import '../../profile/screens/profile_screen.dart';
import '../../../shared/widgets/report_dialog.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key, required this.api});
  final ApiClient api;
  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  List<PostModel> _posts = [];
  bool _loading = true;
  String? _error;
  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final rows = await widget.api.getSavedPosts();
      if (mounted) setState(() { _posts = rows.map((e) => PostModel.fromJson(e as Map<String,dynamic>)).toList(); _error = null; });
    } catch (e) { if (mounted) setState(() => _error = e.toString()); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _reveal(PostModel p) async {
    final data = await widget.api.revealAuthor(p.id);
    if (!mounted) return;
    if (data['anonymous'] == true) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bu paylaşım tamamen anonim.'))); return; }
    final a = data['author'] as Map<String,dynamic>;
    await Navigator.push<void>(context, MaterialPageRoute(builder: (_) => ProfileScreen(api: widget.api, username: a['username'] as String)));
  }
  Future<void> _react(PostModel p, String kind) async { await widget.api.setReaction(p.id, kind); _load(); }
  Future<void> _comments(PostModel p) async { await Navigator.push<void>(context, MaterialPageRoute(builder: (_) => CommentsScreen(api: widget.api, postId: p.id))); _load(); }
  Future<void> _save(PostModel p) async { await widget.api.toggleSave(p.id); _load(); }
  Future<void> _share(PostModel p) async { final root = widget.api.baseUrl.replaceFirst(RegExp(r'/api/v1/?$'), ''); await Clipboard.setData(ClipboardData(text: 'NOVA düşüncesi:\n\n${p.content}\n\n$root/p/${p.id}')); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paylaşım bağlantısı panoya kopyalandı.'))); }
  Future<void> _report(PostModel p) async { final reason = await showReportReasonDialog(context); if (reason != null) { await widget.api.report(targetType: 'post', targetId: p.id, reason: reason); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rapor gönderildi.'))); } }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Kaydedilenler', style: TextStyle(fontWeight: FontWeight.w900))),
    body: _loading ? const Center(child: CircularProgressIndicator()) : _error != null ? Center(child: Text(_error!)) : RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 10, 16, 40), physics: const AlwaysScrollableScrollPhysics(), children: [
        if (_posts.isEmpty) const Padding(padding: EdgeInsets.only(top: 120), child: Center(child: Text('Henüz kaydettiğin düşünce yok.'))),
        ..._posts.map((p) => PostCard(post: p, onReveal: () => _reveal(p), onReaction: (k) => _react(p,k), onComments: () => _comments(p), onSave: () => _save(p), onShare: () => _share(p), onReport: p.isMine ? null : () => _report(p))),
      ]),
    ),
  );
}
