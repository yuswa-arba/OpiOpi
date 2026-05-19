import 'package:flutter/material.dart';

import '../app_theme.dart';
import 'book_selection_screen.dart';
import 'settings/config_sheet_screen.dart';
import 'settings/kategori_management_screen.dart';
import 'settings/users_management_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _MenuItem(
            icon: Icons.table_chart_rounded,
            color: AppTheme.primary,
            title: 'Konfigurasi',
            subtitle: 'Ubah ID spreadsheet konfigurasi',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ConfigSheetScreen()),
            ),
          ),
          _MenuItem(
            icon: Icons.book_rounded,
            color: AppTheme.primary,
            title: 'Buku Keuangan',
            subtitle: 'Pilih buku aktif untuk transaksi',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const BookSelectionScreen(onboarding: false)),
            ),
          ),
          _MenuItem(
            icon: Icons.group_rounded,
            color: AppTheme.primary,
            title: 'Pengguna',
            subtitle: 'Kelola daftar pengguna',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const UsersManagementScreen()),
            ),
          ),
          _MenuItem(
            icon: Icons.category_rounded,
            color: AppTheme.primary,
            title: 'Kategori',
            subtitle: 'Kelola daftar kategori transaksi',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const KategoriManagementScreen()),
            ),
          ),
          const SizedBox(height: 32),
          _buildAppInfo(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAppInfo() {
    return Center(
      child: Column(
        children: [
          Image.asset('assets/icon-remove-background.png', width: 56, height: 56),
          const SizedBox(height: 8),
          const Text(
            'OpiOpi',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary),
          ),
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

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
