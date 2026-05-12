import '../database.dart';

class MediaTable extends SupabaseTable<MediaRow> {
  @override
  String get tableName => 'Media';

  @override
  MediaRow createRow(Map<String, dynamic> data) => MediaRow(data);
}

class MediaRow extends SupabaseDataRow {
  MediaRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => MediaTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get title => getField<String>('title')!;
  set title(String value) => setField<String>('title', value);

  String get originalFilename => getField<String>('original_filename')!;
  set originalFilename(String value) =>
      setField<String>('original_filename', value);

  String? get type => getField<String>('type');
  set type(String? value) => setField<String>('type', value);

  String? get category => getField<String>('category');
  set category(String? value) => setField<String>('category', value);

  String? get filePath => getField<String>('file_path');
  set filePath(String? value) => setField<String>('file_path', value);

  DateTime? get captureDate => getField<DateTime>('capture_date');
  set captureDate(DateTime? value) => setField<DateTime>('capture_date', value);

  DateTime? get importDate => getField<DateTime>('import_date');
  set importDate(DateTime? value) => setField<DateTime>('import_date', value);

  dynamic get metadata => getField<dynamic>('Metadata');
  set metadata(dynamic value) => setField<dynamic>('Metadata', value);

  dynamic get processingData => getField<dynamic>('processing_data');
  set processingData(dynamic value) =>
      setField<dynamic>('processing_data', value);

  String? get currentStatus => getField<String>('current_status');
  set currentStatus(String? value) => setField<String>('current_status', value);

  double? get averageScore => getField<double>('average_score');
  set averageScore(double? value) => setField<double>('average_score', value);

  double? get highestScore => getField<double>('highest_score');
  set highestScore(double? value) => setField<double>('highest_score', value);

  String? get makerId => getField<String>('maker_id');
  set makerId(String? value) => setField<String>('maker_id', value);
}
