import 'package:flutter/material.dart';

import '../../../core/networking/api_client.dart';
import '../../analytics/screens/analytics_screen.dart';
import '../../profile/models/profile_model.dart';
import '../../profile/screens/edit_profile_screen.dart';
import '../../saved/screens/saved_posts_screen.dart';
import 'change_password_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.api,
    required this.profile,
    required this.onLogout,
    required this.themeMode,
    required this.onThemeChanged,
  });

  final ApiClient api;
  final ProfileModel profile;
  final VoidCallback onLogout;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _editProfile() async {
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => EditProfileScreen(api: widget.api, profile: widget.profile)));
    if (changed == true && mounted) Navigator.pop(context, true);
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Çıkış yapılsın mı?'), content: const Text('Bu cihazdaki NOVA oturumun kapatılacak.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Çıkış Yap'))],
    ));
    if (confirmed != true) return;
    await widget.api.clearSession();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    widget.onLogout();
  }

  Future<void> _deleteAccount() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Hesabı kalıcı olarak sil'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Paylaşımların ve hesabın silinecek. Bu işlem geri alınamaz.'),
        const SizedBox(height: 16),
        TextField(controller: controller, decoration: const InputDecoration(labelText: 'Onaylamak için SİL yaz')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
        FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim().toUpperCase() == 'SİL'), child: const Text('Hesabı Sil')),
      ],
    ));
    if (confirmed != true) return;
    try {
      await widget.api.deleteAccount();
      await widget.api.clearSession();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      widget.onLogout();
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ayarlar', style: TextStyle(fontWeight: FontWeight.w900))),
    body: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 28), children: [
      const _SectionTitle('HESAP'),
      Card(child: Column(children: [
        ListTile(leading: const Icon(Icons.person_outline_rounded), title: const Text('Profili düzenle'), subtitle: const Text('Görünen ad ve biyografi'), trailing: const Icon(Icons.chevron_right_rounded), onTap: _editProfile),
        const Divider(height: 1),
        ListTile(leading: const Icon(Icons.key_rounded), title: const Text('Şifreyi değiştir'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => Navigator.push<void>(context, MaterialPageRoute(builder: (_) => ChangePasswordScreen(api: widget.api, onPasswordChanged: widget.onLogout)))),
        const Divider(height: 1),
        ListTile(leading: const Icon(Icons.bookmark_border_rounded), title: const Text('Kaydedilenler'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => Navigator.push<void>(context, MaterialPageRoute(builder: (_) => SavedPostsScreen(api: widget.api)))),
        const Divider(height: 1),
        ListTile(leading: const Icon(Icons.insights_outlined), title: const Text('İstatistiklerim'), subtitle: const Text('Takipçi değil, gerçek etkileşim'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => Navigator.push<void>(context, MaterialPageRoute(builder: (_) => AnalyticsScreen(api: widget.api)))),
      ])),
      const SizedBox(height: 22),
      const _SectionTitle('GÖRÜNÜM'),
      Card(child: SwitchListTile(
        secondary: Icon(widget.themeMode == ThemeMode.dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded),
        title: const Text('Karanlık tema'),
        value: widget.themeMode == ThemeMode.dark,
        onChanged: (v) => widget.onThemeChanged(v ? ThemeMode.dark : ThemeMode.light),
      )),
      const SizedBox(height: 22),
      const _SectionTitle('OTURUM'),
      Card(child: Column(children: [
        ListTile(leading: const Icon(Icons.logout_rounded), title: const Text('Çıkış yap'), subtitle: const Text('Bu cihazdaki hesabından çık'), onTap: _logout),
        const Divider(height: 1),
        ListTile(leading: Icon(Icons.delete_forever_rounded, color: Theme.of(context).colorScheme.error), title: Text('Hesabı sil', style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w800)), subtitle: const Text('Hesabını ve içeriklerini kalıcı olarak sil'), onTap: _deleteAccount),
      ])),
      const SizedBox(height: 26),
      Text('NOVA v1 Beta', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
    ]),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text); final String text;
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(8,8,8,10), child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.1)));
}
