import 'package:drift/drift.dart';

import '../database/database.dart';

final class RoomSummary {
  final int id;
  final String name;
  final int currentPlayers;
  final int maxPlayers;

  const RoomSummary({
    required this.id,
    required this.name,
    required this.currentPlayers,
    required this.maxPlayers,
  });
}

final class OnlineUserSummary {
  final int userId;
  final String username;
  final int? roomId;
  final String? roomName;

  const OnlineUserSummary({
    required this.userId,
    required this.username,
    required this.roomId,
    required this.roomName,
  });
}

final class RoomMemberSummary {
  final int userId;
  final String username;
  final bool isHost;
  final bool isReady;

  const RoomMemberSummary({
    required this.userId,
    required this.username,
    required this.isHost,
    required this.isReady,
  });
}

final class RoomDetail {
  final int id;
  final String name;
  final int currentPlayers;
  final int maxPlayers;
  final List<RoomMemberSummary> members;

  const RoomDetail({
    required this.id,
    required this.name,
    required this.currentPlayers,
    required this.maxPlayers,
    required this.members,
  });
}

final class LobbySnapshot {
  final List<RoomSummary> rooms;
  final List<OnlineUserSummary> onlineUsers;

  const LobbySnapshot({required this.rooms, required this.onlineUsers});
}

abstract interface class RoomRepo {
  Future<T> transaction<T>(Future<T> Function() action);
  Future<List<RoomSummary>> list();
  Future<RoomSummary?> summary(int id);
  Future<RoomDetail?> detail(int id);
  Future<LobbySnapshot> lobbySnapshot();
  Future<int> create({
    required String name,
    required int currentPlayers,
    required int maxPlayers,
  });
  Future<void> delete(int id);
  Future<void> updatePlayerCount({required int id, required int count});
  Future<int> memberCount(int roomId);
  Future<void> touchUser(int userId);
}

abstract interface class RoomMemberRepo {
  Future<int?> findUserRoomId(int userId);
  Future<void> removeUserFromAllRooms(int userId);
  Future<void> removeUserFromRoom({required int roomId, required int userId});
  Future<void> addUserToRoom({required int roomId, required int userId});
  Future<void> toggleReady({required int roomId, required int userId});
}

abstract interface class PresenceRepo {
  Future<List<int>> staleUserIds({required int staleAfterSeconds});
  Future<Set<int>> roomIdsForUser(int userId);
  Future<void> removeOnlineUser(int userId);
  Future<List<OnlineUserSummary>> listOnlineUsers();
}

final class DriftRoomRepo implements RoomRepo {
  final AppDatabase _db;
  final PresenceRepo _presence;

  DriftRoomRepo({required AppDatabase db, PresenceRepo? presence})
    : _db = db,
      _presence = presence ?? DriftPresenceRepo(db: db);

  @override
  Future<T> transaction<T>(Future<T> Function() action) {
    return _db.transaction(action);
  }

  @override
  Future<List<RoomSummary>> list() async {
    final rows = await _db.customSelect('''
      SELECT id, name, current_players, max_players
      FROM rooms
      ORDER BY id ASC
      ''', readsFrom: const {}).get();

    return rows.map(_readSummary).toList(growable: false);
  }

  @override
  Future<RoomSummary?> summary(int id) async {
    final row = await _db
        .customSelect(
          'SELECT id, name, current_players, max_players FROM rooms WHERE id = ?1 LIMIT 1',
          variables: [Variable<int>(id)],
          readsFrom: const {},
        )
        .getSingleOrNull();

    return row == null ? null : _readSummary(row);
  }

  @override
  Future<RoomDetail?> detail(int id) async {
    final roomRow = await _db
        .customSelect(
          'SELECT id, name, current_players, max_players FROM rooms WHERE id = ?1 LIMIT 1',
          variables: [Variable<int>(id)],
          readsFrom: const {},
        )
        .getSingleOrNull();
    if (roomRow == null) return null;

    final memberRows = await _db
        .customSelect(
          'SELECT users.id AS user_id, users.username AS username, room_members.is_ready AS is_ready FROM room_members INNER JOIN users ON users.id = room_members.user_id WHERE room_members.room_id = ?1 ORDER BY room_members.joined_at ASC, users.username COLLATE NOCASE ASC',
          variables: [Variable<int>(id)],
          readsFrom: const {},
        )
        .get();

    return RoomDetail(
      id: roomRow.read<int>('id'),
      name: roomRow.read<String>('name'),
      currentPlayers: roomRow.read<int>('current_players'),
      maxPlayers: roomRow.read<int>('max_players'),
      members: memberRows
          .asMap()
          .entries
          .map(
            (e) => RoomMemberSummary(
              userId: e.value.read<int>('user_id'),
              username: e.value.read<String>('username'),
              isHost: e.key == 0,
              isReady: e.value.read<int>('is_ready') == 1,
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<LobbySnapshot> lobbySnapshot() async {
    final rooms = await list();
    final onlineUsers = await _presence.listOnlineUsers();
    return LobbySnapshot(rooms: rooms, onlineUsers: onlineUsers);
  }

  @override
  Future<int> create({
    required String name,
    required int currentPlayers,
    required int maxPlayers,
  }) async {
    final row = await _db
        .customSelect(
          'INSERT INTO rooms (name, current_players, max_players) VALUES (?1, ?2, ?3) RETURNING id',
          variables: [
            Variable<String>(name),
            Variable<int>(currentPlayers),
            Variable<int>(maxPlayers),
          ],
          readsFrom: const {},
        )
        .getSingle();

    return row.read<int>('id');
  }

  @override
  Future<void> delete(int id) {
    return _db.customStatement('DELETE FROM rooms WHERE id = ?1', [id]);
  }

  @override
  Future<void> updatePlayerCount({required int id, required int count}) {
    return _db.customStatement(
      'UPDATE rooms SET current_players = ?2 WHERE id = ?1',
      [id, count],
    );
  }

  @override
  Future<int> memberCount(int roomId) async {
    final row = await _db
        .customSelect(
          'SELECT COUNT(*) AS member_count FROM room_members WHERE room_id = ?1',
          variables: [Variable<int>(roomId)],
          readsFrom: const {},
        )
        .getSingle();

    return row.read<int>('member_count');
  }

  @override
  Future<void> touchUser(int userId) {
    return _db.customStatement(
      '''
      INSERT INTO online_users (user_id, updated_at)
      VALUES (?1, CURRENT_TIMESTAMP)
      ON CONFLICT(user_id) DO UPDATE SET updated_at = CURRENT_TIMESTAMP
      ''',
      [userId],
    );
  }

  RoomSummary _readSummary(QueryRow row) {
    return RoomSummary(
      id: row.read<int>('id'),
      name: row.read<String>('name'),
      currentPlayers: row.read<int>('current_players'),
      maxPlayers: row.read<int>('max_players'),
    );
  }
}

final class DriftRoomMemberRepo implements RoomMemberRepo {
  final AppDatabase _db;

  DriftRoomMemberRepo({required AppDatabase db}) : _db = db;

  @override
  Future<int?> findUserRoomId(int userId) async {
    final row = await _db
        .customSelect(
          'SELECT room_id FROM room_members WHERE user_id = ?1 LIMIT 1',
          variables: [Variable<int>(userId)],
          readsFrom: const {},
        )
        .getSingleOrNull();

    return row?.read<int>('room_id');
  }

  @override
  Future<void> removeUserFromAllRooms(int userId) {
    return _db.customStatement(
      'DELETE FROM room_members WHERE user_id = ?1',
      [userId],
    );
  }

  @override
  Future<void> removeUserFromRoom({required int roomId, required int userId}) {
    return _db.customStatement(
      'DELETE FROM room_members WHERE room_id = ?1 AND user_id = ?2',
      [roomId, userId],
    );
  }

  @override
  Future<void> addUserToRoom({required int roomId, required int userId}) {
    return _db.customStatement(
      'INSERT INTO room_members (room_id, user_id) VALUES (?1, ?2)',
      [roomId, userId],
    );
  }

  @override
  Future<void> toggleReady({required int roomId, required int userId}) {
    return _db.customStatement(
      'UPDATE room_members SET is_ready = 1 - is_ready WHERE room_id = ?1 AND user_id = ?2',
      [roomId, userId],
    );
  }
}

final class DriftPresenceRepo implements PresenceRepo {
  final AppDatabase _db;

  DriftPresenceRepo({required AppDatabase db}) : _db = db;

  @override
  Future<List<int>> staleUserIds({required int staleAfterSeconds}) async {
    final rows = await _db.customSelect('''
      SELECT user_id FROM online_users
      WHERE datetime(updated_at) <= datetime('now', '-$staleAfterSeconds seconds')
      ''', readsFrom: const {}).get();

    return rows.map((row) => row.read<int>('user_id')).toList(growable: false);
  }

  @override
  Future<Set<int>> roomIdsForUser(int userId) async {
    final rows = await _db
        .customSelect(
          'SELECT room_id FROM room_members WHERE user_id = ?1',
          variables: [Variable<int>(userId)],
          readsFrom: const {},
        )
        .get();

    return rows.map((row) => row.read<int>('room_id')).toSet();
  }

  @override
  Future<void> removeOnlineUser(int userId) {
    return _db.customStatement(
      'DELETE FROM online_users WHERE user_id = ?1',
      [userId],
    );
  }

  @override
  Future<List<OnlineUserSummary>> listOnlineUsers() async {
    final rows = await _db.customSelect('''
      SELECT
        users.id AS user_id,
        users.username AS username,
        rooms.id AS room_id,
        rooms.name AS room_name
      FROM online_users
      INNER JOIN users ON users.id = online_users.user_id
      LEFT JOIN room_members ON room_members.user_id = users.id
      LEFT JOIN rooms ON rooms.id = room_members.room_id
      ORDER BY users.username COLLATE NOCASE ASC
      ''', readsFrom: const {}).get();

    return rows
        .map(
          (row) => OnlineUserSummary(
            userId: row.read<int>('user_id'),
            username: row.read<String>('username'),
            roomId: row.readNullable<int>('room_id'),
            roomName: row.readNullable<String>('room_name'),
          ),
        )
        .toList(growable: false);
  }
}
