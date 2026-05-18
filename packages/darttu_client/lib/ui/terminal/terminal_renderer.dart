import 'dart:io';

final class TerminalRenderer {
  bool _initialized = false;

  void init() {
    if (_initialized) {
      return;
    }

    // Alternate screen buffer 진입.
    // 앱 종료 후 원래 터미널 화면을 복구할 수 있습니다.
    stdout.write('\x1B[?1049h');

    // 커서 숨김.
    stdout.write('\x1B[?25l');

    // 화면 전체 지움.
    stdout.write('\x1B[2J');

    // 커서를 좌상단으로 이동.
    stdout.write('\x1B[H');

    _initialized = true;
  }

  void render(String output) {
    if (!_initialized) {
      init();
    }

    // 커서를 좌상단으로 이동.
    stdout.write('\x1B[H');

    // 새 화면 출력.
    stdout.write(output);

    // 현재 커서 위치부터 화면 끝까지 삭제.
    // 이전 렌더보다 현재 렌더가 짧을 때 잔상이 남는 것을 방지합니다.
    stdout.write('\x1B[J');
  }

  void dispose() {
    if (!_initialized) {
      return;
    }

    // 스타일 초기화.
    stdout.write('\x1B[0m');

    // 커서 다시 표시.
    stdout.write('\x1B[?25h');

    // Alternate screen buffer 종료.
    // 원래 터미널 화면으로 돌아갑니다.
    stdout.write('\x1B[?1049l');

    _initialized = false;
  }
}
