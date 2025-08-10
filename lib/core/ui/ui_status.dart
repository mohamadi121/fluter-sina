/// Unified UI status representation replacing scattered enums like CWSStatus / CommentStatus.
sealed class UiStatus {
  const UiStatus();
  bool get isIdle => this is UiIdle;
  bool get isLoading => this is UiLoading;
  bool get isSuccess => this is UiSuccess;
  bool get isError => this is UiError;
}

class UiIdle extends UiStatus { const UiIdle(); }
class UiLoading extends UiStatus { const UiLoading(); }
class UiSuccess extends UiStatus { const UiSuccess(); }
class UiError extends UiStatus { final String message; const UiError(this.message); }

extension UiStatusX on UiStatus {
  T when<T>({required T Function() idle, required T Function() loading, required T Function() success, required T Function(String msg) error}) {
    final s = this;
    if (s is UiIdle) return idle();
    if (s is UiLoading) return loading();
    if (s is UiSuccess) return success();
    return error((s as UiError).message);
  }
}
