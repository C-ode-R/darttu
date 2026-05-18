import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'database.g.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().unique()();
  TextColumn get passwordHash => text()();
  TextColumn get passwordSalt => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get token => text().unique()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Users, Sessions])
class AppDatabase extends _$AppDatabase {
  AppDatabase(String path) : super(_openConnection(path));

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await customStatement(_createRoomsTableSql);
      await customStatement(_createOnlineUsersTableSql);
      await customStatement(_createRoomMembersTableSql);
      await _seedRooms();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(users);
      }
      if (from < 3) {
        await migrator.createTable(sessions);
      }
      if (from < 4) {
        await customStatement(_createRoomsTableSql);
        await _seedRooms();
      }
      if (from < 5) {
        await customStatement(_createOnlineUsersTableSql);
        await customStatement(_createRoomMembersTableSql);
      }
    },
  );

  Future<void> closeConnection() {
    return close();
  }

  Future<void> _seedRooms() async {
    final existingRooms = await customSelect(
      'SELECT id FROM rooms LIMIT 1',
      readsFrom: const {},
    ).get();
    if (existingRooms.isNotEmpty) {
      return;
    }

    await customStatement(
      "INSERT INTO rooms (name, current_players, max_players) VALUES ('초보자 환영방', 1, 4)",
    );
    await customStatement(
      "INSERT INTO rooms (name, current_players, max_players) VALUES ('빠른 대전', 2, 4)",
    );
    await customStatement(
      "INSERT INTO rooms (name, current_players, max_players) VALUES ('관전 가능', 3, 6)",
    );
  }
}

const _createRoomsTableSql = '''
CREATE TABLE IF NOT EXISTS rooms (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  current_players INTEGER NOT NULL DEFAULT 0,
  max_players INTEGER NOT NULL DEFAULT 4,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
)
''';

const _createOnlineUsersTableSql = '''
CREATE TABLE IF NOT EXISTS online_users (
  user_id INTEGER PRIMARY KEY,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
)
''';

const _createRoomMembersTableSql = '''
CREATE TABLE IF NOT EXISTS room_members (
  room_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL UNIQUE,
  joined_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (room_id, user_id)
)
''';

LazyDatabase _openConnection(String path) {
  return LazyDatabase(() async {
    final file = File(path);
    final parent = file.parent;
    if (!parent.existsSync()) {
      parent.createSync(recursive: true);
    }

    return NativeDatabase.createInBackground(file);
  });
}
