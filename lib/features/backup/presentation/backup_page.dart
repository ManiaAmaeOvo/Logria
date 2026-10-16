import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../core/document_files.dart';
import '../../../core/record_day.dart';
import '../../../l10n/app_localizations.dart';
import '../data/backup_repository.dart';
import '../data/log_export_repository.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key, required this.database});
  final AppDatabase database;
  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  bool _busy = false, _body = true;
  bool _confirming = false;
  DateTimeRange _range = DateTimeRange(
    start: RecordDay.today(),
    end: RecordDay.today(),
  );
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.saveFailed(error)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save(bool full) async {
    final text = full
        ? await BackupRepository(widget.database).create()
        : await LogExportRepository(widget.database)
              .export(_range.start, _range.end, includeBody: _body);
    final saved = await DocumentFiles.save(
      full
          ? 'logria-backup-${DateTime.now().millisecondsSinceEpoch}.json'
          : 'logria-log-${RecordDay.key(_range.start)}-${RecordDay.key(_range.end)}.json',
      text,
    );
    if (saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.fileSaved)),
      );
    }
  }

  Future<void> _restore() async {
    final text = await DocumentFiles.open();
    if (text == null || !mounted) return;
    final repository = BackupRepository(widget.database);
    final tables = repository.validate(text);
    final l = AppLocalizations.of(context)!;
    setState(() => _confirming = true);
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        scrollable: true,
        title: Text(l.backupRestore),
        content: Text(
          '${l.restoreWarning}${BackupRepository.hasOrphanArchive(tables) ? '\n\n${l.orphanArchiveHint}' : ''}\n\n${tables.entries.map((e) => '${e.key}: ${(e.value as List).length}').join('\n')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(l.backupRestore),
          ),
        ],
      ),
    );
    if (mounted) setState(() => _confirming = false);
    if (yes != true) return;
    await repository.restore(text);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.backupData)),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(l.backupHint),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _run(() => _save(true)),
              icon: const Icon(Icons.save_alt),
              label: Text(l.backupCreate),
            ),
            OutlinedButton.icon(
              onPressed: () => _run(_restore),
              icon: const Icon(Icons.restore),
              label: Text(l.backupRestore),
            ),
            const Divider(height: 40),
            ListTile(
              title: Text(
                '${RecordDay.key(_range.start)} → ${RecordDay.key(_range.end)}',
              ),
              trailing: const Icon(Icons.date_range),
              onTap: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: RecordDay.today(),
                  initialDateRange: _range,
                );
                if (range != null && mounted) setState(() => _range = range);
              },
            ),
            SwitchListTile(
              title: Text(l.includeBody),
              value: _body,
              onChanged: (value) => setState(() => _body = value),
            ),
            FilledButton.icon(
              onPressed: () => _run(() => _save(false)),
              icon: const Icon(Icons.download_outlined),
              label: Text(l.exportLogs),
            ),
            if (_busy && !_confirming)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
