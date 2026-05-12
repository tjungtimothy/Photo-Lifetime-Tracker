import '../database.dart';

class ContestsTable extends SupabaseTable<ContestsRow> {
  @override
  String get tableName => 'Contests';

  @override
  ContestsRow createRow(Map<String, dynamic> data) => ContestsRow(data);
}

class ContestsRow extends SupabaseDataRow {
  ContestsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ContestsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get organizationId => getField<String>('organization_id')!;
  set organizationId(String value) =>
      setField<String>('organization_id', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);

  PostgresTime? get submittalStartDate =>
      getField<PostgresTime>('submittal_start_date');
  set submittalStartDate(PostgresTime? value) =>
      setField<PostgresTime>('submittal_start_date', value);

  PostgresTime? get submittalEndDate =>
      getField<PostgresTime>('submittal_end_date');
  set submittalEndDate(PostgresTime? value) =>
      setField<PostgresTime>('submittal_end_date', value);

  PostgresTime? get judgingDatre => getField<PostgresTime>('judging_datre');
  set judgingDatre(PostgresTime? value) =>
      setField<PostgresTime>('judging_datre', value);

  String? get rules => getField<String>('rules');
  set rules(String? value) => setField<String>('rules', value);

  dynamic get awards => getField<dynamic>('awards');
  set awards(dynamic value) => setField<dynamic>('awards', value);

  double? get entryFee => getField<double>('entry_fee');
  set entryFee(double? value) => setField<double>('entry_fee', value);

  PostgresTime? get createdAt => getField<PostgresTime>('created_at');
  set createdAt(PostgresTime? value) =>
      setField<PostgresTime>('created_at', value);
}
