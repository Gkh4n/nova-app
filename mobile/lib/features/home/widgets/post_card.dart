import 'package:flutter/material.dart';
import '../models/post_model.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.onReveal,
    required this.onReaction,
    required this.onComments,
    required this.onSave,
    required this.onShare,
    this.onDelete,
    this.onReport,
  });

  final PostModel post;
  final VoidCallback onReveal;
  final ValueChanged<String> onReaction;
  final VoidCallback onComments;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final title = post.isMine ? (post.isAnonymous ? 'Senin anonim düşüncen' : 'Senin düşüncen') : (post.isAnonymous ? 'Anonim NOVA' : 'NOVA Kullanıcısı');
    final subtitle = post.isMine ? 'Bu paylaşım sana ait' : (post.isAnonymous ? 'Kimliği hiçbir zaman açılmaz' : 'Önce düşünce, sonra insan');
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(radius: 19, backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: Icon(post.isAnonymous ? Icons.visibility_off_rounded : Icons.blur_on_rounded, size: 19)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), Text(subtitle, style: TextStyle(color: muted, fontSize: 11))])),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') onDelete?.call();
                if (value == 'report') onReport?.call();
                if (value == 'share') onShare();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'share', child: ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.ios_share_rounded), title: Text('Paylaş'))),
                if (post.isMine && onDelete != null) const PopupMenuItem(value: 'delete', child: ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.delete_outline_rounded), title: Text('Sil'))),
                if (!post.isMine && onReport != null) const PopupMenuItem(value: 'report', child: ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.flag_outlined), title: Text('Raporla'))),
              ],
            ),
          ]),
          if (post.dailyQuestionText != null) ...[
            const SizedBox(height: 14),
            Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: .10), borderRadius: BorderRadius.circular(12)), child: Text('Bugünün sorusu · ${post.dailyQuestionText}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis)),
          ],
          const SizedBox(height: 18),
          Text(post.content, style: const TextStyle(fontSize: 19, height: 1.46, fontWeight: FontWeight.w500)),
          if (post.topics.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(spacing: 7, runSpacing: 7, children: post.topics.map((t) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: .6), borderRadius: BorderRadius.circular(99)), child: Text('#$t', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)))).toList()),
          ],
          const SizedBox(height: 18),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _ReactionChip(icon: '♥', label: 'Hissettim', count: post.reactionCounts.felt, selected: post.viewerReaction == 'felt', onTap: () => onReaction('felt')),
            _ReactionChip(icon: '🧠', label: 'Düşündürdü', count: post.reactionCounts.thought, selected: post.viewerReaction == 'thought', onTap: () => onReaction('thought')),
            _ReactionChip(icon: '😄', label: 'Güldürdü', count: post.reactionCounts.funny, selected: post.viewerReaction == 'funny', onTap: () => onReaction('funny')),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            TextButton.icon(onPressed: onComments, icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18), label: Text('${post.commentCount} yorum')),
            IconButton(tooltip: post.savedByMe ? 'Kaydedildi' : 'Kaydet', onPressed: onSave, icon: Icon(post.savedByMe ? Icons.bookmark_rounded : Icons.bookmark_border_rounded)),
            if (post.saveCount > 0) Text('${post.saveCount}', style: TextStyle(color: muted, fontSize: 11)),
            const Spacer(),
            if (post.canReveal)
              FilledButton.tonalIcon(onPressed: onReveal, icon: const Icon(Icons.visibility_outlined, size: 18), label: const Text('Kim söyledi?'))
            else if (post.isMine)
              Text('Senin paylaşımın', style: TextStyle(color: muted, fontSize: 12))
            else
              Text('Tamamen anonim', style: TextStyle(color: muted, fontSize: 12)),
          ]),
          if (post.revealCount > 0) Padding(padding: const EdgeInsets.only(top: 2), child: Text('${post.revealCount} kişi yazarı merak etti', style: TextStyle(color: muted, fontSize: 11))),
        ]),
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({required this.icon, required this.label, required this.count, required this.selected, required this.onTap});
  final String icon; final String label; final int count; final bool selected; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ActionChip(backgroundColor: selected ? Theme.of(context).colorScheme.primaryContainer : null, side: selected ? BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: .55)) : null, label: Text('$icon  $label  $count', style: TextStyle(fontWeight: selected ? FontWeight.w800 : FontWeight.w500)), onPressed: onTap);
}
