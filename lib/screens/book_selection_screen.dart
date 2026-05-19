import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/sheets_service.dart';
import '../services/storage_service.dart';
import 'home_screen.dart';

/// Layar pilih Buku Keuangan.
///
/// [activeUser] wajib diisi saat [onboarding] = true (flow pertama kali).
/// Saat [onboarding] = false (ganti buku dari home/settings), cukup pop setelah pilih.
class BookSelectionScreen extends StatefulWidget {
  final String? activeUser;
  final bool onboarding;

  const BookSelectionScreen({
    super.key,
    this.activeUser,
    this.onboarding = true,
  });

  @override
  State<BookSelectionScreen> createState() => _BookSelectionScreenState();
}

class _BookSelectionScreenState extends State<BookSelectionScreen> {
  List<MapEntry<String, String>> _books = []; // (id, name)
  bool _loading = true;
  String? _error;
  String? _activeBookId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final books = await SheetsService.getBukuKeuangan();
      final activeId = await StorageService.getActiveBookId();
      setState(() {
        _books = books;
        _activeBookId = activeId;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat daftar buku.\nCek koneksi internet ya 😊\n\n$e';
        _loading = false;
      });
    }
  }

  Future<void> _selectBook(String id, String name) async {
    await StorageService.setActiveBook(id, name);
    if (!mounted) return;

    if (widget.onboarding) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            activeUser: widget.activeUser!,
            activeBookName: name,
          ),
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primary, Color(0xFFFFD6E3), AppTheme.background],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Header
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.book_rounded, size: 42, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Pilih Buku Keuangan',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Data transaksi akan diambil dari buku ini',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 36),
              // Card
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Buku tersedia:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(child: _buildContent()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Back button (only when not onboarding)
              if (!widget.onboarding)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    label: const Text('Kembali',
                        style: TextStyle(color: Colors.white70)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primary),
            SizedBox(height: 16),
            Text('Memuat daftar buku...',
                style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 52, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppTheme.textSecondary, height: 1.5)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary),
            ),
          ],
        ),
      );
    }

    if (_books.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada Buku Keuangan.\nTambahkan dulu di sheet "Buku Keuangan" ya.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
        ),
      );
    }

    return ListView.separated(
      itemCount: _books.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final book = _books[index];
        final isActive = book.key == _activeBookId;
        return _BookCard(
          name: book.value,
          isActive: isActive,
          onTap: () => _selectBook(book.key, book.value),
        );
      },
    );
  }
}

class _BookCard extends StatelessWidget {
  final String name;
  final bool isActive;
  final VoidCallback onTap;

  const _BookCard({
    required this.name,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.primary.withValues(alpha: 0.12)
                : AppTheme.chipBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? AppTheme.primary
                  : AppTheme.primary.withValues(alpha: 0.2),
              width: isActive ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.primary : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.book_rounded,
                  size: 22,
                  color: isActive ? Colors.white : AppTheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? AppTheme.primary
                            : AppTheme.textPrimary,
                      ),
                    ),
                    if (isActive)
                      const Text(
                        'Sedang aktif',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.primary),
                      ),
                  ],
                ),
              ),
              Icon(
                isActive
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: isActive ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
