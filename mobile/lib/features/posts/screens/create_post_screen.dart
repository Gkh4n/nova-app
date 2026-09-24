import 'package:flutter/material.dart';

import '../../../core/networking/api_client.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({
    super.key,
    required this.api,
    this.dailyQuestionText,
  });

  final ApiClient api;
  final String? dailyQuestionText;

  bool get isDailyQuestion => dailyQuestionText != null;

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _controller = TextEditingController();
  bool _anonymous = false;
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    if (_controller.text.trim().isEmpty || _loading) return;
    setState(() => _loading = true);
    try {
      if (widget.isDailyQuestion) {
        await widget.api.answerDailyQuestion(
          _controller.text.trim(),
          anonymous: _anonymous,
        );
      } else {
        await widget.api.createPost(
          _controller.text.trim(),
          anonymous: _anonymous,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isDailyQuestion ? 'Bugünün sorusu' : 'Yeni düşünce'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (widget.dailyQuestionText != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: .35),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    widget.dailyQuestionText!,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, height: 1.3),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              TextField(
                controller: _controller,
                maxLength: 500,
                maxLines: 8,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: widget.isDailyQuestion
                      ? 'Senin cevabın ne?'
                      : 'Aklından ne geçiyor?  #konu kullanabilirsin',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tamamen anonim paylaş'),
                subtitle: const Text('Bu paylaşımda “Kim söyledi?” kullanılamaz.'),
                value: _anonymous,
                onChanged: (value) => setState(() => _anonymous = value),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _share,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(_loading ? 'Paylaşılıyor...' : 'PAYLAŞ'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
