SQLite-backed auth server example.

- `GET /health`
- `POST /auth/signup`
- `POST /auth/login`

Run from the workspace root after one-time dependency resolution:

```bash
dart pub get
dart packages/darttu_server/bin/darttu_server.dart
```

Or:

```bash
make server
```
