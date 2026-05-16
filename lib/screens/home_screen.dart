import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_theme.dart';
import '../models/transaction.dart';
import '../services/sheets_service.dart';
import '../services/storage_service.dart';
import 'detail_screen.dart';
import 'form_screen.dart';
import 'settings_screen.dart';
import 'user_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  final String activeUser;

  const HomeScreen({super.key, required this.activeUser});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Transaction> _allTransactions = [];
  bool _loading = true;
  String? _error;

  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await SheetsService.getTransactions();
      // Sort by creation timestamp descending; fall back to tanggal for old rows
      data.sort((a, b) {
        final ta = _parseCreatedAt(a.dibuatSaat);
        final tb = _parseCreatedAt(b.dibuatSaat);
        if (ta != null && tb != null) return tb.compareTo(ta);
        if (ta != null) return -1;
        if (tb != null) return 1;
        return b.tanggal.compareTo(a.tanggal);
      });
      setState(() {
        _allTransactions = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat data.\nCoba lagi ya 😊';
        _loading = false;
      });
    }
  }

  DateTime? _parseCreatedAt(String s) {
    if (s.isEmpty) return null;
    try {
      return DateFormat('yyyy-MM-dd HH:mm:ss').parse(s);
    } catch (_) {
      return null;
    }
  }

  List<Transaction> get _filteredTransactions => _allTransactions
      .where((t) =>
          t.tanggal.year == _selectedMonth.year &&
          t.tanggal.month == _selectedMonth.month)
      .toList();

  double get _totalMasuk => _filteredTransactions
      .where((t) => t.jenis == 'Masuk')
      .fold(0, (sum, t) => sum + t.nominal);

  double get _totalKeluar => _filteredTransactions
      .where((t) => t.jenis == 'Keluar')
      .fold(0, (sum, t) => sum + t.nominal);

  // Saldo = semua transaksi dari seluruh data (bukan hanya bulan ini)
  double get _saldo => _allTransactions.fold(0, (sum, t) {
        return t.jenis == 'Masuk' ? sum + t.nominal : sum - t.nominal;
      });

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    if (!next.isAfter(DateTime(now.year, now.month))) {
      setState(() => _selectedMonth = next);
    }
  }

  Future<void> _gantiUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ganti Pengguna'),
        content: const Text('Mau ganti ke nama lain?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Ganti'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await StorageService.clearActiveUser();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const UserSelectionScreen()),
      );
    }
  }

  Future<void> _openForm({Transaction? edit}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FormScreen(
          activeUser: widget.activeUser,
          editTransaction: edit,
        ),
      ),
    );
    if (result == true) _loadTransactions();
  }

  Future<void> _openDetail(Transaction t) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => DetailScreen(transaction: t)),
    );
    if (result == true) _loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy', 'id').format(_selectedMonth);
    final now = DateTime.now();
    final isCurrentMonth =
        _selectedMonth.year == now.year && _selectedMonth.month == now.month;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icon-remove-background.png',
              height: 32,
              width: 32,
            ),
            const SizedBox(width: 8),
            const Text('OpiOpi'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Pengaturan',
            icon: const Icon(Icons.settings_rounded),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              _loadTransactions();
            },
          ),
          IconButton(
            tooltip: 'Ganti Pengguna',
            icon: const Icon(Icons.switch_account_rounded),
            onPressed: _gantiUser,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _loadTransactions,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  children: [
                    // User greeting
                    _buildGreeting(),
                    const SizedBox(height: 16),
                    // Month navigator
                    _buildMonthNavigator(monthLabel, isCurrentMonth),
                    const SizedBox(height: 16),
                    // Summary cards
                    _buildSummaryRow(),
                    const SizedBox(height: 20),
                    // List header
                    Row(
                      children: [
                        const Text(
                          'Transaksi',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        if (!_loading)
                          Text(
                            '${_filteredTransactions.length} data',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            _buildTransactionList(),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('👤', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pengguna aktif',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  widget.activeUser,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNavigator(String label, bool isCurrentMonth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            color: AppTheme.primary,
            onPressed: _prevMonth,
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right_rounded,
              color: isCurrentMonth ? Colors.grey.shade300 : AppTheme.primary,
            ),
            onPressed: isCurrentMonth ? null : _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Pemasukan',
                amount: _totalMasuk,
                color: AppTheme.incomeColor,
                icon: Icons.arrow_downward_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: 'Pengeluaran',
                amount: _totalKeluar,
                color: AppTheme.expenseColor,
                icon: Icons.arrow_upward_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _SummaryCard(
          label: 'Saldo (semua waktu)',
          amount: _saldo,
          color: AppTheme.secondary,
          icon: Icons.account_balance_wallet_rounded,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildTransactionList() {
    if (_loading) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.primary),
              SizedBox(height: 12),
              Text('Memuat transaksi...', style: TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 52, color: AppTheme.expenseColor),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadTransactions,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final list = _filteredTransactions;
    if (list.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('📭', style: TextStyle(fontSize: 48)),
              SizedBox(height: 12),
              Text(
                'Belum ada transaksi bulan ini',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final t = list[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TransactionItem(
                transaction: t,
                onTap: () => _openDetail(t),
              ),
            );
          },
          childCount: list.length,
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final bool fullWidth;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: fullWidth
          ? Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w500)),
                    Text(
                      fmt.format(amount),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color),
                    ),
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(label,
                          style: TextStyle(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  fmt.format(amount),
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: color),
                ),
              ],
            ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;

  const _TransactionItem({required this.transaction, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.jenis == 'Masuk';
    final color = isIncome ? AppTheme.incomeColor : AppTheme.expenseColor;
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFmt = DateFormat('dd MMM', 'id');
    final keterangan = transaction.keterangan.length > 20
        ? '${transaction.keterangan.substring(0, 20)}...'
        : transaction.keterangan;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 2,
      shadowColor: Colors.pink.withValues(alpha: 0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isIncome
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      keterangan.isEmpty ? transaction.kategori : keterangan,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          dateFmt.format(transaction.tanggal),
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        const Text(' · ',
                            style: TextStyle(color: AppTheme.textSecondary)),
                        Text(
                          transaction.diinputOleh,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? '+' : '-'}${fmt.format(transaction.nominal)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      transaction.jenis,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: color),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
