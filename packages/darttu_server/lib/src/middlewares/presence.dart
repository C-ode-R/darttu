import '../repositories/rooms.dart';
import '../routes/socket.dart';
import '../services/room_membership.dart';

SocketMiddleware trackPresence(
  RoomMembershipService membership,
  RoomRepo rooms,
) {
  return (context, next) async {
    final userId = context.session.userId;
    if (userId == null) return next(context);

    await membership.cleanupStaleUsers();
    await rooms.touchUser(userId);

    return next(context);
  };
}
