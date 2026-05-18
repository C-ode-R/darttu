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

  const RoomMemberSummary({
    required this.userId,
    required this.username,
    required this.isHost,
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

abstract interface class RoomsRepo {
  Future<void> cleanupStaleUsers();
  Future<void> disconnectUser(int userId);
  Future<List<RoomSummary>> listRooms();
  Future<List<OnlineUserSummary>> listOnlineUsers();
  Future<LobbySnapshot> getLobbySnapshot();
  Future<void> touchUser(int userId);
  Future<RoomSummary?> createRoom({
    required String name,
    required int currentPlayers,
    required int maxPlayers,
    required int ownerUserId,
  });
  Future<RoomDetail?> getRoom(int roomId);
  Future<RoomDetail?> joinRoom({required int roomId, required int userId});
  Future<RoomDetail?> leaveRoom({required int roomId, required int userId});
}

final class DriftRoomsRepo implements RoomsRepo {
  final AppDatabase _database;
  static const _presenceTimeoutSeconds = 60;

  DriftRoomsRepo({required AppDatabase database}) : _database = database;

  @override
  Future<void> cleanupStaleUsers() async {
    final staleUserRows = await _database.customSelect('''
      SELECT user_id
      FROM online_users
      WHERE datetime(updated_at) <= datetime('now', '-$_presenceTimeoutSeconds seconds')
      ''', readsFrom: const {}).get();

    if (staleUserRows.isEmpty) {
      return;
    }

    final staleUserIds = staleUserRows
        .map((row) => row.read<int>('user_id'))
        .toList(growable: false);

    await _database.transaction(() async {
      final affectedRoomIds = <int>{};

      for (final userId in staleUserIds) {
        final roomRows = await _database
            .customSelect(
              'SELECT room_id FROM room_members WHERE user_id = ?1',
              variables: [Variable<int>(userId)],
              readsFrom: const {},
            )
            .get();

        for (final roomRow in roomRows) {
          affectedRoomIds.add(roomRow.read<int>('room_id'));
        }

        await _database.customStatement(
          'DELETE FROM room_members WHERE user_id = ?1',
          [userId],
        );
        await _database.customStatement(
          'DELETE FROM online_users WHERE user_id = ?1',
          [userId],
        );
      }

      for (final roomId in affectedRoomIds) {
        await _normalizeRoom(roomId);
      }
    });
  }

  @override
  Future<void> disconnectUser(int userId) async {
    await _database.transaction(() async {
      final roomRows = await _database.customSelect(
        'SELECT room_id FROM room_members WHERE user_id = ?1',
        variables: [Variable<int>(userId)],
        readsFrom: const {},
      ).get();

      final affectedRoomIds = roomRows
          .map((row) => row.read<int>('room_id'))
          .toSet();

      await _database.customStatement(
        'DELETE FROM room_members WHERE user_id = ?1',
        [userId],
      );
      await _database.customStatement(
        'DELETE FROM online_users WHERE user_id = ?1',
        [userId],
      );

      for (final roomId in affectedRoomIds) {
        await _normalizeRoom(roomId);
      }
    });
  }

  @override
  Future<List<RoomSummary>> listRooms() async {
    final rows = await _database.customSelect('''
      SELECT id, name, current_players, max_players
      FROM rooms
      ORDER BY id ASC
      ''', readsFrom: const {}).get();

    return rows.map(_readRoomSummary).toList(growable: false);
  }

  @override
  Future<List<OnlineUserSummary>> listOnlineUsers() async {
    final rows = await _database.customSelect('''
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

  @override
  Future<LobbySnapshot> getLobbySnapshot() async {
    final rooms = await listRooms();
    final onlineUsers = await listOnlineUsers();
    return LobbySnapshot(rooms: rooms, onlineUsers: onlineUsers);
  }

  @override
  Future<void> touchUser(int userId) async {
    await _database.customStatement(
      '''
      INSERT INTO online_users (user_id, updated_at)
      VALUES (?1, CURRENT_TIMESTAMP)
      ON CONFLICT(user_id) DO UPDATE SET updated_at = CURRENT_TIMESTAMP
      ''',
      [userId],
    );
  }

  @override
  Future<RoomSummary?> createRoom({
    required String name,
    required int currentPlayers,
    required int maxPlayers,
    required int ownerUserId,
  }) async {
    try {
      await _database.transaction(() async {
        final previousRoomRows = await _database
            .customSelect(
              'SELECT room_id FROM room_members WHERE user_id = ?1 LIMIT 1',
              variables: [Variable<int>(ownerUserId)],
              readsFrom: const {},
            )
            .get();
        final previousRoomId = previousRoomRows.isEmpty
            ? null
            : previousRoomRows.first.read<int>('room_id');

        final row = await _database
            .customSelect(
              '''
          INSERT INTO rooms (name, current_players, max_players)
          VALUES (?1, ?2, ?3)
          RETURNING id
          ''',
              variables: [
                Variable<String>(name),
                Variable<int>(currentPlayers),
                Variable<int>(maxPlayers),
              ],
              readsFrom: const {},
            )
            .getSingle();
        final roomId = row.read<int>('id');

        await _database.customStatement(
          'DELETE FROM room_members WHERE user_id = ?1',
          [ownerUserId],
        );
        await _database.customStatement(
          '''
          INSERT INTO room_members (room_id, user_id)
          VALUES (?1, ?2)
          ''',
          [roomId, ownerUserId],
        );

        if (previousRoomId != null) {
          await _normalizeRoom(previousRoomId);
        }
        await _normalizeRoom(roomId);
      });
    } on Object {
      return null;
    }

    final createdRoom = await _database
        .customSelect(
          '''
      SELECT id, name, current_players, max_players
      FROM rooms
      WHERE name = ?1
      LIMIT 1
      ''',
          variables: [Variable<String>(name)],
          readsFrom: const {},
        )
        .getSingleOrNull();

    if (createdRoom == null) {
      return null;
    }

    return _readRoomSummary(createdRoom);
  }

  @override
  Future<RoomDetail?> getRoom(int roomId) async {
    final roomRow = await _database
        .customSelect(
          '''
      SELECT id, name, current_players, max_players
      FROM rooms
      WHERE id = ?1
      LIMIT 1
      ''',
          variables: [Variable<int>(roomId)],
          readsFrom: const {},
        )
        .getSingleOrNull();
    if (roomRow == null) {
      return null;
    }

    final memberRows = await _database
        .customSelect(
          '''
      SELECT users.id AS user_id, users.username AS username
      FROM room_members
      INNER JOIN users ON users.id = room_members.user_id
      WHERE room_members.room_id = ?1
      ORDER BY room_members.joined_at ASC, users.username COLLATE NOCASE ASC
      ''',
          variables: [Variable<int>(roomId)],
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
            (entry) => RoomMemberSummary(
              userId: entry.value.read<int>('user_id'),
              username: entry.value.read<String>('username'),
              isHost: entry.key == 0,
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<RoomDetail?> joinRoom({
    required int roomId,
    required int userId,
  }) async {
    final room = await getRoom(roomId);
    if (room == null) {
      return null;
    }
    if (room.currentPlayers >= room.maxPlayers &&
        !room.members.any((member) => member.userId == userId)) {
      return null;
    }

    await _database.transaction(() async {
      final previousRoomRows = await _database
          .customSelect(
            'SELECT room_id FROM room_members WHERE user_id = ?1 LIMIT 1',
            variables: [Variable<int>(userId)],
            readsFrom: const {},
          )
          .get();

      final previousRoomId = previousRoomRows.isEmpty
          ? null
          : previousRoomRows.first.read<int>('room_id');

      await _database.customStatement(
        'DELETE FROM room_members WHERE user_id = ?1',
        [userId],
      );

      await _database.customStatement(
        '''
        INSERT INTO room_members (room_id, user_id)
        VALUES (?1, ?2)
        ''',
        [roomId, userId],
      );

      if (previousRoomId != null) {
        await _normalizeRoom(previousRoomId);
      }
      await _normalizeRoom(roomId);
    });

    return getRoom(roomId);
  }

  @override
  Future<RoomDetail?> leaveRoom({
    required int roomId,
    required int userId,
  }) async {
    await _database.transaction(() async {
      await _database.customStatement(
        'DELETE FROM room_members WHERE room_id = ?1 AND user_id = ?2',
        [roomId, userId],
      );
      await _normalizeRoom(roomId);
    });

    return getRoom(roomId);
  }

  RoomSummary _readRoomSummary(QueryRow row) {
    return RoomSummary(
      id: row.read<int>('id'),
      name: row.read<String>('name'),
      currentPlayers: row.read<int>('current_players'),
      maxPlayers: row.read<int>('max_players'),
    );
  }

  Future<void> _normalizeRoom(int roomId) async {
    final countRow = await _database
        .customSelect(
          '''
      SELECT COUNT(*) AS member_count
      FROM room_members
      WHERE room_id = ?1
      ''',
          variables: [Variable<int>(roomId)],
          readsFrom: const {},
        )
        .getSingle();

    final memberCount = countRow.read<int>('member_count');
    if (memberCount <= 0) {
      await _database.customStatement('DELETE FROM rooms WHERE id = ?1', [
        roomId,
      ]);
      return;
    }

    await _database.customStatement(
      '''
      UPDATE rooms
      SET current_players = (
        SELECT COUNT(*)
        FROM room_members
        WHERE room_members.room_id = ?1
      )
      WHERE id = ?1
      ''',
      [roomId],
    );
  }
}
