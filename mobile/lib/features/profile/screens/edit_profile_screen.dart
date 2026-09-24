import 'package:flutter/material.dart';

import '../../../core/networking/api_client.dart';
import '../models/profile_model.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.api,
    required this.profile,
  });

  final ApiClient api;
  final ProfileModel profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _displayName;
  late final TextEditingController _bio;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _displayName = TextEditingController(text: widget.profile.displayName);
    _bio = TextEditingController(text: widget.profile.bio);
  }

  @override
  void dispose() {
    _displayName.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _displayName.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Görünen ad boş olamaz.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.updateMyProfile(
        displayName: name,
        bio: _bio.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profili Düzenle', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Kaydet'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 44,
              child: Text(
                _displayName.text.isEmpty ? '?' : _displayName.text[0].toUpperCase(),
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _displayName,
            maxLength: 80,
            decoration: const InputDecoration(
              labelText: 'Görünen ad',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bio,
            maxLength: 160,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Biyografi',
              hintText: 'Kendin hakkında kısa bir şey yaz...',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.notes_rounded),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Kaydediliyor...' : 'Değişiklikleri Kaydet'),
          ),
        ],
      ),
    );
  }
}
