import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift_postgres/drift_postgres.dart';
import 'package:postgres/postgres.dart' as pg;

import 'isolate_manager.dart';

part 'main.g.dart';

class Users extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

@DriftDatabase(tables: [Users])
class DriftPostgresDatabase extends _$DriftPostgresDatabase {
  DriftPostgresDatabase(super.e);

  DriftPostgresDatabase.withConnection(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;
}

final queryExecutor = PgDatabase(
  endpoint: pg.Endpoint(
    host: 'localhost',
    database: 'postgres',
    username: 'postgres',
    password: 'postgres',
  ),
  settings: pg.ConnectionSettings(
    // If you expect to talk to a Postgres database over a public connection,
    // please use SslMode.verifyFull instead.
    sslMode: pg.SslMode.disable,
  ),
  logStatements: true,
);

void main() async {
  final userConnection = IsolateManager();
  final database = await userConnection.init();

  final rng = Random();
  await database.transaction(() async {
    final user = await database.into(database.users).insertReturning(
          UsersCompanion.insert(
            name: 'Simon',
            id: Value(rng.nextInt(1000)),
          ),
        );

    print(user);

    // await database.users.deleteOne(user);
    await database.users.deleteOne(
      UsersCompanion.insert(
        name: user.name,
        id: Value(user.id),
      ),
    );
  });

  await database.close();
  await userConnection.close();
}
