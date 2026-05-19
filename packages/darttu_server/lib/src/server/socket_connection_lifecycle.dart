import '../routes/socket.dart';
import '../services/room_membership.dart';

abstract interface class SocketConnectionLifecycle {
  Future<void> onDisconnected(SocketSession session);
}

final class RoomsSocketConnectionLifecycle
    implements SocketConnectionLifecycle {
  final RoomMembershipService _membership;

  RoomsSocketConnectionLifecycle({required RoomMembershipService membership})
    : _membership = membership;

  @override
  Future<void> onDisconnected(SocketSession session) async {
    if (session.userId == null) return;
    try {
      await _membership.disconnectUser(session.userId!);
    } on Object {
      // Ignore errors during disconnect (e.g., database closing).
    }
  }
}
