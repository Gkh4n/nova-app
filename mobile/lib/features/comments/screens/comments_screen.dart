import 'package:flutter/material.dart';

import '../../../core/networking/api_client.dart';
import '../models/comment_model.dart';

class CommentsScreen extends StatefulWidget {
  const CommentsScreen({super.key, required this.api, required this.postId});

  final ApiClient api;
  final int postId;

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<CommentModel> _comments = const [];
  bool _loading = true;
  bool _sending = false;
  int? _replyToId;
  String? _replyToUsername;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.api.getComments(widget.postId);
      if (!mounted) return;
      setState(() {
        _comments = data
            .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.api.createComment(
        widget.postId,
        text,
        parentId: _replyToId,
      );
      _controller.clear();
      _cancelReply();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _toggleLike(CommentModel comment) async {
    try {
      await widget.api.toggleCommentLike(comment.id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _reply(CommentModel comment) {
    if (comment.parentId != null) return;
    setState(() {
      _replyToId = comment.id;
      _replyToUsername = comment.username;
    });
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    if (!mounted) return;
    setState(() {
      _replyToId = null;
      _replyToUsername = null;
    });
  }

  List<CommentModel> _repliesFor(int parentId) =>
      _comments.where((c) => c.parentId == parentId).toList();

  Widget _commentTile(CommentModel comment, {bool reply = false}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(reply ? 48 : 16, 8, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: reply ? 16 : 19,
            child: Text(
              comment.displayName.isEmpty ? '?' : comment.displayName[0].toUpperCase(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@${comment.username}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(comment.content, style: const TextStyle(height: 1.35)),
                const SizedBox(height: 7),
                Row(
                  children: [
                    InkWell(
                      onTap: () => _toggleLike(comment),
                      child: Text(
                        '${comment.likedByMe ? '♥' : '♡'} ${comment.likeCount}',
                        style: TextStyle(
                          color: comment.likedByMe
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white60,
                        ),
                      ),
                    ),
                    if (!reply) ...[
                      const SizedBox(width: 18),
                      InkWell(
                        onTap: () => _reply(comment),
                        child: const Text('Yanıtla', style: TextStyle(color: Colors.white60)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roots = _comments.where((c) => c.parentId == null).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Yorumlar')),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(_error!),
                      ))
                    : roots.isEmpty
                        ? const Center(child: Text('Henüz yorum yok. İlk yorumu sen yaz.'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: roots.length,
                              itemBuilder: (context, index) {
                                final root = roots[index];
                                final replies = _repliesFor(root.id);
                                return Column(
                                  children: [
                                    _commentTile(root),
                                    ...replies.map((r) => _commentTile(r, reply: true)),
                                    const Divider(height: 1),
                                  ],
                                );
                              },
                            ),
                          ),
          ),
          if (_replyToId != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  Expanded(child: Text('@$_replyToUsername kullanıcısına yanıt veriyorsun')),
                  IconButton(onPressed: _cancelReply, icon: const Icon(Icons.close_rounded)),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLength: 500,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Bir şey söyle…',
                        counterText: '',
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_upward_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
