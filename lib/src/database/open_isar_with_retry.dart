import 'package:isar_community/isar.dart';

/// Retry only environment-open errors that can result from competing openers.
/// Incompatibility can also be permanent; never delete files or change flags.
Future<T> openIsarWithRetry<T>(
  Future<T> Function() open, {
  Future<void> Function(Duration)? delay,
  void Function(String)? log,
  Future<void> Function(IsarError, StackTrace)? onOpenFailure,
}) async {
  const delays = [100, 250, 500, 1000];
  final wait = delay ?? Future<void>.delayed;
  var attempt = 0;
  while (true) {
    try {
      return await open();
    } on IsarError catch (error, stack) {
      final message = error.toString();
      final environmentError = message.contains('Cannot open Environment');
      final retryable = environmentError &&
          RegExp(r'MdbxError \((11|-30784)\):').hasMatch(message);
      if (!retryable) rethrow;
      if (attempt < delays.length) {
        final milliseconds = delays[attempt++];
        log?.call('Isar open failed: $error; retry $attempt/${delays.length} '
            'in ${milliseconds}ms');
        await wait(Duration(milliseconds: milliseconds));
        continue;
      }
      log?.call('Isar open recovery exhausted: $error');
      if (onOpenFailure == null) rethrow;
      // The caller controls recovery pacing, e.g. a longer background backoff.
      await onOpenFailure(error, stack);
      attempt = 0;
    }
  }
}
