import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../services/sheets_service.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  List<MapEntry<int, String>> _list = [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final list = await SheetsService.getUsersWithIndex();
      if (mounted) setState(() => _list = list);
    } catch (e) {
      _snack('Gagal memuat: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    final name = await _showDialog(title: 'Tambah Pengguna');
    if (name == null || name.isEmpty) return;
    _setBusy(true);
    try {
      await SheetsService.addUser(name);
      await _load();
      _snack('Pengguna "$name" ditambahkan ✓');
    } catch (e) {
      _snack('Gagal menambah: $e', isError: true);
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _edit(int rowIndex, String current) async {
    final name = await _showDialog(title: 'Edit Pengguna', initial: current);
    if (name == null || name.isEmpty || name == current) return;
    _setBusy(true);
    try {
      await SheetsService.updateUser(rowIndex, name);
      await _load();
      _snack('Pengguna diperbarui ✓');
    } catch (e) {
      _snack('Gagal mengubah: $e', isError: true);
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _delete(int rowIndex, String name) async {
    final ok = await _confirmDelete('pengguna "$name"');
    if (!ok) return;
    _setBusy(true);
    try {
      await SheetsService.deleteUser(rowIndex);
      await _load();
      _snack('Pengguna "$name" dihapus');
    } catch (e) {
      _snack('Gagal menghapus: $e', isError: true);
    } finally {
      _setBusy(false);
    }
  }

  void _setBusy(bool v) {
    if (mounted) setState(() => _busy = v);
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.expenseColor : AppTheme.incomeColor,
    ));
  }

  Future<String?> _showDialog({required String title, String? initial}) async {
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Nama pengguna...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(String label) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus?'),
        content: Text(
            'Yakin mau hapus $label?\nData yang dihapus tidak bisa dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.expenseColor),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Pengguna'),
            leading: const BackButton(),
            actions: [
              IconButton(
                tooltip: 'Tambah pengguna',
                icon: const Icon(Icons.add_rounded),
                onPressed: _busy ? null : _add,
              ),
            ],
          ),
          body: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary))
              : _list.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('👤',
                              style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          const Text(
                            'Belum ada pengguna',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 15),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _add,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Tambah Pengguna'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: AppTheme.primary,
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _list.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final entry = _list[index];
                          return _CrudItem(
                            label: entry.value,
                            onEdit: _busy
                                ? null
                                : () => _edit(entry.key, entry.value),
                            onDelete: _busy
                                ? null
                                : () => _delete(entry.key, entry.value),
                          );
                        },
                      ),
                    ),
          floatingActionButton: _list.isNotEmpty
              ? FloatingActionButton(
                  onPressed: _busy ? null : _add,
                  tooltip: 'Tambah pengguna',
                  child: const Icon(Icons.add_rounded),
                )
              : null,
        ),
        if (_busy)
          const ModalBarrier(dismissible: false, color: Color(0x44000000)),
        if (_busy)
          const Center(
              child: CircularProgressIndicator(color: AppTheme.primary)),
      ],
    );
  }
}

class _CrudItem extends StatelessWidget {
  final String label;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _CrudItem({required this.label, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.person_rounded, size: 20, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 18),
            color: AppTheme.secondary,
            tooltip: 'Edit',
            onPressed: onEdit,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded, size: 18),
            color: AppTheme.expenseColor,
            tooltip: 'Hapus',
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
