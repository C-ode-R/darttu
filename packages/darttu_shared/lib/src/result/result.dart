sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;
}

class Ok<T> extends Result<T> {
  final T value;

  const Ok(this.value);
}

class Err<T> extends Result<T> {
  final String message;

  const Err(this.message);
}
