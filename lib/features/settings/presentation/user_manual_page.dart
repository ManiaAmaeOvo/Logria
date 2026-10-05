import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';

/// Uses the same checked-in documents as GitHub. No browser or network needed.
class UserManualPage extends StatefulWidget {
  const UserManualPage({super.key});

  @override
  State<UserManualPage> createState() => _UserManualPageState();
}

class _UserManualPageState extends State<UserManualPage> {
  String? _language;
  Future<String>? _document;
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _load(String language) {
    _language = language;
    _document = rootBundle.loadString(
      language == 'zh' ? 'docs/USER_GUIDE.zh-CN.md' : 'docs/USER_GUIDE.md',
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_language == null) {
      _load(Localizations.localeOf(context).languageCode == 'zh' ? 'zh' : 'en');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.userManual)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'zh', label: Text('简体中文')),
                ButtonSegment(value: 'en', label: Text('English')),
              ],
              selected: {_language!},
              onSelectionChanged: (value) {
                if (_scroll.hasClients) _scroll.jumpTo(0);
                setState(() => _load(value.single));
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<String>(
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
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final sections = snapshot.data!.split(
                  RegExp(r'^## ', multiLine: true),
                );
                final introduction = sections.first.trim().split('\n\n');
                return ListView(
                  controller: _scroll,
                  key: ValueKey(_language),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                  children: [
                    SelectableText(
                      _plainText(introduction.first),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      _plainText(introduction.skip(1).join('\n\n')),
                    ),
                    const SizedBox(height: 12),
                    for (final section in sections.skip(1))
                      Card(
                        child: ExpansionTile(
                          key: ValueKey(
                            '$_language-${section.split('\n').first}',
                          ),
                          title: Text(section.split('\n').first),
                          expandedCrossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          childrenPadding: const EdgeInsets.all(16),
                          children: [
                            SelectableText(
                              _plainText(
                                section.substring(section.indexOf('\n') + 1),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _plainText(String markdown) => markdown
      .replaceAllMapped(RegExp(r'\[([^\]]+)\]\(([^)]+)\)'), (m) => m[1]!)
      .replaceAll(RegExp(r'^#{1,6} ', multiLine: true), '')
      .replaceAll('**', '')
      .replaceAll('`', '')
      .replaceAll(RegExp(r'(?<!\n)\n(?!\n|[-#])'), ' ')
      .trim();
}
