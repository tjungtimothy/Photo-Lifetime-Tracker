import '../database.dart';

class ScoresTable extends SupabaseTable<ScoresRow> {
  @override
  String get tableName => 'Scores';

  @override
  ScoresRow createRow(Map<String, dynamic> data) => ScoresRow(data);
}

class ScoresRow extends SupabaseDataRow {
  ScoresRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ScoresTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get contestEntryId => getField<String>('contest_entry_id')!;
  set contestEntryId(String value) =>
      setField<String>('contest_entry_id', value);

  String? get judgeId => getField<String>('judge_id');
  set judgeId(String? value) => setField<String>('judge_id', value);

  double? get score => getField<double>('score');
  set score(double? value) => setField<double>('score', value);

  String? get comments => getField<String>('comments');
  set comments(String? value) => setField<String>('comments', value);

  PostgresTime? get judgedDate => getField<PostgresTime>('judged_date');
  set judgedDate(PostgresTime? value) =>
      setField<PostgresTime>('judged_date', value);

  String? get award => getField<String>('award');
  set award(String? value) => setField<String>('award', value);

  PostgresTime? get createdAt => getField<PostgresTime>('created_at');
  set createdAt(PostgresTime? value) =>
      setField<PostgresTime>('created_at', value);
}
