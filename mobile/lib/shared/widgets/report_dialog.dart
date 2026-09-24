import 'package:flutter/material.dart';

Future<String?> showReportReasonDialog(BuildContext context) async {
  const reasons = ['Spam', 'Taciz / hakaret', 'Nefret söylemi', 'Cinsel içerik', 'Şiddet', 'Yanıltıcı içerik', 'Diğer'];
  String selected = reasons.first;
  return showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        title: const Text('Raporla'),
        content: DropdownButtonFormField<String>(
          initialValue: selected,
          items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
          onChanged: (v) => setLocal(() => selected = v ?? reasons.first),
          decoration: const InputDecoration(labelText: 'Neden'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, selected), child: const Text('Gönder')),
        ],
      ),
    ),
  );
}
