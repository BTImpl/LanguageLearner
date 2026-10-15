import 'package:languagelearner/features/play/round/schedule.dart';

/// A fake clock: scheduled actions run when the time is moved forward.
class ManualScheduler {
  final _tasks = <({Duration due, void Function() action})>[];
  var _now = Duration.zero;

  /// Use as the `schedule` of a game.
  Cancel call(Duration delay, void Function() action) {
    final task = (due: _now + delay, action: action);
    _tasks.add(task);
    return () => _tasks.remove(task);
  }

  /// The number of actions waiting.
  int get pending => _tasks.length;

  /// Moves the clock forward and runs the actions that are due.
  void elapse(Duration time) {
    _now += time;
    final due = _tasks.where((task) => task.due <= _now).toList();
    _tasks.removeWhere(due.contains);
    for (final task in due) {
      task.action();
    }
  }
}
