import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../backup/backup_parser.dart';
import '../journal/journal_repository.dart';
import '../theme.dart';
import 'liftbig_sheet.dart';

Future<String?> showImportSheet(
  BuildContext context,
  JournalRepository journal,
) {
  return showLiftBigSheet<String>(
    context,
    builder: (context) => _ImportSheet(journal: journal),
  );
}

class _ImportSheet extends StatefulWidget {
  const _ImportSheet({required this.journal});

  final JournalRepository journal;

  @override
  State<_ImportSheet> createState() => _ImportSheetState();
}

const savedBackupFileName = 'liftbig-backup.json';

const missingSavedBackupMessage =
    'Save the backup as liftbig-backup.json, then the file will be picked up after the next copy into the app.';

class MissingSavedBackup implements Exception {
  const MissingSavedBackup(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Reads `liftbig-backup.json` from an application documents directory.
Future<String> readSavedBackupFile(Directory documents) async {
  final file = File('${documents.path}/$savedBackupFileName');
  if (!await file.exists()) {
    throw const MissingSavedBackup(missingSavedBackupMessage);
  }
  return _decodeBackupBytes(await file.readAsBytes());
}

/// iOS keeps the app container's Documents folder next to its temporary folder.
Directory applicationDocumentsDirectory() {
  final temporary = Directory.systemTemp.resolveSymbolicLinksSync();
  return Directory('${Directory(temporary).parent.path}/Documents');
}

class _ImportSheetState extends State<_ImportSheet> {
  String? _error;
  bool _busy = false;

  Future<void> _importSavedFile() async {
    if (_busy) return;
    try {
      final text = await readSavedBackupFile(applicationDocumentsDirectory());
      if (!mounted) return;
      await _importText(text);
    } on MissingSavedBackup catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } on FormatException {
      if (!mounted) return;
      setState(() => _error = 'That file is not text.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not read liftbig-backup.json.');
    }
  }

  Future<void> _chooseFile() async {
    if (_busy) return;
    final PlatformFile? file;
    try {
      file = await FilePicker.pickFile(
        dialogTitle: 'LiftBig backup',
        type: FileType.custom,
        allowedExtensions: const ['json', 'txt'],
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not open the file picker.');
      return;
    }
    if (file == null || !mounted) return;

    final String text;
    try {
      text = _decodeBackupBytes(await file.readAsBytes());
    } on FormatException {
      if (!mounted) return;
      setState(() => _error = 'That file is not text.');
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not read that file.');
      return;
    }
    if (!mounted) return;
    await _importText(text);
  }

  /// Clipboard read is the first await so it stays inside the tap, matching
  /// the website import sheet.
  Future<void> _pasteBackup() async {
    if (_busy) return;
    final ClipboardData? data;
    try {
      data = await Clipboard.getData(Clipboard.kTextPlain);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error =
            'Could not read the clipboard. Choose the backup file instead.',
      );
      return;
    }
    if (!mounted) return;
    final text = data?.text ?? '';
    if (text.trim().isEmpty) {
      setState(() => _error = 'Copy the backup first, then tap Paste backup.');
      return;
    }
    await _importText(text);
  }

  Future<void> _importText(String raw) async {
    final text = raw.trim();
    if (text.isEmpty) {
      setState(() => _error = 'That backup is empty.');
      return;
    }
    if (_busy) return;
    _busy = true;
    setState(() => _error = null);
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    var closed = false;
    try {
      final parsed = parseLiftBigBackup(text);
      final count = await widget.journal.importBackup(parsed);
      if (!mounted) return;
      final days = count == 1 ? '1 day' : '$count days';
      final skipped = parsed.skippedDays == 0
          ? ''
          : ' Skipped ${parsed.skippedDays} unrecognized '
                '${parsed.skippedDays == 1 ? 'day' : 'days'}.';
      closed = true;
      Navigator.of(context).pop('Imported $days.$skipped');
    } on BackupParseException catch (error) {
      setState(() => _error = error.message);
    } catch (error) {
      setState(() => _error = 'Could not import: $error');
    } finally {
      _busy = false;
      if (mounted && !closed) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final safe = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + keyboard + safe),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Import backup',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
             Text(
              'Tap Import liftbig-backup.json. That reads the backup already copied into this app. Dates in the file replace those days. Other days stay.',
              style: TextStyle(color: context.liftBig.muted),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _importSavedFile,
              icon: const Icon(Icons.download),
              label: const Text('Import liftbig-backup.json'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : _chooseFile,
              icon: const Icon(Icons.folder_open),
              label: const Text('Choose backup file'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : _pasteBackup,
              icon: const Icon(Icons.content_paste),
              label: const Text('Paste backup'),
            ),
            if (_busy) ...[
              const SizedBox(height: 12),
               Text(
                'Importing…',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.liftBig.muted),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style:  TextStyle(color: context.liftBig.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _decodeBackupBytes(List<int> bytes) {
  var text = utf8.decode(bytes);
  if (text.startsWith('\uFEFF')) {
    text = text.substring(1);
  }
  return text;
}
