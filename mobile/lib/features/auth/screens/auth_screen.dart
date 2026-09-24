import 'package:flutter/material.dart';

import '../../../core/networking/api_client.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.api, required this.onAuthenticated});
  final ApiClient api;
  final VoidCallback onAuthenticated;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _login = TextEditingController();
  final _email = TextEditingController();
  final _displayName = TextEditingController();
  final _password = TextEditingController();
  bool _registerMode = false;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _login.dispose(); _email.dispose(); _displayName.dispose(); _password.dispose(); super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = _registerMode
          ? await widget.api.register(username: _login.text.trim(), email: _email.text.trim(), displayName: _displayName.text.trim(), password: _password.text)
          : await widget.api.login(login: _login.text.trim(), password: _password.text);
      await widget.api.setToken(result['access_token'] as String);
      widget.onAuthenticated();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgot() async {
    final controller = TextEditingController(text: _login.text.contains('@') ? _login.text : '');
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Şifremi unuttum'),
        content: TextField(controller: controller, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-posta')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('İstek Oluştur')),
        ],
      ),
    );
    if (email == null || email.isEmpty) return;
    try {
      final result = await widget.api.forgotPassword(email);
      if (!mounted) return;
      final token = result['dev_reset_token'] as String?;
      if (token == null) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Şifre sıfırlama'),
            content: const Text('İstek oluşturuldu. Bulut sürümünde e-posta sağlayıcısı bağlandığında sıfırlama kodu e-postaya gönderilecek.'),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tamam'))],
          ),
        );
      } else {
        await _resetWithToken(token);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }


  Future<void> _resetWithToken(String initialToken) async {
    final tokenController = TextEditingController(text: initialToken);
    final passwordController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni şifre belirle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: tokenController, decoration: const InputDecoration(labelText: 'Sıfırlama kodu')),
            const SizedBox(height: 12),
            TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Yeni şifre')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Şifreyi Değiştir')),
        ],
      ),
    );
    if (result != true) return;
    try {
      await widget.api.resetPassword(resetToken: tokenController.text.trim(), newPassword: passwordController.text);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Şifre değiştirildi. Yeni şifrenle giriş yapabilirsin.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF8B6CFF), Color(0xFF5D3FE8)]),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Center(child: Text('N', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white))),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text('NOVA', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 7)),
                    const SizedBox(height: 8),
                    Text('Önce düşünceyi keşfet, sonra insanı.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 38),
                    TextField(controller: _login, textInputAction: TextInputAction.next, decoration: InputDecoration(labelText: _registerMode ? 'Kullanıcı adı' : 'Kullanıcı adı veya e-posta', prefixIcon: const Icon(Icons.person_outline_rounded))),
                    if (_registerMode) ...[
                      const SizedBox(height: 12),
                      TextField(controller: _displayName, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Görünen ad', prefixIcon: Icon(Icons.badge_outlined))),
                      const SizedBox(height: 12),
                      TextField(controller: _email, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'E-posta', prefixIcon: Icon(Icons.mail_outline_rounded))),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: _password,
                      obscureText: _obscure,
                      onSubmitted: (_) => _loading ? null : _submit(),
                      decoration: InputDecoration(
                        labelText: 'Şifre',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined)),
                      ),
                    ),
                    if (!_registerMode)
                      Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _forgot, child: const Text('Şifremi unuttum'))),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ],
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Text(_loading ? '...' : (_registerMode ? 'NOVA’YA KATIL' : 'GİRİŞ YAP'))),
                    ),
                    TextButton(
                      onPressed: () => setState(() { _registerMode = !_registerMode; _error = null; }),
                      child: Text(_registerMode ? 'Zaten hesabın var mı? Giriş yap' : 'Hesabın yok mu? Kayıt ol'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
