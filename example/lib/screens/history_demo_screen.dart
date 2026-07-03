import 'package:db_lens/db_lens.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

/// Demo Change History: [DbLens.configureHistory], [DbLens.createHistoryController],
/// dan [DbLensHistorySheet.show]. Tracking berjalan lewat polling — tombol
/// di sini memicu insert/update/delete manual supaya perubahan terdeteksi.
class HistoryDemoScreen extends StatefulWidget {
  const HistoryDemoScreen({super.key, required this.database});

  /// Database yang sama dengan yang dipakai `DbLens.register('Example DB', db)`
  /// di main.dart — diteruskan langsung dari app, bukan diambil balik lewat
  /// db_lens (registry bukan bagian dari public API).
  final Database database;

  @override
  State<HistoryDemoScreen> createState() => _HistoryDemoScreenState();
}

class _HistoryDemoScreenState extends State<HistoryDemoScreen> {
  static const _sourceId = 'Example DB'; // DbLens.register('Example DB', db) -> id == name

  int _pollSeconds = 5;
  String? _lastAction;

  Future<void> _insertUser() async {
    final now = DateTime.now();
    final id = await widget.database.insert('users', {
      'name': 'New User ${now.millisecondsSinceEpoch}',
      'email': 'new${now.millisecondsSinceEpoch}@example.com',
      'age': 25,
      'is_premium': 0,
      'created_at': now.toIso8601String(),
    });
    setState(() => _lastAction = 'Inserted user #$id');
  }

  Future<void> _updateUser() async {
    await widget.database.update('users', {'age': 99}, where: 'id = ?', whereArgs: [1]);
    setState(() => _lastAction = 'Updated user #1 (age -> 99)');
  }

  Future<void> _deleteUser() async {
    final rows = await widget.database.query('users', orderBy: 'id DESC', limit: 1);
    if (rows.isEmpty) return;
    final id = rows.first['id'];
    await widget.database.delete('users', where: 'id = ?', whereArgs: [id]);
    setState(() => _lastAction = 'Deleted user #$id');
  }

  void _setPollInterval(int seconds) {
    setState(() => _pollSeconds = seconds);
    DbLens.configureHistory(pollInterval: Duration(seconds: seconds));
  }

  Future<void> _openHistory() async {
    final historyController = DbLens.createHistoryController();
    await historyController.loadFor(_sourceId);
    if (!mounted) {
      historyController.dispose();
      return;
    }
    await DbLensHistorySheet.show(
      context,
      controller: historyController,
      sourceName: _sourceId,
      theme: DbLensTheme(DbLensThemeData.fromMaterialTheme(Theme.of(context))),
    );
    historyController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change History')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'DbLens melacak insert/update/delete otomatis lewat polling. '
              'Lakukan aksi di bawah, tunggu sebentar (sesuai poll interval), '
              'lalu buka "View History".',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(onPressed: _insertUser, child: const Text('Insert user')),
                ElevatedButton(onPressed: _updateUser, child: const Text('Update user #1')),
                ElevatedButton(onPressed: _deleteUser, child: const Text('Delete last user')),
              ],
            ),
            const SizedBox(height: 16),
            Text('Poll interval: $_pollSeconds s'),
            Slider(
              value: _pollSeconds.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '$_pollSeconds s',
              onChanged: (v) => _setPollInterval(v.round()),
            ),
            const SizedBox(height: 16),
            if (_lastAction != null) Text('Last action: $_lastAction'),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _openHistory,
              icon: const Icon(Icons.history),
              label: const Text('View History'),
            ),
          ],
        ),
      ),
    );
  }
}
