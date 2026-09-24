import 'package:flutter/material.dart';

import '../../../core/networking/api_client.dart';
import '../../comments/screens/comments_screen.dart';
import '../../profile/models/profile_model.dart';

class ProfilePostDetailScreen extends StatelessWidget {
  const ProfilePostDetailScreen({
    super.key,
    required this.api,
    required this.post,
    required this.isMine,
  });

  final ApiClient api;
  final ProfilePostModel post;
  final bool isMine;

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Paylaşım silinsin mi?'),
        content: const Text('Bu işlem geri alınamaz. Paylaşım ve bağlı etkileşimler silinecek.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Vazgeç')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await api.deletePost(post.id);
      if (context.mounted) Navigator.pop(context, true);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Düşünce', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          if (isMine)
            IconButton(
              tooltip: 'Paylaşımı sil',
              onPressed: () => _delete(context),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.isAnonymous)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Anonim paylaşım', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                    ),
                  if (post.isAnonymous) const SizedBox(height: 14),
                  Text(post.content, style: const TextStyle(fontSize: 20, height: 1.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Text('♥ ${post.reactionCount}'),
                      const SizedBox(width: 18),
                      Text('💬 ${post.commentCount}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => CommentsScreen(api: api, postId: post.id)),
            ),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: const Text('Yorumları Aç'),
          ),
          if (isMine) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _delete(context),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Paylaşımı Sil'),
            ),
          ],
        ],
      ),
    );
  }
}
