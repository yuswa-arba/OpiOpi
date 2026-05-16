import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../app_theme.dart';
import '../models/transaction.dart';
import '../services/sheets_service.dart';

class FormScreen extends StatefulWidget {
  final String activeUser;
  final Transaction? editTransaction;

  const FormScreen({
    super.key,
    required this.activeUser,
    this.editTransaction,
  });

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nominalCtrl = TextEditingController();
  final _keteranganCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime _tanggal = DateTime.now();
  String _jenis = 'Keluar';
  String? _kategori;
  List<String> _kategoriList = [];
  bool _loadingKategori = true;
  bool _saving = false;

  bool get _isEdit => widget.editTransaction != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final t = widget.editTransaction!;
      _tanggal = t.tanggal;
      _jenis = t.jenis;
      _kategori = t.kategori;
      _nominalCtrl.text = t.nominal.toStringAsFixed(0);
      _keteranganCtrl.text = t.keterangan;
      _notesCtrl.text = t.notes;
    }
    _loadKategori();
  }

  @override
  void dispose() {
    _nominalCtrl.dispose();
    _keteranganCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // Asia/Makassar = UTC+8 (WITA)
  String _nowWita() {
    final wita = DateTime.now().toUtc().add(const Duration(hours: 8));
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(wita);
  }

  Future<void> _loadKategori() async {
    try {
      final list = await SheetsService.getKategori();
      setState(() {
        _kategoriList = list;
        _loadingKategori = false;
        // Ensure current kategori is still valid
        if (_kategori != null && !list.contains(_kategori)) {
          _kategori = null;
        }
      });
    } catch (_) {
      setState(() => _loadingKategori = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _tanggal = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_kategori == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori dulu ya 😊')),
      );
      return;
    }

    setState(() => _saving = true);

    final nominal = double.tryParse(_nominalCtrl.text.replaceAll('.', '')) ?? 0;

    final transaction = Transaction(
      id: _isEdit ? widget.editTransaction!.id : const Uuid().v4(),
      tanggal: _tanggal,
      jenis: _jenis,
      kategori: _kategori!,
      nominal: nominal,
      keterangan: _keteranganCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
      diinputOleh: widget.activeUser,
      // Preserve original creation time on edit; auto-fill WITA on create
      dibuatSaat: _isEdit
          ? widget.editTransaction!.dibuatSaat
          : _nowWita(),
      rowIndex: _isEdit ? widget.editTransaction!.rowIndex : 0,
    );

    try {
      if (_isEdit) {
        await SheetsService.updateTransaction(transaction);
      } else {
        await SheetsService.addTransaction(transaction);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: AppTheme.expenseColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEEE, dd MMMM yyyy', 'id');

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Transaksi' : 'Tambah Transaksi'),
        leading: const BackButton(),
      ),
      body: _saving
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTheme.primary),
                  SizedBox(height: 16),
                  Text('Menyimpan...', style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Tanggal
                  _SectionLabel(label: 'Tanggal'),
                  const SizedBox(height: 8),
                  _DatePickerButton(
                    label: dateFmt.format(_tanggal),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 18),

                  // Jenis
                  _SectionLabel(label: 'Jenis Transaksi'),
                  const SizedBox(height: 8),
                  _JenisSelector(
                    value: _jenis,
                    onChanged: (v) => setState(() => _jenis = v),
                  ),
                  const SizedBox(height: 18),

                  // Kategori
                  _SectionLabel(label: 'Kategori'),
                  const SizedBox(height: 8),
                  _loadingKategori
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(color: AppTheme.primary),
                          ),
                        )
                      : DropdownButtonFormField<String>(
                          // ignore: deprecated_member_use
                          value: _kategori,
                          decoration: const InputDecoration(
                            hintText: 'Pilih kategori',
                          ),
                          isExpanded: true,
                          items: _kategoriList
                              .map((k) => DropdownMenuItem(
                                    value: k,
                                    child: Text(k),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _kategori = v),
                        ),
                  const SizedBox(height: 18),

                  // Nominal
                  _SectionLabel(label: 'Nominal (Rp)'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nominalCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      prefixText: 'Rp ',
                      hintText: '0',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Isi nominal dulu ya';
                      final n = double.tryParse(v.replaceAll('.', ''));
                      if (n == null || n <= 0) return 'Nominal harus lebih dari 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Keterangan
                  _SectionLabel(label: 'Keterangan'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _keteranganCtrl,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      hintText: 'Misal: Bayar listrik, Belanja dapur...',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Isi keterangan dulu ya';
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Notes (opsional)
                  _SectionLabel(label: 'Notes (opsional)'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      hintText: 'Catatan tambahan kalau ada...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Diinput oleh (read-only)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.chipBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_rounded,
                            size: 18, color: AppTheme.primary),
                        const SizedBox(width: 10),
                        Text(
                          'Diinput oleh: ${widget.activeUser}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_rounded),
                      label: Text(_isEdit ? 'Simpan Perubahan' : 'Simpan Transaksi'),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _DatePickerButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DatePickerButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.pink.shade100),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 18, color: AppTheme.primary),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              const Icon(Icons.edit_calendar_rounded,
                  size: 16, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _JenisSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _JenisSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _JenisOption(
            label: 'Masuk',
            icon: Icons.arrow_downward_rounded,
            color: AppTheme.incomeColor,
            isSelected: value == 'Masuk',
            onTap: () => onChanged('Masuk'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _JenisOption(
            label: 'Keluar',
            icon: Icons.arrow_upward_rounded,
            color: AppTheme.expenseColor,
            isSelected: value == 'Keluar',
            onTap: () => onChanged('Keluar'),
          ),
        ),
      ],
    );
  }
}

class _JenisOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _JenisOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? color.withValues(alpha: 0.12) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? color : Colors.pink.shade100,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : AppTheme.textSecondary, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
