import '../database.dart';

class CommentsTable extends SupabaseTable<CommentsRow> {
  @override
  String get tableName => 'Comments';

  @override
  CommentsRow createRow(Map<String, dynamic> data) => CommentsRow(data);
}

class CommentsRow extends SupabaseDataRow {
  CommentsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => CommentsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get mediaId => getField<String>('media_id')!;
  set mediaId(String value) => setField<String>('media_id', value);

  String? get contestEntryId => getField<String>('contest_entry-id');
  set contestEntryId(String? value) =>
      setField<String>('contest_entry-id', value);

  String? get authorId => getField<String>('author_id');
  set authorId(String? value) => setField<String>('author_id', value);

  String? get commentTest => getField<String>('comment_test');
  set commentTest(String? value) => setField<String>('comment_test', value);

  String? get commentType => getField<String>('comment_type');
  set commentType(String? value) => setField<String>('comment_type', value);

  PostgresTime? get createdAt => getField<PostgresTime>('created_at');
  set createdAt(PostgresTime? value) =>
      setField<PostgresTime>('created_at', value);
}
