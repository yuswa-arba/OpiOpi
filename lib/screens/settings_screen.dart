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
  // ── Sheet ID ─────────────────────────────────────────────────────────────────
  final _sheetIdCtrl = TextEditingController();
  bool _savingSheetId = false;

  // ── Kategori ─────────────────────────────────────────────────────────────────
  List<MapEntry<int, String>> _kategoriList = [];
  bool _loadingKategori = true;

  // ── Users ─────────────────────────────────────────────────────────────────────
  List<MapEntry<int, String>> _userList = [];
  bool _loadingUsers = true;

  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _sheetIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final id = await StorageService.getSheetId();
    if (mounted) setState(() => _sheetIdCtrl.text = id);
    await Future.wait([_loadKategori(), _loadUsers()]);
    if (mounted) setState(() => _initializing = false);
  }

  // ── Sheet ID ─────────────────────────────────────────────────────────────────

  Future<void> _saveSheetId() async {
    final id = _sheetIdCtrl.text.trim();
    if (id.isEmpty) {
      _snack('Sheet ID tidak boleh kosong', isError: true);
      return;
    }
    setState(() => _savingSheetId = true);
    await StorageService.setSheetId(id);
    SheetsService.invalidateCache();
    setState(() => _savingSheetId = false);
    if (mounted) {
      _snack('Sheet ID berhasil disimpan ✓');
      Navigator.of(context).pop();
    }
  }

  // ── Kategori ─────────────────────────────────────────────────────────────────

  Future<void> _loadKategori() async {
    if (mounted) setState(() => _loadingKategori = true);
    try {
      final list = await SheetsService.getKategoriWithIndex();
      if (mounted) setState(() => _kategoriList = list);
    } catch (e) {
      if (mounted) _snack('Gagal memuat kategori: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loadingKategori = false);
    }
  }

  Future<void> _addKategori() async {
    final name = await _showNameDialog(title: 'Tambah Kategori');
    if (name == null || name.isEmpty) return;
    _setBusy(true);
    try {
      await SheetsService.addKategori(name);
      await _loadKategori();
      _snack('Kategori "$name" ditambahkan ✓');
    } catch (e) {
      _snack('Gagal menambah kategori: $e', isError: true);
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _editKategori(int rowIndex, String current) async {
    final name = await _showNameDialog(title: 'Edit Kategori', initial: current);
    if (name == null || name.isEmpty || name == current) return;
    _setBusy(true);
    try {
      await SheetsService.updateKategori(rowIndex, name);
      await _loadKategori();
      _snack('Kategori diperbarui ✓');
    } catch (e) {
      _snack('Gagal mengubah kategori: $e', isError: true);
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _deleteKategori(int rowIndex, String name) async {
    final ok = await _confirmDelete('kategori "$name"');
    if (!ok) return;
    _setBusy(true);
    try {
      await SheetsService.deleteKategori(rowIndex);
      await _loadKategori();
      _snack('Kategori "$name" dihapus');
    } catch (e) {
      _snack('Gagal menghapus kategori: $e', isError: true);
    } finally {
      _setBusy(false);
    }
  }

  // ── Users ─────────────────────────────────────────────────────────────────────

  Future<void> _loadUsers() async {
    if (mounted) setState(() => _loadingUsers = true);
    try {
      final list = await SheetsService.getUsersWithIndex();
      if (mounted) setState(() => _userList = list);
    } catch (e) {
      if (mounted) _snack('Gagal memuat pengguna: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  Future<void> _addUser() async {
    final name = await _showNameDialog(title: 'Tambah Pengguna');
    if (name == null || name.isEmpty) return;
    _setBusy(true);
    try {
      await SheetsService.addUser(name);
      await _loadUsers();
      _snack('Pengguna "$name" ditambahkan ✓');
    } catch (e) {
      _snack('Gagal menambah pengguna: $e', isError: true);
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _editUser(int rowIndex, String current) async {
    final name = await _showNameDialog(title: 'Edit Nama', initial: current);
    if (name == null || name.isEmpty || name == current) return;
    _setBusy(true);
    try {
      await SheetsService.updateUser(rowIndex, name);
      await _loadUsers();
      _snack('Nama pengguna diperbarui ✓');
    } catch (e) {
      _snack('Gagal mengubah nama: $e', isError: true);
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _deleteUser(int rowIndex, String name) async {
    final ok = await _confirmDelete('pengguna "$name"');
    if (!ok) return;
    _setBusy(true);
    try {
      await SheetsService.deleteUser(rowIndex);
      await _loadUsers();
      _snack('Pengguna "$name" dihapus');
    } catch (e) {
      _snack('Gagal menghapus pengguna: $e', isError: true);
    } finally {
      _setBusy(false);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  bool _busy = false;
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

  Future<String?> _showNameDialog({
    required String title,
    String? initial,
  }) async {
    final ctrl = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Nama...'),
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
    // Do NOT call ctrl.dispose() here — the dialog's TextField is still in
    // teardown when showDialog() returns, and disposing the controller at this
    // point triggers '_dependents.isEmpty': is not true assertion.
    // The controller is short-lived and will be GC'd automatically.
    return result;
  }

  Future<bool> _confirmDelete(String label) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus?'),
        content: Text('Yakin mau hapus $label?\nData yang dihapus tidak bisa dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.expenseColor),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Pengaturan'),
            leading: const BackButton(),
          ),
          body: _initializing
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSheetIdSection(),
                      const SizedBox(height: 28),
                      _buildUsersSection(),
                      const SizedBox(height: 28),
                      _buildKategoriSection(),
                      const SizedBox(height: 40),
                      _buildAppInfo(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
        ),
        // Global busy overlay
        if (_busy)
          const ModalBarrier(dismissible: false, color: Color(0x44000000)),
        if (_busy)
          const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          ),
      ],
    );
  }

  // ── Section: Sheet ID ────────────────────────────────────────────────────────

  Widget _buildSheetIdSection() {
    return _Section(
      title: 'Google Sheet',
      icon: Icons.table_chart_rounded,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.chipBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ubah Sheet ID jika ingin menggunakan spreadsheet yang berbeda. '
                  'Perubahan langsung berlaku tanpa update aplikasi.',
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary, height: 1.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _sheetIdCtrl,
          decoration: const InputDecoration(
            hintText: 'Masukkan Spreadsheet ID',
            prefixIcon: Icon(Icons.link_rounded, color: AppTheme.primary),
          ),
          style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _savingSheetId ? null : _saveSheetId,
            icon: _savingSheetId
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(_savingSheetId ? 'Menyimpan...' : 'Simpan Sheet ID'),
          ),
        ),
      ],
    );
  }

  // ── Section: Kategori ─────────────────────────────────────────────────────────

  Widget _buildKategoriSection() {
    return _Section(
      title: 'Kategori',
      icon: Icons.category_rounded,
      trailing: IconButton(
        tooltip: 'Tambah kategori',
        icon: const Icon(Icons.add_circle_rounded, color: AppTheme.primary),
        onPressed: _busy ? null : _addKategori,
      ),
      children: [
        if (_loadingKategori)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(color: AppTheme.primary),
          ))
        else if (_kategoriList.isEmpty)
          _emptyHint('Belum ada kategori. Tap + untuk menambah.')
        else
          ..._kategoriList.map((entry) => _CrudItem(
                label: entry.value,
                onEdit: _busy ? null : () => _editKategori(entry.key, entry.value),
                onDelete: _busy ? null : () => _deleteKategori(entry.key, entry.value),
              )),
        if (!_loadingKategori)
          _AddButton(
            label: 'Tambah Kategori',
            onTap: _busy ? null : _addKategori,
          ),
      ],
    );
  }

  // ── Section: Users ────────────────────────────────────────────────────────────

  Widget _buildUsersSection() {
    return _Section(
      title: 'Pengguna',
      icon: Icons.group_rounded,
      trailing: IconButton(
        tooltip: 'Tambah pengguna',
        icon: const Icon(Icons.add_circle_rounded, color: AppTheme.primary),
        onPressed: _busy ? null : _addUser,
      ),
      children: [
        if (_loadingUsers)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(color: AppTheme.primary),
          ))
        else if (_userList.isEmpty)
          _emptyHint('Belum ada pengguna. Tap + untuk menambah.')
        else
          ..._userList.map((entry) => _CrudItem(
                label: entry.value,
                onEdit: _busy ? null : () => _editUser(entry.key, entry.value),
                onDelete: _busy ? null : () => _deleteUser(entry.key, entry.value),
              )),
        if (!_loadingUsers)
          _AddButton(
            label: 'Tambah Pengguna',
            onTap: _busy ? null : _addUser,
          ),
      ],
    );
  }

  Widget _emptyHint(String msg) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(msg,
            style:
                const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
      );

  // ── App info ──────────────────────────────────────────────────────────────────

  Widget _buildAppInfo() {
    return Center(
      child: Column(
        children: [
          Image.asset('assets/icon-remove-background.png', width: 56, height: 56),
          const SizedBox(height: 8),
          const Text('OpiOpi',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary)),
          const SizedBox(height: 4),
          const Text('Versi 1.0.0',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const Text('Aplikasi Keuangan Keluarga',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.icon,
    this.trailing,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            ?trailing,
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.pink.withValues(alpha: 0.07),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }
}

class _CrudItem extends StatelessWidget {
  final String label;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _CrudItem({
    required this.label,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.drag_handle_rounded,
              size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 14, color: AppTheme.textPrimary),
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

class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _AddButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.primary,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
