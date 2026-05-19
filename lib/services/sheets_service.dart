import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart';

import '../models/transaction.dart';
import 'storage_service.dart';

/// [SheetsService] memisahkan dua jenis Google Sheet:
///
/// • GS Konfigurasi — berisi Users, Kategori, Buku Keuangan.
///   ID-nya diambil dari [StorageService.getConfigSheetId].
///
/// • GS Keuangan — berisi Transactions saja.
///   ID-nya diambil dari [StorageService.getActiveBookId].
class SheetsService {
  static AutoRefreshingAuthClient? _authClient;

  static Future<SheetsApi> _getApi() async {
    if (_authClient == null) {
      final credJson = await rootBundle.loadString('assets/credentials.json');
      final credentials =
          ServiceAccountCredentials.fromJson(json.decode(credJson));
      _authClient = await clientViaServiceAccount(
        credentials,
        [SheetsApi.spreadsheetsScope],
      );
    }
    return SheetsApi(_authClient!);
  }

  static void invalidateCache() {
    _authClient?.close();
    _authClient = null;
  }

  // ─── Shared helpers ──────────────────────────────────────────────────────────

  static Future<int> _getSheetGid(
    SheetsApi api,
    String spreadsheetId,
    String sheetName,
  ) async {
    final spreadsheet = await api.spreadsheets.get(spreadsheetId);
    final sheet = spreadsheet.sheets?.firstWhere(
      (s) => s.properties?.title == sheetName,
      orElse: () => throw Exception(
          'Tab "$sheetName" tidak ditemukan. '
          'Pastikan nama tab di Google Sheet sudah benar.'),
    );
    return sheet?.properties?.sheetId ?? 0;
  }

  static Future<void> _deleteRow(
    SheetsApi api,
    String spreadsheetId,
    int sheetGid,
    int rowIndex, // 1-based
  ) async {
    await api.spreadsheets.batchUpdate(
      BatchUpdateSpreadsheetRequest(requests: [
        Request(
          deleteDimension: DeleteDimensionRequest(
            range: DimensionRange(
              sheetId: sheetGid,
              dimension: 'ROWS',
              startIndex: rowIndex - 1,
              endIndex: rowIndex,
            ),
          ),
        ),
      ]),
      spreadsheetId,
    );
  }

  static CellData _strCell(String v) =>
      CellData(userEnteredValue: ExtendedValue(stringValue: v));

  static CellData _numCell(double v) =>
      CellData(userEnteredValue: ExtendedValue(numberValue: v));

  // ═══════════════════════════════════════════════════════════════════════════
  // GS KONFIGURASI — Users, Kategori, Buku Keuangan
  // ═══════════════════════════════════════════════════════════════════════════

  // ─── Buku Keuangan ────────────────────────────────────────────────────────

  /// Mengembalikan daftar (spreadsheetId, namaBuku) dari sheet "Buku Keuangan".
  static Future<List<MapEntry<String, String>>> getBukuKeuangan() async {
    final api = await _getApi();
    final configId = await StorageService.getConfigSheetId();
    final response =
        await api.spreadsheets.values.get(configId, 'Buku Keuangan!A2:B');
    return (response.values ?? [])
        .where((row) =>
            row.length >= 2 &&
            row[0].toString().isNotEmpty &&
            row[1].toString().isNotEmpty)
        .map((row) => MapEntry(row[0].toString(), row[1].toString()))
        .toList();
  }

  // ─── Users (GS Konfigurasi) ───────────────────────────────────────────────

  static Future<List<String>> getUsers() async {
    final api = await _getApi();
    final configId = await StorageService.getConfigSheetId();
    final response =
        await api.spreadsheets.values.get(configId, 'Users!B2:B');
    return (response.values ?? [])
        .where((row) => row.isNotEmpty && row[0].toString().isNotEmpty)
        .map((row) => row[0].toString())
        .toList();
  }

  static Future<List<MapEntry<int, String>>> getUsersWithIndex() async {
    final api = await _getApi();
    final configId = await StorageService.getConfigSheetId();
    final response =
        await api.spreadsheets.values.get(configId, 'Users!A2:B');
    return (response.values ?? [])
        .asMap()
        .entries
        .where((e) => e.value.length > 1 && e.value[1].toString().isNotEmpty)
        .map((e) => MapEntry(e.key + 2, e.value[1].toString()))
        .toList();
  }

  static Future<void> addUser(String name) async {
    final api = await _getApi();
    final configId = await StorageService.getConfigSheetId();
    final gid = await _getSheetGid(api, configId, 'Users');
    final existing =
        await api.spreadsheets.values.get(configId, 'Users!A2:A');
    final nextId = (existing.values?.length ?? 0) + 1;
    await api.spreadsheets.batchUpdate(
      BatchUpdateSpreadsheetRequest(requests: [
        Request(
          appendCells: AppendCellsRequest(
            sheetId: gid,
            rows: [
              RowData(values: [_numCell(nextId.toDouble()), _strCell(name)])
            ],
            fields: 'userEnteredValue',
          ),
        ),
      ]),
      configId,
    );
  }

  static Future<void> updateUser(int rowIndex, String name) async {
    final api = await _getApi();
    final configId = await StorageService.getConfigSheetId();
    final gid = await _getSheetGid(api, configId, 'Users');
    await api.spreadsheets.batchUpdate(
      BatchUpdateSpreadsheetRequest(requests: [
        Request(
          updateCells: UpdateCellsRequest(
            rows: [RowData(values: [_strCell(name)])],
            fields: 'userEnteredValue',
            start: GridCoordinate(
                sheetId: gid, rowIndex: rowIndex - 1, columnIndex: 1),
          ),
        ),
      ]),
      configId,
    );
  }

  static Future<void> deleteUser(int rowIndex) async {
    final api = await _getApi();
    final configId = await StorageService.getConfigSheetId();
    final gid = await _getSheetGid(api, configId, 'Users');
    await _deleteRow(api, configId, gid, rowIndex);
  }

  // ─── Kategori (GS Konfigurasi) ────────────────────────────────────────────

  static Future<List<String>> getKategori() async {
    final api = await _getApi();
    final configId = await StorageService.getConfigSheetId();
    final response =
        await api.spreadsheets.values.get(configId, 'Kategori!A2:A');
    return (response.values ?? [])
        .where((row) => row.isNotEmpty && row[0].toString().isNotEmpty)
        .map((row) => row[0].toString())
        .toList();
  }

  static Future<List<MapEntry<int, String>>> getKategoriWithIndex() async {
    final api = await _getApi();
    final configId = await StorageService.getConfigSheetId();
    final response =
        await api.spreadsheets.values.get(configId, 'Kategori!A2:A');
    return (response.values ?? [])
        .asMap()
        .entries
        .where((e) => e.value.isNotEmpty && e.value[0].toString().isNotEmpty)
        .map((e) => MapEntry(e.key + 2, e.value[0].toString()))
        .toList();
  }

  static Future<void> addKategori(String name) async {
    final api = await _getApi();
    final configId = await StorageService.getConfigSheetId();
    final gid = await _getSheetGid(api, configId, 'Kategori');
    await api.spreadsheets.batchUpdate(
      BatchUpdateSpreadsheetRequest(requests: [
        Request(
          appendCells: AppendCellsRequest(
            sheetId: gid,
            rows: [RowData(values: [_strCell(name)])],
            fields: 'userEnteredValue',
          ),
        ),
      ]),
      configId,
    );
  }

  static Future<void> updateKategori(int rowIndex, String name) async {
    final api = await _getApi();
    final configId = await StorageService.getConfigSheetId();
    final gid = await _getSheetGid(api, configId, 'Kategori');
    await api.spreadsheets.batchUpdate(
      BatchUpdateSpreadsheetRequest(requests: [
        Request(
          updateCells: UpdateCellsRequest(
            rows: [RowData(values: [_strCell(name)])],
            fields: 'userEnteredValue',
            start: GridCoordinate(
                sheetId: gid, rowIndex: rowIndex - 1, columnIndex: 0),
          ),
        ),
      ]),
      configId,
    );
  }

  static Future<void> deleteKategori(int rowIndex) async {
    final api = await _getApi();
    final configId = await StorageService.getConfigSheetId();
    final gid = await _getSheetGid(api, configId, 'Kategori');
    await _deleteRow(api, configId, gid, rowIndex);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GS KEUANGAN — Transactions (menggunakan active book ID)
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<String> _requireBookId() async {
    final id = await StorageService.getActiveBookId();
    if (id == null || id.isEmpty) {
      throw Exception('Buku Keuangan belum dipilih. Pilih Buku Keuangan terlebih dahulu.');
    }
    return id;
  }

  static Future<List<Transaction>> getTransactions() async {
    final api = await _getApi();
    final bookId = await _requireBookId();
    final response =
        await api.spreadsheets.values.get(bookId, 'Transactions!A2:I');
    return (response.values ?? [])
        .asMap()
        .entries
        .where((e) => e.value.isNotEmpty && e.value[0].toString().isNotEmpty)
        .map((e) => Transaction.fromRow(e.value, e.key + 2))
        .toList();
  }

  static Future<void> addTransaction(Transaction transaction) async {
    final api = await _getApi();
    final bookId = await _requireBookId();
    final gid = await _getSheetGid(api, bookId, 'Transactions');
    final cells = transaction.toRow().map((v) => _strCell(v.toString())).toList();
    await api.spreadsheets.batchUpdate(
      BatchUpdateSpreadsheetRequest(requests: [
        Request(
          appendCells: AppendCellsRequest(
            sheetId: gid,
            rows: [RowData(values: cells)],
            fields: 'userEnteredValue',
          ),
        ),
      ]),
      bookId,
    );
  }

  static Future<void> updateTransaction(Transaction transaction) async {
    final api = await _getApi();
    final bookId = await _requireBookId();
    final gid = await _getSheetGid(api, bookId, 'Transactions');
    final cells = transaction.toRow().map((v) => _strCell(v.toString())).toList();
    await api.spreadsheets.batchUpdate(
      BatchUpdateSpreadsheetRequest(requests: [
        Request(
          updateCells: UpdateCellsRequest(
            rows: [RowData(values: cells)],
            fields: 'userEnteredValue',
            start: GridCoordinate(
              sheetId: gid,
              rowIndex: transaction.rowIndex - 1,
              columnIndex: 0,
            ),
          ),
        ),
      ]),
      bookId,
    );
  }

  static Future<void> deleteTransaction(int rowIndex) async {
    final api = await _getApi();
    final bookId = await _requireBookId();
    final gid = await _getSheetGid(api, bookId, 'Transactions');
    await _deleteRow(api, bookId, gid, rowIndex);
  }
}
