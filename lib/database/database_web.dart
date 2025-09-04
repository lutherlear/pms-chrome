import 'package:drift/drift.dart';
import 'package:drift/web.dart';

QueryExecutor createDatabaseExecutor(String dbName) {
  return LazyDatabase(() async {
    return WebDatabase(dbName);
  });
}
