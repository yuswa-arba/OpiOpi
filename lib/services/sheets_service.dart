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
      final credentials = ServiceAccountCredentials.fromJson(json.decode(credJson));
      _authClient = await clientViaServiceAccount(
        credentials,
        [SheetsApi.spreadsheetsScope],
      );
    }
    return SheetsApi(_authClient!);
  }

  // Invalidate cached client so next call re-authenticates (used after sheet ID change)
  static void invalidateCache() {
    _authClient?.close();
    _authClient = null;
  }

  static Future<List<String>> getUsers() async {
    final api = await _getApi();
    final sheetId = await StorageService.getSheetId();
    final response = await api.spreadsheets.values.get(sheetId, 'Users!B2:B');
    final rows = response.values ?? [];
    return rows
        .where((row) => row.isNotEmpty && row[0].toString().isNotEmpty)
        .map((row) => row[0].toString())
        .toList();
  }

  static Future<List<String>> getKategori() async {
    final api = await _getApi();
    final sheetId = await StorageService.getSheetId();
    final response = await api.spreadsheets.values.get(sheetId, 'Kategori!A2:A');
    final rows = response.values ?? [];
    return rows
        .where((row) => row.isNotEmpty && row[0].toString().isNotEmpty)
        .map((row) => row[0].toString())
        .toList();
  }

  static Future<List<Transaction>> getTransactions() async {
    final api = await _getApi();
    final sheetId = await StorageService.getSheetId();
    final response = await api.spreadsheets.values.get(sheetId, 'Transactions!A2:I');
    final rows = response.values ?? [];
    return rows
        .asMap()
        .entries
        .where((e) => e.value.isNotEmpty && e.value[0].toString().isNotEmpty)
        .map((e) => Transaction.fromRow(e.value, e.key + 2))
        .toList();
  }

  static Future<void> addTransaction(Transaction transaction) async {
    final api = await _getApi();
    final sheetId = await StorageService.getSheetId();

    // Resolve sheet GID — avoids range-string encoding issues with values.append
    final spreadsheet = await api.spreadsheets.get(sheetId);
    final sheet = spreadsheet.sheets?.firstWhere(
      (s) => s.properties?.title == 'Transactions',
      orElse: () => throw Exception(
          'Tab "Transactions" tidak ditemukan di Google Sheet. '
          'Pastikan nama tab sudah benar (huruf besar/kecil harus sama persis).'),
    );
    final sheetGid = sheet?.properties?.sheetId ?? 0;

    final cells = transaction.toRow().map((v) => CellData(
          userEnteredValue: ExtendedValue(stringValue: v.toString()),
        )).toList();

    final request = Request(
      appendCells: AppendCellsRequest(
        sheetId: sheetGid,
        rows: [RowData(values: cells)],
        fields: 'userEnteredValue',
      ),
    );

    await api.spreadsheets.batchUpdate(
      BatchUpdateSpreadsheetRequest(requests: [request]),
      sheetId,
    );
  }

  static Future<void> updateTransaction(Transaction transaction) async {
    final api = await _getApi();
    final sheetId = await StorageService.getSheetId();

    final spreadsheet = await api.spreadsheets.get(sheetId);
    final sheet = spreadsheet.sheets?.firstWhere(
      (s) => s.properties?.title == 'Transactions',
      orElse: () => throw Exception('Tab "Transactions" tidak ditemukan.'),
    );
    final sheetGid = sheet?.properties?.sheetId ?? 0;

    final cells = transaction.toRow().map((v) => CellData(
          userEnteredValue: ExtendedValue(stringValue: v.toString()),
        )).toList();

    // rowIndex is 1-based; GridCoordinate uses 0-based
    final request = Request(
      updateCells: UpdateCellsRequest(
        rows: [RowData(values: cells)],
        fields: 'userEnteredValue',
        start: GridCoordinate(
          sheetId: sheetGid,
          rowIndex: transaction.rowIndex - 1,
          columnIndex: 0,
        ),
      ),
    );

    await api.spreadsheets.batchUpdate(
      BatchUpdateSpreadsheetRequest(requests: [request]),
      sheetId,
    );
  }

  static Future<void> deleteTransaction(int rowIndex) async {
    final api = await _getApi();
    final sheetId = await StorageService.getSheetId();

    // Resolve the internal sheet GID for "Transactions"
    final spreadsheet = await api.spreadsheets.get(sheetId);
    final sheet = spreadsheet.sheets?.firstWhere(
      (s) => s.properties?.title == 'Transactions',
      orElse: () => throw Exception('Sheet Transactions tidak ditemukan'),
    );
    final sheetGid = sheet?.properties?.sheetId ?? 0;

    final request = Request(
      deleteDimension: DeleteDimensionRequest(
        range: DimensionRange(
          sheetId: sheetGid,
          dimension: 'ROWS',
          startIndex: rowIndex - 1, // API uses 0-based index
          endIndex: rowIndex,
        ),
      ),
    );

    await api.spreadsheets.batchUpdate(
      BatchUpdateSpreadsheetRequest(requests: [request]),
      sheetId,
    );
  }
}
