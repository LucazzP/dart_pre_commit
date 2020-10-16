import 'dart:convert';
import 'dart:io';

import 'logger.dart';
import 'task_error.dart';

class ProgramRunner {
  final Logger _logger;
  final String workingDirectory;

  const ProgramRunner(this._logger, this.workingDirectory);

  Stream<String> stream(
    String program,
    List<String> arguments, {
    bool failOnExit = true,
  }) async* {
    final process = await Process.start(
      program,
      arguments,
      runInShell: true,
      workingDirectory: workingDirectory,
    );
    _logger.pipeStderr(process.stderr);
    yield* process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    if (failOnExit) {
      final exitCode = await process.exitCode;
      if (exitCode != 0) {
        throw TaskError("$program failed with exit code $exitCode");
      }
    }
  }

  Future<int> run(
    String program,
    List<String> arguments, {
    bool runInShell = true,
  }) async {
    final process = await Process.start(
      program,
      arguments,
      runInShell: runInShell,
      workingDirectory: workingDirectory,
    );
    _logger.pipeStderr(process.stderr);
    final stream = process.stdout.asBroadcastStream();
    stream.listen((event) {
      _logger.log(utf8.decode(event));
    });
    await stream.drain<void>();
    return process.exitCode;
  }
}
