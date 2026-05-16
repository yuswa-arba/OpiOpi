class Transaction {
  final String id;
  final DateTime tanggal;
  final String jenis;
  final String kategori;
  final double nominal;
  final String keterangan;
  final String notes;
  final String diinputOleh;
  final String dibuatSaat; // yyyy-MM-dd HH:mm:ss WITA, auto-filled on create
  final int rowIndex; // 1-based row number in the sheet

  const Transaction({
    required this.id,
    required this.tanggal,
    required this.jenis,
    required this.kategori,
    required this.nominal,
    required this.keterangan,
    required this.notes,
    required this.diinputOleh,
    required this.dibuatSaat,
    required this.rowIndex,
  });

  factory Transaction.fromRow(List<dynamic> row, int rowIndex) {
    DateTime date = DateTime.now();
    if (row.length > 1 && row[1] != null && row[1].toString().isNotEmpty) {
      try {
        final parts = row[1].toString().split('/');
        if (parts.length == 3) {
          date = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      } catch (_) {}
    }

    return Transaction(
      id: row.isNotEmpty ? (row[0]?.toString() ?? '') : '',
      tanggal: date,
      jenis: row.length > 2 ? (row[2]?.toString() ?? '') : '',
      kategori: row.length > 3 ? (row[3]?.toString() ?? '') : '',
      nominal: row.length > 4 ? (double.tryParse(row[4]?.toString() ?? '') ?? 0) : 0,
      keterangan: row.length > 5 ? (row[5]?.toString() ?? '') : '',
      notes: row.length > 6 ? (row[6]?.toString() ?? '') : '',
      diinputOleh: row.length > 7 ? (row[7]?.toString() ?? '') : '',
      dibuatSaat: row.length > 8 ? (row[8]?.toString() ?? '') : '',
      rowIndex: rowIndex,
    );
  }

  List<dynamic> toRow() => [
        id,
        '${tanggal.day.toString().padLeft(2, '0')}/${tanggal.month.toString().padLeft(2, '0')}/${tanggal.year}',
        jenis,
        kategori,
        nominal.toStringAsFixed(0),
        keterangan,
        notes,
        diinputOleh,
        dibuatSaat,
      ];

  Transaction copyWith({
    String? id,
    DateTime? tanggal,
    String? jenis,
    String? kategori,
    double? nominal,
    String? keterangan,
    String? notes,
    String? diinputOleh,
    String? dibuatSaat,
    int? rowIndex,
  }) {
    return Transaction(
      id: id ?? this.id,
      tanggal: tanggal ?? this.tanggal,
      jenis: jenis ?? this.jenis,
      kategori: kategori ?? this.kategori,
      nominal: nominal ?? this.nominal,
      keterangan: keterangan ?? this.keterangan,
      notes: notes ?? this.notes,
      diinputOleh: diinputOleh ?? this.diinputOleh,
      dibuatSaat: dibuatSaat ?? this.dibuatSaat,
      rowIndex: rowIndex ?? this.rowIndex,
    );
  }
}
