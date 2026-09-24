import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  final _items = const [
    (Icons.equalizer_rounded, 'Herkes aynı yerden başlar.', 'Takipçi sayın seni öne geçirmez. Her düşünce önce kendi gücüyle test edilir.'),
    (Icons.visibility_outlined, 'Önce düşünceyi gör.', 'Bir paylaşımın sahibini, içeriği değerlendirdikten sonra “Kim söyledi?” ile keşfet.'),
    (Icons.auto_awesome_rounded, 'Yeni seslere yer var.', 'NOVA, yeni kullanıcıların içeriklerini de gerçek insanlara göstermeyi özellikle dener.'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _items.length,
                  onPageChanged: (v) => setState(() => _page = v),
                  itemBuilder: (_, i) {
                    final item = _items[i];
                    return Padding(
                      padding: const EdgeInsets.all(34),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: Icon(item.$1, size: 46),
                          ),
                          const SizedBox(height: 32),
                          Text(item.$2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 14),
                          Text(item.$3, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, height: 1.5, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_items.length, (i) => Container(
                        width: i == _page ? 26 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(color: i == _page ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(99)),
                      )),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _page == _items.length - 1
                            ? widget.onDone
                            : () => _controller.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(_page == _items.length - 1 ? 'NOVA’YA GİR' : 'DEVAM'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
