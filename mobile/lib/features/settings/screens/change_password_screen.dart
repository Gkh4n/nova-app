import 'package:flutter/material.dart';
import '../../../core/networking/api_client.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, required this.api, required this.onPasswordChanged});
  final ApiClient api;
  final VoidCallback onPasswordChanged;
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _again = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() { _current.dispose(); _next.dispose(); _again.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_next.text != _again.text) { setState(() => _error = 'Yeni şifreler eşleşmiyor.'); return; }
    if (_next.text.length < 8) { setState(() => _error = 'Yeni şifre en az 8 karakter olmalı.'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      await widget.api.changePassword(currentPassword: _current.text, newPassword: _next.text);
      await widget.api.clearSession();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      widget.onPasswordChanged();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Şifreyi Değiştir', style: TextStyle(fontWeight: FontWeight.w900))),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      TextField(controller: _current, obscureText: true, decoration: const InputDecoration(labelText: 'Mevcut şifre')),
      const SizedBox(height: 12),
      TextField(controller: _next, obscureText: true, decoration: const InputDecoration(labelText: 'Yeni şifre')),
      const SizedBox(height: 12),
      TextField(controller: _again, obscureText: true, decoration: const InputDecoration(labelText: 'Yeni şifre tekrar')),
      if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))],
      const SizedBox(height: 20),
      FilledButton(onPressed: _loading ? null : _save, child: Text(_loading ? 'Kaydediliyor...' : 'Şifreyi Değiştir')),
      const SizedBox(height: 10),
      Text('Güvenlik nedeniyle şifre değişince tüm mevcut NOVA oturumları kapatılır.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
    ]),
  );
}
