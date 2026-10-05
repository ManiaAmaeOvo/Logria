import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';

/// Bundled release history follows the application's resolved locale.
class ChangelogPage extends StatefulWidget {
  const ChangelogPage({super.key});

  @override
  State<ChangelogPage> createState() => _ChangelogPageState();
}

class _ChangelogPageState extends State<ChangelogPage> {
  String? _language;
  Future<String>? _document;
  final _scroll = ScrollController(keepScrollOffset: false);

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _load(String language) {
    _language = language;
    _document = rootBundle.loadString(
      language == 'zh' ? 'CHANGELOG.zh-CN.md' : 'CHANGELOG.md',
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = Localizations.localeOf(context).languageCode == 'zh'
        ? 'zh'
        : 'en';
    if (_language != language) _load(language);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.changelog)),
      body: FutureBuilder<String>(
        future: _document,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: TextButton(
                onPressed: () => setState(() => _load(_language!)),
                child: Text(l.retry),
              ),
            );
          }
          if (!snapshot.hasData ||
              snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final sections = snapshot.data!.split(
            RegExp(r'^## ', multiLine: true),
          );
          return ListView(
            controller: _scroll,
            key: ValueKey(_language),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              Text(l.changelogHint),
              const SizedBox(height: 12),
              for (var i = 1; i < sections.length; i++)
                Card(
                  child: ExpansionTile(
                    key: ValueKey(
                      '$_language-${sections[i].split('\n').first}',
                    ),
                    initiallyExpanded: i == 1,
                    title: Text(sections[i].split('\n').first),
                    expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                    childrenPadding: const EdgeInsets.all(16),
                    children: [
                      SelectableText(
                        sections[i]
                            .substring(sections[i].indexOf('\n') + 1)
                            .replaceAll(
                              RegExp(r'^#{1,6} ', multiLine: true),
                              '',
                            )
                            .replaceAll('`', '')
                            .replaceAll('**', '')
                            .replaceAll(RegExp(r'(?<!\n)\n(?!\n|[-#])'), ' ')
                            .trim(),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
