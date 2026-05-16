import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/sheets_service.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _sheetIdCtrl = TextEditingController();
  bool _saving = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentId();
  }

  @override
  void dispose() {
    _sheetIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentId() async {
    final id = await StorageService.getSheetId();
    setState(() {
      _sheetIdCtrl.text = id;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final id = _sheetIdCtrl.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sheet ID tidak boleh kosong')),
      );
      return;
    }

    setState(() => _saving = true);
    await StorageService.setSheetId(id);
    // Invalidate cached auth so next request uses fresh sheet ID
    SheetsService.invalidateCache();
    setState(() => _saving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sheet ID berhasil disimpan ✓'),
          backgroundColor: AppTheme.incomeColor,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        leading: const BackButton(),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.chipBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: AppTheme.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Ubah Sheet ID di sini jika kamu ingin menggunakan Google Sheet yang berbeda. '
                            'Perubahan langsung berlaku setelah disimpan tanpa perlu update aplikasi.',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Google Sheet ID',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _sheetIdCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Masukkan Spreadsheet ID',
                      prefixIcon:
                          Icon(Icons.table_chart_rounded, color: AppTheme.primary),
                    ),
                    style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Contoh: 143As1yj2VM1r5zAbFHphzulltAchpySKCmPINWKV_f0',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(_saving ? 'Menyimpan...' : 'Simpan'),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // App info
                  Center(
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/icon-remove-background.png',
                          width: 56,
                          height: 56,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'OpiOpi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Versi 1.0.0',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        const Text(
                          'Aplikasi Keuangan Keluarga',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
