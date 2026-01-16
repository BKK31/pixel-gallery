import 'dart:async';
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

final ServicePolicy servicePolicy = ServicePolicy._private();

class ServicePolicy {
  final Map<Object, (int, _Task)> _paused = {};
  final SplayTreeMap<int, LinkedHashMap<Object, _Task>> _queues =
      SplayTreeMap();
  final LinkedHashMap<Object, _Task> _runningQueue = LinkedHashMap();

  // Limit concurrent tasks to avoid saturating platform channels
  static const concurrentTaskMax = 4;

  ServicePolicy._private();

  Future<T> call<T>(
    Future<T> Function() platformCall, {
    int priority = ServiceCallPriority.normal,
    Object? key,
  }) {
    Completer<T> taskCompleter;
    _Task<T> task;
    key ??= platformCall.hashCode;

    final toResume = _paused.remove(key);
    if (toResume != null) {
      priority = toResume.$1;
      task = toResume.$2 as _Task<T>;
      taskCompleter = task.completer;
    } else {
      taskCompleter = Completer<T>();
      task = _Task<T>(() async {
        try {
          taskCompleter.complete(await platformCall());
        } catch (error, stack) {
          if (!taskCompleter.isCompleted) {
            taskCompleter.completeError(error, stack);
          }
        }
        _runningQueue.remove(key);
        _pickNext();
      }, taskCompleter);
    }

    _getQueue(priority)[key] = task;
    _pickNext();
    return taskCompleter.future;
  }

  Future<T>? resume<T>(Object key) {
    final toResume = _paused.remove(key);
    if (toResume != null) {
      final priority = toResume.$1;
      final task = toResume.$2 as _Task<T>;
      _getQueue(priority)[key] = task;
      _pickNext();
      return task.completer.future;
    } else {
      return null;
    }
  }

  LinkedHashMap<Object, _Task> _getQueue(int priority) =>
      _queues.putIfAbsent(priority, LinkedHashMap.new);

  void _pickNext() {
    if (_runningQueue.length >= concurrentTaskMax) return;

    final queue = _queues.entries
        .firstWhereOrNull((kv) => kv.value.isNotEmpty)
        ?.value;
    if (queue != null && queue.isNotEmpty) {
      // Use LIFO (Last-In, First-Out) for better responsiveness during scrolling.
      // This ensures the most recently requested thumbnails (on-screen) are processed first.
      final key = queue.keys.last;
      final task = queue.remove(key)!;
      _runningQueue[key] = task;
      task.callback();
    }
  }

  bool _takeOut(
    Object key,
    Iterable<int> priorities,
    void Function(int priority, _Task task) action,
  ) {
    var out = false;
    for (final priority in priorities) {
      final task = _getQueue(priority).remove(key);
      if (task != null) {
        out = true;
        action(priority, task);
      }
    }
    return out;
  }

  bool cancel(Object key, Iterable<int> priorities) {
    return _takeOut(key, priorities, (priority, task) {
      if (!task.completer.isCompleted) {
        task.completer.completeError(CancelledException());
      }
    });
  }

  bool pause(Object key, Iterable<int> priorities) {
    return _takeOut(
      key,
      priorities,
      (priority, task) => _paused.putIfAbsent(key, () => (priority, task)),
    );
  }

  bool isPaused(Object key) => _paused.containsKey(key);
}

class _Task<T> {
  final VoidCallback callback;
  final Completer<T> completer;

  const _Task(this.callback, this.completer);
}

class CancelledException implements Exception {}

class ServiceCallPriority {
  static const int getFastThumbnail = 100;
  static const int getRegion = 150;
  static const int getSizedThumbnail = 200;
  static const int normal = 500;
  static const int getMetadata = 1000;
  static const int getLocation = 1000;
}
