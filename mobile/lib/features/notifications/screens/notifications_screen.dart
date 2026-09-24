import 'package:flutter/material.dart';

import '../../../core/networking/api_client.dart';
import '../../profile/screens/profile_screen.dart';
import '../models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await widget.api.getNotifications();
      if (!mounted) return;
      setState(() {
        _items = rows
            .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await widget.api.markAllNotificationsRead();
      if (!mounted) return;
      setState(() {
        _items = _items.map((item) => item.copyWith(isRead: true)).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  IconData _icon(String kind) => switch (kind) {
        'reaction' => Icons.favorite_outline_rounded,
        'comment' => Icons.chat_bubble_outline_rounded,
        'reply' => Icons.reply_rounded,
        'reveal' => Icons.visibility_outlined,
        'follow' => Icons.person_add_alt_1_rounded,
        'save' => Icons.bookmark_border_rounded,
        _ => Icons.notifications_none_rounded,
      };

  Future<void> _open(int index) async {
    final item = _items[index];
    if (!item.isRead) {
      await widget.api.markNotificationRead(item.id);
      if (mounted) setState(() => _items[index] = item.copyWith(isRead: true));
    }
    if (item.actorUsername != null && mounted) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileScreen(
            api: widget.api,
            username: item.actorUsername!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _items.any((item) => !item.isRead);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bildirimler',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Tümünü oku'),
            ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _items.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 160),
                            Icon(Icons.notifications_none_rounded, size: 52),
                            SizedBox(height: 12),
                            Center(child: Text('Henüz bildirimin yok.')),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 110),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (_, index) {
                            final item = _items[index];
                            return Card(
                              child: ListTile(
                                onTap: () => _open(index),
                                leading: CircleAvatar(
                                  child: Icon(_icon(item.kind), size: 20),
                                ),
                                title: Text(
                                  item.message,
                                  style: TextStyle(
                                    fontWeight: item.isRead
                                        ? FontWeight.w500
                                        : FontWeight.w800,
                                  ),
                                ),
                                trailing: item.isRead
                                    ? null
                                    : Container(
                                        width: 9,
                                        height: 9,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
