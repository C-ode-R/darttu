String resolveErrorMessage(
  String error, {
  List<Map<String, String>> catalogs = const [],
}) {
  for (final catalog in catalogs) {
    final message = catalog[error];
    if (message != null) {
      return message;
    }
  }

  return error;
}

const commonErrorMessages = <String, String>{
  'invalid_json': '요청 형식이 올바르지 않습니다.',
  'server_unreachable': '서버에 연결할 수 없습니다.',
  'invalid_server_response': '서버 응답을 해석할 수 없습니다.',
};

const sessionErrorMessages = <String, String>{
  'session_required': '세션이 만료되었습니다.',
  'invalid_session': '세션이 만료되었습니다.',
};

const authErrorMessages = <String, String>{
  'invalid_credentials': '아이디와 비밀번호를 확인해주세요.',
  'username_already_exists': '이미 존재하는 아이디입니다.',
  'invalid_username_or_password': '아이디 또는 비밀번호가 올바르지 않습니다.',
};

const roomErrorMessages = <String, String>{
  'invalid_room_name': '방 이름을 확인해주세요.',
  'invalid_room_capacity': '방 인원 설정이 올바르지 않습니다.',
  'room_name_already_exists': '이미 같은 이름의 방이 있습니다.',
  'room_not_found': '방을 찾을 수 없습니다.',
  'room_full': '방 인원이 가득 찼습니다.',
};
