import 'dart:async';

/// Cancels a scheduled action.
typedef Cancel = void Function();

/// Runs [action] after [delay] and returns a way to cancel it. Tests pass a
/// manual implementation; the default one uses a [Timer].
typedef Schedule = Cancel Function(Duration delay, void Function() action);

/// The default [Schedule]: a real [Timer].
Cancel timerSchedule(Duration delay, void Function() action) {
  final timer = Timer(delay, action);
  return timer.cancel;
}
