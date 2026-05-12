import '../database.dart';

class ContestEntriesTable extends SupabaseTable<ContestEntriesRow> {
  @override
  String get tableName => 'Contest_Entries';

  @override
  ContestEntriesRow createRow(Map<String, dynamic> data) =>
      ContestEntriesRow(data);
}

class ContestEntriesRow extends SupabaseDataRow {
  ContestEntriesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ContestEntriesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get mediaId => getField<String>('media_id')!;
  set mediaId(String value) => setField<String>('media_id', value);

  String? get contestId => getField<String>('contest_id');
  set contestId(String? value) => setField<String>('contest_id', value);

  PostgresTime? get entryDate => getField<PostgresTime>('entry_date');
  set entryDate(PostgresTime? value) =>
      setField<PostgresTime>('entry_date', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  PostgresTime? get judgingDate => getField<PostgresTime>('judging_date');
  set judgingDate(PostgresTime? value) =>
      setField<PostgresTime>('judging_date', value);

  String? get judgingLocation => getField<String>('judging_location');
  set judgingLocation(String? value) =>
      setField<String>('judging_location', value);

  PostgresTime? get createdAt => getField<PostgresTime>('created_at');
  set createdAt(PostgresTime? value) =>
      setField<PostgresTime>('created_at', value);
}
