import '../database.dart';

class JudgesTable extends SupabaseTable<JudgesRow> {
  @override
  String get tableName => 'Judges';

  @override
  JudgesRow createRow(Map<String, dynamic> data) => JudgesRow(data);
}

class JudgesRow extends SupabaseDataRow {
  JudgesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => JudgesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get name => getField<String>('name')!;
  set name(String value) => setField<String>('name', value);

  String? get affiliation => getField<String>('affiliation');
  set affiliation(String? value) => setField<String>('affiliation', value);

  String? get typeOfPhotographer => getField<String>('type_of_photographer');
  set typeOfPhotographer(String? value) =>
      setField<String>('type_of_photographer', value);

  String? get credentials => getField<String>('credentials');
  set credentials(String? value) => setField<String>('credentials', value);

  PostgresTime? get createdAt => getField<PostgresTime>('created_at');
  set createdAt(PostgresTime? value) =>
      setField<PostgresTime>('created_at', value);
}
