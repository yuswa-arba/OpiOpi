import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart';

import '../models/transaction.dart';
import 'storage_service.dart';

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

  /// Resolves the internal numeric GID for a named sheet tab.
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
          'Pastikan nama tab di Google Sheet sudah benar (huruf besar/kecil harus sama persis).'),
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
              startIndex: rowIndex - 1, // 0-based
              endIndex: rowIndex,
            ),
          ),
        ),
      ]),
      spreadsheetId,
    );
  }

  static CellData _strCell(String value) =>
      CellData(userEnteredValue: ExtendedValue(stringValue: value));

  static CellData _numCell(double value) =>
      CellData(userEnteredValue: ExtendedValue(numberValue: value));

  // ─── Transactions ────────────────────────────────────────────────────────────

  static Future<List<Transaction>> getTransactions() async {
    final api = await _getApi();
    final sheetId = await StorageService.getSheetId();
    final response =
        await api.spreadsheets.values.get(sheetId, 'Transactions!A2:I');
    return (response.values ?? [])
        .asMap()
        .entries
        .where((e) => e.value.isNotEmpty && e.value[0].toString().isNotEmpty)
        .map((e) => Transaction.fromRow(e.value, e.key + 2))
        .toList();
  }

  static Future<void> addTransaction(Transaction transaction) async {
    final api = await _getApi();
    final sheetId = await StorageService.getSheetId();
    final gid = await _getSheetGid(api, sheetId, 'Transactions');

    final cells =
        transaction.toRow().map((v) => _strCell(v.toString())).toList();

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
      sheetId,
    );
  }

  static Future<void> updateTransaction(Transaction transaction) async {
    final api = await _getApi();
    final sheetId = await StorageService.getSheetId();
    final gid = await _getSheetGid(api, sheetId, 'Transactions');

    final cells =
        transaction.toRow().map((v) => _strCell(v.toString())).toList();

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
      sheetId,
    );
  }

  static Future<void> deleteTransaction(int rowIndex) async {
    final api = await _getApi();
    final sheetId = await StorageService.getSheetId();
    final gid = await _getSheetGid(api, sheetId, 'Transactions');
    await _deleteRow(api, sheetId, gid, rowIndex);
  }

  // ─── Kategori ────────────────────────────────────────────────────────────────

  /// Simple list (used by form dropdown).
  static Future<List<String>> getKategori() async {
    final api = await _getApi();
    final sheetId = await StorageService.getSheetId();
    final response =
        await api.spreadsheets.values.get(sheetId, 'Kategori!A2:A');
    return (response.values ?? [])
        .where((row) => row.isNotEmpty && row[0].toString().isNotEmpty)
        .map((row) => row[0].toString())
        .toList();
  }

  /// List with 1-based row index (used by settings CRUD).
  static Future<List<MapEntry<int, String>>> getKategoriWithIndex() async {
    final api = await _getApi();
    final sheetId = await StorageService.getSheetId();
    final response =
        await api.spreadsheets.values.get(sheetId, 'Kategori!A2:A');
    return (response.values ?? [])
        .asMap()
        .entries
        .where((e) => e.value.isNotEmpty && e.value[0].toString().isNotEmpty)
        .map((e) => MapEntry(e.key + 2, e.value[0].toString()))
        .toList();
  }

  static Future<void> addKategori(String name) async {
    final api = await _getApi();
    final sheetId = await StorageService.getSheetId();
    final gid = await _getSheetGid(api, sheetId, 'Kategori');

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
      sheetId,
    );
  }

  static Future<void> updateKategori(int rowIndex, String name) async {
    final api = await _getApi();
    final sheetId = await StorageService.getSheetId();
    final gid = await _getSheetGid(api, sheetId, 'Kategori');

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
      sheetId,
    );
  }

  static Future<void> deleteKategori(int rowIndex) async {
    final api = await _getApi();
    final sheetId = await StorageService.getSheetId();
    final gid = await _getSheetGid(api, sheetId, 'Kategori');
    await _deleteRow(api, sheetId, gid, rowIndex);
  }

  // ─── Users ───────────────────────────────────────────────────────────────────

  /// Simple list (used by user-selection screen & form).
  static Future<List<String>> getUsers() async {
    final api = await _getApi();
    final sheetId = await StorageService.getSheetId();
    final response = await api.spreadsheets.values.get(sheetId, 'Users!B2:B');
    return (response.values ?? [])
        .where((row) => row.isNotEmpty && row[0].toString().isNotEmpty)
        .map((row) => row[0].toString())
        .toList();
  }

  /// List with 1-based row index (used by settings CRUD).
  static Future<List<MapEntry<int, String>>> getUsersWithIndex() async {
    final api = await _getApi();
    final sheetId = await StorageService.getSheetId();
    final response = await api.spreadsheets.values.get(sheetId, 'Users!A2:B');
    return (response.values ?? [])
        .asMap()
        .entries
        .where((e) => e.value.length > 1 && e.value[1].toString().isNotEmpty)
        .map((e) => MapEntry(e.key + 2, e.value[1].toString()))
        .toList();
  }

  static Future<void> addUser(String name) async {
    final api = await _getApi();
    final sheetId = await StorageService.getSheetId();
    final gid = await _getSheetGid(api, sheetId, 'Users');

    // Determine next sequential ID from existing rows
    final existing =
        await api.spreadsheets.values.get(sheetId, 'Users!A2:A');
    final nextId = (existing.values?.length ?? 0) + 1;

    await api.spreadsheets.batchUpdate(
      BatchUpdateSpreadsheetRequest(requests: [
        Request(
          appendCells: AppendCellsRequest(
            sheetId: gid,
            rows: [
              RowData(values: [
                _numCell(nextId.toDouble()),
                _strCell(name),
              ])
            ],
            fields: 'userEnteredValue',
          ),
        ),
      ]),
      sheetId,
    );
  }

  static Future<void> updateUser(int rowIndex, String name) async {
    final api = await _getApi();
    final sheetId = await StorageService.getSheetId();
    final gid = await _getSheetGid(api, sheetId, 'Users');

    // Update only column B (Nama); column A (ID) is preserved
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
      sheetId,
    );
  }

  static Future<void> deleteUser(int rowIndex) async {
    final api = await _getApi();
    final sheetId = await StorageService.getSheetId();
    final gid = await _getSheetGid(api, sheetId, 'Users');
    await _deleteRow(api, sheetId, gid, rowIndex);
  }
}
