const officialServerHost = 'darttu-server-0.coder.ac';

final class ServerConnectService {
  const ServerConnectService();

  Uri socketUri({String host = officialServerHost, int? port}) {
    return Uri(scheme: 'wss', host: host, port: port, path: '/ws');
  }

  Uri officialBaseUri({String host = officialServerHost, int? port}) {
    return _buildUri(host: host, port: port);
  }

  Uri healthUri({String host = officialServerHost, int? port}) {
    return _buildUri(host: host, port: port, path: '/health');
  }

  Uri signupUri({String host = officialServerHost, int? port}) {
    return _buildUri(host: host, port: port, path: '/auth/signup');
  }

  Uri loginUri({String host = officialServerHost, int? port}) {
    return _buildUri(host: host, port: port, path: '/auth/login');
  }

  Uri sessionUri({String host = officialServerHost, int? port}) {
    return _buildUri(host: host, port: port, path: '/auth/session');
  }

  Uri _buildUri({required String host, required int? port, String path = ''}) {
    return Uri(scheme: 'https', host: host, port: port, path: path);
  }
}
