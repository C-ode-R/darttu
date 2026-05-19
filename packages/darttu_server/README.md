SQLite-backed auth server example.

- `POST /auth/signup`
- `POST /auth/login`
- `GET /auth/session`
- `GET /ws` upgrade for lobby/room actions

Run from the workspace root after one-time dependency resolution:

```bash
dart pub get
dart packages/darttu_server/bin/darttu_server.dart
```

Or:

```bash
make server
```
