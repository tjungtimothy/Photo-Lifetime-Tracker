import '../database.dart';

class OrganizationsTable extends SupabaseTable<OrganizationsRow> {
  @override
  String get tableName => 'Organizations';

  @override
  OrganizationsRow createRow(Map<String, dynamic> data) =>
      OrganizationsRow(data);
}

class OrganizationsRow extends SupabaseDataRow {
  OrganizationsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => OrganizationsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get name => getField<String>('name')!;
  set name(String value) => setField<String>('name', value);

  String? get fullName => getField<String>('full_name');
  set fullName(String? value) => setField<String>('full_name', value);

  String? get website => getField<String>('website');
  set website(String? value) => setField<String>('website', value);

  PostgresTime? get createdAt => getField<PostgresTime>('created_at');
  set createdAt(PostgresTime? value) =>
      setField<PostgresTime>('created_at', value);
}
