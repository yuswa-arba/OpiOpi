import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../services/sheets_service.dart';
import '../../services/storage_service.dart';

class ConfigSheetScreen extends StatefulWidget {
  const ConfigSheetScreen({super.key});

  @override
  State<ConfigSheetScreen> createState() => _ConfigSheetScreenState();
}

class _ConfigSheetScreenState extends State<ConfigSheetScreen> {
  final _ctrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final id = await StorageService.getConfigSheetId();
    if (mounted) setState(() => _ctrl.text = id);
  }

  Future<void> _save() async {
    final id = _ctrl.text.trim();
    if (id.isEmpty) {
      _snack('ID tidak boleh kosong', isError: true);
      return;
    }
    setState(() => _saving = true);
    await StorageService.setConfigSheetId(id);
    SheetsService.invalidateCache();
    setState(() => _saving = false);
    if (mounted) {
      _snack('ID berhasil disimpan ✓');
      Navigator.of(context).pop();
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.expenseColor : AppTheme.incomeColor,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfigurasi'),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Konfigurasi berisi data pengguna, kategori, dan daftar buku keuangan. '
                      'Ubah ID ini jika ingin menggunakan spreadsheet konfigurasi yang berbeda.',
                      style: TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Spreadsheet ID',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,
              decoration: const InputDecoration(
                hintText: 'Masukkan Spreadsheet ID',
                prefixIcon: Icon(Icons.link_rounded, color: AppTheme.primary),
              ),
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 8),
            Text(
              'Default: ${StorageService.defaultConfigSheetId}',
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_saving ? 'Menyimpan...' : 'Simpan'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
